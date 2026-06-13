import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/chat/chat_session_service.dart';
import 'package:qobo_one_live/services/chat/chat_voice_call_service.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';
import 'package:qobo_one_live/utils/zego_call_id_utils.dart';
import 'package:qobo_one_live/utils/zego_engine_utils.dart';

/// Listens for Firestore `calls/active` on inbox chat rooms and shows ring UI.
class ChatIncomingCallCoordinator extends GetxService {
  ChatIncomingCallCoordinator({ChatVoiceCallService? voiceCallService})
      : _voiceCallService = voiceCallService ?? ChatVoiceCallService();

  final ChatVoiceCallService _voiceCallService;

  final Map<String, StreamSubscription<Map<String, dynamic>>> _subscriptions =
      {};
  final Set<String> _watchedRooms = {};
  bool _dialogOpen = false;
  bool _onCallScreen = false;

  void setOnCallScreen(bool value) {
    _onCallScreen = value;
  }

  /// Add or refresh Firestore listeners for the given chat room ids.
  void syncWatchedRooms(Iterable<String> roomIds, {bool replace = false}) {
    if (!_voiceCallService.isAvailable) return;

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
      _subscriptions[roomId] = _voiceCallService
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
    final peerTargetId = callerId;

    LoggerUtils.logInfo(
      'ChatIncomingCallCoordinator: incoming ${isVideo ? 'video' : 'voice'} '
      'call room=$roomId from $callerName',
    );

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
              await _voiceCallService.endCall(roomId);
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
                callerId: peerTargetId,
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
    if (!signedIn) {
      LoggerUtils.logWarning(
        'ChatIncomingCallCoordinator: Firebase sign-in failed on accept',
      );
      return;
    }

    await _voiceCallService.markAccepted(roomId: roomId, userId: myId);
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
