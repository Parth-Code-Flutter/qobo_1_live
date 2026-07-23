import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:push_notification_service/push_notification_service.dart';
import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/services/firebase/pk_battle_push_handler.dart';
import 'package:qobo_one_live/services/firebase/room_invite_push_handler.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/app_widgets/room_invite_in_app_banner.dart';
import 'package:qobo_one_live/utils/local_storage/controllers/local_storage_controller.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Socket.IO connection for authenticated users.
///
/// - `register_user` + `host_live_started` → follower live alerts
/// - `join_room` / `leave_room` + `room_background_updated` → live room themes
/// - `pk_*` events → PK battle realtime (request / scores / complete)
class UserRealtimeSocketService extends GetxController {
  UserRealtimeSocketService({
    RoomInvitePushHandler? roomInviteHandler,
    PkBattlePushHandler? pkBattleHandler,
  }) : _roomInviteHandler = roomInviteHandler ?? RoomInvitePushHandler(),
       _pkBattleHandler = pkBattleHandler ?? PkBattlePushHandler();

  final RoomInvitePushHandler _roomInviteHandler;
  final PkBattlePushHandler _pkBattleHandler;

  io.Socket? _socket;
  bool _connecting = false;
  String? _joinedRoomId;

  final _roomBackgroundListeners =
      <void Function(Map<String, dynamic> data)>{};

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
      _rejoinActiveRoom();
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
        _rejoinActiveRoom();
      });

      socket.onReconnect((_) {
        LoggerUtils.logInfo('RealtimeSocket: reconnected');
        socket.emit('register_user', userId);
        _rejoinActiveRoom();
      });

      socket.on('host_live_started', _onHostLiveStarted);
      socket.on('room_background_updated', _onRoomBackgroundUpdated);
      socket.on('pk_request', (raw) => _onPkNamed('pk_request', raw));
      socket.on('pk_started', (raw) => _onPkNamed('pk_started', raw));
      socket.on('pk_accepted', (raw) => _onPkNamed('pk_accepted', raw));
      socket.on('pk_rejected', (raw) => _onPkNamed('pk_rejected', raw));
      socket.on('pk_cancelled', (raw) => _onPkNamed('pk_cancelled', raw));
      socket.on('pk_score_update', (raw) => _onPkNamed('pk_score_update', raw));
      socket.on('pk_completed', (raw) => _onPkNamed('pk_completed', raw));

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

  /// Subscribe to a room channel so host theme changes reach this device.
  Future<void> joinRoomChannel(String roomId) async {
    final id = roomId.trim();
    if (id.isEmpty) return;
    await ensureConnected();
    _joinedRoomId = id;
    final socket = _socket;
    if (socket == null || !socket.connected) return;
    // Emit both common aliases — backend may accept either.
    socket.emit('join_room', id);
    socket.emit('joinRoom', id);
    LoggerUtils.logInfo('RealtimeSocket: joined room channel $id');
  }

  Future<void> leaveRoomChannel([String? roomId]) async {
    final id = (roomId ?? _joinedRoomId)?.trim() ?? '';
    final socket = _socket;
    if (id.isNotEmpty && socket != null && socket.connected) {
      socket.emit('leave_room', id);
      socket.emit('leaveRoom', id);
      LoggerUtils.logInfo('RealtimeSocket: left room channel $id');
    }
    if (roomId == null || roomId.trim() == _joinedRoomId) {
      _joinedRoomId = null;
    }
  }

  void addRoomBackgroundListener(
    void Function(Map<String, dynamic> data) listener,
  ) {
    _roomBackgroundListeners.add(listener);
  }

  void removeRoomBackgroundListener(
    void Function(Map<String, dynamic> data) listener,
  ) {
    _roomBackgroundListeners.remove(listener);
  }

  Future<void> disconnect() async {
    final socket = _socket;
    _socket = null;
    if (socket == null) return;
    try {
      socket.off('host_live_started');
      socket.off('room_background_updated');
      socket.off('pk_request');
      socket.off('pk_started');
      socket.off('pk_accepted');
      socket.off('pk_rejected');
      socket.off('pk_cancelled');
      socket.off('pk_score_update');
      socket.off('pk_completed');
      socket.dispose();
    } catch (e) {
      LoggerUtils.logWarning('RealtimeSocket: disconnect error — $e');
    }
  }

  void _rejoinActiveRoom() {
    final id = _joinedRoomId?.trim();
    final socket = _socket;
    if (id == null || id.isEmpty || socket == null || !socket.connected) return;
    socket.emit('join_room', id);
    socket.emit('joinRoom', id);
  }

  void _onRoomBackgroundUpdated(dynamic raw) {
    final data = _asStringKeyedMap(raw);
    if (data.isEmpty) return;
    LoggerUtils.logInfo('RealtimeSocket: room_background_updated data=$data');
    for (final listener in List.of(_roomBackgroundListeners)) {
      try {
        listener(data);
      } catch (e) {
        LoggerUtils.logWarning('RealtimeSocket: background listener error — $e');
      }
    }
  }

  void _onPkNamed(String event, dynamic raw) {
    final data = _asStringKeyedMap(raw);
    if (data.isEmpty && event.isEmpty) return;
    final payload = <String, dynamic>{
      ...data,
      if (data['type'] == null || data['type'].toString().trim().isEmpty)
        'type': event,
    };
    unawaited(_pkBattleHandler.handleSocketEvent(event, payload));
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
