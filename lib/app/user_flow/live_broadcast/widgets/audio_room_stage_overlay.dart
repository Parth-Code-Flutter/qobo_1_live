import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
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
import '../controllers/live_broadcast_controller.dart';
import '../models/audio_room_models.dart';
import '../utils/audio_room_seat_layout.dart';
import 'room_options_sheet.dart';

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
                return Stack(
                  children: [
                    CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            compact ? 10 : 12,
                            compact ? 12 : 14,
                            compact ? 10 : 12,
                            // Keep the last seat row reachable above the chat
                            // feed + input + control dock.
                            compact ? 296 : 312,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate.fixed([
                              _RoomHeader(compact: compact),
                              SizedBox(height: compact ? 14 : 16),
                              _MemberGrid(compact: compact),
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
            _SpeakerControl(compact: compact),
            _ControlButton(
              icon: Icons.back_hand_rounded,
              label: 'Request',
              compact: compact,
              emphasized: true,
              onTap: () => controller.requestAudioSeat(),
            ),
            _ControlButton(
              icon: Icons.favorite_rounded,
              label: 'React',
              compact: compact,
              onTap: () => Get.snackbar('React', 'Reaction sent.'),
            ),
            // Always show Gift; send blocks with toast when host/person is alone.
            Obx(
              () => _GiftControlButton(
                compact: compact,
                coins: controller.coinsBalance.value,
                onTap: controller.openGiftsSheet,
              ),
            ),
            _ControlButton(
              icon: Icons.more_horiz_rounded,
              label: 'More',
              compact: compact,
              onTap: () {
                Get.bottomSheet(
                  RoomOptionsSheet(
                    isHost: controller.isHost.value,
                    isVideoRoom: controller.isVideoRoom,
                  ),
                  backgroundColor: Colors.transparent,
                );
              },
            ),
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
            child: const Icon(
              Icons.send_rounded,
              color: kColorWhite,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

class _MicControl extends StatelessWidget {
  const _MicControl({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final userId = ZegoUIKit().getLocalUser().id;
    return ValueListenableBuilder<bool>(
      valueListenable: ZegoUIKit().getMicrophoneStateNotifier(userId),
      builder: (context, isOn, _) {
        return _ControlButton(
          icon: isOn ? Icons.mic_rounded : Icons.mic_off_rounded,
          label: isOn ? 'Mic On' : 'Muted',
          compact: compact,
          active: isOn,
          onTap: () => ZegoUIKit().turnMicrophoneOn(!isOn, muteMode: true),
        );
      },
    );
  }
}

class _SpeakerControl extends StatelessWidget {
  const _SpeakerControl({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final userId = ZegoUIKit().getLocalUser().id;
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
          active: isSpeaker,
          onTap: isLocked
              ? null
              : () => ZegoUIKit().setAudioOutputToSpeaker(!isSpeaker),
        );
      },
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.compact,
    required this.onTap,
    this.active = false,
    this.emphasized = false,
    this.accentGradient,
  });

  final IconData icon;
  final String label;
  final bool compact;
  final VoidCallback? onTap;
  final bool active;
  final bool emphasized;
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
                    gradient: accentGradient ??
                        (emphasized
                            ? const LinearGradient(
                                colors: [
                                  kColorProfileFeatureBlue,
                                  kColorPrimary,
                                ],
                              )
                            : null),
                    color: accentGradient != null || emphasized
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
                    color: accentGradient != null || emphasized
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
                      decoration: const BoxDecoration(
                        color: kColorProfileActionPinkStart,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.card_giftcard_rounded,
                        color: kColorWhite,
                        size: 20,
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
            final earningsMaxWidth = (constraints.maxWidth * 0.17).clamp(
              52.0,
              compact ? 64.0 : 72.0,
            );

            return Row(
              children: [
                _CircleButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: controller.leaveRoom,
                  compact: compact,
                  filled: false,
                ),
                Spacing.h8,
                AppUserAvatar(
                  name: controller.hostName.value,
                  imageUrl: controller.hostAvatarUrl.value,
                  size: compact ? 40 : 44,
                  border: Border.all(color: kColorWhite, width: 1.5),
                ),
                Spacing.h10,
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
                _CircleButton(
                  icon: Icons.share_rounded,
                  onTap: () => controller.shareRoom(),
                  compact: compact,
                ),
                if (controller.canManageAudioRoomMembers) ...[
                  Spacing.h8,
                  _CircleButton(
                    icon: Icons.wallpaper_rounded,
                    onTap: controller.openRoomBackgroundSheet,
                    compact: compact,
                  ),
                ],
                if (controller.isHost.value) ...[
                  Spacing.h8,
                  SessionEarningsBadge(
                    key: controller.sessionEarningsBadgeKey,
                    tracker: controller.sessionEarnings,
                    compact: compact,
                    maxWidth: earningsMaxWidth,
                    icon: Icons.monetization_on_rounded,
                    iconColor: const Color(0xFFFFA10A),
                    onTap: controller.openSessionEarningsDialog,
                  ),
                ],
                if (controller.isHost.value) ...[
                  Spacing.h8,
                  _CircleButton(
                    icon: Icons.power_settings_new_rounded,
                    onTap: controller.confirmEndRoom,
                    compact: compact,
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
}

/// Responsive seat-cell metrics so the audio grid fits any phone width
/// without fixed-height overflows (e.g. "BOTTOM OVERFLOWED BY 0.9px").
typedef _SeatLayoutMetrics = AudioRoomSeatLayoutMetrics;

class _MemberGrid extends StatefulWidget {
  const _MemberGrid({required this.compact});

  final bool compact;

  @override
  State<_MemberGrid> createState() => _MemberGridState();
}

class _MemberGridState extends State<_MemberGrid> {
  final LiveBroadcastController controller =
      Get.find<LiveBroadcastController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final seats = _buildSeats();
      final visibleSeats = seats;

      return LayoutBuilder(
        builder: (context, constraints) {
          final metrics = _SeatLayoutMetrics.fromWidth(
            constraints.maxWidth,
            compact: widget.compact,
          );
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleSeats.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: AudioRoomSeatLayoutMetrics.crossAxisCount,
              mainAxisExtent: metrics.mainAxisExtent,
              mainAxisSpacing: metrics.mainAxisSpacing,
              crossAxisSpacing: metrics.crossAxisSpacing,
            ),
            itemBuilder: (context, index) {
              final seat = visibleSeats[index];
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

  List<AudioRoomSeatModel> _buildSeats() => controller.audioRoomSeats.toList();
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
    return GestureDetector(
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
              _DiamondCount(value: seat.diamonds),
            ],
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
            if (seat.diamonds > 0)
              _metaPill(
                icon: Icons.diamond_rounded,
                label: '${seat.diamonds}',
                accent: const Color(0xFF2ED3FF),
              ),
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
                    icon: const Icon(Icons.close_rounded, color: Colors.white54),
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
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                            Icon(Icons.copy_rounded, color: kColorWhite, size: 16),
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
      return [
        _SeatActionData(
          icon: seat.isMuted ? Icons.mic_rounded : Icons.mic_off_rounded,
          label: seat.isMuted ? 'Unmute' : 'Mute',
          accent: const Color(0xFF7AD7FF),
          onTap: () => controller.updateAudioSeatMic(
            seat: seat,
            mute: !seat.isMuted,
          ),
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
          icon: Icons.card_giftcard_rounded,
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
        icon: Icons.card_giftcard_rounded,
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
              color: (isCoinSeller && !seat.isHost && !seat.isAdmin
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
          colors: const [Color(0xFFFFF59D), Color(0xFFFFDF00), Color(0xFFD4AF37)],
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
      if (seat.diamonds > 0)
        _BadgeMedalData(
          label: 'x${seat.diamonds}',
          icon: Icons.diamond_rounded,
          colors: const [Color(0xFFB2EBF2), Color(0xFF2ED3FF), Color(0xFF1A9FD4)],
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _goldBright.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _goldBright.withValues(alpha: 0.4)),
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
  }

  Widget _badgeMedalCard(_BadgeMedalData medal, {bool featured = false}) {
    final accent = medal.colors.length > 1 ? medal.colors[1] : medal.colors.first;
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
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
                child: Icon(medal.icon, size: featured ? 22 : 20, color: kColorWhite),
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
    return Row(
      children: [
        _statChip(
          icon: Icons.diamond_rounded,
          label: '${seat.diamonds}',
          color: const Color(0xFF2ED3FF),
        ),
        Spacing.h8,
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
    unawaited(
      controller.openChatWithSeatMember(
        context,
        seat: seat,
      ),
    );
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
                Positioned(
                  left: 6,
                  top: 28,
                  bottom: 28,
                  child: _sidePillar(),
                ),
                Positioned(
                  right: 6,
                  top: 28,
                  bottom: 28,
                  child: _sidePillar(),
                ),
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
      onTap: () => Get.bottomSheet(
        _InviteCandidatesSheet(seatNo: seatNo),
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
      ),
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
              const SemiBoldText(
                text: 'Invite',
                fontSize: TextStyles.k10FontSize,
                color: AudioRoomStageOverlay._muted,
                align: TextAlign.center,
              ),
              // Spacer matching diamond row so empty/occupied cells stay aligned.
              const SizedBox(height: 18),
            ],
          ),
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
          AppText(
            text: '$value',
            fontSize: 9,
            color: AudioRoomStageOverlay._ink,
          ),
        ],
      ),
    );
  }
}
