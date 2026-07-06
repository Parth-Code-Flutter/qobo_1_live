import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:zego_uikit/zego_uikit.dart';

import '../controllers/live_broadcast_controller.dart';

class AudioRoomStageOverlay extends GetView<LiveBroadcastController> {
  const AudioRoomStageOverlay({super.key});

  static const _ink = Color(0xFF24162E);
  static const _muted = Color(0xFF776A80);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF8FD), Color(0xFFF5ECFA), Color(0xFFF9F5FC)],
          stops: [0, 0.42, 1],
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
                        compact ? 8 : 10,
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
              onTap: () => Get.snackbar('Request', 'Seat request coming soon.'),
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

      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 9,
          vertical: compact ? 6 : 7,
        ),
        decoration: BoxDecoration(
          color: kColorWhite.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.72)),
          boxShadow: [
            BoxShadow(
              color: kColorPrimary.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: kColorWhite.withValues(alpha: 0.80),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            _CircleButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: controller.leaveRoom,
              compact: compact,
              filled: false,
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
                        ? TextStyles.k12FontSize
                        : TextStyles.k14FontSize,
                    color: AudioRoomStageOverlay._ink,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Spacing.h8,
            _HeaderMetric(
              icon: Icons.local_fire_department_rounded,
              label: controller.likesLabel.value.isEmpty
                  ? '0'
                  : controller.likesLabel.value,
            ),
            Spacing.h8,
            _CircleButton(
              icon: Icons.power_settings_new_rounded,
              onTap: controller.leaveRoom,
              compact: compact,
            ),
          ],
        ),
      );
    });
  }
}

class _MemberGrid extends StatefulWidget {
  const _MemberGrid({required this.compact});

  final bool compact;

  @override
  State<_MemberGrid> createState() => _MemberGridState();
}

class _MemberGridState extends State<_MemberGrid> {
  final LiveBroadcastController controller =
      Get.find<LiveBroadcastController>();

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final seats = _buildSeats();
      final canToggle = seats.length > 10;
      final visibleSeats = canToggle && !_expanded
          ? seats.take(10).toList()
          : seats;

      return LayoutBuilder(
        builder: (context, constraints) {
          const crossAxisCount = 3;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleSeats.length + (canToggle ? 1 : 0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisExtent: widget.compact ? 136 : 144,
              mainAxisSpacing: widget.compact ? 8 : 10,
              crossAxisSpacing: widget.compact ? 4 : 8,
            ),
            itemBuilder: (context, index) {
              if (canToggle && index == visibleSeats.length) {
                return _SeatToggle(
                  expanded: _expanded,
                  hiddenCount: seats.length - visibleSeats.length,
                  onTap: () => setState(() => _expanded = !_expanded),
                );
              }
              final seat = visibleSeats[index];
              if (seat.locked) return _LockedSeat(seatNo: seat.seatNo);
              if (!seat.occupied) return _GridEmptySeat(seatNo: seat.seatNo);
              return _MemberSeat(seat: seat);
            },
          );
        },
      );
    });
  }

  List<_AudioSeatData> _buildSeats() {
    final hostName = controller.hostName.value.isEmpty
        ? 'Host'
        : controller.hostName.value;
    final seats = <_AudioSeatData>[
      _AudioSeatData(
        seatNo: 1,
        name: hostName,
        avatarUrl: controller.hostAvatarUrl.value,
        occupied: true,
        level: 28,
        isHost: true,
      ),
    ];
    var seatNo = 2;

    while (seatNo <= 5) {
      seats.add(_AudioSeatData.empty(seatNo));
      seatNo++;
    }

    for (final viewer in controller.liveViewers) {
      if (seats.length >= 13) break;
      if (viewer['isHost'] == true) continue;
      seats.add(
        _AudioSeatData(
          seatNo: seatNo,
          name: viewer['name']?.toString() ?? 'Member',
          id: viewer['targetId']?.toString() ?? viewer['id']?.toString() ?? '',
          avatarUrl: viewer['avatarUrl']?.toString(),
          occupied: true,
          muted: seatNo % 5 == 0,
          level: 12 + seats.length,
        ),
      );
      seatNo++;
    }

    const preview = [
      ('Rahul', '785632', 23),
      ('Pooja', '847392', 21),
      ('Arjun', '765921', 19),
      ('Neha', '936471', 18),
      ('Vikash', '665738', 17),
      ('Anjali', '883910', 16),
      ('Karan', '629384', 15),
      ('Simran', '910273', 14),
    ];

    var previewIndex = 0;
    while (seats.length < 13 && previewIndex < preview.length) {
      final item = preview[previewIndex];
      seats.add(
        _AudioSeatData(
          seatNo: seatNo,
          name: item.$1,
          id: item.$2,
          occupied: true,
          muted: seatNo % 5 == 0,
          level: item.$3,
        ),
      );
      seatNo++;
      previewIndex++;
    }

    while (seats.length < 15) {
      seats.add(_AudioSeatData.empty(seatNo));
      seatNo++;
    }
    seats.add(_AudioSeatData.empty(seatNo).copyWith(locked: true, level: 20));
    return seats;
  }
}

class _MemberSeat extends StatelessWidget {
  const _MemberSeat({required this.seat});

  final _AudioSeatData seat;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 14),
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            _PremiumAvatarFrame(
              name: seat.name,
              imageUrl: seat.avatarUrl,
              muted: seat.muted,
              isHost: seat.isHost,
            ),
            Positioned(
              left: -8,
              top: -8,
              child: _SeatBadge(number: seat.seatNo),
            ),
            Positioned(
              right: -7,
              bottom: -5,
              child: _MicBubble(muted: seat.muted, small: true),
            ),
          ],
        ),
        Spacing.v6,
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            gradient: seat.isHost
                ? const LinearGradient(
                    colors: [kColorProfileFeatureBlue, kColorPrimary],
                  )
                : null,
            color: seat.isHost ? null : kColorWhite.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(10),
          ),
          child: SemiBoldText(
            text: seat.name,
            fontSize: TextStyles.k10FontSize,
            color: seat.isHost ? kColorWhite : AudioRoomStageOverlay._ink,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            align: TextAlign.center,
          ),
        ),
        _DiamondCount(value: seat.level),
      ],
    );
  }
}

class _PremiumAvatarFrame extends StatelessWidget {
  const _PremiumAvatarFrame({
    required this.name,
    required this.imageUrl,
    required this.muted,
    required this.isHost,
  });

  final String name;
  final String? imageUrl;
  final bool muted;
  final bool isHost;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: muted
            ? const LinearGradient(
                colors: [Color(0xFFB6A9BC), Color(0xFF74667C)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  kColorProfileFeatureBlue,
                  kColorProfileActionPinkStart,
                  kColorPrimary,
                ],
              ),
        boxShadow: [
          BoxShadow(
            color: (muted ? kColorHint : kColorProfileFeatureBlue).withValues(
              alpha: 0.24,
            ),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: AppUserAvatar(
        name: name,
        imageUrl: imageUrl,
        size: 74,
        border: Border.all(
          color: kColorWhite.withValues(alpha: 0.88),
          width: 2,
        ),
      ),
    );
  }
}

class _GridEmptySeat extends StatelessWidget {
  const _GridEmptySeat({required this.seatNo});

  final int seatNo;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 14),
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: kColorWhite.withValues(alpha: 0.72),
                shape: BoxShape.circle,
                border: Border.all(
                  color: kColorPrimary.withValues(alpha: 0.08),
                ),
              ),
              child: Icon(
                Icons.mic_none_rounded,
                color: kColorPrimary.withValues(alpha: 0.28),
                size: 36,
              ),
            ),
            Positioned(left: -8, top: -8, child: _SeatBadge(number: seatNo)),
            Positioned(
              right: -5,
              bottom: -5,
              child: Container(
                width: 30,
                height: 30,
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
                child: const Icon(
                  Icons.add_rounded,
                  color: kColorPrimary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        Spacing.v6,
        const SemiBoldText(
          text: 'Join',
          fontSize: TextStyles.k10FontSize,
          color: AudioRoomStageOverlay._muted,
          align: TextAlign.center,
        ),
      ],
    );
  }
}

class _LockedSeat extends StatelessWidget {
  const _LockedSeat({required this.seatNo});

  final int seatNo;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 14),
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: kColorWhite.withValues(alpha: 0.62),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_rounded,
                color: kColorPrimary.withValues(alpha: 0.36),
              ),
            ),
            Positioned(left: -8, top: -8, child: _SeatBadge(number: seatNo)),
          ],
        ),
        Spacing.v8,
        const AppText(
          text: 'Locked',
          fontSize: TextStyles.k10FontSize,
          color: AudioRoomStageOverlay._muted,
          align: TextAlign.center,
        ),
        const _DiamondCount(value: 20),
      ],
    );
  }
}

class _SeatToggle extends StatelessWidget {
  const _SeatToggle({
    required this.expanded,
    required this.hiddenCount,
    required this.onTap,
  });

  final bool expanded;
  final int hiddenCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 14),
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kColorProfileFeatureBlue, kColorPrimary],
              ),
              boxShadow: [
                BoxShadow(
                  color: kColorPrimary.withValues(alpha: 0.20),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Icon(
              expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: kColorWhite,
              size: 32,
            ),
          ),
          Spacing.v6,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: kColorWhite.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SemiBoldText(
              text: expanded ? 'Less' : '+$hiddenCount More',
              fontSize: TextStyles.k10FontSize,
              color: AudioRoomStageOverlay._ink,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              align: TextAlign.center,
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: kColorPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kColorPrimary.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: kColorWalletAmount),
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
        width: compact ? 34 : 38,
        height: compact ? 34 : 38,
        decoration: BoxDecoration(
          color: filled
              ? kColorPrimary.withValues(alpha: 0.08)
              : kColorPrimary.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(color: kColorPrimary.withValues(alpha: 0.08)),
        ),
        child: Icon(icon, color: kColorPrimary, size: compact ? 18 : 20),
      ),
    );
  }
}

class _SeatBadge extends StatelessWidget {
  const _SeatBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kColorProfileFeatureBlue, kColorPrimary],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: kColorWhite, width: 1.5),
      ),
      child: SemiBoldText(text: '$number', fontSize: 10, color: kColorWhite),
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
        color: muted ? const Color(0xFF6B6470) : kColorProfileFeatureBlue,
        shape: BoxShape.circle,
        border: Border.all(color: kColorWhite, width: 2),
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
        color: kColorPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.diamond_rounded, size: 13, color: kColorPrimary),
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

class _AudioSeatData {
  const _AudioSeatData({
    required this.seatNo,
    this.name = '',
    this.id = '',
    this.avatarUrl,
    this.level = 0,
    this.occupied = false,
    this.muted = false,
    this.locked = false,
    this.isHost = false,
  });

  factory _AudioSeatData.empty(int seatNo) => _AudioSeatData(seatNo: seatNo);

  final int seatNo;
  final String name;
  final String id;
  final String? avatarUrl;
  final int level;
  final bool occupied;
  final bool muted;
  final bool locked;
  final bool isHost;

  _AudioSeatData copyWith({bool? locked, int? level}) {
    return _AudioSeatData(
      seatNo: seatNo,
      name: name,
      id: id,
      avatarUrl: avatarUrl,
      level: level ?? this.level,
      occupied: occupied,
      muted: muted,
      locked: locked ?? this.locked,
      isHost: isHost,
    );
  }
}
