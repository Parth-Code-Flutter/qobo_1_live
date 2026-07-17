/// Reusable FCM push-notification receive package.
///
/// Supports actionable room-invite trays (`JOIN_ROOM` / `REJECT_ROOM`) via
/// [PushNotificationHandlers.onNotificationAction].
library;

export 'src/push_notification_actions.dart';
export 'src/push_notification_config.dart';
export 'src/push_notification_handlers.dart';
export 'src/push_notification_message.dart';
export 'src/push_notification_service.dart';
export 'src/push_notification_types.dart';
export 'src/push_background_handler.dart';
