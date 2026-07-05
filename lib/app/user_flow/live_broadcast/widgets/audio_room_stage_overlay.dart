import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

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
          colors: [Color(0xFF3B0D45), Color(0xFF8D2578), Color(0xFFF7F1FA)],
          stops: [0, 0.28, 0.58],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 390;
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 12 : 16,
                    10,
                    compact ? 12 : 16,
                    18,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate.fixed([
                      _RoomHeader(compact: compact),
                      SizedBox(height: compact ? 18 : 22),
                      _CenterStage(compact: compact),
                      SizedBox(height: compact ? 16 : 18),
                      _MemberGrid(compact: compact),
                    ]),
                  ),
                ),
              ],
            );
          },
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
      final roomId = controller.roomId.value;

      return Container(
        padding: EdgeInsets.all(compact ? 12 : 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kColorPrimary, Color(0xFF4B0B3D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: kColorPrimary.withValues(alpha: 0.24),
              blurRadius: 20,
              offset: const Offset(0, 10),
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
            AppUserAvatar(
              name: controller.hostName.value,
              imageUrl: controller.hostAvatarUrl.value,
              size: compact ? 48 : 56,
              border: Border.all(color: kColorWhite, width: 2),
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
                    color: kColorWhite,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Spacing.v4,
                  AppText(
                    text: 'Room ID: ${roomId.isEmpty ? '--' : roomId}',
                    fontSize: TextStyles.k10FontSize,
                    color: kColorWhite.withValues(alpha: 0.78),
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

class _CenterStage extends GetView<LiveBroadcastController> {
  const _CenterStage({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hostName = controller.hostName.value.isEmpty
          ? 'Host'
          : controller.hostName.value;
      final hostId = controller.receiverId.value.isNotEmpty
          ? controller.receiverId.value
          : controller.roomId.value;

      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 12 : 16,
        ),
        decoration: BoxDecoration(
          color: kColorWhite.withValues(alpha: 0.80),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: kColorPrimary.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _MiniEmptySeat(seatNo: 2, compact: compact)),
                Spacing.h6,
                Expanded(child: _MiniEmptySeat(seatNo: 3, compact: compact)),
                SizedBox(width: compact ? 8 : 12),
                _HostSeat(
                  name: hostName,
                  avatarUrl: controller.hostAvatarUrl.value,
                  hostId: hostId,
                  compact: compact,
                ),
                SizedBox(width: compact ? 8 : 12),
                Expanded(child: _MiniEmptySeat(seatNo: 4, compact: compact)),
                Spacing.h6,
                Expanded(child: _MiniEmptySeat(seatNo: 5, compact: compact)),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _MemberGrid extends GetView<LiveBroadcastController> {
  const _MemberGrid({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final seats = _buildSeats();
      final crossAxisCount = compact ? 4 : 4;

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: seats.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: compact ? 12 : 14,
          crossAxisSpacing: compact ? 8 : 12,
          childAspectRatio: compact ? 0.70 : 0.74,
        ),
        itemBuilder: (context, index) {
          final seat = seats[index];
          if (seat.locked) return _LockedSeat(seatNo: seat.seatNo);
          if (!seat.occupied) return _GridEmptySeat(seatNo: seat.seatNo);
          return _MemberSeat(seat: seat);
        },
      );
    });
  }

  List<_AudioSeatData> _buildSeats() {
    final seats = <_AudioSeatData>[];
    var seatNo = 6;

    for (final viewer in controller.liveViewers) {
      if (seats.length >= 8) break;
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
    while (seats.length < 8 && previewIndex < preview.length) {
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

    while (seats.length < 10) {
      seats.add(_AudioSeatData.empty(seatNo));
      seatNo++;
    }
    seats.add(_AudioSeatData.empty(seatNo).copyWith(locked: true, level: 20));
    return seats;
  }
}

class _HostSeat extends StatelessWidget {
  const _HostSeat({
    required this.name,
    required this.avatarUrl,
    required this.hostId,
    required this.compact,
  });

  final String name;
  final String? avatarUrl;
  final String hostId;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final avatarSize = compact ? 92.0 : 108.0;
    final ringSize = compact ? 122.0 : 140.0;

    return SizedBox(
      width: compact ? 142 : 166,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: ringSize,
                height: ringSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [kColorProfileActionPinkStart, kColorPrimary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kColorPrimary.withValues(alpha: 0.26),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ),
              AppUserAvatar(
                name: name,
                imageUrl: avatarUrl,
                size: avatarSize,
                border: Border.all(color: kColorWhite, width: 4),
              ),
              const Positioned(
                top: -10,
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: kColorWalletAmount,
                  size: 38,
                ),
              ),
              const Positioned(left: 8, top: 4, child: _SeatBadge(number: 1)),
              const Positioned(right: 8, bottom: 10, child: _MicBubble()),
            ],
          ),
          Transform.translate(
            offset: const Offset(0, -8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kColorProfileFeatureBlue, kColorPrimary],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const SemiBoldText(
                text: 'Host',
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite,
              ),
            ),
          ),
          SemiBoldText(
            text: name,
            fontSize: TextStyles.k14FontSize,
            color: AudioRoomStageOverlay._ink,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            align: TextAlign.center,
          ),
          Spacing.v2,
          AppText(
            text: 'ID: ${hostId.isEmpty ? '000000' : hostId}',
            fontSize: TextStyles.k10FontSize,
            color: AudioRoomStageOverlay._muted,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            align: TextAlign.center,
          ),
          const _DiamondCount(value: 28),
        ],
      ),
    );
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
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            AppUserAvatar(
              name: seat.name,
              imageUrl: seat.avatarUrl,
              size: 58,
              border: Border.all(
                color: kColorPrimary.withValues(alpha: 0.14),
                width: 2,
              ),
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
        Spacing.v8,
        SemiBoldText(
          text: seat.name,
          fontSize: TextStyles.k10FontSize,
          color: AudioRoomStageOverlay._ink,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          align: TextAlign.center,
        ),
        AppText(
          text: 'ID: ${seat.id.isEmpty ? seat.seatNo : seat.id}',
          fontSize: 9,
          color: AudioRoomStageOverlay._muted,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          align: TextAlign.center,
        ),
        _DiamondCount(value: seat.level),
      ],
    );
  }
}

class _MiniEmptySeat extends StatelessWidget {
  const _MiniEmptySeat({required this.seatNo, required this.compact});

  final int seatNo;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 92 : 108,
      constraints: const BoxConstraints(minWidth: 36),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kColorPrimary.withValues(alpha: 0.06)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(top: 7, left: 6, child: _SeatBadge(number: seatNo)),
          Icon(
            Icons.mic_rounded,
            color: kColorPrimary.withValues(alpha: 0.22),
            size: compact ? 28 : 32,
          ),
          Positioned(
            bottom: 8,
            child: Icon(
              Icons.add_rounded,
              color: kColorPrimary,
              size: compact ? 20 : 22,
            ),
          ),
        ],
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
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
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
                size: 28,
              ),
            ),
            Positioned(left: -8, top: -8, child: _SeatBadge(number: seatNo)),
          ],
        ),
        Spacing.v8,
        const AppText(
          text: 'Open',
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
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
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

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: kColorWalletAmount),
          Spacing.h4,
          AppText(
            text: label,
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite,
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
        width: compact ? 38 : 42,
        height: compact ? 38 : 42,
        decoration: BoxDecoration(
          color: filled
              ? kColorWhite.withValues(alpha: 0.96)
              : kColorWhite.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: filled ? kColorPrimary : kColorWhite,
          size: compact ? 20 : 22,
        ),
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
    final size = small ? 28.0 : 34.0;
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
        size: small ? 15 : 18,
      ),
    );
  }
}

class _DiamondCount extends StatelessWidget {
  const _DiamondCount({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.diamond_rounded, size: 13, color: kColorPrimary),
        Spacing.h4,
        AppText(text: '$value', fontSize: 9, color: AudioRoomStageOverlay._ink),
      ],
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
    );
  }
}
