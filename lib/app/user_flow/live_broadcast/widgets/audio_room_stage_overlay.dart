import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/icon_constants.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/app_widgets/session_earnings_badge.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';
import 'package:zego_uikit/zego_uikit.dart';

import 'package:qobo_one_live/utils/ui_utils/vip_entrance_overlay.dart';
import 'package:qobo_one_live/utils/zego_live_id_utils.dart';
import '../controllers/live_broadcast_controller.dart';
import '../models/audio_room_models.dart';
import '../utils/audio_room_seat_layout.dart';
import 'in_room_pk_stage_overlay.dart';
import 'room_options_sheet.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/controllers/pk_v1_controller.dart';

/// Opens floor-audience user profile (Message / Gift / optional Kick).
void openFloorAudienceProfileSheet(FloorAudienceUser user) {
  if (user.userId.trim().isEmpty) return;
  Get.bottomSheet(
    FloorAudienceProfileSheet(user: user),
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    isScrollControlled: true,
  );
}

class AudioRoomStageOverlay extends GetView<LiveBroadcastController> {
  const AudioRoomStageOverlay({super.key});

  static const _ink = Color(0xFFFFFFFF);
  static const _muted = Color(0xCCFFFFFF);
  static const _roomTop = Color(0xFF4A073F);
  static const _roomMid = Color(0xFF30105F);
  static const _roomBottom = Color(0xFF07103F);
  static const _seatGold = Color(0xFFFFA10A);
  static const _micStart = Color(0xFF2FE56E);
  static const _micEnd = Color(0xFF12B845);
  static const _deepPurple = Color(0xFF3B0647);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bgUrl = controller.roomBackgroundUrl.value;
      // Prime Zego ScreenUtil before any seat video tile mounts — avoids the
      // brief LateInitializationError flash on brand-new video rooms.
      if (controller.isVideoRoom && MediaQuery.maybeOf(context) != null) {
        try {
          ZegoScreenUtil().screenWidth;
        } catch (_) {
          try {
            ZegoScreenUtil.init(context);
          } catch (_) {}
        }
      }
      return Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_roomTop, _roomMid, _roomBottom],
                stops: [0, 0.46, 1],
              ),
            ),
          ),
          // Video rooms only: deepen the stage behind rectangular tiles.
          if (controller.isVideoRoom)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                ),
              ),
            ),
          if (bgUrl != null && bgUrl.isNotEmpty)
            Positioned.fill(
              child: Image.network(
                bgUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          if (bgUrl != null && bgUrl.isNotEmpty)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.42),
                      Colors.black.withValues(alpha: 0.55),
                      Colors.black.withValues(alpha: 0.72),
                    ],
                  ),
                ),
              ),
            ),
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 390;
                final isVideo = controller.isVideoRoom;
                // Keep audio padding identical to the previous working UI.
                final side = isVideo
                    ? (compact ? 8.0 : 10.0)
                    : (compact ? 10.0 : 12.0);
                final top = isVideo
                    ? (compact ? 8.0 : 10.0)
                    : (compact ? 12.0 : 14.0);
                final bottomPad = isVideo
                    ? (compact ? 236.0 : 252.0)
                    : (compact ? 264.0 : 280.0);
                final gridGap = isVideo
                    ? (compact ? 8.0 : 10.0)
                    : (compact ? 14.0 : 16.0);
                final headerH = compact ? 58.0 : 64.0;

                // Video: size the seat grid against the middle stage so 4-seat
                // rooms stay ~70% and denser rooms (6–8) get a larger fill.
                final middleH =
                    (constraints.maxHeight -
                            top -
                            bottomPad -
                            headerH -
                            gridGap)
                        .clamp(160.0, constraints.maxHeight);
                final seatCount = controller.audioRoomSeats.length;
                final fillRatio =
                    AudioRoomSeatLayoutMetrics.videoStageFillRatio(seatCount);
                final videoGridH = middleH * fillRatio;

                return Stack(
                  children: [
                    if (isVideo)
                      Positioned(
                        left: side,
                        right: side,
                        top: top,
                        bottom: bottomPad,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _RoomHeader(compact: compact),
                            SizedBox(height: gridGap),
                            Expanded(
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: SizedBox(
                                  height: videoGridH,
                                  width: double.infinity,
                                  child: Obx(() {
                                    if (controller.isInRoomPkActive &&
                                        Get.isRegistered<PkV1Controller>()) {
                                      return InRoomPkStageOverlay(
                                        controller: Get.find<PkV1Controller>(),
                                        compact: compact,
                                        maxHeight: videoGridH,
                                      );
                                    }
                                    return _MemberGrid(
                                      compact: compact,
                                      maxHeight: videoGridH,
                                    );
                                  }),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              side,
                              top,
                              side,
                              // Keep the last seat row reachable above the chat
                              // feed + input + control dock.
                              bottomPad,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate.fixed([
                                _RoomHeader(compact: compact),
                                SizedBox(height: gridGap),
                                Obx(() {
                                  if (controller.isInRoomPkActive &&
                                      Get.isRegistered<PkV1Controller>()) {
                                    return SizedBox(
                                      height: middleH.clamp(220.0, 360.0),
                                      child: InRoomPkStageOverlay(
                                        controller: Get.find<PkV1Controller>(),
                                        compact: compact,
                                        maxHeight: middleH.clamp(220.0, 360.0),
                                      ),
                                    );
                                  }
                                  return _MemberGrid(compact: compact);
                                }),
                              ]),
                            ),
                          ),
                        ],
                      ),
                    Positioned(
                      left: compact ? 10 : 16,
                      right: compact ? 10 : 16,
                      bottom: 8,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Room chat feed + input, mirroring the live streaming
                          // chat so everyone in the audio room can talk directly.
                          _AudioRoomChatFeed(compact: compact),
                          SizedBox(height: compact ? 6 : 8),
                          _AudioRoomChatInput(compact: compact),
                          SizedBox(height: compact ? 6 : 8),
                          _AudioRoomBottomControls(compact: compact),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      );
    });
  }
}

class _AudioRoomBottomControls extends GetView<LiveBroadcastController> {
  const _AudioRoomBottomControls({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1D222B).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _MicControl(compact: compact),
            // Video rooms only: camera on/off + flip.
            if (controller.isVideoRoom) ...[
              _CameraControl(compact: compact),
              _ControlButton(
                icon: Icons.cameraswitch_rounded,
                label: 'Flip',
                compact: compact,
                onTap: controller.flipGroupCallCamera,
              ),
            ],
            _SpeakerControl(compact: compact),
            // Hide Gift for hosts during PK — only viewers support a side.
            Obx(() {
              if (controller.isInRoomPkActive && controller.isHost.value) {
                return const SizedBox.shrink();
              }
              return _GiftControlButton(
                compact: compact,
                coins: controller.coinsBalance.value,
                onTap: controller.openGiftsSheet,
              );
            }),
            // Video dock is crowded (Cam/Flip) — tuck these into More.
            // Audio keeps Background / Share / PK Battle on the dock.
            if (controller.isVideoRoom)
              _ControlButton(
                icon: Icons.more_horiz_rounded,
                label: 'More',
                compact: compact,
                accentGradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF8E8E9A), Color(0xFF4A4A58)],
                ),
                onTap: () {
                  Get.bottomSheet(
                    RoomOptionsSheet(
                      isHost: controller.isHost.value,
                      isVideoRoom: true,
                    ),
                    backgroundColor: Colors.transparent,
                  );
                },
              )
            else ...[
              _ControlButton(
                icon: Icons.image_rounded,
                label: 'Background',
                compact: compact,
                accentGradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4FC3F7), Color(0xFF2979FF)],
                ),
                onTap: controller.openRoomBackgroundSheet,
              ),
              _ControlButton(
                icon: Icons.ios_share_rounded,
                label: 'Share',
                compact: compact,
                accentGradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF9B7BFF), Color(0xFF6C4DFF)],
                ),
                onTap: controller.shareRoom,
              ),
              // Hide start-PK while a battle is already converting this room.
              Obx(() {
                if (controller.isInRoomPkActive) {
                  return const SizedBox.shrink();
                }
                return _ControlButton(
                  icon: Icons.flash_on_rounded,
                  label: 'PK Battle',
                  compact: compact,
                  accentGradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                  ),
                  onTap: controller.openPkV1Arena,
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

/// Scrolling room chat feed shown above the control dock (live-stream style).
class _AudioRoomChatFeed extends GetView<LiveBroadcastController> {
  const _AudioRoomChatFeed({required this.compact});

  final bool compact;

  static const _bubbleColor = Color(0xB31A1030);
  static const _giftBubbleColor = Color(0xCC4E2E90);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 128 : 146,
      child: Obx(() {
        if (controller.chatMessages.isEmpty) {
          return Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _bubbleColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: AppText(
                text: controller.isZegoConnected.value
                    ? 'Say hi to everyone...'
                    : 'Connecting to room chat...',
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite.withValues(alpha: 0.72),
              ),
            ),
          );
        }

        return ListView.separated(
          reverse: true, // Newest message pinned at the bottom.
          padding: const EdgeInsets.only(top: 10),
          itemCount: controller.chatMessages.length,
          separatorBuilder: (_, __) => Spacing.v6,
          itemBuilder: (_, index) {
            // List is reversed, so map back to the original order.
            final actualIndex = controller.chatMessages.length - 1 - index;
            final msg = controller.chatMessages[actualIndex];
            final sender = msg['sender']?.toString() ?? '';
            final text = msg['message']?.toString() ?? '';
            final isSystem = msg['isSystem'] == true;
            final isTranslated = msg['isTranslated'] == true;
            final translation = msg['translation']?.toString() ?? '';
            final displayMessage = isTranslated && translation.isNotEmpty
                ? translation
                : text;

            return Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: isSystem
                    ? null
                    : () => controller.translateMessage(actualIndex),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSystem ? _giftBubbleColor : _bubbleColor,
                    borderRadius: BorderRadius.circular(18),
                    border: isSystem
                        ? Border.all(color: const Color(0xFF7D5BFF))
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
                          color: isTranslated ? kColorPrimary : Colors.white38,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

/// Chat input bar so every room member can send messages directly.
class _AudioRoomChatInput extends GetView<LiveBroadcastController> {
  const _AudioRoomChatInput({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppTextField(
            controller: controller.chatTextController,
            hintText: 'Say something...',
            fillColor: const Color(0xE61A1030),
            inputBorderRadius: BorderRadius.circular(24),
            borderColor: kColorWhite.withValues(alpha: 0.08),
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: compact ? 10 : 12,
            ),
            textStyle: TextStyles.kRegularPoppins(
              colors: kColorWhite,
              fontSize: 14,
            ),
            hintStyle: TextStyles.kRegularPoppins(
              colors: kColorWhite.withValues(alpha: 0.5),
              fontSize: 14,
            ),
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => controller.sendMessage(),
          ),
        ),
        Spacing.h8,
        InkWell(
          onTap: controller.sendMessage,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: compact ? 42 : 46,
            height: compact ? 42 : 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [kColorProfileFeatureBlue, kColorPrimary],
              ),
              border: Border.all(color: kColorWhite.withValues(alpha: 0.12)),
            ),
            child: const Icon(Icons.send_rounded, color: kColorWhite, size: 20),
          ),
        ),
      ],
    );
  }
}

class _MicControl extends StatelessWidget {
  const _MicControl({required this.compact});

  final bool compact;

  static const _onGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6AD5), Color(0xFF9B1FE8)],
  );
  static const _offGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5C4A72), Color(0xFF2E2740)],
  );

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LiveBroadcastController>();
    return Obx(() {
      if (!controller.isZegoConnected.value) {
        return _ControlButton(
          icon: Icons.mic_off_rounded,
          label: 'Muted',
          compact: compact,
          accentGradient: _offGradient,
          onTap: null,
        );
      }
      final userId = ZegoUIKit().getLocalUser().id;
      if (userId.isEmpty) {
        return _ControlButton(
          icon: Icons.mic_off_rounded,
          label: 'Muted',
          compact: compact,
          accentGradient: _offGradient,
          onTap: null,
        );
      }
      return ValueListenableBuilder<bool>(
        valueListenable: ZegoUIKit().getMicrophoneStateNotifier(userId),
        builder: (context, isOn, _) {
          return _ControlButton(
            icon: isOn ? Icons.mic_rounded : Icons.mic_off_rounded,
            label: isOn ? 'Mic On' : 'Muted',
            compact: compact,
            accentGradient: isOn ? _onGradient : _offGradient,
            onTap: () => ZegoUIKit().turnMicrophoneOn(!isOn, muteMode: true),
          );
        },
      );
    });
  }
}

/// Local camera toggle for video party rooms (group-call Zego engine).
class _CameraControl extends StatelessWidget {
  const _CameraControl({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LiveBroadcastController>();
    return Obx(() {
      if (!controller.isZegoConnected.value) {
        return _ControlButton(
          icon: Icons.videocam_off_rounded,
          label: 'Cam Off',
          compact: compact,
          active: false,
          onTap: null,
        );
      }
      final userId = ZegoUIKit().getLocalUser().id;
      if (userId.isEmpty) {
        return _ControlButton(
          icon: Icons.videocam_off_rounded,
          label: 'Cam Off',
          compact: compact,
          active: false,
          onTap: null,
        );
      }
      return ValueListenableBuilder<bool>(
        valueListenable: ZegoUIKit().getCameraStateNotifier(userId),
        builder: (context, isOn, _) {
          return _ControlButton(
            icon: isOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
            label: isOn ? 'Cam On' : 'Cam Off',
            compact: compact,
            active: isOn,
            onTap: () => ZegoUIKit().turnCameraOn(!isOn),
          );
        },
      );
    });
  }
}

class _SpeakerControl extends StatelessWidget {
  const _SpeakerControl({required this.compact});

  final bool compact;

  static const _speakerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7B5CFF), Color(0xFF2ED3FF)],
  );
  static const _earpieceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5C4A72), Color(0xFF2E2740)],
  );

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LiveBroadcastController>();
    return Obx(() {
      if (!controller.isZegoConnected.value) {
        return _ControlButton(
          icon: Icons.volume_up_rounded,
          label: 'Speaker',
          compact: compact,
          accentGradient: _speakerGradient,
          onTap: null,
        );
      }
      final userId = ZegoUIKit().getLocalUser().id;
      if (userId.isEmpty) {
        return _ControlButton(
          icon: Icons.volume_up_rounded,
          label: 'Speaker',
          compact: compact,
          accentGradient: _speakerGradient,
          onTap: null,
        );
      }
      return ValueListenableBuilder<ZegoUIKitAudioRoute>(
        valueListenable: ZegoUIKit().getAudioOutputDeviceNotifier(userId),
        builder: (context, route, _) {
          final isSpeaker = route == ZegoUIKitAudioRoute.speaker;
          final isLocked =
              route == ZegoUIKitAudioRoute.headphone ||
              route == ZegoUIKitAudioRoute.bluetooth;
          return _ControlButton(
            icon: isSpeaker ? Icons.volume_up_rounded : Icons.hearing_rounded,
            label: isSpeaker ? 'Speaker' : 'Earpiece',
            compact: compact,
            accentGradient: isSpeaker ? _speakerGradient : _earpieceGradient,
            onTap: isLocked
                ? null
                : () => ZegoUIKit().setAudioOutputToSpeaker(!isSpeaker),
          );
        },
      );
    });
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.compact,
    required this.onTap,
    this.active = false,
    this.accentGradient,
  });

  final IconData icon;
  final String label;
  final bool compact;
  final VoidCallback? onTap;
  final bool active;
  final Gradient? accentGradient;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 40.0 : 46.0;
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: compact ? 1 : 3),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: accentGradient,
                    color: accentGradient != null
                        ? null
                        : active
                        ? kColorWhite
                        : kColorWhite.withValues(alpha: 0.12),
                    border: Border.all(
                      color: kColorWhite.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: compact ? 19 : 22,
                    color: accentGradient != null
                        ? kColorWhite
                        : active
                        ? kColorPrimary
                        : kColorWhite.withValues(alpha: 0.88),
                  ),
                ),
                Spacing.v4,
                AppText(
                  text: label,
                  fontSize: compact ? 8 : 9,
                  color: kColorWhite.withValues(alpha: 0.78),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  align: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GiftControlButton extends StatelessWidget {
  const _GiftControlButton({
    required this.compact,
    required this.coins,
    required this.onTap,
  });

  final bool compact;
  final num coins;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = coins >= 1000
        ? '${(coins / 1000).toStringAsFixed(coins >= 10000 ? 0 : 1)}K'
        : coins.toStringAsFixed(0);
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: compact ? 1 : 3),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: compact ? 40 : 46,
                      height: compact ? 40 : 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFF7AB8),
                            Color(0xFFFF3EA5),
                            Color(0xFFE12BC5),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFFF3EA5,
                            ).withValues(alpha: 0.45),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        kGiftIcon,
                        color: kColorWhite,
                        size: compact ? 20 : 22,
                      ),
                    ),
                    if (!compact)
                      Positioned(
                        right: -8,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF262D38),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: kColorWhite.withValues(alpha: 0.10),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.diamond_rounded,
                                color: kColorWalletAmount,
                                size: 10,
                              ),
                              const SizedBox(width: 2),
                              SemiBoldText(
                                text: label,
                                fontSize: TextStyles.k10FontSize,
                                color: kColorWhite,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                Spacing.v4,
                AppText(
                  text: 'Gift',
                  fontSize: compact ? 8 : 9,
                  color: kColorWhite.withValues(alpha: 0.78),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  align: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomHeader extends GetView<LiveBroadcastController> {
  const _RoomHeader({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final title = controller.streamTitle.value.isNotEmpty
          ? controller.streamTitle.value
          : 'Audio Room';
      final roomId = controller.roomId.value.trim();

      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF2A0737).withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        constraints: BoxConstraints(minHeight: compact ? 58 : 64),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Video rooms carry more trailing actions than audio; shrink the
            // header chrome when the bar is tight so it never overflows.
            final dense =
                compact ||
                (controller.isVideoRoom && constraints.maxWidth < 420);
            final earningsMaxWidth = (constraints.maxWidth * 0.17).clamp(
              52.0,
              dense ? 64.0 : 72.0,
            );

            return Row(
              children: [
                _CircleButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: controller.leaveRoom,
                  compact: dense,
                  filled: false,
                ),
                Spacing.h8,
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _openHostProfileSheet,
                  child: AppUserAvatar(
                    name: controller.hostName.value,
                    imageUrl: controller.hostAvatarUrl.value,
                    size: dense ? 38 : 44,
                    border: Border.all(color: kColorWhite, width: 1.5),
                  ),
                ),
                dense ? Spacing.h6 : Spacing.h10,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SemiBoldText(
                        text: title,
                        fontSize: compact
                            ? TextStyles.k14FontSize
                            : TextStyles.k16FontSize,
                        color: AudioRoomStageOverlay._ink,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Spacing.v2,
                      AppText(
                        text: 'Room Id : ${roomId.isEmpty ? '--' : roomId}',
                        fontSize: compact
                            ? TextStyles.k10FontSize
                            : TextStyles.k12FontSize,
                        color: kColorWhite.withValues(alpha: 0.82),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Share + background stay on video rooms only — removed from audio AppBar.
                // Audio hosts can still change background from More → Background.
                if (controller.isVideoRoom) ...[
                  _CircleButton(
                    icon: Icons.share_rounded,
                    onTap: () => controller.shareRoom(),
                    compact: dense,
                  ),
                  if (controller.canManageAudioRoomMembers) ...[
                    dense ? Spacing.h6 : Spacing.h8,
                    _CircleButton(
                      icon: Icons.wallpaper_rounded,
                      onTap: controller.openRoomBackgroundSheet,
                      compact: dense,
                    ),
                  ],
                ],
                // Floor audience moved here from the bottom strip: person + count.
                dense ? Spacing.h6 : Spacing.h8,
                _FloorAudienceBadge(compact: dense),
                // Host session earnings only. Audience can see the pill, not the dialog.
                dense ? Spacing.h6 : Spacing.h8,
                SessionEarningsBadge(
                  key: controller.sessionEarningsBadgeKey,
                  tracker: controller.sessionEarnings,
                  compact: dense,
                  maxWidth: earningsMaxWidth,
                  icon: Icons.monetization_on_rounded,
                  iconColor: const Color(0xFFFFA10A),
                  onTap: controller.isHost.value
                      ? controller.openSessionEarningsDialog
                      : null,
                ),
                if (controller.isHost.value) ...[
                  dense ? Spacing.h6 : Spacing.h8,
                  _CircleButton(
                    icon: Icons.power_settings_new_rounded,
                    onTap: controller.confirmEndRoom,
                    compact: dense,
                    iconColor: const Color(0xFFFF3B5C),
                  ),
                ],
              ],
            );
          },
        ),
      );
    });
  }

  /// AppBar host avatar → same ornate seat profile sheet used for mic seats.
  void _openHostProfileSheet() {
    final hostSeat = _resolveHostSeatForProfile();
    if (hostSeat == null) return;

    Get.bottomSheet(
      _AudioSeatActionsSheet(
        seat: hostSeat,
        // Profile view only (Message / Gift). Avoid host manage actions
        // like Kick/Mute against the room host from the header entry.
        isHostView: false,
      ),
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      isScrollControlled: true,
    );
  }

  AudioRoomSeatModel? _resolveHostSeatForProfile() {
    // Prefer the live seat model so diamonds / badges / frame match the grid.
    for (final seat in controller.audioRoomSeats) {
      if (seat.occupied && seat.isHost) return seat;
    }
    for (final seat in controller.audioRoomSeats) {
      if (seat.occupied && seat.seatNo == 1) return seat;
    }

    final name = controller.hostName.value.trim();
    final userId = controller.receiverId.value.trim();
    if (name.isEmpty && userId.isEmpty) return null;

    return AudioRoomSeatModel(
      seatNo: 1,
      userId: userId,
      name: name.isEmpty ? 'Host' : name,
      avatarUrl: controller.hostAvatarUrl.value,
      avatarFrameUrl: controller.hostAvatarFrameUrl.value,
      role: 'host',
    );
  }
}

/// Responsive seat-cell metrics so the audio grid fits any phone width
/// without fixed-height overflows (e.g. "BOTTOM OVERFLOWED BY 0.9px").
typedef _SeatLayoutMetrics = AudioRoomSeatLayoutMetrics;

class _MemberGrid extends StatefulWidget {
  const _MemberGrid({required this.compact, this.maxHeight});

  final bool compact;

  /// Video only: target height so tiles fill ~70%+ of the middle stage.
  final double? maxHeight;

  @override
  State<_MemberGrid> createState() => _MemberGridState();
}

class _MemberGridState extends State<_MemberGrid> {
  final LiveBroadcastController controller =
      Get.find<LiveBroadcastController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final seats = controller.audioRoomSeats.toList();

      return LayoutBuilder(
        builder: (context, constraints) {
          final isVideo = controller.isVideoRoom;

          // Audio: restore fixed 3-column circular seats (previous working UI).
          // Video: equal rectangular tiles sized from seat count + stage height.
          final metrics = isVideo
              ? _SeatLayoutMetrics.videoFromWidth(
                  constraints.maxWidth,
                  compact: widget.compact,
                  seatCount: seats.length,
                  maxHeight:
                      widget.maxHeight ??
                      (constraints.maxHeight.isFinite
                          ? constraints.maxHeight
                          : null),
                )
              : _SeatLayoutMetrics.fromWidth(
                  constraints.maxWidth,
                  compact: widget.compact,
                );

          return GridView.builder(
            shrinkWrap: !isVideo,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: seats.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isVideo
                  ? metrics.columns
                  : AudioRoomSeatLayoutMetrics.crossAxisCount,
              mainAxisExtent: metrics.mainAxisExtent,
              mainAxisSpacing: metrics.mainAxisSpacing,
              crossAxisSpacing: metrics.crossAxisSpacing,
            ),
            itemBuilder: (context, index) {
              final seat = seats[index];
              if (isVideo) {
                if (seat.isLocked) {
                  return _VideoLockedSeatTile(seatNo: seat.seatNo);
                }
                if (!seat.occupied) {
                  return _VideoEmptySeatTile(
                    seatNo: seat.seatNo,
                    metrics: metrics,
                  );
                }
                return _VideoOccupiedSeatTile(seat: seat);
              }

              if (seat.isLocked) {
                return _LockedSeat(seatNo: seat.seatNo, metrics: metrics);
              }
              if (!seat.occupied) {
                return _GridEmptySeat(seatNo: seat.seatNo, metrics: metrics);
              }
              return _MemberSeat(seat: seat, metrics: metrics);
            },
          );
        },
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Video-room seat tiles — equal rounded rectangles (conference-style grid).
// Audio rooms keep the circular premium frames below.
// ---------------------------------------------------------------------------

/// Shared chrome for every video seat: rounded rect, soft frame border.
class _VideoSeatShell extends StatelessWidget {
  const _VideoSeatShell({
    required this.child,
    required this.isHost,
    this.onTap,
  });

  final Widget child;
  final bool isHost;
  final VoidCallback? onTap;

  static const _radius = 18.0;

  @override
  Widget build(BuildContext context) {
    final borderColor = isHost
        ? const Color(0xFFFFC857).withValues(alpha: 0.85)
        : kColorWhite.withValues(alpha: 0.14);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: borderColor, width: isHost ? 1.6 : 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
              if (isHost)
                BoxShadow(
                  color: const Color(0xFFFFC857).withValues(alpha: 0.18),
                  blurRadius: 16,
                  spreadRadius: 0.5,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_radius - 0.5),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Occupied video seat: full-bleed camera + mic badge + bottom identity bar.
class _VideoOccupiedSeatTile extends GetView<LiveBroadcastController> {
  const _VideoOccupiedSeatTile({required this.seat});

  final AudioRoomSeatModel seat;

  @override
  Widget build(BuildContext context) {
    final rawRole = seat.role.trim();
    final roleLabel = seat.isHost
        ? 'Host'
        : (seat.isCoinsSeller
              ? 'Seller'
              : (rawRole.isEmpty
                    ? 'Speaker'
                    : '${rawRole[0].toUpperCase()}${rawRole.substring(1).toLowerCase()}'));

    return KeyedSubtree(
      key: controller.seatCoinFlyKeyFor(seat.userId),
      child: _VideoSeatShell(
        isHost: seat.isHost,
        onTap: () => _openSeatActions(context),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tiny = constraints.maxHeight < 120;
            final pad = tiny ? 5.0 : 8.0;
            return Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                _SeatVideoFill(
                  userId: seat.userId,
                  name: seat.name,
                  imageUrl: seat.avatarUrl,
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: tiny ? 40 : 52,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x00000000),
                          Color(0x99000000),
                          Color(0xCC000000),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: pad,
                  top: pad,
                  child: _VideoMicBadge(muted: seat.isMuted, compact: tiny),
                ),
                Positioned(
                  right: pad,
                  top: pad,
                  child: _VideoSeatIndexChip(
                    seatNo: seat.seatNo,
                    compact: tiny,
                  ),
                ),
                Positioned(
                  left: pad,
                  right: pad,
                  bottom: tiny ? 5 : 8,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SemiBoldText(
                              text: seat.name,
                              fontSize: tiny
                                  ? TextStyles.k10FontSize
                                  : TextStyles.k12FontSize,
                              color: kColorWhite,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (!tiny) const SizedBox(height: 2),
                            Row(
                              children: [
                                Flexible(
                                  child: _VideoRoleChip(
                                    label: roleLabel,
                                    highlighted: seat.isHost,
                                    compact: tiny,
                                  ),
                                ),
                                _SeatSessionCoinInline(
                                  seat: seat,
                                  compact: tiny,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (!tiny &&
                          seat.avatarFrameUrl?.trim().isNotEmpty == true) ...[
                        const SizedBox(width: 6),
                        _VideoMiniFrameThumb(url: seat.avatarFrameUrl!.trim()),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openSeatActions(BuildContext context) {
    if (seat.isHost) return;
    Get.bottomSheet(
      _AudioSeatActionsSheet(
        seat: seat,
        isHostView: controller.canManageAudioRoomMembers,
      ),
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      isScrollControlled: true,
    );
  }
}

/// Empty video seat placeholder — same size as occupied tiles.
class _VideoEmptySeatTile extends GetView<LiveBroadcastController> {
  const _VideoEmptySeatTile({required this.seatNo, required this.metrics});

  final int seatNo;
  final _SeatLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isManager =
          controller.isHost.value || controller.canManageAudioRoomMembers;
      final actionLabel = isManager
          ? 'Invite'
          : (controller.viewerFollowsHost.value ? 'Sit' : 'Request');

      return _VideoSeatShell(
        isHost: false,
        onTap: () => _onEmptySeatTap(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            final tiny = h < 120;
            final avatar =
                (tiny
                        ? metrics.avatarSize.clamp(28.0, 40.0)
                        : metrics.avatarSize.clamp(36.0, 56.0))
                    .toDouble();
            final pad = tiny ? 5.0 : 8.0;
            final plus = tiny ? 22.0 : metrics.addButtonSize;

            return Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1B1528),
                        Color(0xFF12141C),
                        Color(0xFF0B0D14),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _VideoEmptySeatDashPainter(
                        color: kColorWhite.withValues(alpha: 0.10),
                        radius: 16,
                      ),
                    ),
                  ),
                ),
                // Center: avatar only (no Seat/Empty labels — those overlapped
                // the bottom Invite row on dense 8–12 seat grids).
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: tiny ? 18 : 22),
                    child: Container(
                      width: avatar,
                      height: avatar,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kColorWhite.withValues(alpha: 0.06),
                        border: Border.all(
                          color: kColorWhite.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Icon(
                        Icons.person_outline_rounded,
                        color: kColorWhite.withValues(alpha: 0.42),
                        size: avatar * 0.48,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: pad,
                  right: pad,
                  bottom: pad,
                  child: Row(
                    children: [
                      Expanded(
                        child: SemiBoldText(
                          text: actionLabel,
                          fontSize: tiny
                              ? TextStyles.k10FontSize
                              : TextStyles.k12FontSize,
                          color: kColorWhite.withValues(alpha: 0.88),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        width: plus,
                        height: plus,
                        decoration: BoxDecoration(
                          color: kColorWhite.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: kColorWhite.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: kColorWhite,
                          size: plus * 0.58,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: pad,
                  top: pad,
                  child: _VideoSeatIndexChip(seatNo: seatNo, compact: tiny),
                ),
              ],
            );
          },
        ),
      );
    });
  }

  void _onEmptySeatTap() {
    final isManager =
        controller.isHost.value || controller.canManageAudioRoomMembers;
    if (isManager) {
      Get.bottomSheet(
        _EmptySeatActionsSheet(seatNo: seatNo),
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
      );
      return;
    }
    unawaited(controller.requestSeatForSeatNo(seatNo));
  }
}

class _VideoLockedSeatTile extends StatelessWidget {
  const _VideoLockedSeatTile({required this.seatNo});

  final int seatNo;

  @override
  Widget build(BuildContext context) {
    return _VideoSeatShell(
      isHost: false,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFF12141C)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_rounded,
                  color: kColorWhite.withValues(alpha: 0.45),
                  size: 28,
                ),
                const SizedBox(height: 8),
                SemiBoldText(
                  text: 'Locked',
                  fontSize: TextStyles.k12FontSize,
                  color: kColorWhite.withValues(alpha: 0.55),
                ),
              ],
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: _VideoSeatIndexChip(seatNo: seatNo),
          ),
        ],
      ),
    );
  }
}

class _VideoMicBadge extends StatelessWidget {
  const _VideoMicBadge({required this.muted, this.compact = false});

  final bool muted;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 22.0 : 28.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.48),
        shape: BoxShape.circle,
        border: Border.all(color: kColorWhite.withValues(alpha: 0.14)),
      ),
      child: Icon(
        muted ? Icons.mic_off_rounded : Icons.mic_rounded,
        size: compact ? 12 : 15,
        color: muted ? const Color(0xFFFF6B7A) : kColorWhite,
      ),
    );
  }
}

class _VideoSeatIndexChip extends StatelessWidget {
  const _VideoSeatIndexChip({required this.seatNo, this.compact = false});

  final int seatNo;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 7,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.12)),
      ),
      child: AppText(
        text: '#$seatNo',
        fontSize: TextStyles.k10FontSize,
        color: kColorWhite.withValues(alpha: 0.78),
      ),
    );
  }
}

class _VideoRoleChip extends StatelessWidget {
  const _VideoRoleChip({
    required this.label,
    required this.highlighted,
    this.compact = false,
  });

  final String label;
  final bool highlighted;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 7,
        vertical: compact ? 1 : 2,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: highlighted
            ? const LinearGradient(
                colors: [Color(0xFFFFC857), Color(0xFFE8A317)],
              )
            : null,
        color: highlighted ? null : kColorWhite.withValues(alpha: 0.14),
      ),
      child: SemiBoldText(
        text: label,
        fontSize: TextStyles.k10FontSize,
        color: highlighted ? const Color(0xFF2A1A08) : kColorWhite,
      ),
    );
  }
}

/// Tiny avatar-frame preview on the identity bar when the user wears one.
class _VideoMiniFrameThumb extends StatelessWidget {
  const _VideoMiniFrameThumb({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.22)),
        image: DecorationImage(
          image: NetworkImage(ApiImageUtils.normalize(url) ?? url),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

/// Soft dashed outline painted inside empty video seats.
class _VideoEmptySeatDashPainter extends CustomPainter {
  _VideoEmptySeatDashPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(6, 6, size.width - 12, size.height - 12),
      Radius.circular(radius),
    );
    // Approximate a dashed look with a path metric dash.
    final path = Path()..addRRect(rect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + 5;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _VideoEmptySeatDashPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

/// Full-bleed Zego camera for rectangular video seats.
///
/// ZegoAudioVideoView reads [ZegoScreenUtil] late fields. On brand-new rooms
/// the PrebuiltCall may not have initialized ScreenUtil yet, which flashes
/// `LateInitializationError: Field '_data' has not been initialized`.
/// We show the avatar until ScreenUtil + the call engine are ready.
class _SeatVideoFill extends StatefulWidget {
  const _SeatVideoFill({
    required this.userId,
    required this.name,
    required this.imageUrl,
  });

  final String userId;
  final String name;
  final String? imageUrl;

  @override
  State<_SeatVideoFill> createState() => _SeatVideoFillState();
}

class _SeatVideoFillState extends State<_SeatVideoFill> {
  bool _screenUtilReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureScreenUtil();
  }

  void _ensureScreenUtil() {
    if (_screenUtilReady) return;
    if (MediaQuery.maybeOf(context) == null) return;
    try {
      // Probe — throws LateInitializationError when not configured yet.
      final _ = ZegoScreenUtil().screenWidth;
      _screenUtilReady = true;
    } catch (_) {
      try {
        ZegoScreenUtil.init(context);
        _screenUtilReady = true;
      } catch (_) {
        _screenUtilReady = false;
      }
    }
    if (_screenUtilReady && mounted) {
      // Rebuild once ScreenUtil is ready so the camera tile can mount safely.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _ensureScreenUtil();

    final zegoId = ZegoLiveIdUtils.sanitizeUserId(widget.userId.trim());
    if (zegoId.isEmpty) {
      return _videoFallbackAvatar();
    }

    final controller = Get.find<LiveBroadcastController>();
    return Obx(() {
      final _ = controller.zegoMediaUsersTick.value;
      // Wait for group-call login so Zego user/stream state exists.
      if (!controller.isZegoConnected.value || !_screenUtilReady) {
        return _videoFallbackAvatar();
      }

      ZegoUIKitUser? matched;
      try {
        for (final user in ZegoUIKit().getAllUsers()) {
          if (user.id == zegoId ||
              ZegoLiveIdUtils.sanitizeUserId(user.id) == zegoId) {
            matched = user;
            break;
          }
        }
      } catch (_) {
        return _videoFallbackAvatar();
      }
      // A synthetic user (not yet in the room) mounts a black PlatformView.
      if (matched == null) {
        return _videoFallbackAvatar();
      }

      return ZegoAudioVideoView(
        user: matched,
        borderRadius: 0,
        borderColor: Colors.transparent,
        backgroundBuilder: (context, size, user, extraInfo) {
          return _videoFallbackAvatar();
        },
        avatarConfig: ZegoAvatarConfig(
          showInAudioMode: true,
          showSoundWavesInAudioMode: false,
          builder: (context, size, user, extraInfo) {
            return AppUserAvatar(
              name: widget.name,
              imageUrl: widget.imageUrl,
              size: size.shortestSide * 0.42,
            );
          },
        ),
      );
    });
  }

  Widget _videoFallbackAvatar() {
    return ColoredBox(
      color: const Color(0xFF1A1228),
      child: Center(
        child: AppUserAvatar(
          name: widget.name,
          imageUrl: widget.imageUrl,
          size: 72,
        ),
      ),
    );
  }
}

/// Scales seat content down if fonts/accessibility push past the cell height.
Widget _seatCellShell({required Widget child}) {
  return Align(
    alignment: Alignment.topCenter,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.topCenter,
      child: child,
    ),
  );
}

class _MemberSeat extends GetView<LiveBroadcastController> {
  const _MemberSeat({required this.seat, required this.metrics});

  final AudioRoomSeatModel seat;
  final _SeatLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: controller.seatCoinFlyKeyFor(seat.userId),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openSeatActions(context),
        child: _seatCellShell(
          child: SizedBox(
            width: metrics.frameSize + metrics.badgeSize,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: metrics.topInset),
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    _PremiumAvatarFrame(
                      name: seat.name,
                      imageUrl: seat.avatarUrl,
                      frameUrl: seat.avatarFrameUrl,
                      muted: seat.isMuted,
                      isHost: seat.isHost,
                      seatNo: seat.seatNo,
                      frameSize: metrics.frameSize,
                      avatarSize: metrics.avatarSize,
                    ),
                    Positioned(
                      left: -6,
                      top: -6,
                      child: _SeatBadge(
                        number: seat.seatNo,
                        size: metrics.badgeSize,
                      ),
                    ),
                    Positioned(
                      right: -6,
                      bottom: -4,
                      child: _MicBubble(muted: seat.isMuted, small: true),
                    ),
                    if (seat.hasJoinableFollowerPk)
                      Positioned(
                        right: -8,
                        top: -8,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => controller.joinFollowerPkFromSeat(seat),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF3EA5), Color(0xFFFF8A2A)],
                              ),
                              border: Border.all(
                                color: kColorWhite,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFF3EA5,
                                  ).withValues(alpha: 0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.bolt_rounded,
                              color: kColorWhite,
                              size: 17,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: metrics.gapAfterFrame),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (seat.isCoinsSeller) ...[
                        const Icon(
                          Icons.verified_rounded,
                          size: 11,
                          color: Color(0xFFFFC107),
                        ),
                        const SizedBox(width: 2),
                      ],
                      Flexible(
                        child: SemiBoldText(
                          text: seat.name,
                          fontSize: TextStyles.k10FontSize,
                          color: kColorWhite,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          align: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                _SeatSessionCoinCount(seat: seat),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openSeatActions(BuildContext context) {
    if (seat.isHost) return;
    Get.bottomSheet(
      _AudioSeatActionsSheet(
        seat: seat,
        isHostView: controller.canManageAudioRoomMembers,
      ),
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      isScrollControlled: true,
    );
  }
}

class _AudioSeatActionsSheet extends GetView<LiveBroadcastController> {
  const _AudioSeatActionsSheet({required this.seat, required this.isHostView});

  static const _frameRed = Color(0xFF8E1B24);
  static const _goldBright = Color(0xFFFFD56A);
  static const _goldDeep = Color(0xFFC4891A);
  static const _goldChampagne = Color(0xFFF6E7C3);
  static const _ink = Color(0xFF2A1A12);

  final AudioRoomSeatModel seat;
  final bool isHostView;

  @override
  Widget build(BuildContext context) {
    final actions = _buildActions(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.75;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(10, 0, 10, bottomInset + 10),
      child: SizedBox(
        height: maxHeight,
        child: _OrnateMemberProfileCard(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: SizedBox(height: 4),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: _dragHandle(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _profileStage(),
                      Spacing.v8,
                      _roleRibbon(),
                      Spacing.v12,
                      _identityBlock(context),
                      Spacing.v12,
                      _badgeShowcase(),
                      Spacing.v10,
                      _collectionRow(
                        title: 'Room',
                        background: const Color(0xFFF08FA8),
                        child: _roomStatsRow(),
                      ),
                      Spacing.v16,
                      _actionsGrid(actions),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Center avatar with icon-only floating orbs (no truncated labels).
  Widget _profileStage() {
    final pattiLabel = VipEntranceOverlay.formatPattiLabel(seat.pattiStyle);
    final orbs = <_ProfileOrbData>[
      if (seat.isCoinsSeller)
        const _ProfileOrbData(
          tip: 'Coin Seller',
          icon: Icons.storefront_rounded,
          colors: [Color(0xFFFFE082), Color(0xFFFF8F00)],
        ),
      if (seat.isVip)
        const _ProfileOrbData(
          tip: 'VIP Member',
          icon: Icons.workspace_premium_rounded,
          colors: [Color(0xFFFFE0B2), Color(0xFFFF6B35)],
        ),
      if (seat.isAdmin)
        const _ProfileOrbData(
          tip: 'Room Admin',
          icon: Icons.shield_rounded,
          colors: [Color(0xFFB794FF), Color(0xFF6A3DFF)],
        ),
      if (seat.seatNo > 0)
        _ProfileOrbData(
          tip: 'Seat ${seat.seatNo}',
          icon: Icons.event_seat_rounded,
          colors: const [Color(0xFFB2EBF2), Color(0xFF1A9FD4)],
        ),
      if (pattiLabel.isNotEmpty)
        _ProfileOrbData(
          tip: '$pattiLabel Patti',
          icon: Icons.auto_awesome_rounded,
          colors: const [Color(0xFFFFF59D), Color(0xFFD4AF37)],
        ),
      if (seat.isMuted)
        const _ProfileOrbData(
          tip: 'Muted',
          icon: Icons.mic_off_rounded,
          colors: [Color(0xFFFFCDD2), Color(0xFFC62828)],
        ),
    ];

    // Place up to 4 orbs around the frame.
    final topLeft = orbs.isNotEmpty ? orbs[0] : null;
    final topRight = orbs.length > 1 ? orbs[1] : null;
    final bottomLeft = orbs.length > 2 ? orbs[2] : null;
    final bottomRight = orbs.length > 3 ? orbs[3] : null;

    return SizedBox(
      height: 168,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          _PremiumAvatarFrame(
            name: seat.name,
            imageUrl: seat.avatarUrl,
            frameUrl: seat.avatarFrameUrl,
            muted: seat.isMuted,
            isHost: seat.isHost,
            seatNo: seat.seatNo,
            frameSize: 132,
            avatarSize: 74,
          ),
          if (topLeft != null)
            Positioned(left: 8, top: 10, child: _profileOrb(topLeft)),
          if (topRight != null)
            Positioned(right: 8, top: 10, child: _profileOrb(topRight)),
          if (bottomLeft != null)
            Positioned(left: 18, bottom: 8, child: _profileOrb(bottomLeft)),
          if (bottomRight != null)
            Positioned(right: 18, bottom: 8, child: _profileOrb(bottomRight)),
        ],
      ),
    );
  }

  Widget _profileOrb(_ProfileOrbData orb) {
    return Tooltip(
      message: orb.tip,
      triggerMode: TooltipTriggerMode.tap,
      decoration: BoxDecoration(
        color: const Color(0xFF2A1A12),
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: const TextStyle(color: kColorWhite, fontSize: 11),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: orb.colors),
          border: Border.all(color: Colors.white, width: 1.6),
          boxShadow: [
            BoxShadow(
              color: orb.colors.last.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(orb.icon, size: 18, color: kColorWhite),
      ),
    );
  }

  Widget _identityBlock(BuildContext context) {
    return Column(
      children: [
        SemiBoldText(
          text: seat.name,
          fontSize: TextStyles.k18FontSize,
          color: _ink,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          align: TextAlign.center,
        ),
        Spacing.v8,
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _metaPill(
              icon: Icons.info_outline_rounded,
              label: 'User ID',
              accent: const Color(0xFFFF4DC4),
              onTap: () => _showUserIdCard(context),
            ),
            if (seat.seatNo > 0)
              _metaPill(
                icon: Icons.event_seat_rounded,
                label: 'Seat ${seat.seatNo}',
                accent: const Color(0xFF1A9FD4),
              ),
            Obx(() {
              if (!controller.shouldShowSeatSessionCoins(seat)) {
                return const SizedBox.shrink();
              }
              return _metaPill(
                icon: Icons.diamond_rounded,
                label: '${controller.sessionCoinsForSeat(seat)}',
                accent: const Color(0xFF2ED3FF),
              );
            }),
            if (seat.isCoinsSeller)
              _metaPill(
                icon: Icons.storefront_rounded,
                label: 'Seller',
                accent: const Color(0xFFFF8F00),
              ),
            if (seat.isVip)
              _metaPill(
                icon: Icons.workspace_premium_rounded,
                label: 'VIP',
                accent: _goldDeep,
              ),
          ],
        ),
      ],
    );
  }

  Widget _metaPill({
    required IconData icon,
    required String label,
    required Color accent,
    VoidCallback? onTap,
  }) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.55),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          Spacing.h4,
          SemiBoldText(
            text: label,
            fontSize: TextStyles.k10FontSize,
            color: _ink,
          ),
        ],
      ),
    );

    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: child,
      ),
    );
  }

  void _showUserIdCard(BuildContext context) {
    final id = seat.userId.trim();
    if (id.isEmpty) {
      AppToast.showError(context, 'No user ID available');
      return;
    }

    Get.dialog<void>(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 36),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2A1638), Color(0xFF140C22)],
            ),
            border: Border.all(color: _goldBright.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF4DC4).withValues(alpha: 0.18),
                      border: Border.all(
                        color: const Color(0xFFFF4DC4).withValues(alpha: 0.45),
                      ),
                    ),
                    child: const Icon(
                      Icons.badge_rounded,
                      size: 18,
                      color: Color(0xFFFF4DC4),
                    ),
                  ),
                  Spacing.h10,
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SemiBoldText(
                          text: 'User ID',
                          fontSize: TextStyles.k14FontSize,
                          color: kColorWhite,
                        ),
                        AppText(
                          text: 'Tap copy to share this profile',
                          fontSize: TextStyles.k10FontSize,
                          color: Colors.white54,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: Get.back,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white54,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              Spacing.v12,
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: SelectableText(
                  id,
                  style: const TextStyle(
                    color: kColorWhite,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
              Spacing.v12,
              SizedBox(
                width: double.infinity,
                height: 44,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF8F00), Color(0xFFFF4081)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: id));
                        Get.back();
                        AppToast.showSuccess(context, 'ID copied');
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.copy_rounded,
                              color: kColorWhite,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            SemiBoldText(
                              text: 'Copy ID',
                              fontSize: TextStyles.k12FontSize,
                              color: kColorWhite,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierColor: Colors.black.withValues(alpha: 0.55),
    );
  }

  List<_SeatActionData> _buildActions(BuildContext context) {
    if (isHostView) {
      final canClearSeat =
          seat.seatNo > 1 &&
          seat.occupied &&
          seat.role.trim().toLowerCase() != 'host';
      return [
        _SeatActionData(
          icon: seat.isMuted ? Icons.mic_rounded : Icons.mic_off_rounded,
          label: seat.isMuted ? 'Unmute' : 'Mute',
          accent: const Color(0xFF7AD7FF),
          onTap: () =>
              controller.updateAudioSeatMic(seat: seat, mute: !seat.isMuted),
        ),
        if (canClearSeat)
          _SeatActionData(
            icon: Icons.event_seat_rounded,
            label: 'Remove from seat',
            accent: const Color(0xFFFFB347),
            onTap: () => controller.removeUserFromAudioSeat(seat),
          ),
        _SeatActionData(
          icon: Icons.person_remove_rounded,
          label: 'Kick off',
          accent: const Color(0xFFFF6B6B),
          onTap: () => controller.kickAudioRoomUser(seat),
        ),
        _SeatActionData(
          icon: Icons.admin_panel_settings_rounded,
          label: seat.isAdmin ? 'Remove admin' : 'Make admin',
          accent: _goldBright,
          onTap: () => controller.setAudioRoomAdmin(
            seat: seat,
            makeAdmin: !seat.isAdmin,
          ),
        ),
        _SeatActionData(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Message',
          accent: const Color(0xFFFF8FB8),
          onTap: () => _openMessage(context),
        ),
        _SeatActionData(
          icon: kGiftIcon,
          label: 'Gift',
          accent: const Color(0xFFFFB347),
          onTap: _openGift,
        ),
      ];
    }

    return [
      _SeatActionData(
        icon: Icons.chat_bubble_outline_rounded,
        label: 'Message',
        accent: const Color(0xFFFF8FB8),
        onTap: () => _openMessage(context),
      ),
      _SeatActionData(
        icon: kGiftIcon,
        label: 'Send gift',
        accent: const Color(0xFFFFB347),
        onTap: _openGift,
      ),
    ];
  }

  Widget _dragHandle() {
    return Container(
      width: 42,
      height: 4,
      decoration: BoxDecoration(
        color: _frameRed.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }

  Widget _roleRibbon() {
    final isCoinSeller = seat.isCoinsSeller;
    final label = seat.isHost
        ? 'Room Host'
        : seat.isAdmin
        ? 'Room Admin'
        : isCoinSeller
        ? 'Coin Seller'
        : seat.isVip
        ? 'VIP Member'
        : 'Room Member';

    final colors = isCoinSeller && !seat.isHost && !seat.isAdmin
        ? const [Color(0xFFFF8F00), Color(0xFFFF4081), Color(0xFFFF8F00)]
        : const [Color(0xFFB71C1C), Color(0xFF8E1B24), Color(0xFFB71C1C)];

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _goldBright, width: 1.2),
          boxShadow: [
            BoxShadow(
              color:
                  (isCoinSeller && !seat.isHost && !seat.isAdmin
                          ? const Color(0xFFFF8F00)
                          : _frameRed)
                      .withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCoinSeller && !seat.isHost && !seat.isAdmin) ...[
              const Icon(
                Icons.storefront_rounded,
                size: 14,
                color: _goldChampagne,
              ),
              Spacing.h4,
            ],
            SemiBoldText(
              text: label,
              fontSize: TextStyles.k12FontSize,
              color: _goldChampagne,
            ),
          ],
        ),
      ),
    );
  }

  Widget _collectionRow({
    required String title,
    required Color background,
    required Widget child,
    Color? borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            background,
            Color.lerp(background, Colors.black, 0.18) ?? background,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (borderColor ?? kColorWhite).withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: (borderColor ?? Colors.black).withValues(alpha: 0.16),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w700,
                color: kColorWhite.withValues(alpha: 0.95),
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _badgeShowcase() {
    return Obx(() {
      final pattiLabel = VipEntranceOverlay.formatPattiLabel(seat.pattiStyle);
      final medals = <_BadgeMedalData>[
        if (seat.isAdmin)
          const _BadgeMedalData(
            label: 'Admin',
            icon: Icons.shield_rounded,
            colors: [Color(0xFFB794FF), Color(0xFF7B5CFF), Color(0xFF5A2FE0)],
          ),
        if (seat.isCoinsSeller)
          const _BadgeMedalData(
            label: 'Seller',
            icon: Icons.storefront_rounded,
            colors: [Color(0xFFFFE082), Color(0xFFFFC107), Color(0xFFFF8F00)],
          ),
        if (seat.isVip)
          const _BadgeMedalData(
            label: 'VIP',
            icon: Icons.workspace_premium_rounded,
            colors: [Color(0xFFFFE0B2), Color(0xFFFFB347), Color(0xFFFF6B35)],
          ),
        if (pattiLabel.isNotEmpty)
          _BadgeMedalData(
            label: pattiLabel,
            icon: Icons.auto_awesome_rounded,
            colors: const [
              Color(0xFFFFF59D),
              Color(0xFFFFDF00),
              Color(0xFFD4AF37),
            ],
          ),
        if (seat.isMuted)
          const _BadgeMedalData(
            label: 'Muted',
            icon: Icons.mic_off_rounded,
            colors: [Color(0xFFFFCDD2), Color(0xFFFF6B6B), Color(0xFFC62828)],
          )
        else
          const _BadgeMedalData(
            label: 'Live Mic',
            icon: Icons.mic_rounded,
            colors: [Color(0xFFB9F6CA), Color(0xFF2FE56E), Color(0xFF00C853)],
          ),
        if (controller.shouldShowSeatSessionCoins(seat))
          _BadgeMedalData(
            label: 'x${controller.sessionCoinsForSeat(seat)}',
            icon: Icons.diamond_rounded,
            colors: const [
              Color(0xFFB2EBF2),
              Color(0xFF2ED3FF),
              Color(0xFF1A9FD4),
            ],
          ),
      ];

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2A1638).withValues(alpha: 0.92),
              const Color(0xFF140C22).withValues(alpha: 0.95),
              const Color(0xFF1A1030),
            ],
          ),
          border: Border.all(color: _goldBright.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(
              color: _goldDeep.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFE082), Color(0xFFFF8F00)],
                    ),
                    border: Border.all(color: Colors.white, width: 1.2),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    size: 15,
                    color: kColorWhite,
                  ),
                ),
                Spacing.h8,
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SemiBoldText(
                        text: 'Badge Showcase',
                        fontSize: TextStyles.k12FontSize,
                        color: kColorWhite,
                      ),
                      AppText(
                        text: 'Collected honors on this profile',
                        fontSize: TextStyles.k10FontSize,
                        color: Colors.white54,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _goldBright.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _goldBright.withValues(alpha: 0.4),
                    ),
                  ),
                  child: SemiBoldText(
                    text: '${medals.length}',
                    fontSize: TextStyles.k10FontSize,
                    color: _goldChampagne,
                  ),
                ),
              ],
            ),
            Spacing.v12,
            if (medals.isEmpty)
              const AppText(
                text: 'No badges unlocked yet',
                fontSize: TextStyles.k10FontSize,
                color: Colors.white54,
              )
            else
              SizedBox(
                height: 108,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: medals.length,
                  separatorBuilder: (_, __) => Spacing.h10,
                  itemBuilder: (_, index) =>
                      _badgeMedalCard(medals[index], featured: index == 0),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _badgeMedalCard(_BadgeMedalData medal, {bool featured = false}) {
    final accent = medal.colors.length > 1
        ? medal.colors[1]
        : medal.colors.first;
    final size = featured ? 54.0 : 48.0;

    return SizedBox(
      width: featured ? 78 : 70,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ribbon
          Container(
            width: 22,
            height: 10,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accent.withValues(alpha: 0.95),
                  accent.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -2),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    medal.colors.first,
                    accent,
                    medal.colors.last,
                    medal.colors.first,
                  ],
                ),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.55),
                    blurRadius: 16,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.35),
                      accent.withValues(alpha: 0.85),
                      medal.colors.last,
                    ],
                  ),
                ),
                child: Icon(
                  medal.icon,
                  size: featured ? 22 : 20,
                  color: kColorWhite,
                ),
              ),
            ),
          ),
          Spacing.v6,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: SemiBoldText(
              text: medal.label,
              fontSize: TextStyles.k10FontSize,
              color: kColorWhite,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              align: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _roomStatsRow() {
    return Obx(() {
      final sessionCoins = controller.shouldShowSeatSessionCoins(seat)
          ? controller.sessionCoinsForSeat(seat)
          : null;
      return Row(
        children: [
          if (sessionCoins != null) ...[
            _statChip(
              icon: Icons.diamond_rounded,
              label: '$sessionCoins',
              color: const Color(0xFF2ED3FF),
            ),
            Spacing.h8,
          ],
          _statChip(
            icon: Icons.event_seat_rounded,
            label: 'Seat ${seat.seatNo}',
            color: const Color(0xFFFFB347),
          ),
          const Spacer(),
          Icon(
            Icons.chevron_right_rounded,
            color: kColorWhite.withValues(alpha: 0.8),
            size: 22,
          ),
        ],
      );
    });
  }

  Widget _statChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          Spacing.h4,
          SemiBoldText(
            text: label,
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite,
          ),
        ],
      ),
    );
  }

  Widget _actionsGrid(List<_SeatActionData> actions) {
    if (actions.length <= 2) {
      return Row(
        children: actions
            .map(
              (action) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _SeatActionButton(action: action),
                ),
              ),
            )
            .toList(),
      );
    }

    // Host manage: 3 + remaining in a calm two-row grid.
    final top = actions.take(3).toList();
    final bottom = actions.skip(3).toList();
    return Column(
      children: [
        Row(
          children: top
              .map(
                (action) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _SeatActionButton(action: action),
                  ),
                ),
              )
              .toList(),
        ),
        if (bottom.isNotEmpty) ...[
          Spacing.v12,
          Row(
            children: [
              ...bottom.map(
                (action) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _SeatActionButton(action: action),
                  ),
                ),
              ),
              // Keep second row visually balanced when it has fewer tiles.
              if (bottom.length < 3)
                ...List.generate(
                  3 - bottom.length,
                  (_) => const Expanded(child: SizedBox()),
                ),
            ],
          ),
        ],
      ],
    );
  }

  void _openMessage(BuildContext context) {
    final receiverId = seat.userId.trim();
    if (receiverId.isEmpty) {
      Get.back();
      Get.snackbar(
        'Message unavailable',
        'This user id is missing from the room member data.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1E1E2D),
        colorText: kColorWhite,
      );
      return;
    }

    Get.back();
    unawaited(controller.openChatWithSeatMember(context, seat: seat));
  }

  void _openGift() {
    final receiverId = seat.userId.trim();
    if (receiverId.isEmpty) {
      Get.back();
      Get.snackbar(
        'Gift not available',
        'This user id is missing from the room member data.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1E1E2D),
        colorText: kColorWhite,
      );
      return;
    }
    controller.openGiftsSheet(
      receiverId: receiverId,
      receiverName: seat.name,
      roomGift: false,
    );
  }
}

class _SeatActionData {
  const _SeatActionData({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color accent;
}

class _SeatActionButton extends StatelessWidget {
  const _SeatActionButton({required this.action});

  final _SeatActionData action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kColorWhite,
                  border: Border.all(
                    color: action.accent.withValues(alpha: 0.55),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: action.accent.withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(action.icon, color: action.accent, size: 23),
              ),
              Spacing.v6,
              SemiBoldText(
                text: action.label,
                fontSize: TextStyles.k10FontSize,
                color: const Color(0xFF2A1A12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                align: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileOrbData {
  const _ProfileOrbData({
    required this.tip,
    required this.icon,
    required this.colors,
  });

  final String tip;
  final IconData icon;
  final List<Color> colors;
}

class _BadgeMedalData {
  const _BadgeMedalData({
    required this.label,
    required this.icon,
    required this.colors,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
}

/// Ornate red/gold profile card shell — matches premium room-member reference.
class _OrnateMemberProfileCard extends StatelessWidget {
  const _OrnateMemberProfileCard({required this.child});

  static const _salmon = Color(0xFFF2B8A7);
  static const _salmonDeep = Color(0xFFE89B88);
  static const _frameRed = Color(0xFF8E1B24);
  static const _frameRedDark = Color(0xFF5C0D14);
  static const _goldBright = Color(0xFFFFD56A);
  static const _goldDeep = Color(0xFFC4891A);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _frameRed.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _frameRedDark,
              _frameRed,
              _goldDeep,
              _frameRed,
              _frameRedDark,
            ],
            stops: [0.0, 0.22, 0.5, 0.78, 1.0],
          ),
        ),
        padding: const EdgeInsets.all(5),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_goldBright, _goldDeep, _goldBright],
            ),
          ),
          padding: const EdgeInsets.all(2.5),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [_salmon, _salmonDeep, _salmon],
                        stops: [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 3,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _goldBright.withValues(alpha: 0.0),
                          _goldBright.withValues(alpha: 0.85),
                          _goldBright.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(left: 6, top: 28, bottom: 28, child: _sidePillar()),
                Positioned(right: 6, top: 28, bottom: 28, child: _sidePillar()),
                Positioned.fill(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sidePillar() {
    return Container(
      width: 5,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _goldBright.withValues(alpha: 0.15),
            _goldBright.withValues(alpha: 0.55),
            _goldDeep.withValues(alpha: 0.45),
            _goldBright.withValues(alpha: 0.15),
          ],
        ),
      ),
    );
  }
}

class _PremiumAvatarFrame extends StatelessWidget {
  const _PremiumAvatarFrame({
    required this.name,
    required this.imageUrl,
    this.frameUrl,
    required this.muted,
    required this.isHost,
    required this.seatNo,
    this.frameSize = 112,
    this.avatarSize = 64,
  });

  final String name;
  final String? imageUrl;
  final String? frameUrl;
  final bool muted;
  final bool isHost;
  final int seatNo;
  final double frameSize;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    return _AudioSeatFrame(
      assetPath: _AudioSeatFrame.assetForSeat(seatNo, isHost: isHost),
      frameUrl: frameUrl,
      muted: muted,
      size: frameSize,
      contentSize: avatarSize,
      child: AppUserAvatar(
        name: name,
        imageUrl: imageUrl,
        size: avatarSize,
        border: Border.all(
          color: kColorWhite.withValues(alpha: 0.90),
          width: 1.6,
        ),
      ),
    );
  }
}

class _AudioSeatFrame extends StatelessWidget {
  const _AudioSeatFrame({
    required this.assetPath,
    required this.child,
    this.frameUrl,
    this.muted = false,
    this.locked = false,
    this.size = 112,
    this.contentSize,
  });

  static const _royal = 'assets/images/audio_room_frame_royal.svg';
  static const _neon = 'assets/images/audio_room_frame_neon.svg';
  static const _luxe = 'assets/images/audio_room_frame_luxe.svg';
  static const _empty = 'assets/images/audio_room_frame_empty.svg';

  final String assetPath;
  final Widget child;
  final String? frameUrl;
  final bool muted;
  final bool locked;
  final double size;
  final double? contentSize;

  static String assetForSeat(int seatNo, {required bool isHost}) {
    if (isHost) return _royal;
    const frames = [_neon, _luxe, _royal, _empty];
    return frames[seatNo % frames.length];
  }

  @override
  Widget build(BuildContext context) {
    final opacity = muted || locked ? 0.64 : 1.0;
    final innerSize = contentSize ?? (locked ? size * 0.52 : size * 0.57);
    final customFrame = frameUrl?.trim() ?? '';
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            IgnorePointer(
              child: _FrameMedia(source: assetPath, size: size),
            ),
            if (customFrame.isNotEmpty && customFrame != assetPath)
              IgnorePointer(
                child: _FrameMedia(source: customFrame, size: size),
              ),
            Container(
              width: innerSize,
              height: innerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: locked
                    ? const Color(0xFFDADADA)
                    : const Color(0xFF2B0D48),
                boxShadow: [
                  BoxShadow(
                    color: (muted ? kColorHint : kColorPrimary).withValues(
                      alpha: locked ? 0.08 : 0.20,
                    ),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _FrameMedia extends StatelessWidget {
  const _FrameMedia({required this.source, required this.size});

  final String source;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isRemote =
        source.startsWith('http://') ||
        source.startsWith('https://') ||
        source.startsWith('/');
    final normalizedUrl = isRemote ? ApiImageUtils.normalize(source) : null;
    final isSvg = source.toLowerCase().endsWith('.svg');

    if (isRemote && isSvg) {
      return SvgPicture.network(
        normalizedUrl!,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }

    if (isRemote) {
      return Image.network(
        normalizedUrl!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }

    if (isSvg) {
      return SvgPicture.asset(
        source,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }

    return Image.asset(source, width: size, height: size, fit: BoxFit.contain);
  }
}

class _EmptySeatPlaceholder extends StatelessWidget {
  const _EmptySeatPlaceholder({required this.seatNo});

  final int seatNo;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kColorWhite,
            kColorWhite.withValues(alpha: 0.88),
            kColorProfileChipPinkStart.withValues(alpha: 0.28),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.person_rounded,
            color: AudioRoomStageOverlay._deepPurple.withValues(alpha: 0.36),
            size: 38,
          ),
          Positioned(
            right: 12,
            bottom: 10,
            child: Icon(
              Icons.mic_rounded,
              color: AudioRoomStageOverlay._deepPurple.withValues(alpha: 0.46),
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _GridEmptySeat extends GetView<LiveBroadcastController> {
  const _GridEmptySeat({required this.seatNo, required this.metrics});

  final int seatNo;
  final _SeatLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onEmptySeatTap(context),
      child: _seatCellShell(
        child: SizedBox(
          width: metrics.frameSize + metrics.badgeSize,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: metrics.topInset),
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  _AudioSeatFrame(
                    assetPath: _AudioSeatFrame.assetForSeat(
                      seatNo,
                      isHost: false,
                    ),
                    size: metrics.frameSize,
                    contentSize: metrics.avatarSize,
                    child: _EmptySeatPlaceholder(seatNo: seatNo),
                  ),
                  Positioned(
                    left: -6,
                    top: -6,
                    child: _SeatBadge(number: seatNo, size: metrics.badgeSize),
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: metrics.addButtonSize,
                      height: metrics.addButtonSize,
                      decoration: BoxDecoration(
                        color: kColorWhite,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: kColorPrimary.withValues(alpha: 0.12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: kColorPrimary.withValues(alpha: 0.10),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: AudioRoomStageOverlay._deepPurple,
                        size: metrics.addButtonSize * 0.66,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: metrics.gapAfterFrame),
              Obx(() {
                final label =
                    controller.isHost.value ||
                        controller.canManageAudioRoomMembers
                    ? 'Invite'
                    : (controller.viewerFollowsHost.value ? 'Sit' : 'Request');
                return SemiBoldText(
                  text: label,
                  fontSize: TextStyles.k10FontSize,
                  color: AudioRoomStageOverlay._muted,
                  align: TextAlign.center,
                );
              }),
              // Spacer matching diamond row so empty/occupied cells stay aligned.
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  void _onEmptySeatTap(BuildContext context) {
    final isManager =
        controller.isHost.value || controller.canManageAudioRoomMembers;
    if (isManager) {
      Get.bottomSheet(
        _EmptySeatActionsSheet(seatNo: seatNo),
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
      );
      return;
    }
    // Guest: request / take seat directly.
    unawaited(controller.requestSeatForSeatNo(seatNo));
  }
}

class _EmptySeatActionsSheet extends GetView<LiveBroadcastController> {
  const _EmptySeatActionsSheet({required this.seatNo});

  final int seatNo;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF161622),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SemiBoldText(
              text: 'Seat $seatNo',
              fontSize: TextStyles.k16FontSize,
              color: kColorWhite,
            ),
            const SizedBox(height: 6),
            AppText(
              text: 'Invite someone or leave this seat open for requests.',
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite.withValues(alpha: 0.65),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.person_add_alt_1_rounded,
                color: Color(0xFFFF3EA5),
              ),
              title: const SemiBoldText(
                text: 'Invite',
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite,
              ),
              subtitle: AppText(
                text: 'Invite a follower who is not in the room yet',
                fontSize: TextStyles.k10FontSize,
                color: kColorWhite.withValues(alpha: 0.55),
              ),
              onTap: () {
                Get.back<void>();
                Get.bottomSheet(
                  _InviteCandidatesSheet(seatNo: seatNo),
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                );
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.groups_rounded,
                color: Color(0xFFFFD56A),
              ),
              title: const SemiBoldText(
                text: 'Seat floor user',
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite,
              ),
              subtitle: AppText(
                text: 'Place someone from the floor list on this seat',
                fontSize: TextStyles.k10FontSize,
                color: kColorWhite.withValues(alpha: 0.55),
              ),
              onTap: () {
                Get.back<void>();
                Get.bottomSheet(
                  _FloorAudienceSeatPickerSheet(seatNo: seatNo),
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  barrierColor: Colors.black.withValues(alpha: 0.55),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FloorAudienceBadge extends GetView<LiveBroadcastController> {
  const _FloorAudienceBadge({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final count = controller.floorAudience.length;
      final size = compact ? 36.0 : 40.0;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          key: controller.floorAudienceBadgeKey,
          onTap: _openFloorAudienceListSheet,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            height: size,
            padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF6AD5), Color(0xFF9B1FE8)],
              ),
              border: Border.all(color: kColorWhite.withValues(alpha: 0.18)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF3EA5).withValues(alpha: 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.people_alt_rounded,
                  color: kColorWhite,
                  size: compact ? 15 : 17,
                ),
                Spacing.h6,
                SemiBoldText(
                  text: '$count',
                  fontSize: compact
                      ? TextStyles.k10FontSize
                      : TextStyles.k12FontSize,
                  color: kColorWhite,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _openFloorAudienceListSheet() {
    Get.bottomSheet(
      const _FloorAudienceListSheet(),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
    );
  }
}

/// Full floor-audience list opened from the AppBar people badge.
class _FloorAudienceListSheet extends GetView<LiveBroadcastController> {
  const _FloorAudienceListSheet();

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(10, 0, 10, bottomInset + 10),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.62,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2B1654), Color(0xFF171339)],
          ),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.14)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kColorWhite.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Spacing.v16,
            Obx(() {
              final count = controller.floorAudience.length;
              return Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF6AD5), Color(0xFF9B1FE8)],
                      ),
                    ),
                    child: const Icon(
                      Icons.people_alt_rounded,
                      color: kColorWhite,
                      size: 18,
                    ),
                  ),
                  Spacing.h10,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SemiBoldText(
                          text: 'Floor audience',
                          fontSize: TextStyles.k16FontSize,
                          color: kColorWhite,
                        ),
                        AppText(
                          text: count == 0
                              ? 'No one on the floor yet'
                              : '$count ${count == 1 ? 'person' : 'people'} watching',
                          fontSize: TextStyles.k12FontSize,
                          color: kColorWhite.withValues(alpha: 0.65),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
            Spacing.v12,
            Flexible(
              child: Obx(() {
                final users = controller.floorAudience;
                if (users.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 36,
                          color: kColorWhite.withValues(alpha: 0.35),
                        ),
                        Spacing.v10,
                        AppText(
                          text:
                              'When someone joins this room, they show up here.',
                          fontSize: TextStyles.k12FontSize,
                          color: kColorWhite.withValues(alpha: 0.65),
                          align: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final name = user.name.trim().isEmpty
                        ? 'Guest'
                        : user.name.trim();
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Get.back();
                          Future.delayed(const Duration(milliseconds: 120), () {
                            openFloorAudienceProfileSheet(user);
                          });
                        },
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: kColorWhite.withValues(alpha: 0.06),
                            border: Border.all(
                              color: kColorWhite.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white12,
                                backgroundImage:
                                    (user.avatarUrl ?? '').trim().isNotEmpty
                                    ? NetworkImage(user.avatarUrl!.trim())
                                    : null,
                                child: (user.avatarUrl ?? '').trim().isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        color: kColorWhite,
                                        size: 20,
                                      )
                                    : null,
                              ),
                              Spacing.h12,
                              Expanded(
                                child: SemiBoldText(
                                  text: name,
                                  fontSize: TextStyles.k14FontSize,
                                  color: kColorWhite,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: kColorWhite.withValues(alpha: 0.45),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floor-list user profile — Message / Gift (+ Kick for host/admin).
class FloorAudienceProfileSheet extends GetView<LiveBroadcastController> {
  const FloorAudienceProfileSheet({super.key, required this.user});

  final FloorAudienceUser user;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final canManage = controller.canManageAudioRoomMembers;
    final isSelf = _isSelf();

    return Padding(
      padding: EdgeInsets.fromLTRB(10, 0, 10, bottomInset + 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2B1654), Color(0xFF171339)],
          ),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.14)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF3EA5).withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kColorWhite.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Spacing.v16,
            CircleAvatar(
              radius: 36,
              backgroundColor: Colors.white12,
              backgroundImage: (user.avatarUrl ?? '').trim().isNotEmpty
                  ? NetworkImage(user.avatarUrl!.trim())
                  : null,
              child: (user.avatarUrl ?? '').trim().isEmpty
                  ? const Icon(Icons.person, color: kColorWhite, size: 36)
                  : null,
            ),
            Spacing.v12,
            SemiBoldText(
              text: user.name.trim().isEmpty ? 'Guest' : user.name.trim(),
              fontSize: TextStyles.k18FontSize,
              color: kColorWhite,
            ),
            Spacing.v6,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFFFF3EA5).withValues(alpha: 0.18),
                border: Border.all(
                  color: const Color(0xFFFF3EA5).withValues(alpha: 0.4),
                ),
              ),
              child: const SemiBoldText(
                text: 'Floor audience',
                fontSize: TextStyles.k10FontSize,
                color: Color(0xFFFF8FB8),
              ),
            ),
            if (user.isVip || user.isCoinsSeller) ...[
              Spacing.v10,
              Wrap(
                spacing: 8,
                children: [
                  if (user.isVip)
                    _floorChip(
                      icon: Icons.workspace_premium_rounded,
                      label: 'VIP',
                    ),
                  if (user.isCoinsSeller)
                    _floorChip(
                      icon: Icons.storefront_rounded,
                      label: 'Coin Seller',
                    ),
                ],
              ),
            ],
            Spacing.v16,
            if (!isSelf) ...[
              Row(
                children: [
                  Expanded(
                    child: _floorActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Message',
                      colors: const [Color(0xFFFF8FB8), Color(0xFFFF3EA5)],
                      onTap: () => _openMessage(context),
                    ),
                  ),
                  Spacing.h10,
                  Expanded(
                    child: _floorActionButton(
                      icon: kGiftIcon,
                      label: 'Gift',
                      colors: const [Color(0xFFFFB347), Color(0xFFFF6B35)],
                      onTap: _openGift,
                    ),
                  ),
                ],
              ),
              if (canManage) ...[
                Spacing.v10,
                SizedBox(
                  width: double.infinity,
                  child: _floorActionButton(
                    icon: Icons.event_seat_rounded,
                    label: 'Put on seat',
                    colors: const [Color(0xFF7C9CFF), Color(0xFF5B6CFF)],
                    onTap: _openSeatPicker,
                  ),
                ),
                Spacing.v10,
                SizedBox(
                  width: double.infinity,
                  child: _floorActionButton(
                    icon: Icons.person_remove_rounded,
                    label: 'Remove from room',
                    colors: const [Color(0xFFFF6B6B), Color(0xFFD32F2F)],
                    onTap: _kick,
                  ),
                ),
              ],
            ] else
              AppText(
                text: 'This is you in the floor audience.',
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite.withValues(alpha: 0.7),
              ),
          ],
        ),
      ),
    );
  }

  bool _isSelf() {
    final myId = Get.isRegistered<UserSessionController>()
        ? Get.find<UserSessionController>().userId.trim()
        : '';
    if (myId.isEmpty) return false;
    return myId == user.userId.trim();
  }

  Widget _floorChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: kColorWhite.withValues(alpha: 0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFFFFD56A)),
          const SizedBox(width: 4),
          SemiBoldText(
            text: label,
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite,
          ),
        ],
      ),
    );
  }

  Widget _floorActionButton({
    required IconData icon,
    required String label,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(colors: colors),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: kColorWhite, size: 18),
              const SizedBox(width: 8),
              SemiBoldText(
                text: label,
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openMessage(BuildContext context) {
    Get.back<void>();
    unawaited(
      controller.openChatWithViewer(context, {
        'targetId': user.userId,
        'name': user.name,
        'avatarUrl': user.avatarUrl,
      }),
    );
  }

  void _openGift() {
    final receiverId = user.userId.trim();
    if (receiverId.isEmpty) {
      Get.back<void>();
      return;
    }
    controller.openGiftsSheet(
      receiverId: receiverId,
      receiverName: user.name,
      roomGift: false,
    );
  }

  void _openSeatPicker() {
    Get.back<void>();
    Get.bottomSheet(
      _EmptySeatsForFloorUserSheet(user: user),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
    );
  }

  void _kick() {
    Get.back<void>();
    unawaited(
      controller.kickAudioRoomUser(
        AudioRoomSeatModel(
          seatNo: 0,
          userId: user.userId,
          name: user.name,
          avatarUrl: user.avatarUrl,
          role: 'audience',
        ),
      ),
    );
  }
}

/// Host picks an empty seat for a floor-audience user.
class _EmptySeatsForFloorUserSheet extends GetView<LiveBroadcastController> {
  const _EmptySeatsForFloorUserSheet({required this.user});

  final FloorAudienceUser user;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final name = user.name.trim().isEmpty ? 'Guest' : user.name.trim();

    return Padding(
      padding: EdgeInsets.fromLTRB(10, 0, 10, bottomInset + 10),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.55,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2B1654), Color(0xFF171339)],
          ),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.14)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kColorWhite.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Spacing.v16,
            SemiBoldText(
              text: 'Put $name on a seat',
              fontSize: TextStyles.k16FontSize,
              color: kColorWhite,
            ),
            Spacing.v6,
            AppText(
              text: 'Choose an empty guest seat.',
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite.withValues(alpha: 0.65),
            ),
            Spacing.v12,
            Flexible(
              child: Obx(() {
                final emptySeats = controller.audioRoomSeats
                    .where((s) => s.seatNo > 1 && !s.occupied && !s.isLocked)
                    .toList();
                if (emptySeats.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: AppText(
                      text: 'No empty seats available right now.',
                      fontSize: TextStyles.k12FontSize,
                      color: kColorWhite.withValues(alpha: 0.7),
                      align: TextAlign.center,
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: emptySeats.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final seat = emptySeats[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => unawaited(
                          controller.placeFloorUserOnSeat(
                            user: user,
                            seatNo: seat.seatNo,
                          ),
                        ),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: kColorWhite.withValues(alpha: 0.06),
                            border: Border.all(
                              color: kColorWhite.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(
                                        0xFF7C9CFF,
                                      ).withValues(alpha: 0.9),
                                      const Color(0xFF5B6CFF),
                                    ],
                                  ),
                                ),
                                child: SemiBoldText(
                                  text: '${seat.seatNo}',
                                  fontSize: TextStyles.k14FontSize,
                                  color: kColorWhite,
                                ),
                              ),
                              Spacing.h12,
                              Expanded(
                                child: SemiBoldText(
                                  text: 'Seat ${seat.seatNo}',
                                  fontSize: TextStyles.k14FontSize,
                                  color: kColorWhite,
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: kColorWhite,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// Host picks a floor-audience user for a specific empty seat.
class _FloorAudienceSeatPickerSheet extends GetView<LiveBroadcastController> {
  const _FloorAudienceSeatPickerSheet({required this.seatNo});

  final int seatNo;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(10, 0, 10, bottomInset + 10),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.55,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2B1654), Color(0xFF171339)],
          ),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.14)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kColorWhite.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Spacing.v16,
            SemiBoldText(
              text: 'Seat $seatNo — floor audience',
              fontSize: TextStyles.k16FontSize,
              color: kColorWhite,
            ),
            Spacing.v6,
            AppText(
              text: 'Tap a user to place them on this seat.',
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite.withValues(alpha: 0.65),
            ),
            Spacing.v12,
            Flexible(
              child: Obx(() {
                final users = controller.floorAudience;
                if (users.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: AppText(
                      text: 'No floor audience users in this room.',
                      fontSize: TextStyles.k12FontSize,
                      color: kColorWhite.withValues(alpha: 0.7),
                      align: TextAlign.center,
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final name = user.name.trim().isEmpty
                        ? 'Guest'
                        : user.name.trim();
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => unawaited(
                          controller.placeFloorUserOnSeat(
                            user: user,
                            seatNo: seatNo,
                          ),
                        ),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: kColorWhite.withValues(alpha: 0.06),
                            border: Border.all(
                              color: kColorWhite.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white12,
                                backgroundImage:
                                    (user.avatarUrl ?? '').trim().isNotEmpty
                                    ? NetworkImage(user.avatarUrl!.trim())
                                    : null,
                                child: (user.avatarUrl ?? '').trim().isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        color: kColorWhite,
                                        size: 20,
                                      )
                                    : null,
                              ),
                              Spacing.h12,
                              Expanded(
                                child: SemiBoldText(
                                  text: name,
                                  fontSize: TextStyles.k14FontSize,
                                  color: kColorWhite,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(
                                Icons.event_seat_rounded,
                                color: Color(0xFFFFD56A),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteCandidatesSheet extends StatefulWidget {
  const _InviteCandidatesSheet({required this.seatNo});

  final int seatNo;

  @override
  State<_InviteCandidatesSheet> createState() => _InviteCandidatesSheetState();
}

class _InviteCandidatesSheetState extends State<_InviteCandidatesSheet> {
  final LiveBroadcastController controller =
      Get.find<LiveBroadcastController>();
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller.loadAudioInviteCandidates();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.72,
      ),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1D102F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kColorWhite.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Spacing.v16,
            Row(
              children: [
                const Expanded(
                  child: SemiBoldText(
                    text: 'Invite to mic',
                    fontSize: TextStyles.k16FontSize,
                    color: kColorWhite,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AudioRoomStageOverlay._seatGold.withValues(
                      alpha: 0.16,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SemiBoldText(
                    text: 'Seat ${widget.seatNo}',
                    fontSize: TextStyles.k10FontSize,
                    color: AudioRoomStageOverlay._seatGold,
                  ),
                ),
              ],
            ),
            Spacing.v12,
            TextField(
              controller: searchController,
              style: const TextStyle(color: kColorWhite),
              onSubmitted: (value) =>
                  controller.loadAudioInviteCandidates(search: value),
              decoration: InputDecoration(
                hintText: 'Search followers',
                hintStyle: TextStyle(
                  color: kColorWhite.withValues(alpha: 0.48),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: kColorWhite.withValues(alpha: 0.7),
                ),
                filled: true,
                fillColor: kColorWhite.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            Spacing.v12,
            Flexible(
              child: Obx(() {
                if (controller.isLoadingInviteCandidates.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AudioRoomStageOverlay._seatGold,
                    ),
                  );
                }
                final users = controller.audioInviteCandidates;
                if (users.isEmpty) {
                  return Center(
                    child: AppText(
                      text: 'No followers available to invite right now.',
                      fontSize: TextStyles.k12FontSize,
                      color: kColorWhite.withValues(alpha: 0.64),
                      align: TextAlign.center,
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: users.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: kColorWhite.withValues(alpha: 0.08),
                  ),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: AppUserAvatar(
                        name: user.name,
                        imageUrl: user.avatarUrl,
                        size: 42,
                      ),
                      title: SemiBoldText(
                        text: user.name,
                        fontSize: TextStyles.k12FontSize,
                        color: kColorWhite,
                      ),
                      subtitle: AppText(
                        text: user.isOnline ? 'Online follower' : 'Follower',
                        fontSize: TextStyles.k10FontSize,
                        color: kColorWhite.withValues(alpha: 0.58),
                      ),
                      trailing: TextButton(
                        onPressed: () => controller.inviteUserToAudioSeat(
                          seatNo: widget.seatNo,
                          user: user,
                        ),
                        child: const SemiBoldText(
                          text: 'Invite',
                          fontSize: TextStyles.k10FontSize,
                          color: AudioRoomStageOverlay._seatGold,
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedSeat extends StatelessWidget {
  const _LockedSeat({required this.seatNo, required this.metrics});

  final int seatNo;
  final _SeatLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return _seatCellShell(
      child: SizedBox(
        width: metrics.frameSize + metrics.badgeSize,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: metrics.topInset),
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                _AudioSeatFrame(
                  assetPath: _AudioSeatFrame._empty,
                  locked: true,
                  size: metrics.frameSize,
                  contentSize: metrics.avatarSize * 0.9,
                  child: Icon(
                    Icons.lock_rounded,
                    color: AudioRoomStageOverlay._deepPurple.withValues(
                      alpha: 0.45,
                    ),
                    size: metrics.avatarSize * 0.45,
                  ),
                ),
                Positioned(
                  left: -6,
                  top: -6,
                  child: _SeatBadge(number: seatNo, size: metrics.badgeSize),
                ),
              ],
            ),
            SizedBox(height: metrics.gapAfterFrame),
            const AppText(
              text: 'Locked',
              fontSize: TextStyles.k10FontSize,
              color: AudioRoomStageOverlay._muted,
              align: TextAlign.center,
            ),
            const _DiamondCount(value: 20),
          ],
        ),
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AudioRoomStageOverlay._seatGold),
          Spacing.h4,
          AppText(
            text: label,
            fontSize: TextStyles.k10FontSize,
            color: AudioRoomStageOverlay._ink,
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.compact,
    this.filled = true,
    this.iconColor = kColorWhite,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool compact;
  final bool filled;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: compact ? 40 : 44,
        height: compact ? 40 : 44,
        decoration: BoxDecoration(
          color: filled
              ? Colors.black.withValues(alpha: 0.24)
              : Colors.black.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.06)),
        ),
        child: Icon(icon, color: iconColor, size: compact ? 22 : 24),
      ),
    );
  }
}

class _SeatBadge extends StatelessWidget {
  const _SeatBadge({required this.number, this.size = 24});

  final int number;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AudioRoomStageOverlay._seatGold,
        shape: BoxShape.circle,
        border: Border.all(
          color: kColorWhite.withValues(alpha: 0.82),
          width: 1.2,
        ),
      ),
      child: SemiBoldText(
        text: '$number',
        fontSize: size >= 22 ? 10 : 9,
        color: kColorWhite,
      ),
    );
  }
}

class _MicBubble extends StatelessWidget {
  const _MicBubble({this.muted = false, this.small = false});

  final bool muted;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 34.0 : 38.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: muted ? const Color(0xFF6B6470) : null,
        gradient: muted
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AudioRoomStageOverlay._micStart,
                  AudioRoomStageOverlay._micEnd,
                ],
              ),
        shape: BoxShape.circle,
        border: Border.all(color: kColorWhite, width: 2),
        boxShadow: muted
            ? null
            : [
                BoxShadow(
                  color: AudioRoomStageOverlay._micStart.withValues(
                    alpha: 0.22,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Icon(
        muted ? Icons.mic_off_rounded : Icons.mic_rounded,
        color: kColorWhite,
        size: small ? 19 : 21,
      ),
    );
  }
}

class _SeatSessionCoinCount extends GetView<LiveBroadcastController> {
  const _SeatSessionCoinCount({required this.seat});

  final AudioRoomSeatModel seat;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.shouldShowSeatSessionCoins(seat)) {
        return const SizedBox.shrink();
      }
      return _DiamondCount(value: controller.sessionCoinsForSeat(seat));
    });
  }
}

class _SeatSessionCoinInline extends GetView<LiveBroadcastController> {
  const _SeatSessionCoinInline({required this.seat, required this.compact});

  final AudioRoomSeatModel seat;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.shouldShowSeatSessionCoins(seat)) {
        return const SizedBox.shrink();
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 4),
          Icon(
            Icons.diamond_rounded,
            size: compact ? 9 : 11,
            color: AudioRoomStageOverlay._seatGold,
          ),
          const SizedBox(width: 2),
          AppText(
            text: '${controller.sessionCoinsForSeat(seat)}',
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite.withValues(alpha: 0.78),
          ),
        ],
      );
    });
  }
}

class _DiamondCount extends StatelessWidget {
  const _DiamondCount({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.diamond_rounded,
            size: 13,
            color: AudioRoomStageOverlay._seatGold,
          ),
          Spacing.h4,
          AppText(text: '$value', fontSize: 9, color: kColorWhite),
        ],
      ),
    );
  }
}
