import 'package:flutter/scheduler.dart';
import 'package:push_notification_service/push_notification_service.dart';
import 'package:qobo_one_live/services/firebase/incoming_call_presentation.dart';
import 'package:qobo_one_live/services/firebase/incoming_call_push_handler.dart';
import 'package:qobo_one_live/services/firebase/incoming_call_push_payload.dart';
import 'package:qobo_one_live/utils/app_widgets/incoming_call_ring_ui.dart';

/// Foreground incoming-call surface (FCM push path).
///
/// Always uses the WhatsApp-style full-screen green/red [IncomingCallRingUi]
/// while the app is open — never a small banner / tray only.
abstract final class IncomingCallInAppBanner {
  IncomingCallInAppBanner._();

  static void dismissIfShowing() => IncomingCallRingUi.dismissIfShowing();

  /// Returns true when custom UI was shown (skip duplicate OS tray).
  static Future<bool> tryShow(
    PushNotificationMessage message, {
    IncomingCallPushHandler? handler,
  }) async {
    final payload = IncomingCallPushPayload.fromMessage(message);
    if (payload == null || !payload.isIncomingRing) return false;
    if (payload.isExpired) return false;
    if (IncomingCallPresentation.isHandled(payload.callId)) return false;
    if (IncomingCallRingUi.isShowing) return true;
    if (IncomingCallPresentation.inAppCallId == payload.callId) return true;

    final callHandler = handler ?? IncomingCallPushHandler();
    IncomingCallPresentation.markInAppShowing(payload.callId);

    try {
      // Wait a frame so Get.dialog has an overlay (cold FCM race).
      await SchedulerBinding.instance.endOfFrame;
      await IncomingCallRingUi.show(
        callerName: payload.callerName.trim().isEmpty
            ? 'Incoming call'
            : payload.callerName.trim(),
        subtitle: payload.bannerBody,
        isVideo: payload.isVideo,
        avatarUrl: payload.callerAvatar,
        onDecline: () => callHandler.handleNotificationAction(
          actionId: PushNotificationActions.rejectCall,
          message: message,
        ),
        onAccept: () => callHandler.handleNotificationAction(
          actionId: PushNotificationActions.acceptCall,
          message: message,
        ),
      );
    } finally {
      IncomingCallPresentation.clearInAppShowing(payload.callId);
    }
    return true;
  }
}
