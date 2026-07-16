import 'push_notification_message.dart';

/// Host-app callbacks for push receive / token / action events.
///
/// Background isolate work must be done in a **top-level** function that wraps
/// [pushNotificationBackgroundHandler] — callbacks set in the UI isolate are
/// not available in the FCM background isolate.
class PushNotificationHandlers {
  const PushNotificationHandlers({
    this.onForegroundMessage,
    this.onNotificationTap,
    this.onNotificationAction,
    this.onToken,
    this.onTokenRefresh,
  });

  /// Fires when a message arrives while the app is in the foreground.
  final void Function(PushNotificationMessage message)? onForegroundMessage;

  /// Called when the user opens the app via a notification body tap.
  final void Function(PushNotificationMessage message)? onNotificationTap;

  /// Called when the user taps a local-notification action button
  /// (e.g. `JOIN_ROOM` / `REJECT_ROOM`).
  final void Function(String actionId, PushNotificationMessage message)?
  onNotificationAction;

  /// Called once with the current FCM token after successful initialize.
  final void Function(String token)? onToken;

  /// Called whenever FCM rotates the device token.
  final void Function(String token)? onTokenRefresh;
}
