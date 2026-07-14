import 'package:firebase_messaging/firebase_messaging.dart';

import 'push_notification_message.dart';
import 'push_notification_service.dart';

/// Top-level FCM background entry point.
///
/// Register this in the host app `main()` **before** other FCM usage:
/// ```dart
/// FirebaseMessaging.onBackgroundMessage(pushNotificationBackgroundHandler);
/// ```
@pragma('vm:entry-point')
Future<void> pushNotificationBackgroundHandler(RemoteMessage message) async {
  await PushNotificationService.handleBackgroundMessage(message);
}

/// Convenience mapper used by the background handler and unit tests.
PushNotificationMessage mapRemoteMessage(RemoteMessage message) {
  return PushNotificationMessage.fromRemoteMessage(message);
}
