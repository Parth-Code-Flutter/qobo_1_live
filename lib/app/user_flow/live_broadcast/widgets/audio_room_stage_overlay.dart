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

  static const _surfaceStrong = Color(0xFFFFFFFF);
  static const _ink = Color(0xFF21172C);
  static const _muted = Color(0xFF6C6074);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3B0D45), Color(0xFF761B65), Color(0xFFF7F2FA)],
          stops: [0, 0.22, 0.46],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 390;
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                compact ? 12 : 16,
                10,
                compact ? 12 : 16,
                18,
              ),
              child: Column(
                children: [
                  _RoomHeader(compact: compact),
                  const SizedBox(height: 14),
                  _AnnouncementRow(compact: compact),
                  const SizedBox(height: 18),
                  _SeatStage(compact: compact),
                  Spacing.v16,
                  _ChatPreview(compact: compact),
                ],
              ),
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
      final roomId = controller.roomId.value;
      final title = controller.streamTitle.value.isNotEmpty
          ? controller.streamTitle.value
          : 'Audio Room';

      return Container(
        padding: EdgeInsets.all(compact ? 10 : 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kColorPrimary, kColorBottomNav],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: kColorPrimary.withValues(alpha: 0.26),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            _RoundIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: controller.leaveRoom,
              compact: compact,
              filled: false,
            ),
            Spacing.h10,
            AppUserAvatar(
              name: controller.hostName.value,
              imageUrl: controller.hostAvatarUrl.value,
              size: compact ? 50 : 58,
              border: Border.all(
                color: kColorWhite.withValues(alpha: 0.9),
                width: 2,
              ),
            ),
            Spacing.h10,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: SemiBoldText(
                          text: title,
                          fontSize: compact
                              ? TextStyles.k14FontSize
                              : TextStyles.k16FontSize,
                          color: kColorWhite,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Spacing.h6,
                      Icon(
                        Icons.edit_square,
                        size: compact ? 15 : 17,
                        color: kColorWhite.withValues(alpha: 0.86),
                      ),
                    ],
                  ),
                  Spacing.v4,
                  Row(
                    children: [
                      Flexible(
                        child: AppText(
                          text: 'Room ID: $roomId',
                          fontSize: TextStyles.k12FontSize,
                          color: kColorWhite.withValues(alpha: 0.82),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Spacing.h6,
                      Icon(
                        Icons.copy_rounded,
                        size: compact ? 14 : 16,
                        color: kColorWhite.withValues(alpha: 0.78),
                      ),
                    ],
                  ),
                  Spacing.v6,
                  Row(
                    children: [
                      _HeaderMetric(
                        icon: Icons.local_fire_department_rounded,
                        label: controller.likesLabel.value,
                      ),
                      Spacing.h8,
                      _HeaderMetric(
                        icon: Icons.group_rounded,
                        label: '${controller.viewerCount.value}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Spacing.h8,
            _RoundIconButton(
              icon: Icons.ios_share_rounded,
              onTap: controller.shareRoom,
              compact: compact,
            ),
            Spacing.h8,
            _RoundIconButton(
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

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            text: label.isEmpty ? '0' : label,
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite,
          ),
        ],
      ),
    );
  }
}

class _AnnouncementRow extends GetView<LiveBroadcastController> {
  const _AnnouncementRow({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: compact ? 42 : 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AudioRoomStageOverlay._surfaceStrong.withValues(
                alpha: 0.94,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kColorPrimary.withValues(alpha: 0.10)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.campaign_rounded,
                  color: kColorPrimary,
                  size: 20,
                ),
                Spacing.h8,
                Expanded(
                  child: AppText(
                    text: 'Announcement: Enjoy the talk and be respectful...',
                    fontSize: TextStyles.k12FontSize,
                    color: AudioRoomStageOverlay._ink,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AudioRoomStageOverlay._muted,
                ),
              ],
            ),
          ),
        ),
        Spacing.h10,
        _PillAction(icon: Icons.settings_rounded, label: 'Room Set'),
        Spacing.h8,
        _PillAction(icon: Icons.emoji_events_rounded, label: 'Ranking'),
      ],
    );
  }
}

class _SeatStage extends GetView<LiveBroadcastController> {
  const _SeatStage({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final seats = _buildSeats();
      final seatSize = compact ? 74.0 : 82.0;
      final hostSize = compact ? 126.0 : 144.0;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _EmptySeat(seatNo: 2, size: seatSize)),
                    Spacing.h8,
                    Expanded(child: _EmptySeat(seatNo: 3, size: seatSize)),
                    Spacing.h10,
                    SizedBox(
                      width: hostSize,
                      child: _HostSeat(
                        name: controller.hostName.value,
                        avatarUrl: controller.hostAvatarUrl.value,
                        roomId: controller.receiverId.value.isNotEmpty
                            ? controller.receiverId.value
                            : controller.roomId.value,
                      ),
                    ),
                    Spacing.h10,
                    Expanded(child: _EmptySeat(seatNo: 4, size: seatSize)),
                    Spacing.h8,
                    Expanded(child: _EmptySeat(seatNo: 5, size: seatSize)),
                  ],
                ),
                const SizedBox(height: 18),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 11,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: compact ? 3 : 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: compact ? 0.78 : 0.82,
                  ),
                  itemBuilder: (context, index) {
                    final seat = seats[index + 5];
                    if (seat.locked) return _LockedSeat(seatNo: seat.seatNo);
                    if (!seat.occupied) {
                      return _EmptySeat(seatNo: seat.seatNo, size: seatSize);
                    }
                    return _MemberSeat(seat: seat);
                  },
                ),
              ],
            ),
          ),
          Spacing.h10,
          _SideRail(compact: compact),
        ],
      );
    });
  }

  List<_AudioSeatData> _buildSeats() {
    final seats = List.generate(16, (index) => _AudioSeatData.empty(index + 1));
    seats[0] = _AudioSeatData(
      seatNo: 1,
      name: controller.hostName.value,
      id: controller.receiverId.value,
      avatarUrl: controller.hostAvatarUrl.value,
      level: 28,
      occupied: true,
      host: true,
    );

    var cursor = 5;
    for (final viewer in controller.liveViewers) {
      if (cursor >= 15) break;
      if (viewer['isHost'] == true) continue;
      seats[cursor] = _AudioSeatData(
        seatNo: cursor + 1,
        name: viewer['name']?.toString() ?? 'Member',
        id: viewer['targetId']?.toString() ?? viewer['id']?.toString() ?? '',
        avatarUrl: viewer['avatarUrl']?.toString(),
        level: 12 + cursor,
        occupied: true,
        muted: cursor % 4 == 2,
      );
      cursor++;
    }

    // UI-only preview seats keep the room lively before real members join.
    final preview = [
      ('Rahul', '785632', 23),
      ('Pooja', '847392', 21),
      ('Arjun', '765921', 19),
      ('Neha', '936471', 18),
      ('Vikash', '665738', 17),
      ('Anjali', '883910', 16),
      ('Karan', '629384', 15),
      ('Simran', '910273', 14),
      ('Rohit', '772910', 13),
      ('Divya', '883112', 12),
    ];
    var previewIndex = 0;
    while (cursor < 15 && previewIndex < preview.length) {
      final item = preview[previewIndex];
      seats[cursor] = _AudioSeatData(
        seatNo: cursor + 1,
        name: item.$1,
        id: item.$2,
        level: item.$3,
        occupied: true,
        muted: cursor % 5 == 0,
      );
      cursor++;
      previewIndex++;
    }

    seats[15] = _AudioSeatData.empty(16).copyWith(locked: true, level: 20);
    return seats;
  }
}

class _HostSeat extends StatelessWidget {
  const _HostSeat({
    required this.name,
    required this.avatarUrl,
    required this.roomId,
  });

  final String name;
  final String? avatarUrl;
  final String roomId;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [kColorProfileActionPinkStart, kColorPrimary],
                ),
                boxShadow: [
                  BoxShadow(
                    color: kColorPrimary.withValues(alpha: 0.30),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
            ),
            AppUserAvatar(
              name: name,
              imageUrl: avatarUrl,
              size: 92,
              border: Border.all(color: kColorWhite, width: 4),
            ),
            const Positioned(
              top: -12,
              child: Icon(
                Icons.workspace_premium_rounded,
                color: kColorWalletAmount,
                size: 38,
              ),
            ),
            Positioned(right: 4, bottom: 8, child: _MicBubble(muted: false)),
            const Positioned(left: 4, top: 4, child: _SeatBadge(number: 1)),
          ],
        ),
        Transform.translate(
          offset: const Offset(0, -7),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kColorProfileFeatureBlue, kColorPrimary],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const SemiBoldText(
              text: 'Host',
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite,
            ),
          ),
        ),
        SemiBoldText(
          text: name.isEmpty ? 'Host' : name,
          fontSize: TextStyles.k12FontSize,
          color: AudioRoomStageOverlay._ink,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          align: TextAlign.center,
        ),
        AppText(
          text: 'ID: ${roomId.isEmpty ? '000000' : roomId}',
          fontSize: TextStyles.k10FontSize,
          color: AudioRoomStageOverlay._muted,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const _DiamondCount(value: 28),
      ],
    );
  }
}

class _MemberSeat extends StatelessWidget {
  const _MemberSeat({required this.seat});

  final _AudioSeatData seat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 7),
      decoration: BoxDecoration(
        color: AudioRoomStageOverlay._surfaceStrong.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kColorPrimary.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AppUserAvatar(
                name: seat.name,
                imageUrl: seat.avatarUrl,
                size: 58,
                border: Border.all(
                  color: kColorPrimary.withValues(alpha: 0.16),
                  width: 2,
                ),
              ),
              Positioned(
                left: -10,
                top: -8,
                child: _SeatBadge(number: seat.seatNo),
              ),
              Positioned(
                right: -6,
                bottom: -4,
                child: _MicBubble(muted: seat.muted),
              ),
              Positioned(
                right: -8,
                top: -7,
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: seat.muted ? kColorHint : kColorProfileFeatureBlue,
                  size: 20,
                ),
              ),
            ],
          ),
          Spacing.v8,
          SemiBoldText(
            text: seat.name,
            fontSize: TextStyles.k12FontSize,
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
          ),
          _DiamondCount(value: seat.level),
        ],
      ),
    );
  }
}

class _EmptySeat extends StatelessWidget {
  const _EmptySeat({required this.seatNo, required this.size});

  final int seatNo;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size * 1.32,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AudioRoomStageOverlay._surfaceStrong.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kColorPrimary.withValues(alpha: 0.05)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(left: 0, top: 0, child: _SeatBadge(number: seatNo)),
          Icon(
            Icons.mic_rounded,
            color: kColorPrimary.withValues(alpha: 0.26),
            size: 34,
          ),
          Positioned(
            bottom: 0,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: kColorWhite,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kColorPrimary.withValues(alpha: 0.18),
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
    );
  }
}

class _LockedSeat extends StatelessWidget {
  const _LockedSeat({required this.seatNo});

  final int seatNo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AudioRoomStageOverlay._surfaceStrong.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SeatBadge(number: seatNo),
          Spacing.v8,
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFF0E8F6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_rounded,
              color: kColorPrimary.withValues(alpha: 0.42),
            ),
          ),
          Spacing.v8,
          const SemiBoldText(
            text: 'Locked Seat',
            fontSize: TextStyles.k10FontSize,
            color: AudioRoomStageOverlay._ink,
            align: TextAlign.center,
          ),
          const AppText(
            text: 'Unlock to join',
            fontSize: 9,
            color: AudioRoomStageOverlay._muted,
            align: TextAlign.center,
          ),
          const _DiamondCount(value: 20),
        ],
      ),
    );
  }
}

class _SideRail extends GetView<LiveBroadcastController> {
  const _SideRail({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 62 : 72,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AudioRoomStageOverlay._surfaceStrong.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: kColorPrimary.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _RailAction(
            icon: Icons.person_add_alt_1_rounded,
            label: 'Invite',
            onTap: controller.shareRoom,
          ),
          _RailAction(
            icon: Icons.music_note_rounded,
            label: 'Music',
            onTap: () => Get.snackbar('Music', 'Music panel coming soon.'),
          ),
          _RailAction(
            icon: Icons.card_giftcard_rounded,
            label: 'Gift',
            onTap: controller.openGiftsSheet,
          ),
          _RailAction(
            icon: Icons.chat_bubble_rounded,
            label: 'Chat',
            onTap: () => Get.snackbar('Chat', 'Use the room chat below.'),
          ),
          _RailAction(
            icon: Icons.queue_music_rounded,
            label: 'Queue',
            onTap: controller.openViewersSheet,
          ),
        ],
      ),
    );
  }
}

class _ChatPreview extends GetView<LiveBroadcastController> {
  const _ChatPreview({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final messages = controller.chatMessages.take(3).toList();
      final rows = messages.isEmpty
          ? const [
              ('Rahul', 'Hello everyone 👋'),
              ('Pooja', 'sent Rose 🌹 x1'),
              ('Arjun', 'Nice song 🎶'),
            ]
          : messages
                .map(
                  (message) => (
                    message['sender']?.toString() ?? 'User',
                    message['message']?.toString() ?? '',
                  ),
                )
                .toList();

      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AudioRoomStageOverlay._surfaceStrong.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: kColorPrimary.withValues(alpha: 0.06)),
          ),
          child: Column(
            children: rows.map((row) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    AppUserAvatar(name: row.$1, size: 28),
                    Spacing.h8,
                    SemiBoldText(
                      text: '${row.$1}:',
                      fontSize: TextStyles.k12FontSize,
                      color: kColorPrimary,
                    ),
                    Spacing.h6,
                    Expanded(
                      child: AppText(
                        text: row.$2,
                        fontSize: TextStyles.k12FontSize,
                        color: AudioRoomStageOverlay._ink,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      );
    });
  }
}

class _PillAction extends StatelessWidget {
  const _PillAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AudioRoomStageOverlay._surfaceStrong.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kColorPrimary.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kColorPrimary, size: 18),
          Spacing.h6,
          SemiBoldText(
            text: label,
            fontSize: TextStyles.k10FontSize,
            color: AudioRoomStageOverlay._ink,
          ),
        ],
      ),
    );
  }
}

class _RailAction extends StatelessWidget {
  const _RailAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: kColorPrimary, size: 24),
            Spacing.v4,
            AppText(
              text: label,
              fontSize: 9,
              color: AudioRoomStageOverlay._ink,
              align: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
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
        width: compact ? 38 : 44,
        height: compact ? 38 : 44,
        decoration: BoxDecoration(
          color: filled
              ? kColorWhite.withValues(alpha: 0.95)
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
  const _MicBubble({required this.muted});

  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: muted ? const Color(0xFF6B6470) : kColorProfileFeatureBlue,
        shape: BoxShape.circle,
        border: Border.all(color: kColorWhite, width: 2),
      ),
      child: Icon(
        muted ? Icons.mic_off_rounded : Icons.mic_rounded,
        color: kColorWhite,
        size: 17,
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
    this.host = false,
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
  final bool host;
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
      host: host,
      muted: muted,
      locked: locked ?? this.locked,
    );
  }
}
