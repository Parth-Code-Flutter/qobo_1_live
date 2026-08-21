import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:push_notification_service/push_notification_service.dart';
import 'package:qobo_one_live/repo/call/call_repo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/chat/chat_call_service.dart';
import 'package:qobo_one_live/services/chat/chat_incoming_call_coordinator.dart';
import 'package:qobo_one_live/services/chat/chat_session_service.dart';
import 'package:qobo_one_live/app/user_flow/messages/chat_voice_call/controllers/chat_voice_call_controller.dart';
import 'package:qobo_one_live/services/firebase/incoming_call_kit_display.dart';
import 'package:qobo_one_live/services/firebase/incoming_call_presentation.dart';
import 'package:qobo_one_live/services/firebase/incoming_call_push_payload.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/app_widgets/incoming_call_in_app_banner.dart';
import 'package:qobo_one_live/utils/app_widgets/incoming_call_ring_ui.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';
import 'package:qobo_one_live/utils/zego_engine_utils.dart';

/// Handles 1:1 call FCM types: `incoming_call`, `call_cancelled`, `call_missed`.
///
/// Foreground → branded in-app ring UI.
/// Background / killed → [IncomingCallKitDisplay] (native CallKit / full-screen).
/// `call_cancelled` closes caller "Waiting for answer" **and** tears down an
/// active call UI when either side already connected (`reason: ended`).
class IncomingCallPushHandler {
  IncomingCallPushHandler({
    CallRepo? callRepo,
    ChatCallService? callService,
  })  : _callRepo = callRepo ?? CallRepo(),
        _callService = callService ?? ChatCallService();

  final CallRepo _callRepo;
  final ChatCallService _callService;

  static bool isIncomingCallMessage(PushNotificationMessage message) {
    final type = PushNotificationTypes.resolveType(message.data);
    return PushNotificationTypes.isIncomingCallType(type);
  }

  Future<void> handleForegroundMessage(PushNotificationMessage message) async {
    final payload = IncomingCallPushPayload.fromMessage(message);
    if (payload == null) return;

    if (payload.isCancelled ||
        payload.type == PushNotificationTypes.callMissed) {
      IncomingCallPresentation.markHandled(payload.callId);
      await PushNotificationService.instance.cancelLocalNotification(message);
      IncomingCallInAppBanner.dismissIfShowing();
      await IncomingCallKitDisplay.endForMessage(message);
      // Caller A may be on "Waiting for answer" — close that UI (decline / miss).
      ChatVoiceCallController.tryHandleRemoteCancelPush(payload);
      return;
    }

    // App is open — always show WhatsApp-style full-screen green/red ring.
    // (CallKit is for background/killed only; do not suppress in-app here.)
    await IncomingCallInAppBanner.tryShow(message, handler: this);
  }

  Future<void> handleNotificationTap(PushNotificationMessage message) async {
    final payload = IncomingCallPushPayload.fromMessage(message);
    if (payload == null) return;

    if (payload.isCancelled ||
        payload.type == PushNotificationTypes.callMissed) {
      IncomingCallPresentation.markHandled(payload.callId);
      await PushNotificationService.instance.cancelLocalNotification(message);
      await IncomingCallKitDisplay.endForMessage(message);
      ChatVoiceCallController.tryHandleRemoteCancelPush(payload);
      return;
    }

    // Already answering / ringing in-app — do not stack another UI.
    if (IncomingCallRingUi.isShowing ||
        IncomingCallPresentation.inAppCallId == payload.callId ||
        IncomingCallPresentation.isHandled(payload.callId)) {
      return;
    }

    // Opened from tray while CallKit was up (background → tap): keep CallKit /
    // accept path. If app is already foreground, show in-app ring.
    if (IncomingCallPresentation.isAppInForeground) {
      await IncomingCallInAppBanner.tryShow(message, handler: this);
      return;
    }
    if (await IncomingCallPresentation.hasActiveCallKit(payload.callId)) {
      return;
    }

    await IncomingCallInAppBanner.tryShow(message, handler: this);
  }

  Future<void> handleNotificationAction({
    required String actionId,
    required PushNotificationMessage message,
  }) async {
    final payload = IncomingCallPushPayload.fromMessage(message);
    if (payload == null) {
      LoggerUtils.logInfo(
        'IncomingCallPush: ignore action=$actionId data=${message.data}',
      );
      return;
    }

    switch (actionId) {
      case PushNotificationActions.acceptCall:
        await acceptCall(payload, sourceMessage: message);
        return;
      case PushNotificationActions.rejectCall:
        await rejectCall(payload, sourceMessage: message);
        return;
      default:
        await handleNotificationTap(message);
    }
  }

  Future<void> acceptCall(
    IncomingCallPushPayload payload, {
    PushNotificationMessage? sourceMessage,
  }) async {
    // Accept → respond API + Zego room only. Never show the ringing screen again.
    IncomingCallPresentation.markHandled(payload.callId);

    if (payload.isExpired) {
      _showFeedback('This call has expired');
      if (sourceMessage != null) {
        await PushNotificationService.instance.cancelLocalNotification(
          sourceMessage,
        );
      }
      await IncomingCallKitDisplay.endForPayload(payload);
      return;
    }

    if (sourceMessage != null) {
      await PushNotificationService.instance.cancelLocalNotification(
        sourceMessage,
      );
    }
    IncomingCallInAppBanner.dismissIfShowing();
    await IncomingCallKitDisplay.endForPayload(payload);

    if (!await _ensureFirebaseSession()) {
      _showFeedback('Sign in required to accept calls');
      return;
    }

    final response = await _callRepo.respondDirectCall(
      callId: payload.callId,
      roomId: payload.roomId,
      action: 'accept',
      isShowLoader: true,
    );

    Map<String, dynamic> data = {};
    if (_isApiSuccess(response) && response?['data'] is Map) {
      data = Map<String, dynamic>.from(response!['data'] as Map);
    }

    final roomId =
        data['roomId']?.toString() ??
        data['room_id']?.toString() ??
        payload.roomId;
    final callId =
        data['zegoCallId']?.toString() ??
        data['callId']?.toString() ??
        (payload.zegoCallId.isNotEmpty ? payload.zegoCallId : payload.callId);
    final callerId =
        data['callerId']?.toString() ??
        data['caller_id']?.toString() ??
        payload.callerId;
    final callerName =
        data['callerName']?.toString() ??
        data['caller_name']?.toString() ??
        payload.callerName;
    final historyDocId =
        data['historyDocId']?.toString() ??
        data['history_doc_id']?.toString() ??
        payload.historyDocId;
    final callStartedAt =
        data['callStartedAt']?.toString() ??
        data['call_started_at']?.toString() ??
        payload.callStartedAt;
    final callType =
        data['callType']?.toString() ??
        data['call_type']?.toString() ??
        payload.callType;
    final isVideo = callType.trim().toLowerCase() == 'video';

    if (roomId.isNotEmpty) {
      await _callService.markAccepted(
        roomId: roomId,
        userId: _myUserId(),
      );
    }

    await ZegoEngineUtils.resetForCallProject();
    if (Get.isRegistered<ChatIncomingCallCoordinator>()) {
      Get.find<ChatIncomingCallCoordinator>().setOnCallScreen(true);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.toNamed(
        Routes.CHAT_VOICE_CALL,
        arguments: {
          'roomId': roomId,
          'callId': callId,
          if (historyDocId.isNotEmpty) 'historyDocId': historyDocId,
          if (callStartedAt.isNotEmpty) 'callStartedAt': callStartedAt,
          'hostId': callerId,
          'peerName': callerName,
          if (payload.callerAvatar.isNotEmpty)
            'peerAvatar': payload.callerAvatar,
          'isCaller': false,
          'isVideo': isVideo,
          'recordCallHistory': payload.recordCallHistory,
        },
      );
    });
  }

  Future<void> rejectCall(
    IncomingCallPushPayload payload, {
    PushNotificationMessage? sourceMessage,
  }) async {
    IncomingCallPresentation.markHandled(payload.callId);
    if (sourceMessage != null) {
      await PushNotificationService.instance.cancelLocalNotification(
        sourceMessage,
      );
    }
    IncomingCallInAppBanner.dismissIfShowing();
    await IncomingCallKitDisplay.endForPayload(payload);

    await _callRepo.respondDirectCall(
      callId: payload.callId,
      roomId: payload.roomId,
      action: 'reject',
      isShowLoader: false,
    );

    if (payload.roomId.isNotEmpty) {
      await _callService.endCall(
        payload.roomId,
        endedByUserId: _myUserId(),
      );
    }
  }

  Future<bool> _ensureFirebaseSession() async {
    if (!Get.isRegistered<ChatSessionService>()) {
      Get.put(ChatSessionService(), permanent: true);
    }
    return Get.find<ChatSessionService>().ensureSignedIn(isShowLoader: false);
  }

  String _myUserId() {
    if (!Get.isRegistered<UserSessionController>()) return '';
    return Get.find<UserSessionController>().userId;
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
    Get.snackbar('Call', message, snackPosition: SnackPosition.BOTTOM);
  }
}
