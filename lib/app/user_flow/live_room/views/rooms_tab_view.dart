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
              Spacing.v16,
              _modeTabs(controller),
              Spacing.v12,
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
        height: 78,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kColorWhite.withValues(alpha: 0.16),
              kColorWhite.withValues(alpha: 0.07),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.14)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: kColorProfileActionPinkStart.withValues(alpha: 0.10),
              blurRadius: 22,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Row(
          children: [
            _modeTab(
              label: 'Audio',
              subtitle: _modeSubtitle(
                count: controller.audioRooms.length,
                isLoading: controller.isAudioRoomsLoading.value,
              ),
              icon: Icons.mic_rounded,
              selected: controller.isRoomsAudioMode,
              startColor: const Color(0xFF8C45FF),
              endColor: const Color(0xFFFF4EB8),
              onTap: () => controller.selectRoomsMode('audio'),
            ),
            _modeTab(
              label: 'Video',
              subtitle: _modeSubtitle(
                count: controller.videoRooms.length,
                isLoading: controller.isVideoRoomsLoading.value,
              ),
              icon: Icons.videocam_rounded,
              selected: controller.isRoomsVideoMode,
              startColor: const Color(0xFFFF6D48),
              endColor: const Color(0xFFFF2E7E),
              onTap: () => controller.selectRoomsMode('video'),
            ),
          ],
        ),
      ),
    );
  }

  String _modeSubtitle({required int count, required bool isLoading}) {
    if (isLoading) return 'Updating...';
    if (count == 0) return 'No rooms yet';
    return count == 1 ? '1 room live' : '$count rooms live';
  }

  Widget _modeTab({
    required String label,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required Color startColor,
    required Color endColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [startColor, endColor],
                  )
                : null,
            color: selected ? null : kColorWhite.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? kColorWhite.withValues(alpha: 0.30)
                  : kColorWhite.withValues(alpha: 0.06),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: endColor.withValues(alpha: 0.34),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? kColorWhite.withValues(alpha: 0.20)
                      : kColorWhite.withValues(alpha: 0.10),
                  border: Border.all(
                    color: kColorWhite.withValues(
                      alpha: selected ? 0.28 : 0.08,
                    ),
                  ),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: kColorWhite.withValues(alpha: selected ? 1 : 0.72),
                ),
              ),
              Spacing.h10,
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemiBoldText(
                      text: label,
                      fontSize: TextStyles.k14FontSize,
                      color: kColorWhite.withValues(alpha: selected ? 1 : 0.82),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacing.v2,
                    AppText(
                      text: subtitle,
                      fontSize: TextStyles.k10FontSize,
                      color: kColorWhite.withValues(
                        alpha: selected ? 0.78 : 0.48,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
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
