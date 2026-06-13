import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/zego_config.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../controllers/chat_voice_call_controller.dart';

class ChatVoiceCallView extends GetView<ChatVoiceCallController> {
  const ChatVoiceCallView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final callId = controller.callId.value;
      if (callId.isEmpty) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      final isVideo = controller.isVideo.value;
      final config = isVideo
          ? (ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
            ..turnOnCameraWhenJoining = true
            ..turnOnMicrophoneWhenJoining = true
            ..useSpeakerWhenJoining = true)
          : (ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall()
            ..turnOnCameraWhenJoining = false
            ..useSpeakerWhenJoining = true);

      config
        ..duration.isVisible = true
        ..user.requiredUsers.enabled = false;

      return ZegoUIKitPrebuiltCall(
        appID: ZegoConfig.callAppId,
        appSign: ZegoConfig.callAppSign,
        userID: controller.zegoUserId,
        userName: controller.zegoUserName,
        callID: callId,
        config: config,
        events: ZegoUIKitPrebuiltCallEvents(
          onError: (error) {
            controller.onZegoError(error);
            if (context.mounted) {
              AppToast.showError(
                context,
                _zegoErrorMessage(error),
                title: 'Call failed',
              );
            }
          },
          room: ZegoCallRoomEvents(
            onStateChanged: (state) {
              LoggerUtils.logInfo(
                'ChatVoiceCallView: room ${state.reason} code=${state.errorCode}',
              );
              if (state.reason == ZegoRoomStateChangedReason.Logined &&
                  state.errorCode != 0 &&
                  context.mounted) {
                AppToast.showError(
                  context,
                  'Could not join call (code ${state.errorCode})',
                  title: 'Call failed',
                );
              }
            },
          ),
          user: ZegoCallUserEvents(
            onEnter: (user) {
              LoggerUtils.logInfo(
                'ChatVoiceCallView: user joined — ${user.id}',
              );
            },
          ),
          onCallEnd: (event, defaultAction) async {
            await controller.onCallEnded();
            defaultAction.call();
          },
        ),
      );
    });
  }

  String _zegoErrorMessage(ZegoUIKitError error) {
    if (error.message.isNotEmpty) return error.message;
    return 'Could not connect (code ${error.code}). '
        'Check Zego Call Kit project ${ZegoConfig.callAppId} '
        'and bundle ID com.qobo1live.live.';
  }
}
