import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:qobo_one_live/constants/zego_config.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/zego_live_id_utils.dart';

import '../controllers/live_broadcast_controller.dart';
import '../widgets/gifts_bottom_sheet.dart';
import '../widgets/room_options_sheet.dart';

class LiveBroadcastView extends GetView<LiveBroadcastController> {
  const LiveBroadcastView({super.key});

  static const Color _surface = Color(0xE6121720);
  static const Color _surfaceSoft = Color(0xB3121720);
  static const Color _accent = Color(0xFFFF3F7F);
  static const Color _accentPurple = Color(0xFF8E1B85);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildMainVideoBackground(),
          const Positioned.fill(child: _LiveOverlayScrim()),
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
    final currentUserId = ZegoLiveIdUtils.sanitizeUserId(rawUserId);
    final currentUserName = userSession.displayName.isNotEmpty
        ? userSession.displayName
        : 'Host';

    final signalingPlugins = ZegoConfig.useSignalingPlugin
        ? [ZegoUIKitSignalingPlugin()]
        : null;

    return Obx(() {
      if (!controller.canOpenZego) {
        return Positioned.fill(child: _buildConnectionIssueState());
      }

      final liveId = controller.roomId.value;
      if (liveId.isEmpty) {
        return Positioned.fill(child: _buildConnectionIssueState());
      }

      final config = controller.isHost.value
          ? ZegoUIKitPrebuiltLiveStreamingConfig.host(
              plugins: signalingPlugins,
            )
          : ZegoUIKitPrebuiltLiveStreamingConfig.audience(
              plugins: signalingPlugins,
            );

      // Custom overlay replaces Zego chrome — hide built-in bars.
      config.bottomMenuBar = ZegoLiveStreamingBottomMenuBarConfig(
        hostButtons: [],
        audienceButtons: [],
      );
      config.topMenuBar = ZegoLiveStreamingTopMenuBarConfig(
        showCloseButton: false,
        height: 0,
        hostAvatarBuilder: (_) => const SizedBox.shrink(),
      );
      config.memberButton = ZegoLiveStreamingMemberButtonConfig(
        builder: (_) => const SizedBox.shrink(),
      );
      config.inRoomMessage = ZegoLiveStreamingInRoomMessageConfig(
        visible: false,
      );

      // Preview page has its own "Start Live" button — our overlay covers it.
      config.preview.showPreviewForHost = false;

      final isVideoRoom = controller.isVideoRoom;
      if (isVideoRoom) {
        config.turnOnCameraWhenJoining = controller.isHost.value;
        config.turnOnMicrophoneWhenJoining = controller.isHost.value;
        config.useFrontFacingCamera = true;
      } else {
        config.turnOnCameraWhenJoining = false;
        config.turnOnMicrophoneWhenJoining = controller.isHost.value;
        config.audioVideoView.showAvatarInAudioMode = true;
        config.audioVideoView.showSoundWavesInAudioMode = true;
      }

      return Positioned.fill(
        key: ValueKey('zego_$liveId'),
        child: ZegoUIKitPrebuiltLiveStreaming(
          appID: ZegoConfig.liveAppId,
          appSign: ZegoConfig.liveAppSign,
          userID: currentUserId,
          userName: currentUserName,
          liveID: liveId,
          config: config,
          events: ZegoUIKitPrebuiltLiveStreamingEvents(
            room: ZegoLiveStreamingRoomEvents(
              onStateChanged: (state) {
                if (state.reason == ZegoRoomStateChangedReason.Logined &&
                    state.errorCode == 0) {
                  controller.clearConnectionIssue();
                  controller.onZegoRoomLogined();
                }
              },
              onLoginFailed: (event, defaultAction) {
                // Avoid defaultAction dialog — it crashes if Obx rebuilds first.
                controller.handleZegoLoginFailed(event.errorCode);
              },
            ),
            onEnded: (event, defaultAction) {
              controller.leaveRoom();
              defaultAction.call();
            },
          ),
        ),
      );
    });
  }

  Widget _buildConnectionIssueState() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kColorWhite.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_tethering_error_rounded,
                color: _accent,
                size: 42,
              ),
              Spacing.v12,
              const SemiBoldText(
                text: 'Unable to join live',
                fontSize: TextStyles.k18FontSize,
                color: kColorWhite,
                align: TextAlign.center,
              ),
              Spacing.v8,
              Obx(
                () => AppText(
                  text: controller.connectionIssue.value,
                  fontSize: TextStyles.k12FontSize,
                  color: kColorWhite.withValues(alpha: 0.72),
                  align: TextAlign.center,
                ),
              ),
              Spacing.v16,
              SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton(
                  onPressed: controller.leaveRoom,
                  style: TextButton.styleFrom(
                    backgroundColor: _accentPurple,
                    foregroundColor: kColorWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const SemiBoldText(
                    text: 'Back',
                    fontSize: TextStyles.k14FontSize,
                    color: kColorWhite,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 390;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _hostSummaryCard(compact: isCompact)),
              SizedBox(width: isCompact ? 6 : 10),
              _topActions(compact: isCompact),
            ],
          );
        },
      ),
    );
  }

  Widget _hostSummaryCard({bool compact = false}) {
    return Obx(() {
      final subtitle = compact
          ? controller.likesLabel.value
          : '${controller.likesLabel.value}  •  ${controller.roomType.value}';

      return ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 20 : 24),
        child: Container(
          constraints: BoxConstraints(maxWidth: compact ? 170 : 238),
          padding: EdgeInsets.all(compact ? 6 : 8),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(compact ? 20 : 24),
            border: Border.all(color: kColorWhite.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  AppUserAvatar(
                    name: controller.hostName.value,
                    imageUrl: controller.hostAvatarUrl.value,
                    size: compact ? 38 : 48,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 1,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: const Color(0xFF35F27A),
                        shape: BoxShape.circle,
                        border: Border.all(color: _surface, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: compact ? 7 : 10),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemiBoldText(
                      text: controller.hostName.value,
                      fontSize: compact
                          ? TextStyles.k14FontSize
                          : TextStyles.k16FontSize,
                      color: kColorWhite,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacing.v2,
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite, color: _accent, size: 14),
                        Spacing.h4,
                        Flexible(
                          child: AppText(
                            text: subtitle,
                            fontSize: compact ? 9 : TextStyles.k10FontSize,
                            color: kColorWhite.withValues(alpha: 0.72),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!compact && !controller.isHost.value) ...[
                Spacing.h8,
                _followButton(),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _followButton() {
    return Obx(() {
      final following = controller.isFollowingHost.value;
      return GestureDetector(
        onTap: controller.toggleFollowHost,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: following
                ? null
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE12BC5), _accentPurple],
                  ),
            color: following ? Colors.white12 : null,
            border: following
                ? Border.all(color: kColorWhite.withValues(alpha: 0.2))
                : null,
          ),
          child: Icon(
            following ? Icons.check_rounded : Icons.add_rounded,
            color: kColorWhite,
            size: 22,
          ),
        ),
      );
    });
  }

  Widget _topActions({bool compact = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _viewerCountPill(compact: compact),
        SizedBox(width: compact ? 5 : 8),
        _topIconButton(
          Icons.ios_share_rounded,
          compact: compact,
          onTap: controller.shareRoom,
        ),
        SizedBox(width: compact ? 5 : 8),
        _topIconButton(
          Icons.close_rounded,
          compact: compact,
          onTap: controller.leaveRoom,
        ),
      ],
    );
  }

  Widget _viewerCountPill({bool compact = false}) {
    return Obx(
      () => GestureDetector(
        onTap: controller.openViewersSheet,
        child: Container(
          height: compact ? 36 : 42,
          padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 12),
          decoration: BoxDecoration(
            color: const Color(0xCC1A2233),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: kColorWhite.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_rounded,
                color: kColorWhite,
                size: compact ? 17 : 20,
              ),
              SizedBox(width: compact ? 3 : 5),
              SemiBoldText(
                text: controller.viewerCount.value.toString(),
                fontSize:
                    compact ? TextStyles.k12FontSize : TextStyles.k14FontSize,
                color: kColorWhite,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topIconButton(
    IconData icon, {
    bool compact = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: compact ? 36 : 42,
        height: compact ? 36 : 42,
        decoration: BoxDecoration(
          color: _surface,
          shape: BoxShape.circle,
          border: Border.all(color: kColorWhite.withValues(alpha: 0.08)),
        ),
        child: Icon(icon, color: kColorWhite, size: compact ? 19 : 22),
      ),
    );
  }

  Widget _buildChatList() {
    return SizedBox(
      height: 170,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Obx(
          () => controller.chatMessages.isEmpty
              ? Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _surfaceSoft,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: AppText(
                      text: controller.isZegoConnected.value
                          ? 'Say hi to everyone...'
                          : 'Connecting to live room...',
                      fontSize: TextStyles.k12FontSize,
                      color: kColorWhite.withValues(alpha: 0.72),
                    ),
                  ),
                )
              : ListView.separated(
                  reverse: true, // Auto-scroll to bottom behavior
                  padding: const EdgeInsets.only(top: 12),
                  itemCount: controller.chatMessages.length,
                  separatorBuilder: (_, __) => Spacing.v6,
                  itemBuilder: (_, index) {
                    // Because list is reversed, we access elements from end
                    final actualIndex =
                        controller.chatMessages.length - 1 - index;
                    final msg = controller.chatMessages[actualIndex];
                    final sender = msg['sender'] ?? '';
                    final text = msg['message'] ?? '';
                    final isSystem = msg['isSystem'] ?? false;
                    final isTranslated = msg['isTranslated'] ?? false;
                    final translation = msg['translation'] ?? '';

                    final displayMessage =
                        isTranslated && translation.isNotEmpty
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
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSystem
                                ? const Color(0xCC4E2E90)
                                : _surfaceSoft,
                            borderRadius: BorderRadius.circular(18),
                            border: isSystem
                                ? Border.all(
                                    color: const Color(0xFF7D5BFF),
                                    width: 1,
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
                                              ? const Color(0xFFFF8AC0)
                                              : const Color(0xFFFF79B4),
                                          fontSize: 13,
                                        ),
                                      ),
                                      TextSpan(
                                        text: displayMessage,
                                        style: TextStyle(
                                          color: isSystem
                                              ? Colors.amberAccent
                                              : kColorWhite,
                                          fontSize: 13,
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
                                  color: isTranslated
                                      ? kColorPrimary
                                      : Colors.white38,
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
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: controller.chatTextController,
                  hintText: 'Say something...',
                  fillColor: _surface,
                  inputBorderRadius: BorderRadius.circular(24),
                  borderColor: kColorWhite.withValues(alpha: 0.06),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  textStyle: TextStyles.kRegularPoppins(
                    colors: kColorWhite,
                    fontSize: 14,
                  ),
                  hintStyle: TextStyles.kRegularPoppins(
                    colors: Colors.white54,
                    fontSize: 14,
                  ),
                  suffix: _sendButton(),
                ),
              ),
              Spacing.h10,
              Obx(
                () => _bottomActionIcon(
                  controller.isMicMuted.value
                      ? Icons.mic_off_rounded
                      : Icons.mic_rounded,
                  active: !controller.isMicMuted.value,
                  onTap: controller.toggleMic,
                ),
              ),
              if (controller.isHost.value && controller.isVideoRoom) ...[
                Spacing.h8,
                Obx(
                  () => _bottomActionIcon(
                    controller.isCameraOff.value
                        ? Icons.videocam_off_rounded
                        : Icons.videocam_rounded,
                    active: !controller.isCameraOff.value,
                    onTap: controller.toggleCamera,
                  ),
                ),
              ],
              Spacing.h8,
              _bottomActionIcon(
                Icons.card_giftcard_rounded,
                color: _accent,
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
                Icons.more_horiz_rounded,
                onTap: () {
                  Get.bottomSheet(
                    RoomOptionsSheet(isHost: controller.isHost.value),
                    backgroundColor: Colors.transparent,
                  );
                },
              ),
            ],
          ),
          Spacing.v10,
          Align(alignment: Alignment.centerLeft, child: _chatShortcut()),
        ],
      ),
    );
  }

  Widget _sendButton() {
    return IconButton(
      icon: const Icon(Icons.send_rounded, color: kColorWhite, size: 22),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      onPressed: controller.sendMessage,
    );
  }

  Widget _chatShortcut() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xCC1D2740),
        shape: BoxShape.circle,
        border: Border.all(color: kColorWhite.withValues(alpha: 0.08)),
      ),
      child: const Icon(Icons.chat_bubble_outline_rounded, color: kColorWhite),
    );
  }

  Widget _bottomActionIcon(
    IconData icon, {
    Color? color,
    bool active = true,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: active ? _surface : const Color(0xCC351D2B),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.06)),
        ),
        child: Icon(icon, color: color ?? kColorWhite, size: 24),
      ),
    );
  }
}

class _LiveOverlayScrim extends StatelessWidget {
  const _LiveOverlayScrim();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.42),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withValues(alpha: 0.58),
            ],
            stops: const [0, 0.22, 0.56, 1],
          ),
        ),
      ),
    );
  }
}
