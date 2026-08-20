import 'package:push_notification_service/push_notification_service.dart';
import 'package:qobo_one_live/services/firebase/incoming_call_push_handler.dart';
import 'package:qobo_one_live/services/firebase/incoming_call_push_payload.dart';
import 'package:qobo_one_live/utils/app_widgets/incoming_call_ring_ui.dart';

/// Foreground incoming-call surface (FCM push path).
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
    if (IncomingCallRingUi.isShowing) return true;

    final callHandler = handler ?? IncomingCallPushHandler();

    await IncomingCallRingUi.show(
      callerName: payload.callerName,
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
    return true;
  }
}
