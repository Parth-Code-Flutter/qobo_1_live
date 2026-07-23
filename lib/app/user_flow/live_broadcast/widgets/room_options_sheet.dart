import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/controllers/live_broadcast_controller.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';

class RoomOptionsSheet extends StatelessWidget {
  final bool isHost;
  final bool isVideoRoom;

  const RoomOptionsSheet({
    super.key,
    required this.isHost,
    this.isVideoRoom = false,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> options = isHost
        ? [
            if (isVideoRoom)
              {
                'icon': Icons.auto_fix_high_rounded,
                'label': 'Filters',
                'color': const Color(0xFFE12BC5),
              },
            {
              'icon': Icons.wallpaper_rounded,
              'label': 'Background',
              'color': const Color(0xFF7AD7FF),
            },
            {
              'icon': Icons.mic_off_rounded,
              'label': 'Mute All',
              'color': kColorWhite,
            },
            {
              'icon': Icons.lock_outline_rounded,
              'label': 'Lock Room',
              'color': kColorWhite,
            },
            {
              'icon': Icons.pan_tool_rounded,
              'label': 'Clear Seats',
              'color': kColorWhite,
            },
            {
              'icon': Icons.share_rounded,
              'label': 'Share',
              'color': kColorWhite,
            },
            {
              'icon': Icons.bolt_rounded,
              'label': 'PK Battle',
              'color': Colors.amber,
            },
            {
              'icon': Icons.security_rounded,
              'label': 'Security SOS',
              'color': Colors.redAccent,
            },
          ]
        : [
            {
              'icon': Icons.report_problem_outlined,
              'label': 'Report',
              'color': Colors.redAccent,
            },
            {
              'icon': Icons.share_rounded,
              'label': 'Share',
              'color': kColorWhite,
            },
            {
              'icon': Icons.person_add_alt_1_rounded,
              'label': 'Follow',
              'color': kColorWhite,
            },
          ];

    return Container(
      padding: const EdgeInsets.only(bottom: 24),
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 24,
              runSpacing: 24,
              children: options.map((opt) {
                return GestureDetector(
                  onTap: () {
                    Get.back(); // close sheet
                    if (opt['label'] == 'PK Battle') {
                      final liveController =
                          Get.isRegistered<LiveBroadcastController>()
                          ? Get.find<LiveBroadcastController>()
                          : null;
                      // PK APIs need the backend room id (with dashes), not the
                      // sanitized Zego channel id used for call login.
                      final roomId = (liveController?.audioRoomApiId.trim().isNotEmpty ==
                              true)
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
                    } else if (opt['label'] == 'Filters') {
                      if (Get.isRegistered<LiveBroadcastController>()) {
                        Future.delayed(const Duration(milliseconds: 120), () {
                          Get.find<LiveBroadcastController>()
                              .openLiveFiltersSheet();
                        });
                      }
                    } else if (opt['label'] == 'Background') {
                      if (Get.isRegistered<LiveBroadcastController>()) {
                        Future.delayed(const Duration(milliseconds: 120), () {
                          Get.find<LiveBroadcastController>()
                              .openRoomBackgroundSheet();
                        });
                      }
                    } else if (opt['label'] == 'Share') {
                      if (Get.isRegistered<LiveBroadcastController>()) {
                        Get.find<LiveBroadcastController>().shareRoom();
                      }
                    } else if (opt['label'] == 'Follow') {
                      if (Get.isRegistered<LiveBroadcastController>()) {
                        Get.find<LiveBroadcastController>().toggleFollowHost();
                      }
                    } else {
                      Get.snackbar(
                        'Action',
                        'Triggered ${opt['label']} action',
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: Colors.black.withValues(alpha: 0.8),
                        colorText: kColorWhite,
                      );
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(opt['icon'], color: opt['color'], size: 24),
                      ),
                      Spacing.v8,
                      AppText(
                        text: opt['label'],
                        fontSize: 11,
                        color: opt['color'],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
