import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qobo_one_live/app/user_flow/messages/chat_voice_call/controllers/chat_voice_call_controller.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/social_user_card.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/zego_config.dart';
import 'package:qobo_one_live/repo/chat/chat_repo.dart';
import 'package:qobo_one_live/repo/call/call_repo.dart';
import 'package:qobo_one_live/repo/chat/models/chat_room_model.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/chat/chat_call_service.dart';
import 'package:qobo_one_live/services/chat/chat_incoming_call_coordinator.dart';
import 'package:qobo_one_live/services/chat/chat_session_service.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
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

            // Ask backend to FCM-ring callee when app is background/killed.
            unawaited(
              _notifyBackendCallStart(
                calleeUserId: targetId,
                callType: callType,
                roomId: chatRoomId,
                clientCallId: callId,
                historyDocId: historyDocId,
              ),
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
          if (coinsPerSecond != null && coinsPerSecond > 0)
            'coinsPerSecond': coinsPerSecond,
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
        await _showCallApiErrorDialog(
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

  static Future<void> _showCallApiErrorDialog(
    BuildContext context,
    String message,
  ) async {
    final cleanMessage = message.trim().isEmpty
        ? 'Unable to start this call right now.'
        : message.trim();

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.62),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 30),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2A1248),
                  Color(0xFF1A0E32),
                  Color(0xFF120822),
                ],
              ),
              border: Border.all(color: kColorWhite.withValues(alpha: 0.10)),
              boxShadow: [
                BoxShadow(
                  color: kColorPrimary.withValues(alpha: 0.35),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kColorBottomNavHeart.withValues(alpha: 0.14),
                      border: Border.all(
                        color: kColorBottomNavHeart.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Icon(
                      Icons.info_rounded,
                      color: kColorBottomNavHeart,
                      size: 30,
                    ),
                  ),
                  Spacing.v16,
                  const SemiBoldText(
                    text: 'Call unavailable',
                    fontSize: TextStyles.k20FontSize,
                    color: kColorWhite,
                    align: TextAlign.center,
                  ),
                  Spacing.v10,
                  AppText(
                    text: cleanMessage,
                    fontSize: TextStyles.k14FontSize - 1,
                    color: kColorWhite.withValues(alpha: 0.76),
                    align: TextAlign.center,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Spacing.v20,
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: TextButton.styleFrom(
                        backgroundColor: kColorWhite,
                        foregroundColor: kColorPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const SemiBoldText(
                        text: 'Got it',
                        fontSize: TextStyles.k14FontSize,
                        color: kColorPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

  /// Fire-and-forget REST ring so backend can push FCM to the callee.
  static Future<void> _notifyBackendCallStart({
    required String calleeUserId,
    required ChatCallType callType,
    required String roomId,
    required String clientCallId,
    required String historyDocId,
  }) async {
    try {
      await CallRepo().startDirectCall(
        calleeUserId: calleeUserId,
        callType: callType == ChatCallType.video ? 'video' : 'voice',
        clientCallId: clientCallId,
        roomId: roomId,
        historyDocId: historyDocId,
        isShowLoader: false,
      );
    } catch (e) {
      LoggerUtils.logWarning(
        'ChatCallLauncher: direct/start for FCM ring failed — $e',
      );
    }
  }
}
