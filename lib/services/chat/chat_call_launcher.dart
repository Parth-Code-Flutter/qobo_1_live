import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/social_user_card.dart';
import 'package:qobo_one_live/constants/zego_config.dart';
import 'package:qobo_one_live/repo/chat/chat_repo.dart';
import 'package:qobo_one_live/repo/chat/models/chat_room_model.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/chat/chat_call_service.dart';
import 'package:qobo_one_live/services/chat/chat_incoming_call_coordinator.dart';
import 'package:qobo_one_live/services/chat/chat_session_service.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';
import 'package:qobo_one_live/utils/zego_call_id_utils.dart';
import 'package:qobo_one_live/utils/zego_engine_utils.dart';

/// Launches ZegoUIKitPrebuiltCall for 1:1 voice or video from chat.
///
/// Follows [Zego Call Kit quick start](https://www.zegocloud.com/docs/uikit/callkit-flutter/quick-start):
/// reset engine → join room with shared `callID`.
abstract final class ChatCallLauncher {
  ChatCallLauncher._();

  static bool _inFlight = false;

  static Future<void> start({
    required BuildContext context,
    required String targetId,
    required String peerName,
    String? roomId,
    required ChatCallType callType,
    ChatRepo? chatRepo,
    ChatCallService? callService,
  }) async {
    if (_inFlight) return;

    if (!ZegoConfig.callEnabled) {
      AppToast.showError(context, 'Calling is not enabled');
      return;
    }
    if (targetId.trim().isEmpty) {
      AppToast.showError(context, 'Invalid chat partner');
      return;
    }

    _inFlight = true;
    try {
      if (!await _ensurePermissions(context, callType)) return;
      if (!context.mounted) return;

      final repo = chatRepo ?? ChatRepo();
      final signaling = callService ?? ChatCallService();
      final chatRoomId = await _resolveChatRoomId(
        context,
        targetId: targetId,
        roomId: roomId,
        chatRepo: repo,
      );
      if (chatRoomId.isEmpty || !context.mounted) return;

      final myId = _myUserId;
      if (myId.isEmpty) {
        AppToast.showError(context, 'You must be logged in to call');
        return;
      }

      var callId = ZegoCallIdUtils.fromRoomId(chatRoomId);

      if (signaling.isAvailable) {
        final signedIn = await _ensureFirebaseSession();
        if (!signedIn) {
          if (!context.mounted) return;
          AppToast.showError(
            context,
            'Could not connect to calling service. Try again.',
          );
          return;
        }

        try {
          callId = await signaling.ringOutgoingCall(
            roomId: chatRoomId,
            callerId: myId,
            callerName: _myDisplayName,
            calleeId: targetId,
            callType: callType,
          );
        } catch (e) {
          LoggerUtils.logWarning(
            'ChatCallLauncher: Firestore ring failed — $e (joining Zego anyway)',
          );
          if (context.mounted && e is FirebaseException) {
            if (e.code == 'permission-denied') {
              AppToast.showWarning(
                context,
                'Ring signal blocked — publish Firestore rules. Joining call…',
              );
            }
          }
        }
      }

      if (!context.mounted) return;

      await ZegoEngineUtils.resetForCallProject();
      if (Get.isRegistered<ChatIncomingCallCoordinator>()) {
        Get.find<ChatIncomingCallCoordinator>().setOnCallScreen(true);
      }

      LoggerUtils.logInfo(
        'ChatCallLauncher: ${callType.name} callId=$callId room=$chatRoomId',
      );

      await Get.toNamed(
        Routes.CHAT_VOICE_CALL,
        arguments: {
          'roomId': chatRoomId,
          'callId': callId,
          'hostId': targetId,
          'peerName': peerName,
          'isCaller': true,
          'isVideo': callType == ChatCallType.video,
        },
      );

      if (Get.isRegistered<ChatIncomingCallCoordinator>()) {
        Get.find<ChatIncomingCallCoordinator>().setOnCallScreen(false);
      }
    } finally {
      _inFlight = false;
    }
  }

  static Future<bool> _ensurePermissions(
    BuildContext context,
    ChatCallType callType,
  ) async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      if (context.mounted) {
        AppToast.showError(
          context,
          'Microphone permission is required for calls',
        );
      }
      return false;
    }
    if (callType == ChatCallType.video) {
      final camera = await Permission.camera.request();
      if (!camera.isGranted) {
        if (context.mounted) {
          AppToast.showError(
            context,
            'Camera permission is required for video calls',
          );
        }
        return false;
      }
    }
    return true;
  }

  static Future<bool> _ensureFirebaseSession() async {
    if (!Get.isRegistered<ChatSessionService>()) {
      Get.put(ChatSessionService(), permanent: true);
    }
    return Get.find<ChatSessionService>().ensureSignedIn(isShowLoader: false);
  }

  static Future<String> _resolveChatRoomId(
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
