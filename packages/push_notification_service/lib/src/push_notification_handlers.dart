import 'push_notification_message.dart';

/// Host-app callbacks for push receive / token events.
///
/// Tap / open routing is intentionally left as a hook for a later phase.
///
/// Background isolate work must be done in a **top-level** function that wraps
/// [pushNotificationBackgroundHandler] — callbacks set in the UI isolate are
/// not available in the FCM background isolate.
class PushNotificationHandlers {
  const PushNotificationHandlers({
    this.onForegroundMessage,
    this.onNotificationTap,
    this.onToken,
    this.onTokenRefresh,
  });

  /// Fires when a message arrives while the app is in the foreground.
  final void Function(PushNotificationMessage message)? onForegroundMessage;

  /// Called when the user opens the app via a notification.
  ///
  /// TODO(host): implement navigation / deep-links later.
  final void Function(PushNotificationMessage message)? onNotificationTap;

  /// Called once with the current FCM token after successful initialize.
  final void Function(String token)? onToken;

  /// Called whenever FCM rotates the device token.
  final void Function(String token)? onTokenRefresh;
}
