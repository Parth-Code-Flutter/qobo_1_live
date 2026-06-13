import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/zego_config.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../controllers/chat_voice_call_controller.dart';

/// Zego Call Kit screen — 1:1 voice or video (quick-start pattern).
class ChatVoiceCallView extends GetView<ChatVoiceCallController> {
  const ChatVoiceCallView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final callId = controller.callId.value;
      if (callId.isEmpty) {
        return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: CircularProgressIndicator(color: kColorPrimary),
          ),
        );
      }

      final isVideo = controller.isVideo.value;
      final config = _buildConfig(isVideo);

      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: ZegoUIKitPrebuiltCall(
            appID: ZegoConfig.callAppId,
            appSign: ZegoConfig.callAppSign,
            userID: controller.zegoUserId,
            userName: controller.zegoUserName,
            callID: callId,
            config: config,
            events: ZegoUIKitPrebuiltCallEvents(
              onError: (error) {
                controller.onZegoError(error);
                if (!context.mounted) return;
                AppToast.showError(
                  context,
                  error.message.isNotEmpty
                      ? error.message
                      : 'Call error (code ${error.code})',
                  title: 'Call failed',
                );
              },
              room: ZegoCallRoomEvents(
                onStateChanged: (state) {
                  LoggerUtils.logInfo(
                    'ChatVoiceCallView: room ${state.reason} '
                    'error=${state.errorCode}',
                  );
                },
              ),
              user: ZegoCallUserEvents(
                onEnter: (user) {
                  controller.onPeerJoined();
                  LoggerUtils.logInfo(
                    'ChatVoiceCallView: peer joined ${user.id}',
                  );
                },
              ),
              onCallEnd: (event, defaultAction) async {
                await controller.finishCall(refreshInbox: false);
                defaultAction.call();
                await controller.onCallScreenDisposed();
                ChatVoiceCallController.refreshMessagesInbox();
              },
            ),
          ),
        ),
      );
    });
  }

  ZegoUIKitPrebuiltCallConfig _buildConfig(bool isVideo) {
    if (isVideo) {
      return ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
        ..turnOnCameraWhenJoining = true
        ..turnOnMicrophoneWhenJoining = true
        ..useSpeakerWhenJoining = true
        ..duration.isVisible = true
        ..user.requiredUsers.enabled = false;
    }

    return ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall()
      ..turnOnCameraWhenJoining = false
      ..turnOnMicrophoneWhenJoining = true
      ..useSpeakerWhenJoining = true
      ..duration.isVisible = true
      ..user.requiredUsers.enabled = false;
  }
}
