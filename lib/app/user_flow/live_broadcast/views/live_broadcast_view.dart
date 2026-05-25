import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:qobo_one_live/constants/zego_config.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';

import '../controllers/live_broadcast_controller.dart';
import '../widgets/gifts_bottom_sheet.dart';
import '../widgets/room_options_sheet.dart';

class LiveBroadcastView extends GetView<LiveBroadcastController> {
  const LiveBroadcastView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildMainVideoBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopHeader(),
                const Spacer(),
                // ZEGOCLOUD Prebuilt UIKit automatically handles the interactive audio seats/grids
                // in the viewport background. Hence, we do not double-render our simulated seat layout.
                _buildChatList(),
                _buildBottomControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainVideoBackground() {
    final userSession = Get.find<UserSessionController>();
    final rawUserId = userSession.userId.isNotEmpty
        ? userSession.userId
        : 'user_${userSession.hashCode}';
    // ZEGOCLOUD limits userID to 32 characters/bytes. Remove hyphens and truncate if needed.
    var currentUserId = rawUserId.replaceAll('-', '');
    if (currentUserId.length > 32) {
      currentUserId = currentUserId.substring(0, 32);
    }
    final currentUserName = userSession.displayName;

    return Obx(() {
      final config = controller.isHost.value
          ? ZegoUIKitPrebuiltLiveStreamingConfig.host(
              plugins: [ZegoUIKitSignalingPlugin()],
            )
          : ZegoUIKitPrebuiltLiveStreamingConfig.audience(
              plugins: [ZegoUIKitSignalingPlugin()],
            );

      // Customize Zego controls so they do not conflict with our custom styled overlays
      config.bottomMenuBar = ZegoLiveStreamingBottomMenuBarConfig(
        hostButtons: [],
        audienceButtons: [],
      );
      config.inRoomMessage = ZegoLiveStreamingInRoomMessageConfig(
        visible: false,
      );

      // Configure for Audio rooms (turn off camera, show avatars and soundwaves)
      if (controller.roomType.value == 'AUDIO') {
        config.turnOnCameraWhenJoining = false;
        config.audioVideoView.showAvatarInAudioMode = true;
        config.audioVideoView.showSoundWavesInAudioMode = true;
      }

      return Positioned.fill(
        child: ZegoUIKitPrebuiltLiveStreaming(
          appID: ZegoConfig.appId,
          appSign: ZegoConfig.appSign,
          userID: currentUserId,
          userName: currentUserName,
          liveID: controller.roomId.value,
          config: config,
          events: ZegoUIKitPrebuiltLiveStreamingEvents(
            onEnded: (event, defaultAction) {
              controller.leaveRoom();
              defaultAction.call();
            },
          ),
        ),
      );
    });
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundImage: const AssetImage(kImgTemp2),
                ),
                Spacing.h8,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SemiBoldText(
                      text: 'Star Host',
                      fontSize: TextStyles.k12FontSize,
                      color: kColorWhite,
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: Colors.pink,
                          size: 10,
                        ),
                        Spacing.h4,
                        const AppText(
                          text: '1.2k',
                          fontSize: 9,
                          color: kColorWhite,
                        ),
                      ],
                    ),
                  ],
                ),
                Spacing.h8,
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kColorPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.add, color: kColorWhite, size: 12),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _topIconButton(Icons.person_add_alt_rounded),
          Spacing.h8,
          _topIconButton(Icons.close_rounded, onTap: controller.leaveRoom),
        ],
      ),
    );
  }

  Widget _topIconButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: kColorWhite, size: 18),
      ),
    );
  }

  Widget _buildChatList() {
    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(
        () => ListView.separated(
          reverse: true, // Auto-scroll to bottom behavior
          itemCount: controller.chatMessages.length,
          separatorBuilder: (_, __) => Spacing.v6,
          itemBuilder: (_, index) {
            // Because list is reversed, we access elements from end
            final actualIndex = controller.chatMessages.length - 1 - index;
            final msg = controller.chatMessages[actualIndex];
            final sender = msg['sender'] ?? '';
            final text = msg['message'] ?? '';
            final isSystem = msg['isSystem'] ?? false;
            final isTranslated = msg['isTranslated'] ?? false;
            final translation = msg['translation'] ?? '';

            final displayMessage = isTranslated && translation.isNotEmpty
                ? translation
                : text;

            return Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () {
                  if (!isSystem) {
                    controller.translateMessage(actualIndex);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSystem
                        ? Colors.deepPurpleAccent.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: isSystem
                        ? Border.all(
                            color: Colors.deepPurpleAccent.withValues(
                              alpha: 0.4,
                            ),
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: isSystem ? '' : '$sender: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: sender == 'You'
                                      ? kColorPrimary
                                      : Colors.pinkAccent.shade100,
                                  fontSize: 12,
                                ),
                              ),
                              TextSpan(
                                text: displayMessage,
                                style: TextStyle(
                                  color: isSystem
                                      ? Colors.amberAccent
                                      : kColorWhite,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!isSystem && translation.isNotEmpty) ...[
                        Spacing.h6,
                        Icon(
                          Icons.translate_rounded,
                          size: 12,
                          color: isTranslated ? kColorPrimary : Colors.white38,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: AppTextField(
              controller: controller.chatTextController,
              hintText: 'Say something...',
              fillColor: Colors.black.withValues(alpha: 0.3),
              inputBorderRadius: BorderRadius.circular(20),
              borderColor: Colors
                  .transparent, // Disable border to prevent overlap visuals
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: TextStyles.kRegularPoppins(
                colors: kColorWhite,
                fontSize: 13,
              ),
              hintStyle: TextStyles.kRegularPoppins(
                colors: Colors.white54,
                fontSize: 12,
              ),
              suffix: IconButton(
                icon: const Icon(
                  Icons.send_rounded,
                  color: kColorWhite,
                  size: 18,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: controller.sendMessage,
              ),
            ),
          ),
          Spacing.h12,
          _bottomActionIcon(Icons.mic_off_rounded, onTap: controller.toggleMic),
          Spacing.h8,
          _bottomActionIcon(
            Icons.card_giftcard_rounded,
            color: Colors.pinkAccent,
            onTap: () {
              Get.bottomSheet(
                const GiftsBottomSheet(),
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
              );
            },
          ),
          Spacing.h8,
          _bottomActionIcon(
            Icons.more_vert_rounded,
            onTap: () {
              Get.bottomSheet(
                RoomOptionsSheet(isHost: controller.isHost.value),
                backgroundColor: Colors.transparent,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _bottomActionIcon(IconData icon, {Color? color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color ?? kColorWhite, size: 20),
      ),
    );
  }
}
