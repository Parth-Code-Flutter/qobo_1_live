import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/social_user_card.dart';
import 'package:qobo_one_live/constants/zego_config.dart';
import 'package:qobo_one_live/repo/chat/chat_repo.dart';
import 'package:qobo_one_live/repo/chat/models/chat_room_model.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/chat/chat_incoming_call_coordinator.dart';
import 'package:qobo_one_live/services/chat/chat_session_service.dart';
import 'package:qobo_one_live/services/chat/chat_voice_call_service.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';
import 'package:qobo_one_live/utils/zego_call_id_utils.dart';
import 'package:qobo_one_live/utils/zego_engine_utils.dart';

/// Starts a 1:1 voice or video call from chat detail or messages inbox.
abstract final class ChatOutgoingCallHelper {
  ChatOutgoingCallHelper._();

  static bool _callInFlight = false;

  static Future<void> startCall(
    BuildContext context, {
    required String targetId,
    required String peerName,
    String? roomId,
    required bool isVideo,
    ChatRepo? chatRepo,
    ChatVoiceCallService? voiceCallService,
  }) async {
    if (_callInFlight) return;

    if (!ZegoConfig.voiceCallEnabled) {
      AppToast.showError(context, 'Calling is not enabled');
      return;
    }

    if (targetId.trim().isEmpty) {
      AppToast.showError(context, 'Invalid chat partner');
      return;
    }

    _callInFlight = true;
    try {
      final mic = await Permission.microphone.request();
      if (!mic.isGranted) {
        if (!context.mounted) return;
        AppToast.showError(
          context,
          'Microphone permission is required for calls',
        );
        return;
      }

      if (isVideo) {
        final camera = await Permission.camera.request();
        if (!camera.isGranted) {
          if (!context.mounted) return;
          AppToast.showError(
            context,
            'Camera permission is required for video calls',
          );
          return;
        }
      }

      if (!context.mounted) return;

      final repo = chatRepo ?? ChatRepo();
      final callService = voiceCallService ?? ChatVoiceCallService();
      final room = await _resolveRoomId(
        context,
        targetId: targetId,
        roomId: roomId,
        chatRepo: repo,
      );
      if (room.isEmpty) return;

      if (callService.isAvailable) {
        if (!Get.isRegistered<ChatSessionService>()) {
          Get.put(ChatSessionService(), permanent: true);
        }
        final signedIn = await Get.find<ChatSessionService>().ensureSignedIn(
          isShowLoader: false,
        );
        if (!signedIn) {
          if (!context.mounted) return;
          AppToast.showError(
            context,
            'Could not connect to calling service. Try again.',
          );
          return;
        }
      }

      final myId = _myUserId;
      if (myId.isEmpty) {
        if (!context.mounted) return;
        AppToast.showError(context, 'You must be logged in to call');
        return;
      }

      final callerName = _myDisplayName;
      var callId = ZegoCallIdUtils.fromRoomId(room);
      if (callService.isAvailable) {
        try {
          callId = await callService.startOutgoingCall(
            roomId: room,
            callerId: myId,
            callerName: callerName,
            calleeId: targetId,
            callType: isVideo ? ChatCallType.video : ChatCallType.voice,
          );
        } catch (e) {
          LoggerUtils.logWarning('ChatOutgoingCallHelper: start failed — $e');
          if (!context.mounted) return;
          final message = e is FirebaseException && e.code == 'permission-denied'
              ? 'Calling blocked — publish Firestore rules for chatRooms/.../calls'
              : 'Could not start call';
          AppToast.showError(context, message);
          return;
        }
      }

      if (!context.mounted) return;
      LoggerUtils.logInfo(
        'ChatOutgoingCallHelper: opening ${isVideo ? 'video' : 'voice'} '
        'callId=$callId room=$room',
      );

      await ZegoEngineUtils.resetForCallProject();
      if (Get.isRegistered<ChatIncomingCallCoordinator>()) {
        Get.find<ChatIncomingCallCoordinator>().setOnCallScreen(true);
      }

      await Get.toNamed(
        Routes.CHAT_VOICE_CALL,
        arguments: {
          'roomId': room,
          'callId': callId,
          'hostId': targetId,
          'peerName': peerName,
          'isCaller': true,
          'isVideo': isVideo,
        },
      );

      if (Get.isRegistered<ChatIncomingCallCoordinator>()) {
        Get.find<ChatIncomingCallCoordinator>().setOnCallScreen(false);
      }
    } finally {
      _callInFlight = false;
    }
  }

  static Future<String> _resolveRoomId(
    BuildContext context, {
    required String targetId,
    String? roomId,
    required ChatRepo chatRepo,
  }) async {
    final trimmed = roomId?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;

    final response = await chatRepo.createRoom(
      targetId: targetId,
      isShowLoader: false,
    );
    if (!isSocialApiSuccess(response)) {
      if (context.mounted) {
        AppToast.showError(
          context,
          response?['message']?.toString() ?? 'Chat room is not ready yet',
        );
      }
      return '';
    }

    final room = ChatRoomModel.fromResponseData(response?['data']);
    if (room.roomId.isEmpty) {
      if (context.mounted) {
        AppToast.showError(context, 'Chat room is not ready yet');
      }
      return '';
    }
    return room.roomId;
  }

  static String get _myUserId {
    if (!Get.isRegistered<UserSessionController>()) return '';
    return Get.find<UserSessionController>().userId;
  }

  static String get _myDisplayName {
    if (!Get.isRegistered<UserSessionController>()) return 'User';
    final name = Get.find<UserSessionController>().displayName;
    return name.isNotEmpty ? name : 'User';
  }
}
