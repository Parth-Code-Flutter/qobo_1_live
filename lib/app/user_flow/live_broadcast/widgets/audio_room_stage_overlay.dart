import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:zego_uikit/zego_uikit.dart';

import '../controllers/live_broadcast_controller.dart';
import '../models/audio_room_models.dart';
import '../utils/audio_room_seat_layout.dart';

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
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_roomTop, _roomMid, _roomBottom],
          stops: [0, 0.46, 1],
        ),
      ),
      child: SafeArea(
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
                        compact ? 132 : 140,
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
                  child: _AudioRoomBottomControls(compact: compact),
                ),
              ],
            );
          },
        ),
      ),
    );
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
            Obx(
              () => _GiftControlButton(
                compact: compact,
                coins: controller.coinsBalance.value,
                onTap: controller.openGiftsSheet,
              ),
            ),
          ],
        ),
      ),
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
  });

  final IconData icon;
  final String label;
  final bool compact;
  final VoidCallback? onTap;
  final bool active;
  final bool emphasized;

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
                    gradient: emphasized
                        ? const LinearGradient(
                            colors: [kColorProfileFeatureBlue, kColorPrimary],
                          )
                        : null,
                    color: emphasized
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
                    color: emphasized
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
        child: Row(
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
            Spacing.h8,
            _HeaderMetric(
              icon: Icons.local_fire_department_rounded,
              label: controller.likesLabel.value.isEmpty
                  ? '0'
                  : controller.likesLabel.value,
            ),
            if (controller.isHost.value) ...[
              Spacing.h8,
              _CircleButton(
                icon: Icons.power_settings_new_rounded,
                onTap: controller.confirmEndRoom,
                compact: compact,
              ),
            ],
          ],
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
                child: SemiBoldText(
                  text: seat.name,
                  fontSize: TextStyles.k10FontSize,
                  color: kColorWhite,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  align: TextAlign.center,
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
    if (controller.isHost.value && seat.isHost) return;
    Get.bottomSheet(
      _AudioSeatActionsSheet(seat: seat, isHostView: controller.isHost.value),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }
}

class _AudioSeatActionsSheet extends GetView<LiveBroadcastController> {
  const _AudioSeatActionsSheet({required this.seat, required this.isHostView});

  final AudioRoomSeatModel seat;
  final bool isHostView;

  @override
  Widget build(BuildContext context) {
    final actions = isHostView
        ? [
            _SeatActionData(
              icon: seat.isMuted ? Icons.mic_rounded : Icons.mic_off_rounded,
              label: seat.isMuted ? 'Unmute' : 'Mute',
              onTap: () => controller.updateAudioSeatMic(
                seat: seat,
                mute: !seat.isMuted,
              ),
            ),
            _SeatActionData(
              icon: Icons.person_remove_rounded,
              label: 'Kick off',
              onTap: () => controller.kickAudioRoomUser(seat),
            ),
            _SeatActionData(
              icon: Icons.admin_panel_settings_rounded,
              label: seat.isAdmin ? 'Remove admin' : 'Make admin',
              onTap: () => controller.setAudioRoomAdmin(
                seat: seat,
                makeAdmin: !seat.isAdmin,
              ),
            ),
            _SeatActionData(
              icon: Icons.card_giftcard_rounded,
              label: 'Gift',
              onTap: _openGift,
            ),
          ]
        : [
            _SeatActionData(
              icon: Icons.card_giftcard_rounded,
              label: 'Send gift',
              onTap: _openGift,
            ),
          ];

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      decoration: const BoxDecoration(
        color: Color(0xFF1D222B),
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
                _PremiumAvatarFrame(
                  name: seat.name,
                  imageUrl: seat.avatarUrl,
                  muted: seat.isMuted,
                  isHost: seat.isHost,
                  seatNo: seat.seatNo,
                ),
                Spacing.h12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SemiBoldText(
                        text: seat.name,
                        fontSize: TextStyles.k16FontSize,
                        color: kColorWhite,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Spacing.v4,
                      AppText(
                        text: isHostView
                            ? 'Manage this room member'
                            : 'Send an individual gift',
                        fontSize: TextStyles.k12FontSize,
                        color: kColorWhite.withValues(alpha: 0.62),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: actions
                  .map(
                    (action) =>
                        Expanded(child: _SeatActionButton(action: action)),
                  )
                  .toList(),
            ),
          ],
        ),
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
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _SeatActionButton extends StatelessWidget {
  const _SeatActionButton({required this.action});

  final _SeatActionData action;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: kColorWhite.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: kColorWhite.withValues(alpha: 0.08)),
              ),
              child: Icon(action.icon, color: kColorWhite, size: 22),
            ),
            Spacing.v6,
            AppText(
              text: action.label,
              fontSize: 9,
              color: kColorWhite.withValues(alpha: 0.78),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              align: TextAlign.center,
            ),
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
    required this.muted,
    required this.isHost,
    required this.seatNo,
    this.frameSize = 112,
    this.avatarSize = 64,
  });

  final String name;
  final String? imageUrl;
  final bool muted;
  final bool isHost;
  final int seatNo;
  final double frameSize;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    return _AudioSeatFrame(
      assetPath: _AudioSeatFrame.assetForSeat(seatNo, isHost: isHost),
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
              child: SvgPicture.asset(
                assetPath,
                width: size,
                height: size,
                fit: BoxFit.contain,
              ),
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
                    child: _SeatBadge(
                      number: seatNo,
                      size: metrics.badgeSize,
                    ),
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
                  child: _SeatBadge(
                    number: seatNo,
                    size: metrics.badgeSize,
                  ),
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
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool compact;
  final bool filled;

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
        child: Icon(icon, color: kColorWhite, size: compact ? 22 : 24),
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
