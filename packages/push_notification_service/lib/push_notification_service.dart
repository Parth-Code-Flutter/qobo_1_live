/// Reusable FCM push-notification receive package.
///
/// Copy / path-depend this package in other Flutter apps that already call
/// `Firebase.initializeApp()`. Notification tap / deep-link routing can be
/// added later via [PushNotificationHandlers.onNotificationTap].
library;

export 'src/push_notification_config.dart';
export 'src/push_notification_handlers.dart';
export 'src/push_notification_message.dart';
export 'src/push_notification_service.dart';
export 'src/push_background_handler.dart';
