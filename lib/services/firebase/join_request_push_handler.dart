import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:push_notification_service/push_notification_service.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/controllers/live_broadcast_controller.dart';
import 'package:qobo_one_live/repo/room/room_repo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/firebase/join_request_payload.dart';
import 'package:qobo_one_live/services/room/join_approval_service.dart';
import 'package:qobo_one_live/utils/app_widgets/join_request_in_app_banner.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';
import 'package:qobo_one_live/utils/zego_engine_utils.dart';

/// Handles FCM / tray / socket events for host join approval.
class JoinRequestPushHandler {
  JoinRequestPushHandler({RoomRepo? roomRepo})
    : _roomRepo = roomRepo ?? RoomRepo();

  final RoomRepo _roomRepo;

  static bool isJoinRequestMessage(PushNotificationMessage message) {
    final type = message.data['type']?.toString().trim().toLowerCase() ?? '';
    return PushNotificationTypes.isJoinRequestType(type);
  }

  Future<void> handleNotificationTap(PushNotificationMessage message) async {
    final payload = JoinRequestPayload.fromMessage(message);
    if (payload == null) return;

    if (payload.isHostRequest) {
      await _openHostInbox(payload);
      return;
    }
    if (payload.isApproved) {
      await _enterAfterApproval(payload, sourceMessage: message);
      return;
    }
    if (payload.isRejected || payload.isExpired) {
      _toast(payload.bannerBody);
    }
  }

  Future<void> handleNotificationAction({
    required String actionId,
    required PushNotificationMessage message,
  }) async {
    final payload = JoinRequestPayload.fromMessage(message);
    if (payload == null) return;

    switch (actionId) {
      case PushNotificationActions.approveJoin:
        await respond(payload, action: 'approve', sourceMessage: message);
      case PushNotificationActions.rejectJoin:
        await respond(payload, action: 'reject', sourceMessage: message);
      default:
        await handleNotificationTap(message);
    }

    await PushNotificationService.instance.cancelLocalNotification(message);
  }

  Future<void> handleSocketEvent(
    String event,
    Map<String, dynamic> data,
  ) async {
    final type = (data['type']?.toString().trim().isNotEmpty == true
            ? data['type'].toString()
            : event)
        .trim()
        .toLowerCase();
    LoggerUtils.logInfo('JoinRequestPush: socket event=$event type=$type');

    final payload = JoinRequestPayload.tryParse({
      ...data,
      'type': type,
    });
    if (payload == null) return;

    if (type == PushNotificationTypes.joinRequest) {
      _ingestHostRequest(payload, data);
      if (Get.isRegistered<LiveBroadcastController>()) {
        Get.find<LiveBroadcastController>()
            .markJoinRequestPrompted(payload.requestId);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        JoinRequestInAppBanner.tryShowFromMap({
          ...data,
          'type': type,
        }, handler: this);
      });
      return;
    }

    if (type == PushNotificationTypes.joinRequestCancelled) {
      _removeHostRequest(payload.requestId);
      return;
    }

    if (type == PushNotificationTypes.joinApproved) {
      JoinRequestWaitRegistry.completeIfPending(
        payload.requestId,
        JoinRequestWaitOutcome(
          result: JoinRequestWaitResult.approved,
          requestId: payload.requestId,
          roomId: payload.roomId,
          sessionType: payload.sessionType,
        ),
      );
      // Cold-start / background: viewer may not have waiting dialog open.
      if (Get.isDialogOpen != true) {
        await _enterAfterApproval(payload);
      }
      return;
    }

    if (type == PushNotificationTypes.joinRejected) {
      JoinRequestWaitRegistry.completeIfPending(
        payload.requestId,
        JoinRequestWaitOutcome(
          result: JoinRequestWaitResult.rejected,
          requestId: payload.requestId,
          roomId: payload.roomId,
          sessionType: payload.sessionType,
          message: payload.message.isNotEmpty
              ? payload.message
              : 'Host request rejected',
        ),
      );
      if (Get.isDialogOpen != true) {
        _toast('Host request rejected');
      }
      return;
    }

    if (type == PushNotificationTypes.joinRequestExpired) {
      JoinRequestWaitRegistry.completeIfPending(
        payload.requestId,
        JoinRequestWaitOutcome(
          result: JoinRequestWaitResult.expired,
          requestId: payload.requestId,
          roomId: payload.roomId,
          sessionType: payload.sessionType,
          message: 'Your join request expired. Try again.',
        ),
      );
      _removeHostRequest(payload.requestId);
      if (Get.isDialogOpen != true) {
        _toast('Your join request expired. Try again.');
      }
    }
  }

  Future<void> respond(
    JoinRequestPayload payload, {
    required String action,
    PushNotificationMessage? sourceMessage,
  }) async {
    if (payload.roomId.isEmpty || payload.requestId.isEmpty) {
      _toast('Join request details are missing.', isError: true);
      return;
    }

    final response = await _roomRepo.respondToJoinRequest(
      roomId: payload.roomId,
      requestId: payload.requestId,
      action: action,
      isShowLoader: true,
    );

    if (!JoinApprovalService.isApiSuccess(response)) {
      _toast(
        response?['message']?.toString() ?? 'Could not update join request',
        isError: true,
      );
      return;
    }

    _removeHostRequest(payload.requestId);
    if (sourceMessage != null) {
      await PushNotificationService.instance.cancelLocalNotification(
        sourceMessage,
      );
    }
    _toast(action == 'approve' ? 'Added to room' : 'Rejected');
  }

  Future<void> _enterAfterApproval(
    JoinRequestPayload payload, {
    PushNotificationMessage? sourceMessage,
  }) async {
    if (payload.roomId.isEmpty || payload.requestId.isEmpty) {
      _toast('Approved request is missing room details.', isError: true);
      return;
    }

    final joinResponse = await _roomRepo.joinRoom(
      roomId: payload.roomId,
      joinRequestId: payload.requestId,
      sessionType: payload.sessionType.isNotEmpty
          ? payload.sessionType
          : 'audio_room',
      isShowLoader: true,
    );

    if (!JoinApprovalService.isApiSuccess(joinResponse)) {
      _toast(
        joinResponse?['message']?.toString() ?? 'Could not join room',
        isError: true,
      );
      return;
    }

    if (sourceMessage != null) {
      await PushNotificationService.instance.cancelLocalNotification(
        sourceMessage,
      );
    }

    final data = joinResponse?['data'];
    final roomData = <String, dynamic>{
      'room_id': payload.roomId,
      'id': payload.roomId,
      'name': payload.roomTitle,
    };
    if (data is Map) {
      roomData.addAll(Map<String, dynamic>.from(data));
      if (data['room'] is Map) {
        roomData.addAll(Map<String, dynamic>.from(data['room'] as Map));
      }
    }
    roomData['room_id'] =
        roomData['room_id'] ?? roomData['roomId'] ?? payload.roomId;
    roomData['join_request_id'] = payload.requestId;
    roomData['joinApprovalRequired'] = false;

    final isLive = payload.isLiveStream;
    if (isLive) {
      roomData['type'] = 'live_stream';
      roomData['zegoLiveId'] =
          roomData['zegoLiveId'] ?? roomData['room_id'] ?? payload.roomId;
      await ZegoEngineUtils.resetForLiveProject().timeout(
        const Duration(milliseconds: 700),
        onTimeout: () {},
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.toNamed(
          Routes.LIVE_BROADCAST,
          arguments: {
            'isHost': false,
            'roomType': 'LIVE_STREAM',
            'roomData': roomData,
          },
        );
      });
      return;
    }

    final rawType = (roomData['type']?.toString() ?? payload.sessionType)
        .toUpperCase();
    final roomType = rawType.contains('AUDIO') ? 'AUDIO' : 'VIDEO';
    roomData['type'] = roomType.toLowerCase();
    await ZegoEngineUtils.resetForRoomProject().timeout(
      const Duration(milliseconds: 700),
      onTimeout: () {},
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.toNamed(
        Routes.LIVE_BROADCAST,
        arguments: {
          'isHost': false,
          'roomType': roomType,
          'roomData': roomData,
        },
      );
    });
  }

  Future<void> _openHostInbox(JoinRequestPayload payload) async {
    if (Get.isRegistered<LiveBroadcastController>()) {
      final live = Get.find<LiveBroadcastController>();
      _ingestHostRequest(payload, {
        'request_id': payload.requestId,
        'room_id': payload.roomId,
        'session_type': payload.sessionType,
        'requester_id': payload.requesterId,
        'requester_name': payload.requesterName,
        'requester_avatar': payload.requesterAvatar,
        'expires_at': payload.expiresAt?.toIso8601String(),
      });
      await live.openJoinRequestsSheet();
      return;
    }

    if (payload.roomId.isNotEmpty) {
      await JoinRequestsSheet.show(roomId: payload.roomId, handler: this);
    }
  }

  void _ingestHostRequest(
    JoinRequestPayload payload,
    Map<String, dynamic> data,
  ) {
    if (!Get.isRegistered<LiveBroadcastController>()) return;
    Get.find<LiveBroadcastController>().upsertPendingJoinRequest({
      ...data,
      'request_id': payload.requestId,
      'room_id': payload.roomId,
      'session_type': payload.sessionType,
      'requester_id': payload.requesterId,
      'requester_name': payload.requesterName,
      'requester_avatar': payload.requesterAvatar,
      'status': 'pending',
    });
  }

  void _removeHostRequest(String requestId) {
    if (!Get.isRegistered<LiveBroadcastController>()) return;
    Get.find<LiveBroadcastController>().removePendingJoinRequest(requestId);
  }

  void _toast(String message, {bool isError = false}) {
    final context = Get.context;
    if (context == null) return;
    if (isError) {
      AppToast.showError(context, message);
    } else {
      AppToast.showSuccess(context, message);
    }
  }
}
