import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'push_notification_config.dart';
import 'push_notification_message.dart';

/// Thin wrapper around [FlutterLocalNotificationsPlugin] for foreground trays.
///
/// Kept inside the package so host apps do not re-implement Android channels.
class LocalNotificationBridge {
  LocalNotificationBridge({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  /// Payload callback reserved for future on-tap navigation.
  void Function(String? payload)? onLocalNotificationTap;

  Future<void> initialize(PushNotificationConfig config) async {
    if (_ready) return;

    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      InitializationSettings(
        android: AndroidInitializationSettings(config.androidDefaultIcon),
        iOS: iosInit,
      ),
      onDidReceiveNotificationResponse: (response) {
        // Hook for later: map response.payload -> host navigation.
        onLocalNotificationTap?.call(response.payload);
      },
    );

    if (!kIsWeb && Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        AndroidNotificationChannel(
          config.androidNotificationChannelId,
          config.androidNotificationChannelName,
          description: config.androidNotificationChannelDescription,
          importance: Importance.high,
        ),
      );
    }

    _ready = true;
  }

  Future<void> showFromMessage({
    required PushNotificationConfig config,
    required PushNotificationMessage message,
  }) async {
    if (!_ready) return;
    if (!message.hasNotificationContent) return;

    final androidDetails = AndroidNotificationDetails(
      config.androidNotificationChannelId,
      config.androidNotificationChannelName,
      channelDescription: config.androidNotificationChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: config.androidDefaultIcon,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      // Prefer a stable-ish id so rapid duplicates replace instead of stacking wildly.
      _notificationIdFor(message),
      message.title.isEmpty ? 'Notification' : message.title,
      message.body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: message.messageId.isEmpty ? null : message.messageId,
    );
  }

  int _notificationIdFor(PushNotificationMessage message) {
    if (message.messageId.isNotEmpty) {
      return message.messageId.hashCode & 0x7fffffff;
    }
    return DateTime.now().millisecondsSinceEpoch.remainder(100000);
  }
}
