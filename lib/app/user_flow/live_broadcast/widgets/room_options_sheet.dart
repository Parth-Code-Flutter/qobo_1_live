import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/controllers/live_broadcast_controller.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';

enum _RoomOptionAction {
  filters,
  background,
  share,
  pkBattle,
  report,
  follow,
}

class _RoomOption {
  const _RoomOption({
    required this.action,
    required this.icon,
    required this.label,
    required this.color,
    required this.gradient,
  });

  final _RoomOptionAction action;
  final IconData icon;
  final String label;
  final Color color;
  final List<Color> gradient;
}

class RoomOptionsSheet extends StatelessWidget {
  final bool isHost;
  final bool isVideoRoom;

  const RoomOptionsSheet({
    super.key,
    required this.isHost,
    this.isVideoRoom = false,
  });

  List<_RoomOption> get _options {
    if (isHost) {
      return [
        if (isVideoRoom)
          const _RoomOption(
            action: _RoomOptionAction.filters,
            icon: Icons.auto_fix_high_rounded,
            label: 'Filters',
            color: Color(0xFFFF6AD5),
            gradient: [Color(0xFFE12BC5), Color(0xFF9B1FE8)],
          ),
        const _RoomOption(
          action: _RoomOptionAction.background,
          icon: Icons.image_rounded,
          label: 'Background',
          color: Color(0xFF7AD7FF),
          gradient: [Color(0xFF4FC3F7), Color(0xFF2979FF)],
        ),
        const _RoomOption(
          action: _RoomOptionAction.share,
          icon: Icons.ios_share_rounded,
          label: 'Share',
          color: Color(0xFFB8A4FF),
          gradient: [Color(0xFF9B7BFF), Color(0xFF6C4DFF)],
        ),
        const _RoomOption(
          action: _RoomOptionAction.pkBattle,
          icon: Icons.flash_on_rounded,
          label: 'PK Battle',
          color: Color(0xFFFFC857),
          gradient: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
        ),
      ];
    }

    return const [
      _RoomOption(
        action: _RoomOptionAction.report,
        icon: Icons.report_problem_rounded,
        label: 'Report',
        color: Color(0xFFFF6B7A),
        gradient: [Color(0xFFFF6B7A), Color(0xFFE53935)],
      ),
      _RoomOption(
        action: _RoomOptionAction.share,
        icon: Icons.ios_share_rounded,
        label: 'Share',
        color: Color(0xFFB8A4FF),
        gradient: [Color(0xFF9B7BFF), Color(0xFF6C4DFF)],
      ),
      _RoomOption(
        action: _RoomOptionAction.follow,
        icon: Icons.person_add_alt_1_rounded,
        label: 'Follow',
        color: Color(0xFFFF8FB8),
        gradient: [Color(0xFFFF8FB8), Color(0xFFFF4081)],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final options = _options;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(bottom: 24 + bottomInset),
        decoration: const BoxDecoration(
          color: Color(0xFF161622),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Spacing.v12,
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Spacing.v20,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final opt in options)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _onOptionTap(opt),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: opt.gradient,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: opt.color.withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                opt.icon,
                                color: kColorWhite,
                                size: 26,
                              ),
                            ),
                            Spacing.v8,
                            AppText(
                              text: opt.label,
                              fontSize: 11,
                              color: opt.color,
                              align: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onOptionTap(_RoomOption option) {
    Get.back();

    switch (option.action) {
      case _RoomOptionAction.pkBattle:
        _openPkBattle();
      case _RoomOptionAction.filters:
        _runAfterClose(
          () => Get.find<LiveBroadcastController>().openLiveFiltersSheet(),
        );
      case _RoomOptionAction.background:
        _runAfterClose(
          () => Get.find<LiveBroadcastController>().openRoomBackgroundSheet(),
        );
      case _RoomOptionAction.share:
        if (Get.isRegistered<LiveBroadcastController>()) {
          Get.find<LiveBroadcastController>().shareRoom();
        }
      case _RoomOptionAction.follow:
        if (Get.isRegistered<LiveBroadcastController>()) {
          Get.find<LiveBroadcastController>().toggleFollowHost();
        }
      case _RoomOptionAction.report:
        Get.snackbar(
          'Report',
          'Report flow coming soon.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black87,
          colorText: kColorWhite,
        );
    }
  }

  void _runAfterClose(VoidCallback action) {
    if (!Get.isRegistered<LiveBroadcastController>()) return;
    Future.delayed(const Duration(milliseconds: 120), action);
  }

  void _openPkBattle() {
    final liveController = Get.isRegistered<LiveBroadcastController>()
        ? Get.find<LiveBroadcastController>()
        : null;
    // PK APIs need the backend room id (with dashes), not the
    // sanitized Zego channel id used for call login.
    final roomId =
        (liveController?.audioRoomApiId.trim().isNotEmpty == true)
            ? liveController!.audioRoomApiId.trim()
            : (liveController?.roomId.value.trim() ?? '');
    if (roomId.isEmpty) {
      Get.snackbar(
        'PK Battle',
        'Room id is missing. Rejoin the room and try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: kColorWhite,
      );
      return;
    }
    Get.toNamed(
      Routes.PK_BATTLE,
      arguments: {
        'room_id': roomId,
        'title': liveController?.streamTitle.value ?? '',
        'name': liveController?.hostName.value ?? '',
      },
    );
  }
}
