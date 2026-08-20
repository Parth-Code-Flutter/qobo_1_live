import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:push_notification_service/push_notification_service.dart';
import 'package:qobo_one_live/services/firebase/fcm_token_sync_service.dart';
import 'package:qobo_one_live/services/firebase/firebase_bootstrap.dart';
import 'package:qobo_one_live/services/firebase/incoming_call_kit_display.dart';
import 'package:qobo_one_live/services/firebase/incoming_call_kit_service.dart';
import 'package:qobo_one_live/services/firebase/incoming_call_push_handler.dart';
import 'package:qobo_one_live/services/firebase/join_request_push_handler.dart';
import 'package:qobo_one_live/services/firebase/pk_battle_push_handler.dart';
import 'package:qobo_one_live/services/firebase/room_invite_push_handler.dart';
import 'package:qobo_one_live/utils/app_widgets/join_request_in_app_banner.dart';
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
  static final JoinRequestPushHandler _joinRequestHandler =
      JoinRequestPushHandler();
  static final IncomingCallPushHandler _incomingCallHandler =
      IncomingCallPushHandler();

  /// Registers the top-level FCM background handler once.
  ///
  /// Must run before other FCM APIs (Firebase Messaging requirement).
  static void registerBackgroundHandler() {
    if (_backgroundHandlerRegistered || kIsWeb) return;
    FirebaseMessaging.onBackgroundMessage(qoboFirebaseMessagingBackgroundHandler);
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
          if (IncomingCallPushHandler.isIncomingCallMessage(message)) {
            unawaited(_incomingCallHandler.handleForegroundMessage(message));
          }
        },
        // Branded in-app cards while open; PK / join / call use custom UI.
        onForegroundActionableMessage: (message) async {
          if (IncomingCallPushHandler.isIncomingCallMessage(message)) {
            await _incomingCallHandler.handleForegroundMessage(message);
            return true;
          }
          if (PkBattlePushHandler.isPkMessage(message)) return false;
          if (JoinRequestPushHandler.isJoinRequestMessage(message)) {
            return JoinRequestInAppBanner.tryShow(
              message,
              handler: _joinRequestHandler,
            );
          }
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
          FcmTokenSyncService.ensureSynced();
        },
        onNotificationTap: (message) {
          LoggerUtils.logInfo(
            'Push tapped: ${message.title} | ${message.data}',
          );
          if (IncomingCallPushHandler.isIncomingCallMessage(message)) {
            _incomingCallHandler.handleNotificationTap(message);
            return;
          }
          if (PkBattlePushHandler.isPkMessage(message)) {
            _pkBattleHandler.handleNotificationTap(message);
            return;
          }
          if (JoinRequestPushHandler.isJoinRequestMessage(message)) {
            _joinRequestHandler.handleNotificationTap(message);
            return;
          }
          _roomInviteHandler.handleNotificationTap(message);
        },
        onNotificationAction: (actionId, message) {
          LoggerUtils.logInfo('Push action=$actionId | data=${message.data}');
          if (IncomingCallPushHandler.isIncomingCallMessage(message) ||
              actionId == PushNotificationActions.acceptCall ||
              actionId == PushNotificationActions.rejectCall) {
            _incomingCallHandler.handleNotificationAction(
              actionId: actionId,
              message: message,
            );
            return;
          }
          if (PkBattlePushHandler.isPkMessage(message) ||
              actionId == PushNotificationActions.acceptPk ||
              actionId == PushNotificationActions.rejectPk) {
            _pkBattleHandler.handleNotificationAction(
              actionId: actionId,
              message: message,
            );
            return;
          }
          if (JoinRequestPushHandler.isJoinRequestMessage(message) ||
              actionId == PushNotificationActions.approveJoin ||
              actionId == PushNotificationActions.rejectJoin) {
            _joinRequestHandler.handleNotificationAction(
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

    if (ok) {
      await IncomingCallKitService.initialize();
    }

    LoggerUtils.logInfo(
      ok
          ? 'PushNotificationBootstrap: listening for notifications'
          : 'PushNotificationBootstrap: initialize failed',
    );
  }

  /// Call once after [runApp] so cold-start Accept/Reject can navigate safely.
  static void flushPendingLaunch() {
    PushNotificationService.instance.flushPendingLaunch();
    unawaited(IncomingCallKitService.initialize());
  }
}

/// FCM background isolate — CallKit for 1:1 rings, then package handler for others.
@pragma('vm:entry-point')
Future<void> qoboFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  try {
    await IncomingCallKitDisplay.handleBackgroundRemoteMessage(message);
  } catch (_) {
    // Never block the shared background handler.
  }

  final mapped = PushNotificationMessage.fromRemoteMessage(message);
  final type = PushNotificationTypes.resolveType(mapped.data);

  // Native CallKit already shows full-screen ring — skip duplicate Accept/Reject tray.
  if (PushNotificationTypes.isIncomingCall(type)) {
    return;
  }

  await pushNotificationBackgroundHandler(message);
}
