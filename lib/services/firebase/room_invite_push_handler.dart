import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:push_notification_service/push_notification_service.dart';
import 'package:qobo_one_live/repo/room/room_repo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/firebase/room_invite_push_payload.dart';
import 'package:qobo_one_live/services/room/join_approval_service.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';
import 'package:qobo_one_live/utils/zego_engine_utils.dart';

/// Handles Join / Reject / Dismiss for actionable push notifications.
///
/// Contract (backend types):
/// - `room_invite` → Join + Reject (`invitation_id` required for Join)
/// - `room_created` / `live_streaming_created` → Join + Dismiss
/// - `general` / `custom` → Join + Dismiss (Join only when `room_id` present)
/// - Block Join when `expires_at` is in the past
class RoomInvitePushHandler {
  RoomInvitePushHandler({RoomRepo? roomRepo})
    : _roomRepo = roomRepo ?? RoomRepo();

  final RoomRepo _roomRepo;

  /// Body tap → same as Join for invite / broadcast room alerts.
  Future<void> handleNotificationTap(PushNotificationMessage message) async {
    final payload = RoomInvitePushPayload.fromMessage(message);
    if (payload == null) {
      LoggerUtils.logInfo(
        'RoomInvitePush: ignore non-room tap data=${message.data}',
      );
      return;
    }
    await joinFromInvite(payload, sourceMessage: message);
  }

  /// Action button: `JOIN_ROOM` / `REJECT_ROOM` / `DISMISS_ROOM`.
  Future<void> handleNotificationAction({
    required String actionId,
    required PushNotificationMessage message,
  }) async {
    final payload = RoomInvitePushPayload.fromMessage(message);
    if (payload == null) {
      LoggerUtils.logInfo(
        'RoomInvitePush: ignore action=$actionId data=${message.data}',
      );
      return;
    }

    switch (actionId) {
      case PushNotificationActions.joinRoom:
        await joinFromInvite(payload, sourceMessage: message);
      case PushNotificationActions.rejectRoom:
        await rejectInvite(payload, sourceMessage: message);
      case PushNotificationActions.dismissRoom:
        await PushNotificationService.instance.cancelLocalNotification(message);
        LoggerUtils.logInfo(
          'RoomInvitePush: dismissed type=${payload.type} room=${payload.roomId}',
        );
      default:
        LoggerUtils.logInfo('RoomInvitePush: unknown action=$actionId');
    }
  }

  /// Joins the room via API and opens the live broadcast screen.
  Future<void> joinFromInvite(
    RoomInvitePushPayload payload, {
    PushNotificationMessage? sourceMessage,
  }) async {
    if (payload.isExpired) {
      _showFeedback('This invitation has expired');
      if (sourceMessage != null) {
        await PushNotificationService.instance.cancelLocalNotification(
          sourceMessage,
        );
      }
      return;
    }

    // Admin / general broadcasts without a room just open the app.
    if (!payload.hasRoomId) {
      if (sourceMessage != null) {
        await PushNotificationService.instance.cancelLocalNotification(
          sourceMessage,
        );
      }
      LoggerUtils.logInfo(
        'RoomInvitePush: Join with no room_id for type=${payload.type}',
      );
      return;
    }

    // Direct invites must carry invitation_id for private-room bypass.
    if (payload.isDirectInvite && !payload.hasInvitationId) {
      _showFeedback('Invitation id is missing from this notification');
      return;
    }

    // Live-stream follower alerts open the streaming viewer directly.
    // Audio/video room invites still go through the room join API.
    if (payload.isLiveStreamAlert) {
      await _openLiveStream(payload, sourceMessage: sourceMessage);
      return;
    }

    final response = await JoinApprovalService().joinWithApprovalGate(
      roomId: payload.roomId,
      sessionType: JoinApprovalService.sessionTypeFor(
        roomType: payload.roomType,
        isLiveStream: payload.isLiveStreamAlert,
      ),
      invitationId: payload.hasInvitationId ? payload.invitationId : null,
      roomHint: <String, dynamic>{
        'room_id': payload.roomId,
        'type': payload.roomType,
      },
      isShowLoader: true,
    );

    if (!_isApiSuccess(response)) {
      final error =
          response?['error']?.toString() ??
          response?['message']?.toString() ??
          'Could not join room';
      _showFeedback(error);
      return;
    }

    if (sourceMessage != null) {
      await PushNotificationService.instance.cancelLocalNotification(
        sourceMessage,
      );
    }

    final roomData = _normalizeJoinPayload(response?['data'], payload: payload);
    final roomType = (roomData['type']?.toString() ?? payload.roomType)
        .toUpperCase();

    await ZegoEngineUtils.resetForRoomProject().timeout(
      const Duration(milliseconds: 700),
      onTimeout: () {},
    );

    // Defer navigation until after any pending frame (cold-start race).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.toNamed(
        Routes.LIVE_BROADCAST,
        arguments: {
          'isHost': false,
          'roomType': roomType == 'AUDIO' ? 'AUDIO' : 'VIDEO',
          'roomData': roomData,
        },
      );
    });
  }

  /// Opens the live-streaming UI for follower `live_stream_started` alerts.
  Future<void> _openLiveStream(
    RoomInvitePushPayload payload, {
    PushNotificationMessage? sourceMessage,
  }) async {
    final roomHint = <String, dynamic>{
      'room_id': payload.roomId,
      'type': 'live_stream',
    };

    final response = await JoinApprovalService().joinWithApprovalGate(
      roomId: payload.roomId,
      sessionType: 'live_stream',
      invitationId: payload.hasInvitationId ? payload.invitationId : null,
      roomHint: roomHint,
      isShowLoader: true,
    );

    if (!_isApiSuccess(response)) {
      final status = response?['data'] is Map
          ? (response!['data'] as Map)['status']?.toString().toLowerCase()
          : null;
      final blocked = JoinApprovalService.isApprovalRequiredError(response) ||
          status == 'rejected' ||
          status == 'blocked' ||
          status == 'expired' ||
          status == 'cancelled';
      if (blocked) {
        _showFeedback(
          response?['message']?.toString() ?? 'Could not join live stream',
        );
        return;
      }
      // Legacy open rooms: continue even if optional join reporting failed.
    }

    if (sourceMessage != null) {
      await PushNotificationService.instance.cancelLocalNotification(
        sourceMessage,
      );
    }

    final roomData = <String, dynamic>{
      'type': 'live_stream',
      'room_id': payload.roomId,
      'id': payload.roomId,
      'zegoLiveId': payload.roomId,
      'channelName': payload.roomId,
      'liveStreamingId': payload.roomId,
      'name': payload.roomTitle,
      'title': payload.roomTitle,
      'hostId': payload.hostId,
      'hostName': payload.hostName,
      'isLive': true,
    };
    if (_isApiSuccess(response) && response?['data'] is Map) {
      final joined = Map<String, dynamic>.from(response!['data'] as Map);
      roomData.addAll(joined);
      if (joined['room'] is Map) {
        roomData.addAll(Map<String, dynamic>.from(joined['room'] as Map));
      }
      roomData['type'] = 'live_stream';
      final joinRequestId =
          joined['join_request_id']?.toString() ??
          joined['request_id']?.toString();
      if (joinRequestId != null && joinRequestId.isNotEmpty) {
        roomData['join_request_id'] = joinRequestId;
      }
    }

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
  }

  /// Marks a direct invitation as rejected on the backend.
  Future<void> rejectInvite(
    RoomInvitePushPayload payload, {
    PushNotificationMessage? sourceMessage,
  }) async {
    if (!payload.isDirectInvite) {
      // Broadcast alerts only dismiss locally — no server reject.
      if (sourceMessage != null) {
        await PushNotificationService.instance.cancelLocalNotification(
          sourceMessage,
        );
      }
      return;
    }

    if (!payload.hasInvitationId) {
      _showFeedback('Invitation id is missing');
      return;
    }

    final response = await _roomRepo.respondToRoomInvite(
      invitationId: payload.invitationId,
      action: 'reject',
      roomId: payload.roomId,
      isShowLoader: false,
    );

    if (sourceMessage != null) {
      await PushNotificationService.instance.cancelLocalNotification(
        sourceMessage,
      );
    }

    if (_isApiSuccess(response)) {
      _showFeedback('Invitation rejected', isError: false);
      return;
    }

    _showFeedback(
      response?['message']?.toString() ?? 'Could not reject invitation',
    );
  }

  Map<String, dynamic> _normalizeJoinPayload(
    dynamic raw, {
    required RoomInvitePushPayload payload,
  }) {
    final data = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    final joinedRoom = data['room'] is Map
        ? Map<String, dynamic>.from(data['room'] as Map)
        : <String, dynamic>{};

    final roomData = <String, dynamic>{
      ...joinedRoom,
      if (data['room'] is! Map) ...data,
      'room_id': payload.roomId,
      'id': joinedRoom['id'] ?? data['room_id'] ?? payload.roomId,
      'type': joinedRoom['type'] ?? payload.roomType,
      'title': joinedRoom['title'] ?? payload.roomTitle,
      'name': joinedRoom['name'] ?? joinedRoom['title'] ?? payload.roomTitle,
      'hostId': joinedRoom['hostId'] ?? payload.hostId,
      'hostName': joinedRoom['hostName'] ?? payload.hostName,
    };

    final zegoStreaming = data['zegoStreaming'] ?? joinedRoom['zegoStreaming'];
    if (zegoStreaming is Map) {
      roomData['zegoStreaming'] = Map<String, dynamic>.from(zegoStreaming);
      roomData.putIfAbsent('zegoToken', () => zegoStreaming['token']);
    }

    roomData['zegoLiveId'] =
        data['zegoLiveId']?.toString() ??
        data['channelName']?.toString() ??
        joinedRoom['zegoLiveId']?.toString() ??
        (zegoStreaming is Map ? zegoStreaming['roomId']?.toString() : null) ??
        payload.roomId;
    roomData['channelName'] =
        data['channelName']?.toString() ??
        roomData['zegoLiveId']?.toString() ??
        payload.roomId;

    if (data['seatId'] != null) {
      roomData['seatId'] = data['seatId'];
    }

    return roomData;
  }

  bool _isApiSuccess(Map<String, dynamic>? response) {
    if (response == null) return false;
    if (response['success'] == true) return true;
    final code = response['statusCode'];
    return code == 1 || code == 200 || code == 201 || code == true;
  }

  void _showFeedback(String message, {bool isError = true}) {
    final context = Get.overlayContext ?? Get.context;
    if (context != null) {
      if (isError) {
        AppToast.showError(context, message);
      } else {
        AppToast.showSuccess(context, message);
      }
      return;
    }
    Get.snackbar('Room invite', message, snackPosition: SnackPosition.BOTTOM);
  }
}
