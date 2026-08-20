import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qobo_one_live/app/user_flow/messages/chat_voice_call/controllers/chat_voice_call_controller.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/social_user_card.dart';
import 'package:qobo_one_live/constants/zego_config.dart';
import 'package:qobo_one_live/repo/call/call_api_utils.dart';
import 'package:qobo_one_live/repo/call/call_repo.dart';
import 'package:qobo_one_live/repo/chat/chat_repo.dart';
import 'package:qobo_one_live/repo/chat/models/chat_room_model.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/chat/chat_call_service.dart';
import 'package:qobo_one_live/services/chat/chat_incoming_call_coordinator.dart';
import 'package:qobo_one_live/services/chat/chat_session_service.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/app_dialogs/common_app_dialog.dart';
import 'package:qobo_one_live/utils/app_widgets/admin_agency_chrome.dart';
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
    String? peerAvatar,
    String? peerCountry,
    String? peerBio,
    double? coinsPerSecond,
    String? roomId,
    String? serverCallId,
    required ChatCallType callType,
    bool recordCallHistory = true,
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

      // Backend must approve the call (wallet, busy state, FCM ring) before UI.
      var resolvedServerCallId = serverCallId?.trim() ?? '';
      var effectiveCoinsPerSecond = coinsPerSecond;
      if (resolvedServerCallId.isEmpty) {
        final startResult = await _ensureBackendCallStarted(
          context: context,
          calleeUserId: targetId,
          callType: callType,
        );
        if (startResult == null || !startResult.isValid) return;
        resolvedServerCallId = startResult.callId;
        effectiveCoinsPerSecond ??= startResult.coinsPerSecond;
      }

      var callId = ZegoCallIdUtils.fromRoomId(chatRoomId);
      var historyDocId = 'call_${DateTime.now().microsecondsSinceEpoch}';
      final callStartedAt = DateTime.now().toUtc().toIso8601String();

      if (signaling.isAvailable) {
        final signedIn = await _ensureFirebaseSession();
        if (!signedIn) {
          LoggerUtils.logWarning(
            'ChatCallLauncher: Firebase sign-in failed — joining Zego without ring',
          );
          if (context.mounted) {
            AppToast.showWarning(
              context,
              'Could not ring the other person — opening call anyway.',
            );
          }
        } else {
          if (Get.isRegistered<ChatIncomingCallCoordinator>()) {
            Get.find<ChatIncomingCallCoordinator>().syncWatchedRooms([
              chatRoomId,
            ], replace: false);
          }

          try {
            final ringResult = await signaling.ringOutgoingCall(
              roomId: chatRoomId,
              callerId: myId,
              callerName: _myDisplayName,
              calleeId: targetId,
              callType: callType,
              recordCallHistory: recordCallHistory,
            );
            callId = ringResult.zegoCallId;
            if (recordCallHistory) {
              historyDocId = ringResult.historyDocId;
            }
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
      }

      if (!context.mounted) return;

      await ZegoEngineUtils.resetForCallProject();
      if (Get.isRegistered<ChatIncomingCallCoordinator>()) {
        Get.find<ChatIncomingCallCoordinator>().setOnCallScreen(true);
      }

      LoggerUtils.logInfo(
        'ChatCallLauncher: ${callType.name} callId=$callId room=$chatRoomId',
      );

      final resolvedCallId = resolvedServerCallId.isNotEmpty
          ? resolvedServerCallId
          : callId;

      await Get.toNamed(
        Routes.CHAT_VOICE_CALL,
        arguments: {
          'roomId': chatRoomId,
          'callId': resolvedCallId,
          if (recordCallHistory && historyDocId.isNotEmpty)
            'historyDocId': historyDocId,
          'callStartedAt': callStartedAt,
          'hostId': targetId,
          'peerName': peerName,
          if (peerAvatar?.trim().isNotEmpty == true)
            'peerAvatar': peerAvatar!.trim(),
          if (peerCountry?.trim().isNotEmpty == true)
            'peerCountry': peerCountry!.trim(),
          if (peerBio?.trim().isNotEmpty == true) 'peerBio': peerBio!.trim(),
          if (effectiveCoinsPerSecond != null && effectiveCoinsPerSecond > 0)
            'coinsPerSecond': effectiveCoinsPerSecond,
          'isCaller': true,
          'isVideo': callType == ChatCallType.video,
          'recordCallHistory': recordCallHistory,
        },
      );

      if (Get.isRegistered<ChatIncomingCallCoordinator>()) {
        Get.find<ChatIncomingCallCoordinator>().setOnCallScreen(false);
      }
      _refreshInboxIfVisible();
    } finally {
      _inFlight = false;
    }
  }

  static void _refreshInboxIfVisible() {
    ChatVoiceCallController.refreshMessagesInbox();
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
        await _showCallStartFailedDialog(
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

  static Future<DirectCallStartResult?> _ensureBackendCallStarted({
    required BuildContext context,
    required String calleeUserId,
    required ChatCallType callType,
  }) async {
    try {
      final response = await CallRepo().startDirectCall(
        calleeUserId: calleeUserId,
        callType: callType == ChatCallType.video ? 'video' : 'voice',
        isShowLoader: false,
      );
      if (!isCallModuleApiSuccess(response)) {
        if (context.mounted) {
          await _showCallStartFailedDialog(
            context,
            callModuleApiMessage(
              response,
              'Unable to start this call right now.',
            ),
          );
        }
        return null;
      }

      final parsed = DirectCallStartResult.fromResponse(response);
      if (!parsed.isValid) {
        if (context.mounted) {
          await _showCallStartFailedDialog(
            context,
            'Unable to start this call right now.',
          );
        }
        return null;
      }
      return parsed;
    } catch (e) {
      LoggerUtils.logWarning(
        'ChatCallLauncher: direct/start failed — $e',
      );
      if (context.mounted) {
        await _showCallStartFailedDialog(
          context,
          'Unable to start this call right now.',
        );
      }
      return null;
    }
  }

  static Future<void> _showCallStartFailedDialog(
    BuildContext context,
    String message,
  ) {
    final cleanMessage = message.trim().isEmpty
        ? 'Unable to start this call right now.'
        : message.trim();

    return CommonAppDialog.show(
      context,
      title: 'Call unavailable',
      message: cleanMessage,
      icon: Icons.phone_disabled_rounded,
      iconAccent: AdminAgencyUi.pink,
      barrierDismissible: true,
      actions: const [
        CommonAppDialogAction(label: 'Got it', isPrimary: true),
      ],
    );
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
