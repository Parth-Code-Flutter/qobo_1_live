import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/live_room_controller.dart';
import '../widgets/audio_room_grid_view.dart';
import '../widgets/video_room_list_view.dart';

class RoomsTabView extends StatelessWidget {
  const RoomsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController();

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage(kImgBG), fit: BoxFit.cover),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(controller),
              Spacing.v12,
              _modeTabs(controller),
              Spacing.v10,
              Expanded(
                child: Obx(() {
                  if (controller.isRoomsVideoMode) {
                    return VideoRoomListView(
                      rooms: controller.videoRooms,
                      isLoading: controller.isVideoRoomsLoading.value,
                      onCreateVideoRoom: controller.openCreateVideoRoom,
                      onRefresh: controller.fetchVideoRooms,
                      showCreatePanel: false,
                      onJoinLive: (room) =>
                          controller.joinTypedRoom(context, room),
                    );
                  }
                  return AudioRoomGridView(
                    rooms: controller.audioRooms,
                    isLoading: controller.isAudioRoomsLoading.value,
                    onCreateAudioRoom: controller.openCreateAudioRoom,
                    onRefresh: controller.fetchAudioRooms,
                    showCreatePanel: false,
                    onJoinRoom: (room) =>
                        controller.joinTypedRoom(context, room),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(LiveRoomController controller) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SemiBoldText(
                text: 'Rooms',
                fontSize: TextStyles.k24FontSize,
                color: kColorWhite,
              ),
              AppText(
                text: 'Browse audio and video rooms',
                fontSize: TextStyles.k12FontSize,
                color: kColorHint,
              ),
            ],
          ),
        ),
        _createButton(controller),
      ],
    );
  }

  Widget _modeTabs(LiveRoomController controller) {
    return Obx(
      () => Container(
        height: 46,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: kColorWhite.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.10)),
        ),
        child: Row(
          children: [
            _modeTab(
              label: 'Audio',
              icon: Icons.mic_rounded,
              selected: controller.isRoomsAudioMode,
              onTap: () => controller.selectRoomsMode('audio'),
            ),
            _modeTab(
              label: 'Video',
              icon: Icons.videocam_rounded,
              selected: controller.isRoomsVideoMode,
              onTap: () => controller.selectRoomsMode('video'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeTab({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF8C45FF), Color(0xFFFF4EB8)],
                  )
                : null,
            color: selected ? null : kColorWhite.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? kColorWhite.withValues(alpha: 0.22)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: kColorWhite.withValues(alpha: selected ? 1 : 0.72),
              ),
              Spacing.h6,
              SemiBoldText(
                text: label,
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite.withValues(alpha: selected ? 1 : 0.78),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _createButton(LiveRoomController controller) {
    return GestureDetector(
      onTap: controller.openCreateSelectedRoom,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF2C4D), Color(0xFFFF7A45)],
          ),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF3651).withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: kColorWhite, size: 26),
      ),
    );
  }

  LiveRoomController _resolveController() {
    if (Get.isRegistered<LiveRoomController>()) {
      return Get.find<LiveRoomController>();
    }
    return Get.put(LiveRoomController());
  }
}
