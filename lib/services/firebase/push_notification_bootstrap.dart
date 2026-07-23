import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:push_notification_service/push_notification_service.dart';
import 'package:qobo_one_live/services/firebase/fcm_token_sync_service.dart';
import 'package:qobo_one_live/services/firebase/firebase_bootstrap.dart';
import 'package:qobo_one_live/services/firebase/pk_battle_push_handler.dart';
import 'package:qobo_one_live/services/firebase/room_invite_push_handler.dart';
import 'package:qobo_one_live/utils/app_widgets/room_invite_in_app_banner.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';

/// App-level wiring for the reusable [PushNotificationService] package.
///
/// Keeps `main.dart` thin and is safe to call even when Firebase is unavailable.
abstract final class PushNotificationBootstrap {
  PushNotificationBootstrap._();

  static bool _backgroundHandlerRegistered = false;
  static final RoomInvitePushHandler _roomInviteHandler =
      RoomInvitePushHandler();
  static final PkBattlePushHandler _pkBattleHandler = PkBattlePushHandler();

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
        // Branded Join/Dismiss card while the app is open (OS tray buttons
        // cannot use app gradients). PK uses Accept/Reject tray actions.
        onForegroundActionableMessage: (message) async {
          if (PkBattlePushHandler.isPkMessage(message)) return false;
          return RoomInviteInAppBanner.tryShow(
            message,
            handler: _roomInviteHandler,
          );
        },
        onToken: (token) {
          LoggerUtils.logInfo('Push token ready (${token.length} chars)');
          FcmTokenSyncService.ensureSynced();
        },
        onTokenRefresh: (token) {
          LoggerUtils.logInfo('Push token refreshed (${token.length} chars)');
          // Keep backend in sync so follower live-stream pushes stay deliverable.
          FcmTokenSyncService.ensureSynced();
        },
        onNotificationTap: (message) {
          LoggerUtils.logInfo(
            'Push tapped: ${message.title} | ${message.data}',
          );
          if (PkBattlePushHandler.isPkMessage(message)) {
            _pkBattleHandler.handleNotificationTap(message);
            return;
          }
          _roomInviteHandler.handleNotificationTap(message);
        },
        onNotificationAction: (actionId, message) {
          LoggerUtils.logInfo('Push action=$actionId | data=${message.data}');
          if (PkBattlePushHandler.isPkMessage(message) ||
              actionId == PushNotificationActions.acceptPk ||
              actionId == PushNotificationActions.rejectPk) {
            _pkBattleHandler.handleNotificationAction(
              actionId: actionId,
              message: message,
            );
            return;
          }
          _roomInviteHandler.handleNotificationAction(
            actionId: actionId,
            message: message,
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

  /// Call once after [runApp] so cold-start Join/Reject can navigate safely.
  static void flushPendingLaunch() {
    PushNotificationService.instance.flushPendingLaunch();
  }
}
