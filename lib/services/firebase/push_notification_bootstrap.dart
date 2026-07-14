import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:push_notification_service/push_notification_service.dart';
import 'package:qobo_one_live/services/firebase/firebase_bootstrap.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';

/// App-level wiring for the reusable [PushNotificationService] package.
///
/// Keeps `main.dart` thin and is safe to call even when Firebase is unavailable.
abstract final class PushNotificationBootstrap {
  PushNotificationBootstrap._();

  static bool _backgroundHandlerRegistered = false;

  /// Registers the top-level FCM background handler once.
  ///
  /// Must run before other FCM APIs (Firebase Messaging requirement).
  static void registerBackgroundHandler() {
    if (_backgroundHandlerRegistered || kIsWeb) return;
    FirebaseMessaging.onBackgroundMessage(pushNotificationBackgroundHandler);
    _backgroundHandlerRegistered = true;
  }

  /// Initializes receive listeners after [FirebaseBootstrap.tryInitialize].
  static Future<void> tryInitialize() async {
    if (kIsWeb) return;
    if (!FirebaseBootstrap.isAvailable) {
      LoggerUtils.logInfo(
        'PushNotificationBootstrap: skipped — Firebase unavailable',
      );
      return;
    }

    final ok = await PushNotificationService.instance.initialize(
      config: const PushNotificationConfig(
        requestPermissionsOnInit: true,
        showForegroundNotifications: true,
        enableVerboseLogging: kDebugMode,
      ),
      handlers: PushNotificationHandlers(
        onForegroundMessage: (message) {
          LoggerUtils.logInfo(
            'Push foreground: ${message.title} | data=${message.data}',
          );
        },
        onToken: (token) {
          LoggerUtils.logInfo(
            'Push token ready (${token.length} chars)',
          );
        },
        onTokenRefresh: (token) {
          LoggerUtils.logInfo(
            'Push token refreshed (${token.length} chars)',
          );
          // TODO: sync refreshed token with backend profile/device APIs.
        },
        // TODO: implement notification onClick / deep-link navigation later.
        onNotificationTap: (message) {
          LoggerUtils.logInfo(
            'Push tapped (onClick pending): ${message.title} | ${message.data}',
          );
        },
      ),
    );

    LoggerUtils.logInfo(
      ok
          ? 'PushNotificationBootstrap: listening for notifications'
          : 'PushNotificationBootstrap: initialize failed',
    );
  }
}
