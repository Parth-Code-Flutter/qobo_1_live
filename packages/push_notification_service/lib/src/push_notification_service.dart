import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'local_notification_bridge.dart';
import 'push_notification_actions.dart';
import 'push_notification_config.dart';
import 'push_notification_handlers.dart';
import 'push_notification_message.dart';
import 'push_notification_types.dart';

/// Portable FCM receive service usable across Flutter projects.
///
/// Supports optional actionable local notifications (Join / Reject) so Android
/// data-only invites and iOS `ROOM_INVITE` category payloads can share one flow.
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static PushNotificationConfig _config = const PushNotificationConfig();
  static bool _initialized = false;

  final LocalNotificationBridge _localNotifications = LocalNotificationBridge();
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  PushNotificationHandlers _handlers = const PushNotificationHandlers();
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  /// Cold-start tap/action captured before [GetMaterialApp] is ready.
  PushNotificationMessage? _pendingTapMessage;
  String? _pendingActionId;

  bool get isInitialized => _initialized;

  /// Optional host override for background action handling (terminated state).
  static DidReceiveBackgroundNotificationResponseCallback?
  backgroundNotificationActionHandler;

  /// Called by [pushNotificationBackgroundHandler] in a background isolate.
  ///
  /// Shows an actionable local notification for known push types
  /// (`room_invite`, `room_created`, `live_streaming_created`,
  /// `live_stream_started`, `general`, `custom`) so Android data-only messages
  /// can expose Join / Reject or Join / Dismiss buttons.
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (_) {
      // Host may already have initialized with options; ignore duplicates.
    }

    final mapped = PushNotificationMessage.fromRemoteMessage(message);
    _log('background message: $mapped');

    final type = PushNotificationTypes.resolveType(mapped.data);
    if (type == PushNotificationTypes.callCancelled) {
      final bridge = LocalNotificationBridge();
      await bridge.initialize(_config);
      await bridge.cancelForMessage(mapped);
      return;
    }

    final actionSet = actionSetForData(mapped.data);
    if (actionSet == PushNotificationActionSet.none) return;

    // Background isolate has no shared UI bridge — spin up a throwaway plugin.
    final bridge = LocalNotificationBridge();
    bridge.backgroundActionHandler = backgroundNotificationActionHandler;
    await bridge.initialize(_config);
    final display = displayCopyFor(mapped);
    await bridge.showFromMessage(
      config: _config,
      message: mapped,
      actionSet: actionSet,
      titleOverride: display.title,
      bodyOverride: display.body,
    );
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

      _localNotifications.backgroundActionHandler =
          backgroundNotificationActionHandler;
      await _localNotifications.initialize(config);
      _localNotifications.onLocalNotificationTap = (message) {
        _dispatchTap(message);
      };
      _localNotifications.onLocalNotificationAction = (actionId, message) {
        _dispatchAction(actionId, message);
      };

      _bindMessageStreams();
      await _emitInitialToken();
      _bindTokenRefresh();

      // Cold-start: stash until the host app calls [flushPendingLaunch] after
      // runApp() — GetX navigation is not available during initialize().
      final launchDetails = await FlutterLocalNotificationsPlugin()
          .getNotificationAppLaunchDetails();
      final launchResponse = launchDetails?.notificationResponse;
      if (launchDetails?.didNotificationLaunchApp == true &&
          launchResponse != null) {
        final message = PushNotificationMessage.fromPayloadJson(
          launchResponse.payload,
        );
        final actionId = launchResponse.actionId?.trim() ?? '';
        _pendingTapMessage = message;
        _pendingActionId = actionId.isEmpty ? null : actionId;
      } else {
        final initial = await _messaging.getInitialMessage();
        if (initial != null) {
          _pendingTapMessage = PushNotificationMessage.fromRemoteMessage(
            initial,
          );
          _pendingActionId = null;
        }
      }

      _initialized = true;
      _log('initialized');
      return true;
    } catch (e, st) {
      _log('initialize failed: $e\n$st');
      return false;
    }
  }

  /// Delivers a cold-start notification tap/action after the UI tree exists.
  void flushPendingLaunch() {
    final message = _pendingTapMessage;
    if (message == null) return;
    final actionId = _pendingActionId;
    _pendingTapMessage = null;
    _pendingActionId = null;

    if (actionId != null && actionId.isNotEmpty) {
      _dispatchAction(actionId, message);
    } else {
      _dispatchTap(message);
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

  /// Shows (or re-shows) a local tray entry, optionally with action buttons.
  Future<void> showLocalNotification({
    required PushNotificationMessage message,
    PushNotificationActionSet actionSet = PushNotificationActionSet.none,
    String? title,
    String? body,
  }) {
    return _localNotifications.showFromMessage(
      config: _config,
      message: message,
      actionSet: actionSet,
      titleOverride: title,
      bodyOverride: body,
    );
  }

  Future<void> cancelLocalNotification(PushNotificationMessage message) {
    return _localNotifications.cancelForMessage(message);
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
    _subscriptions.add(
      FirebaseMessaging.onMessage.listen((remote) async {
        final message = PushNotificationMessage.fromRemoteMessage(remote);
        _log('foreground message: $message');
        _handlers.onForegroundMessage?.call(message);

        final type = PushNotificationTypes.resolveType(message.data);
        if (type == PushNotificationTypes.callCancelled) {
          await _localNotifications.cancelForMessage(message);
          return;
        }

        final actionSet = actionSetForData(message.data);
        if (actionSet != PushNotificationActionSet.none) {
          // Prefer branded in-app UI when the host provides one.
          final handled =
              await _handlers.onForegroundActionableMessage?.call(message) ??
              false;
          if (handled) return;

          // iOS already renders the APNs alert + ROOM_INVITE actions when a
          // `notification` block is present — avoid a duplicate local tray.
          if (!kIsWeb && Platform.isIOS && message.hasNotificationContent) {
            return;
          }
          final display = displayCopyFor(message);
          await _localNotifications.showFromMessage(
            config: _config,
            message: message,
            actionSet: actionSet,
            titleOverride: display.title,
            bodyOverride: display.body,
          );
          return;
        }

        if (_config.showForegroundNotifications &&
            message.hasNotificationContent) {
          await _localNotifications.showFromMessage(
            config: _config,
            message: message,
          );
        }
      }),
    );

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
    _handlers.onNotificationTap?.call(message);
  }

  void _dispatchAction(String actionId, PushNotificationMessage message) {
    _log('action=$actionId message=$message');
    _handlers.onNotificationAction?.call(actionId, message);
  }

  /// Maps FCM `type` → which action buttons the tray should show.
  static PushNotificationActionSet actionSetForData(Map<String, dynamic> data) {
    final type = PushNotificationTypes.resolveType(data);
    if (PushNotificationTypes.isDirectInvite(type)) {
      return PushNotificationActionSet.joinReject;
    }
    if (PushNotificationTypes.isPkRequest(type)) {
      return PushNotificationActionSet.pkAcceptReject;
    }
    if (PushNotificationTypes.isJoinRequest(type)) {
      return PushNotificationActionSet.joinApproveReject;
    }
    if (PushNotificationTypes.isIncomingCall(type)) {
      return PushNotificationActionSet.callAcceptReject;
    }
    if (PushNotificationTypes.isJoinDismiss(type)) {
      return PushNotificationActionSet.joinDismiss;
    }
    return PushNotificationActionSet.none;
  }

  /// Builds title/body when Android data-only payloads omit notification text.
  static ({String title, String body}) displayCopyFor(
    PushNotificationMessage message,
  ) {
    final type = PushNotificationTypes.resolveType(message.data);
    final host = message.data['host_name']?.toString().trim();
    final roomTitle = message.data['room_title']?.toString().trim();
    final roomType = message.data['room_type']?.toString().trim() ?? 'live';
    final hostLabel = host?.isNotEmpty == true ? host! : 'A host';
    final roomLabel = roomTitle?.isNotEmpty == true ? roomTitle! : 'a room';

    if (message.title.trim().isNotEmpty || message.body.trim().isNotEmpty) {
      return (
        title: message.title.trim().isNotEmpty
            ? message.title.trim()
            : _defaultTitleFor(type),
        body: message.body.trim(),
      );
    }

    switch (type) {
      case PushNotificationTypes.roomInvite:
        return (
          title: 'Room Invitation',
          body:
              '${host?.isNotEmpty == true ? host : 'Someone'} invited you to '
              'join "$roomLabel"',
        );
      case PushNotificationTypes.roomCreated:
        return (
          title: 'Live Stream Alert',
          body:
              '$hostLabel started a $roomType room'
              '${roomTitle?.isNotEmpty == true ? ': $roomTitle' : ''}',
        );
      case PushNotificationTypes.liveStreamingCreated:
      case PushNotificationTypes.liveStreamStarted:
        return (
          title: 'Live Stream Alert! 🔴',
          body:
              '$hostLabel started a live video stream'
              '${roomTitle?.isNotEmpty == true ? ': $roomTitle' : ''}',
        );
      case PushNotificationTypes.pkRequest:
        final sender =
            message.data['sender_host_name']?.toString().trim().isNotEmpty ==
                true
            ? message.data['sender_host_name']!.toString().trim()
            : 'A host';
        final senderRoom =
            message.data['sender_room_title']?.toString().trim().isNotEmpty ==
                true
            ? message.data['sender_room_title']!.toString().trim()
            : 'their room';
        return (
          title: 'PK Battle Challenge',
          body: '$sender challenged you from "$senderRoom"',
        );
      case PushNotificationTypes.pkFollowerInvite:
        final challenger =
            message.data['challenger_name']?.toString().trim().isNotEmpty ==
                true
            ? message.data['challenger_name']!.toString().trim()
            : (message.data['from_user_name']?.toString().trim().isNotEmpty ==
                      true
                  ? message.data['from_user_name']!.toString().trim()
                  : 'A user you follow');
        return (
          title: 'Follower PK Challenge ⚡',
          body: '$challenger is looking for a PK opponent. Accept now!',
        );
      case PushNotificationTypes.pkAccepted:
      case PushNotificationTypes.pkStarted:
        return (
          title: 'PK Battle Started',
          body: 'Your PK battle is now live. Open the arena to compete!',
        );
      case PushNotificationTypes.pkRejected:
        return (
          title: 'PK Challenge Declined',
          body: 'Your PK request was rejected.',
        );
      case PushNotificationTypes.pkCancelled:
        return (
          title: 'PK Challenge Cancelled',
          body: 'The PK request was cancelled.',
        );
      case PushNotificationTypes.pkCompleted:
        return (
          title: 'PK Battle Finished',
          body: 'The PK battle has ended. Check the results!',
        );
      case PushNotificationTypes.pkFollowerJoined:
        return (
          title: 'Follower PK Opponent Found',
          body: 'Your opponent joined. Choose the battle duration.',
        );
      case PushNotificationTypes.pkFollowerDurationSet:
        return (
          title: 'Follower PK Started ⚡',
          body: 'The timer is running. Open the arena!',
        );
      case PushNotificationTypes.pkFollowerCompleted:
        return (
          title: 'Follower PK Finished',
          body: 'The battle ended. Open to see the result.',
        );
      case PushNotificationTypes.pkFollowerCancelled:
        return (
          title: 'Follower PK Cancelled',
          body: 'This follower PK is no longer available.',
        );
      case PushNotificationTypes.joinRequest:
        final requester =
            message.data['requester_name']?.toString().trim().isNotEmpty == true
            ? message.data['requester_name']!.toString().trim()
            : 'Someone';
        return (
          title: 'Join Request',
          body: '$requester wants to join "$roomLabel"',
        );
      case PushNotificationTypes.joinApproved:
        return (
          title: 'Join Approved',
          body: 'Host approved your request. Tap to join.',
        );
      case PushNotificationTypes.joinRejected:
        return (
          title: 'Join Declined',
          body: message.data['message']?.toString().trim().isNotEmpty == true
              ? message.data['message']!.toString().trim()
              : 'Host declined your request to join',
        );
      case PushNotificationTypes.joinRequestExpired:
        return (
          title: 'Request Expired',
          body: 'Your join request expired. Try again.',
        );
      case PushNotificationTypes.incomingCall:
        final caller =
            message.data['caller_name']?.toString().trim().isNotEmpty == true
            ? message.data['caller_name']!.toString().trim()
            : 'Someone';
        final callType =
            message.data['call_type']?.toString().trim().toLowerCase() ?? '';
        final isVideo = callType == 'video';
        return (
          title: isVideo ? 'Incoming video call' : 'Incoming call',
          body: isVideo
              ? '$caller is video calling you'
              : '$caller is calling you',
        );
      case PushNotificationTypes.callCancelled:
        return (
          title: 'Call ended',
          body: 'The incoming call is no longer available.',
        );
      case PushNotificationTypes.callMissed:
        final callee =
            message.data['callee_name']?.toString().trim().isNotEmpty == true
            ? message.data['callee_name']!.toString().trim()
            : 'User';
        return (
          title: 'Missed call',
          body: '$callee did not answer.',
        );
      case PushNotificationTypes.general:
      case PushNotificationTypes.custom:
        return (title: 'Notification', body: '');
      default:
        return (title: 'Notification', body: '');
    }
  }

  static String _defaultTitleFor(String type) {
    switch (type) {
      case PushNotificationTypes.roomInvite:
        return 'Room Invitation';
      case PushNotificationTypes.roomCreated:
      case PushNotificationTypes.liveStreamingCreated:
      case PushNotificationTypes.liveStreamStarted:
        return 'Live Stream Alert! 🔴';
      case PushNotificationTypes.pkRequest:
      case PushNotificationTypes.pkFollowerInvite:
        return 'PK Battle Challenge';
      case PushNotificationTypes.pkAccepted:
      case PushNotificationTypes.pkStarted:
        return 'PK Battle Started';
      case PushNotificationTypes.pkRejected:
        return 'PK Challenge Declined';
      case PushNotificationTypes.pkCancelled:
        return 'PK Challenge Cancelled';
      case PushNotificationTypes.pkCompleted:
      case PushNotificationTypes.pkFollowerCompleted:
        return 'PK Battle Finished';
      case PushNotificationTypes.pkFollowerJoined:
        return 'PK Opponent Found';
      case PushNotificationTypes.pkFollowerDurationSet:
        return 'PK Battle Started';
      case PushNotificationTypes.pkFollowerCancelled:
        return 'PK Challenge Cancelled';
      case PushNotificationTypes.joinRequest:
        return 'Join Request';
      case PushNotificationTypes.joinApproved:
        return 'Join Approved';
      case PushNotificationTypes.joinRejected:
        return 'Join Declined';
      case PushNotificationTypes.joinRequestExpired:
        return 'Request Expired';
      case PushNotificationTypes.incomingCall:
        return 'Incoming call';
      case PushNotificationTypes.callCancelled:
        return 'Call ended';
      case PushNotificationTypes.callMissed:
        return 'Missed call';
      default:
        return 'Notification';
    }
  }

  static void _log(String message) {
    if (!_config.enableVerboseLogging && !kDebugMode) return;
    debugPrint('[PushNotificationService] $message');
  }
}
