import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'local_notification_bridge.dart';
import 'push_notification_config.dart';
import 'push_notification_handlers.dart';
import 'push_notification_message.dart';

/// Portable FCM receive service usable across Flutter projects.
///
/// Responsibilities in this phase:
/// - request notification permission
/// - listen for foreground / background / opened messages
/// - optionally show foreground local notifications
/// - expose FCM token + refresh events
///
/// Navigation on tap is deferred — use [PushNotificationHandlers.onNotificationTap].
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  /// Host callback invoked from the top-level background isolate.
  static PushNotificationConfig _config = const PushNotificationConfig();
  static bool _initialized = false;

  final LocalNotificationBridge _localNotifications = LocalNotificationBridge();
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  PushNotificationHandlers _handlers = const PushNotificationHandlers();
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  bool get isInitialized => _initialized;

  /// Called by [pushNotificationBackgroundHandler] in a background isolate.
  ///
  /// Keep this lightweight. Host-specific work should live in a custom
  /// top-level handler that calls this method first.
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    // Firebase must be initialized in secondary isolates as well.
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (_) {
      // Host may already have initialized with options; ignore duplicates.
    }

    final mapped = PushNotificationMessage.fromRemoteMessage(message);
    _log('background message: $mapped');
  }

  /// Initialize listeners after the host app has initialized Firebase Core.
  Future<bool> initialize({
    PushNotificationConfig config = const PushNotificationConfig(),
    PushNotificationHandlers handlers = const PushNotificationHandlers(),
  }) async {
    if (kIsWeb) {
      _log('skipped on web');
      return false;
    }

    if (_initialized) {
      _log('already initialized');
      return true;
    }

    if (Firebase.apps.isEmpty) {
      _log('Firebase not initialized — call Firebase.initializeApp first');
      return false;
    }

    _config = config;
    _handlers = handlers;

    try {
      if (config.requestPermissionsOnInit) {
        await requestPermission();
      }

      // iOS: allow alert presentation while app is foregrounded.
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      if (config.showForegroundNotifications) {
        await _localNotifications.initialize(config);
        // Local-notification taps share the same future onTap hook.
        _localNotifications.onLocalNotificationTap = (_) {
          // Payload mapping (messageId) can be expanded in the onClick phase.
        };
      }

      _bindMessageStreams();
      await _emitInitialToken();
      _bindTokenRefresh();

      // App launched from a terminated state by tapping a notification.
      final initial = await _messaging.getInitialMessage();
      if (initial != null) {
        _dispatchTap(PushNotificationMessage.fromRemoteMessage(initial));
      }

      _initialized = true;
      _log('initialized');
      return true;
    } catch (e, st) {
      _log('initialize failed: $e\n$st');
      return false;
    }
  }

  /// Requests OS notification permission (safe to call again later).
  Future<NotificationSettings> requestPermission() {
    return _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  /// Current FCM registration token, or null when unavailable.
  Future<String?> getToken() async {
    try {
      final token = (await _messaging.getToken())?.trim();
      if (token == null || token.isEmpty) return null;
      return token;
    } catch (e) {
      _log('getToken failed: $e');
      return null;
    }
  }

  /// Removes stream subscriptions. Safe to call from tests / logout flows.
  Future<void> dispose() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    _initialized = false;
  }

  void _bindMessageStreams() {
    // Foreground delivery
    _subscriptions.add(
      FirebaseMessaging.onMessage.listen((remote) async {
        final message = PushNotificationMessage.fromRemoteMessage(remote);
        _log('foreground message: $message');
        _handlers.onForegroundMessage?.call(message);

        if (_config.showForegroundNotifications &&
            message.hasNotificationContent) {
          await _localNotifications.showFromMessage(
            config: _config,
            message: message,
          );
        }
      }),
    );

    // User opened a notification while app was backgrounded (not terminated).
    _subscriptions.add(
      FirebaseMessaging.onMessageOpenedApp.listen((remote) {
        final message = PushNotificationMessage.fromRemoteMessage(remote);
        _log('opened from background: $message');
        _dispatchTap(message);
      }),
    );
  }

  void _bindTokenRefresh() {
    _subscriptions.add(
      _messaging.onTokenRefresh.listen((token) {
        final normalized = token.trim();
        if (normalized.isEmpty) return;
        _log('token refreshed');
        _handlers.onTokenRefresh?.call(normalized);
      }),
    );
  }

  Future<void> _emitInitialToken() async {
    final token = await getToken();
    if (token == null) return;
    _handlers.onToken?.call(token);
  }

  void _dispatchTap(PushNotificationMessage message) {
    // Placeholder for the upcoming onClick / deep-link feature.
    _handlers.onNotificationTap?.call(message);
  }

  static void _log(String message) {
    if (!_config.enableVerboseLogging && !kDebugMode) return;
    debugPrint('[PushNotificationService] $message');
  }
}
