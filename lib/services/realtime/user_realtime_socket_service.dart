import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:push_notification_service/push_notification_service.dart';
import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/services/firebase/room_invite_push_handler.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/app_widgets/room_invite_in_app_banner.dart';
import 'package:qobo_one_live/utils/local_storage/controllers/local_storage_controller.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Socket.IO connection for authenticated users (follower live-stream alerts).
///
/// Contract (backend guide):
/// - On connect: `socket.emit('register_user', currentUserId)`
/// - Listen: `socket.on('host_live_started', …)` → in-app Join banner
class UserRealtimeSocketService extends GetxController {
  UserRealtimeSocketService({
    RoomInvitePushHandler? roomInviteHandler,
  }) : _roomInviteHandler = roomInviteHandler ?? RoomInvitePushHandler();

  final RoomInvitePushHandler _roomInviteHandler;

  io.Socket? _socket;
  bool _connecting = false;

  /// Ensures a singleton exists and connects when the user is logged in.
  static Future<void> ensureConnected() async {
    final service = Get.isRegistered<UserRealtimeSocketService>()
        ? Get.find<UserRealtimeSocketService>()
        : Get.put(UserRealtimeSocketService(), permanent: true);
    await service.connect();
  }

  /// Disconnects and forgets the socket (call on logout).
  static Future<void> ensureDisconnected() async {
    if (!Get.isRegistered<UserRealtimeSocketService>()) return;
    await Get.find<UserRealtimeSocketService>().disconnect();
  }

  Future<void> connect() async {
    final isLoggedIn = await LocalStorage.shared.isLoggedIn();
    if (!isLoggedIn) return;

    final userId = await _resolveUserId();
    if (userId.isEmpty) {
      LoggerUtils.logInfo('RealtimeSocket: skipped — empty userId');
      return;
    }

    if (_socket?.connected == true) {
      _socket!.emit('register_user', userId);
      return;
    }
    if (_connecting) return;
    _connecting = true;

    try {
      await disconnect();

      final socket = io.io(
        ApiConstants.baseUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(8)
            .setReconnectionDelay(1500)
            .build(),
      );
      _socket = socket;

      socket.onConnect((_) {
        LoggerUtils.logInfo('RealtimeSocket: connected');
        socket.emit('register_user', userId);
      });

      socket.onReconnect((_) {
        LoggerUtils.logInfo('RealtimeSocket: reconnected');
        socket.emit('register_user', userId);
      });

      socket.on('host_live_started', _onHostLiveStarted);

      socket.onDisconnect((_) {
        LoggerUtils.logInfo('RealtimeSocket: disconnected');
      });

      socket.onConnectError((error) {
        LoggerUtils.logWarning('RealtimeSocket: connect error — $error');
      });

      socket.connect();
    } catch (e) {
      LoggerUtils.logWarning('RealtimeSocket: connect failed — $e');
    } finally {
      _connecting = false;
    }
  }

  Future<void> disconnect() async {
    final socket = _socket;
    _socket = null;
    if (socket == null) return;
    try {
      socket.off('host_live_started');
      socket.dispose();
    } catch (e) {
      LoggerUtils.logWarning('RealtimeSocket: disconnect error — $e');
    }
  }

  void _onHostLiveStarted(dynamic raw) {
    final data = _asStringKeyedMap(raw);
    if (data.isEmpty) {
      LoggerUtils.logInfo('RealtimeSocket: host_live_started empty payload');
      return;
    }

    LoggerUtils.logInfo(
      'RealtimeSocket: host_live_started data=$data',
    );

    // Normalize to the same shape the FCM path already understands.
    final normalized = <String, dynamic>{
      ...data,
      'type': data['type'] ?? PushNotificationTypes.liveStreamStarted,
      'event': data['event'] ?? 'host_live_started',
      'room_id': data['room_id'] ?? data['roomId'],
      'roomId': data['roomId'] ?? data['room_id'],
      'room_type': data['room_type'] ?? data['roomType'] ?? 'live_stream',
      'host_id': data['host_id'] ?? data['hostId'],
      'host_name': data['host_name'] ?? data['hostName'],
      'title': data['title'],
      'message': data['message'],
    };

    final hostName =
        normalized['host_name']?.toString() ??
        normalized['hostName']?.toString() ??
        'A user you follow';
    final message =
        normalized['message']?.toString() ?? '$hostName is now live!';

    final pushMessage = PushNotificationMessage(
      messageId: 'socket_host_live_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Live Stream Alert! 🔴',
      body: message,
      data: normalized,
    );

    // Show the branded Join banner once the overlay is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        RoomInviteInAppBanner.tryShow(
          pushMessage,
          handler: _roomInviteHandler,
        ),
      );
    });
  }

  Future<String> _resolveUserId() async {
    final session = Get.isRegistered<UserSessionController>()
        ? Get.find<UserSessionController>()
        : Get.put(UserSessionController(), permanent: true);
    if (session.userId.isEmpty) {
      await session.loadFromStorage();
    }
    return session.userId.trim();
  }

  Map<String, dynamic> _asStringKeyedMap(dynamic raw) {
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return const <String, dynamic>{};
  }

  @override
  void onClose() {
    unawaited(disconnect());
    super.onClose();
  }
}
