import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:push_notification_service/push_notification_service.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/controllers/live_broadcast_controller.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/controllers/pk_battle_controller.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/repo/pk/pk_repo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/pk/pk_v1_coordinator.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

/// Handles FCM / tray actions for PK Battle types from the backend guide.
class PkBattlePushHandler {
  PkBattlePushHandler({PkRepo? pkRepo}) : _pkRepo = pkRepo ?? PkRepo();

  final PkRepo _pkRepo;

  static bool isPkMessage(PushNotificationMessage message) {
    final type = message.data['type']?.toString().trim().toLowerCase() ?? '';
    return PushNotificationTypes.isPkType(type);
  }

  Future<void> handleNotificationTap(PushNotificationMessage message) async {
    final type = message.data['type']?.toString().trim().toLowerCase() ?? '';
    if (!PushNotificationTypes.isPkType(type)) return;

    if (PushNotificationTypes.isFollowerPkType(type)) {
      await _openFollowerArena(message.data, type: type);
      return;
    }

    if (type == PushNotificationTypes.pkRequest) {
      await _openIncomingChallenge(message.data);
      return;
    }

    if (type == PushNotificationTypes.pkRejected ||
        type == PushNotificationTypes.pkCancelled) {
      if (Get.isRegistered<PKBattleController>()) {
        final pk = Get.find<PKBattleController>();
        if (type == PushNotificationTypes.pkRejected) {
          pk.handlePkRejected(message.data);
        } else {
          pk.handlePkCancelled(message.data);
        }
      } else {
        _toast(
          type == PushNotificationTypes.pkRejected
              ? 'Your PK request was rejected.'
              : 'The PK request was cancelled.',
        );
      }
      return;
    }

    await _openArenaFromLifecycle(message.data, type: type);
  }

  Future<void> handleNotificationAction({
    required String actionId,
    required PushNotificationMessage message,
  }) async {
    final type = message.data['type']?.toString().trim().toLowerCase() ?? '';
    if (!PushNotificationTypes.isPkType(type)) return;

    if (PushNotificationTypes.isFollowerPkType(type)) {
      if (actionId == PushNotificationActions.acceptPk) {
        await _openFollowerArena(message.data, type: type);
        await Future<void>.delayed(const Duration(milliseconds: 120));
        if (Get.isRegistered<PKBattleController>()) {
          await Get.find<PKBattleController>().acceptFollowerChallenge();
        }
      }
      await PushNotificationService.instance.cancelLocalNotification(message);
      return;
    }

    switch (actionId) {
      case PushNotificationActions.acceptPk:
        await _respondToRequest(message.data, action: 'accept');
      case PushNotificationActions.rejectPk:
        await _respondToRequest(message.data, action: 'reject');
      default:
        await handleNotificationTap(message);
    }

    await PushNotificationService.instance.cancelLocalNotification(message);
  }

  /// Socket payloads reuse the same field names as FCM data.
  Future<void> handleSocketEvent(
    String event,
    Map<String, dynamic> data,
  ) async {
    final type =
        (data['type']?.toString().trim().isNotEmpty == true
                ? data['type'].toString()
                : event)
            .trim()
            .toLowerCase();
    LoggerUtils.logInfo(
      'PkBattlePush: socket event=$event type=$type data=$data',
    );

    if (PushNotificationTypes.isFollowerPkType(type)) {
      if (Get.isRegistered<PKBattleController>()) {
        Get.find<PKBattleController>().handleFollowerPkEvent(type, data);
      } else if (type == PushNotificationTypes.pkFollowerInvite) {
        await _openFollowerArena(data, type: type);
      }

      // Keep seat PK badges / gift targets fresh for everyone still in-room.
      if (type != PushNotificationTypes.pkFollowerInvite &&
          Get.isRegistered<LiveBroadcastController>()) {
        unawaited(Get.find<LiveBroadcastController>().loadAudioRoomSeats());
      }
      return;
    }

    if (Get.isRegistered<PKBattleController>()) {
      // Prefer in-room V1 PK while a live session is open.
      if (_isInActiveLiveRoom() &&
          (type == PushNotificationTypes.pkStarted ||
              type == PushNotificationTypes.pkAccepted ||
              type == PushNotificationTypes.pkRequest)) {
        if (type == PushNotificationTypes.pkStarted ||
            type == PushNotificationTypes.pkAccepted) {
          await _ensureEmbeddedPkV1(data);
        }
        _dismissLegacyPkArenaIfOpen();
        return;
      }

      final pk = Get.find<PKBattleController>();
      switch (type) {
        case PushNotificationTypes.pkRequest:
          pk.handleIncomingPkRequest(data);
          return;
        case PushNotificationTypes.pkStarted:
        case PushNotificationTypes.pkAccepted:
          pk.handlePkStarted(data);
          return;
        case 'pk_score_update':
          pk.handlePkScoreUpdate(data);
          return;
        case PushNotificationTypes.pkCompleted:
          pk.handlePkCompleted(data);
          return;
        case PushNotificationTypes.pkRejected:
          pk.handlePkRejected(data);
          return;
        case PushNotificationTypes.pkCancelled:
          pk.handlePkCancelled(data);
          return;
      }
    }

    if (type == PushNotificationTypes.pkRequest) {
      await _openIncomingChallenge(data);
      return;
    }
    if (type == PushNotificationTypes.pkRejected) {
      _toast('Your PK request was rejected.');
      return;
    }
    if (type == PushNotificationTypes.pkCancelled) {
      _toast('The PK request was cancelled.');
      return;
    }
    if (type == PushNotificationTypes.pkStarted ||
        type == PushNotificationTypes.pkAccepted ||
        type == PushNotificationTypes.pkCompleted) {
      await _openArenaFromLifecycle(data, type: type);
    }
  }

  Future<void> _openIncomingChallenge(Map<String, dynamic> data) async {
    // Live streaming / in-room PK must never leave the live screen.
    // V1 invitations are shown via [PkV1Coordinator] dialog instead.
    if (_isInActiveLiveRoom()) {
      LoggerUtils.logInfo(
        'PkBattlePush: skip legacy PK arena for incoming challenge (stay in live)',
      );
      return;
    }

    final myRoomId = _resolveMyRoomId(data);
    final args = <String, dynamic>{
      'room_id': myRoomId,
      'incoming_pk': true,
      ...data,
    };

    if (Get.isRegistered<PKBattleController>()) {
      Get.find<PKBattleController>().handleIncomingPkRequest(data);
      if (Get.currentRoute != Routes.PK_BATTLE) {
        Get.toNamed(Routes.PK_BATTLE, arguments: args);
      }
      return;
    }

    Get.toNamed(Routes.PK_BATTLE, arguments: args);
  }

  Future<void> _openFollowerArena(
    Map<String, dynamic> data, {
    required String type,
  }) async {
    final args = <String, dynamic>{
      'mode': 'audio_follower_pk',
      'room_id': _resolveMyRoomId(data),
      'lifecycle_type': type,
      'type': type,
      ...data,
    };

    if (Get.isRegistered<PKBattleController>()) {
      Get.find<PKBattleController>().handleFollowerPkEvent(type, data);
      if (Get.currentRoute != Routes.PK_BATTLE) {
        Get.toNamed(Routes.PK_BATTLE, arguments: args);
      }
      return;
    }
    Get.toNamed(Routes.PK_BATTLE, arguments: args);
  }

  Future<void> _openArenaFromLifecycle(
    Map<String, dynamic> data, {
    required String type,
  }) async {
    // Host-vs-host PK while live must stay embedded in the live room.
    // Legacy `pk_started` / `pk_accepted` used to push PKBattleView ("End Battle"
    // screen) on top of the stream — that breaks camera / chat / gifts.
    if (_isInActiveLiveRoom()) {
      LoggerUtils.logInfo(
        'PkBattlePush: keep host PK embedded in live (type=$type)',
      );
      if (type == PushNotificationTypes.pkStarted ||
          type == PushNotificationTypes.pkAccepted) {
        await _ensureEmbeddedPkV1(data);
      }
      _dismissLegacyPkArenaIfOpen();
      return;
    }

    final myRoomId = _resolveMyRoomId(data);
    final args = <String, dynamic>{
      'room_id': myRoomId,
      'lifecycle_type': type,
      ...data,
    };

    if (Get.isRegistered<PKBattleController>()) {
      final pk = Get.find<PKBattleController>();
      if (type == PushNotificationTypes.pkStarted ||
          type == PushNotificationTypes.pkAccepted) {
        pk.handlePkStarted(data);
      } else if (type == PushNotificationTypes.pkCompleted) {
        pk.handlePkCompleted(data);
      } else if (type == PushNotificationTypes.pkRejected) {
        pk.handlePkRejected(data);
      } else if (type == PushNotificationTypes.pkCancelled) {
        pk.handlePkCancelled(data);
      }
      if (Get.currentRoute != Routes.PK_BATTLE) {
        Get.toNamed(Routes.PK_BATTLE, arguments: args);
      }
      return;
    }

    Get.toNamed(Routes.PK_BATTLE, arguments: args);
  }

  Future<void> _respondToRequest(
    Map<String, dynamic> data, {
    required String action,
  }) async {
    // Prefer V1 accept/reject while already in a live room (no arena navigation).
    if (_isInActiveLiveRoom()) {
      final invitationId = _text(data['invitationId']) ??
          _text(data['invitation_id']) ??
          _text(data['request_id']) ??
          _text(data['requestId']);
      if (invitationId != null && invitationId.isNotEmpty) {
        final pk = PkV1Coordinator.ensureController();
        final live = Get.find<LiveBroadcastController>();
        final roomApiId = live.audioRoomApiId.trim().isNotEmpty
            ? live.audioRoomApiId.trim()
            : live.roomId.value.trim();
        pk.bindLiveRoomContext(
          roomId: roomApiId,
          name: live.hostName.value,
          avatar: live.hostAvatarUrl.value,
        );
        if (action == 'accept') {
          await pk.acceptInvitationById(invitationId);
        } else {
          await pk.rejectInvitationById(invitationId);
        }
        return;
      }
    }

    final myRoomId = _resolveMyRoomId(data);
    final requestId =
        _text(data['request_id']) ?? _text(data['sender_room_id']) ?? '';
    if (myRoomId.isEmpty || requestId.isEmpty) {
      _toast('PK request details are missing.', isError: true);
      return;
    }

    // Ensure arena controller is ready so accept can start the battle UI.
    await _openIncomingChallenge(data);
    await Future<void>.delayed(const Duration(milliseconds: 120));

    if (Get.isRegistered<PKBattleController>()) {
      final pk = Get.find<PKBattleController>();
      if (action == 'accept') {
        await pk.acceptChallenge();
      } else {
        await pk.rejectChallenge();
      }
      return;
    }

    final response = await _pkRepo.acceptRejectPkRequest(
      roomId: myRoomId,
      requestId: requestId,
      action: action,
      duration: int.tryParse(data['battle_duration']?.toString() ?? '') ?? 300,
    );
    final ok =
        response?['success'] == true ||
        response?['statusCode'] == 1 ||
        response?['statusCode'] == 200;
    if (!ok) {
      _toast(
        response?['message']?.toString() ?? 'Unable to $action PK request.',
        isError: true,
      );
      return;
    }
    _toast(action == 'accept' ? 'PK battle accepted.' : 'PK request rejected.');
  }

  String _resolveMyRoomId(Map<String, dynamic> data) {
    if (Get.isRegistered<LiveBroadcastController>()) {
      final live = Get.find<LiveBroadcastController>();
      final apiId = live.audioRoomApiId.trim();
      if (apiId.isNotEmpty) return apiId;
      if (live.roomId.value.trim().isNotEmpty) return live.roomId.value.trim();
    }

    // For recipient of pk_request, room_id is their own room.
    return _text(data['room_id']) ?? _text(data['target_room_id']) ?? '';
  }

  /// True when the user is already inside a live / audio / video room screen.
  bool _isInActiveLiveRoom() {
    if (!Get.isRegistered<LiveBroadcastController>()) return false;
    final live = Get.find<LiveBroadcastController>();
    return live.audioRoomApiId.trim().isNotEmpty ||
        live.roomId.value.trim().isNotEmpty ||
        live.liveStreamingApiId.trim().isNotEmpty;
  }

  /// Hand host PK lifecycle to the in-room V1 controller (no route push).
  Future<void> _ensureEmbeddedPkV1(Map<String, dynamic> data) async {
    if (!Get.isRegistered<LiveBroadcastController>()) return;
    final live = Get.find<LiveBroadcastController>();
    final roomApiId = live.audioRoomApiId.trim().isNotEmpty
        ? live.audioRoomApiId.trim()
        : live.roomId.value.trim();
    final pk = PkV1Coordinator.ensureController();
    pk.bindLiveRoomContext(
      roomId: roomApiId,
      name: live.hostName.value,
      avatar: live.hostAvatarUrl.value,
    );

    final pkId = _text(data['pkId']) ??
        _text(data['pk_id']) ??
        _text(data['battle_id']) ??
        _text(data['battleId']) ??
        pk.session.value?.pkId;
    if (pkId == null || pkId.isEmpty) {
      // Still mark embedded so live UI can show PK chrome if session arrives.
      pk.embeddedInLiveRoom.value = true;
      return;
    }
    await pk.refreshSession(pkId);
  }

  void _dismissLegacyPkArenaIfOpen() {
    try {
      if (Get.currentRoute.contains('pk-battle') &&
          (Get.key.currentState?.canPop() ?? false)) {
        Get.back();
      }
    } catch (_) {}
  }

  String? _text(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return null;
    return text;
  }

  void _toast(String message, {bool isError = false}) {
    final context = Get.overlayContext ?? Get.context;
    if (context == null) {
      Get.snackbar(
        'PK Battle',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: isError ? Colors.redAccent : Colors.black87,
        colorText: kColorWhite,
      );
      return;
    }
    if (isError) {
      AppToast.showError(context, message);
    } else {
      AppToast.showSuccess(context, message);
    }
  }
}
