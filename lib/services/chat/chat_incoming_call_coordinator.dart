import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/messages/chat_voice_call/controllers/chat_voice_call_controller.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/chat/chat_call_service.dart';
import 'package:qobo_one_live/services/chat/chat_session_service.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/zego_call_id_utils.dart';
import 'package:qobo_one_live/utils/zego_engine_utils.dart';

/// Listens for Firestore `calls/active` and shows incoming call UI.
class ChatIncomingCallCoordinator extends GetxService {
  ChatIncomingCallCoordinator({ChatCallService? callService})
      : _callService = callService ?? ChatCallService();

  final ChatCallService _callService;

  final Map<String, StreamSubscription<Map<String, dynamic>>> _subscriptions =
      {};
  final Set<String> _watchedRooms = {};
  bool _dialogOpen = false;
  bool _onCallScreen = false;

  void setOnCallScreen(bool value) => _onCallScreen = value;

  void syncWatchedRooms(Iterable<String> roomIds, {bool replace = false}) {
    if (!_callService.isAvailable) return;

    final normalized = roomIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (replace) {
      _watchedRooms
        ..clear()
        ..addAll(normalized);
    } else {
      _watchedRooms.addAll(normalized);
    }
    _applyWatchers();
  }

  void _applyWatchers() {
    final stale = _subscriptions.keys
        .where((roomId) => !_watchedRooms.contains(roomId))
        .toList();
    for (final roomId in stale) {
      unawaited(_subscriptions.remove(roomId)?.cancel());
    }

    for (final roomId in _watchedRooms) {
      if (_subscriptions.containsKey(roomId)) continue;
      _subscriptions[roomId] = _callService
          .watchActiveCall(roomId)
          .listen(
            (data) => _onActiveCallSnapshot(roomId: roomId, data: data),
            onError: (_) {},
          );
    }
  }

  void _onActiveCallSnapshot({
    required String roomId,
    required Map<String, dynamic> data,
  }) {
    if (data.isEmpty || _onCallScreen || _dialogOpen) return;

    final myId = _myUserId;
    if (myId.isEmpty) return;

    final status = data['status']?.toString() ?? '';
    final callerId = data['callerId']?.toString() ?? '';
    if (status != 'ringing' || callerId.isEmpty || callerId == myId) return;

    final calleeId = data['calleeId']?.toString() ?? '';
    if (calleeId.isNotEmpty && calleeId != myId) return;

    _dialogOpen = true;
    final callerName = data['callerName']?.toString() ?? 'Someone';
    final callId =
        data['callId']?.toString() ?? ZegoCallIdUtils.fromRoomId(roomId);
    final isVideo = data['type']?.toString() == 'video';

    Get.dialog<void>(
      AlertDialog(
        title: Text(isVideo ? 'Incoming video call' : 'Incoming call'),
        content: Text(
          isVideo
              ? '$callerName is video calling you'
              : '$callerName is calling you',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Get.back();
              _dialogOpen = false;
              await _callService.endCall(
                roomId,
                endedByUserId: myId,
              );
              ChatVoiceCallController.refreshMessagesInbox();
            },
            child: const Text('Decline'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              _dialogOpen = false;
              await _acceptCall(
                roomId: roomId,
                callId: callId,
                callerId: callerId,
                callerName: callerName,
                isVideo: isVideo,
              );
            },
            child: const Text('Accept'),
          ),
        ],
      ),
      barrierDismissible: false,
    ).whenComplete(() => _dialogOpen = false);
  }

  Future<void> _acceptCall({
    required String roomId,
    required String callId,
    required String callerId,
    required String callerName,
    required bool isVideo,
  }) async {
    final myId = _myUserId;
    if (myId.isEmpty) return;

    if (!Get.isRegistered<ChatSessionService>()) {
      Get.put(ChatSessionService(), permanent: true);
    }
    final signedIn =
        await Get.find<ChatSessionService>().ensureSignedIn(isShowLoader: false);
    if (!signedIn) return;

    await _callService.markAccepted(roomId: roomId, userId: myId);
    await ZegoEngineUtils.resetForCallProject();
    _onCallScreen = true;

    await Get.toNamed(
      Routes.CHAT_VOICE_CALL,
      arguments: {
        'roomId': roomId,
        'callId': callId,
        'hostId': callerId,
        'peerName': callerName,
        'isCaller': false,
        'isVideo': isVideo,
      },
    );
    _onCallScreen = false;
  }

  String get _myUserId {
    if (!Get.isRegistered<UserSessionController>()) return '';
    return Get.find<UserSessionController>().userId;
  }

  @override
  void onClose() {
    for (final sub in _subscriptions.values) {
      unawaited(sub.cancel());
    }
    _subscriptions.clear();
    super.onClose();
  }
}
