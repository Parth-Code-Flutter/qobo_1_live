import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'push_notification_actions.dart';
import 'push_notification_config.dart';
import 'push_notification_message.dart';

/// Thin wrapper around [FlutterLocalNotificationsPlugin].
///
/// Hosts can show plain or actionable (Join / Reject) trays without re-creating
/// Android channels or iOS notification categories.
class LocalNotificationBridge {
  LocalNotificationBridge({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  /// Body tap (no action button).
  void Function(PushNotificationMessage message)? onLocalNotificationTap;

  /// Action button tap (`JOIN_ROOM`, `REJECT_ROOM`, …).
  void Function(String actionId, PushNotificationMessage message)?
  onLocalNotificationAction;

  /// Optional background entry used when the UI isolate is not alive.
  DidReceiveBackgroundNotificationResponseCallback? backgroundActionHandler;

  Future<void> initialize(PushNotificationConfig config) async {
    if (_ready) return;

    // Register APNs categories so iOS can render the correct action buttons.
    final iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: <DarwinNotificationCategory>[
        DarwinNotificationCategory(
          PushNotificationActions.roomInviteCategory,
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(
              PushNotificationActions.joinRoom,
              'Join Now',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
            DarwinNotificationAction.plain(
              PushNotificationActions.rejectRoom,
              'Reject',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.destructive,
              },
            ),
          ],
        ),
        DarwinNotificationCategory(
          PushNotificationActions.roomBroadcastCategory,
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(
              PushNotificationActions.joinRoom,
              'Join Now',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
            DarwinNotificationAction.plain(
              PushNotificationActions.dismissRoom,
              'Dismiss',
            ),
          ],
        ),
      ],
    );

    await _plugin.initialize(
      InitializationSettings(
        android: AndroidInitializationSettings(config.androidDefaultIcon),
        iOS: iosInit,
      ),
      onDidReceiveNotificationResponse: _onResponse,
      onDidReceiveBackgroundNotificationResponse: backgroundActionHandler,
    );

    if (!kIsWeb && Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
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
    PushNotificationActionSet actionSet = PushNotificationActionSet.none,
    String? titleOverride,
    String? bodyOverride,
  }) async {
    if (!_ready) return;

    final title = (titleOverride ?? message.title).trim();
    final body = (bodyOverride ?? message.body).trim();
    if (title.isEmpty && body.isEmpty) return;

    final androidActions = _androidActionsFor(actionSet);
    final androidDetails = AndroidNotificationDetails(
      config.androidNotificationChannelId,
      config.androidNotificationChannelName,
      channelDescription: config.androidNotificationChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: config.androidDefaultIcon,
      // Brand accent tints the small icon / action chrome on many OEMs.
      color: const Color(0xFFFF2C4D),
      category: AndroidNotificationCategory.call,
      actions: androidActions,
      styleInformation: BigTextStyleInformation(
        body.isEmpty ? title : body,
        contentTitle: title.isEmpty ? 'Notification' : title,
        summaryText: actionSet == PushNotificationActionSet.joinReject
            ? 'Tap Join Now to enter'
            : actionSet == PushNotificationActionSet.joinDismiss
            ? 'Tap Join Now to enter'
            : null,
      ),
      autoCancel: true,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: switch (actionSet) {
        PushNotificationActionSet.joinReject =>
          PushNotificationActions.roomInviteCategory,
        PushNotificationActionSet.joinDismiss =>
          PushNotificationActions.roomBroadcastCategory,
        PushNotificationActionSet.none => null,
      },
    );

    await _plugin.show(
      _notificationIdFor(message),
      title.isEmpty ? 'Notification' : title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: message.toPayloadJson(),
    );
  }

  /// Cancels a previously shown invite (e.g. after Reject / successful Join).
  Future<void> cancelForMessage(PushNotificationMessage message) async {
    if (!_ready) return;
    await _plugin.cancel(_notificationIdFor(message));
  }

  void _onResponse(NotificationResponse response) {
    final message = PushNotificationMessage.fromPayloadJson(response.payload);
    final actionId = response.actionId?.trim() ?? '';

    // Body tap → treat as Join when the payload is a room invite/alert.
    if (actionId.isEmpty ||
        response.notificationResponseType ==
            NotificationResponseType.selectedNotification) {
      onLocalNotificationTap?.call(message);
      return;
    }

    onLocalNotificationAction?.call(actionId, message);
  }

  List<AndroidNotificationAction> _androidActionsFor(
    PushNotificationActionSet actionSet,
  ) {
    switch (actionSet) {
      case PushNotificationActionSet.joinReject:
        return const <AndroidNotificationAction>[
          AndroidNotificationAction(
            PushNotificationActions.joinRoom,
            'Join Now',
            icon: DrawableResourceAndroidBitmap('ic_notif_join'),
            showsUserInterface: true,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            PushNotificationActions.rejectRoom,
            'Reject',
            icon: DrawableResourceAndroidBitmap('ic_notif_reject'),
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ];
      case PushNotificationActionSet.joinDismiss:
        return const <AndroidNotificationAction>[
          AndroidNotificationAction(
            PushNotificationActions.joinRoom,
            'Join Now',
            icon: DrawableResourceAndroidBitmap('ic_notif_join'),
            showsUserInterface: true,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            PushNotificationActions.dismissRoom,
            'Dismiss',
            icon: DrawableResourceAndroidBitmap('ic_notif_dismiss'),
            cancelNotification: true,
          ),
        ];
      case PushNotificationActionSet.none:
        return const <AndroidNotificationAction>[];
    }
  }

  int _notificationIdFor(PushNotificationMessage message) {
    // Prefer backend notification_id so retries replace the same tray entry.
    final notificationId = message.data['notification_id']?.toString().trim();
    if (notificationId != null && notificationId.isNotEmpty) {
      return notificationId.hashCode & 0x7fffffff;
    }
    if (message.messageId.isNotEmpty) {
      return message.messageId.hashCode & 0x7fffffff;
    }
    return DateTime.now().millisecondsSinceEpoch.remainder(100000);
  }
}
