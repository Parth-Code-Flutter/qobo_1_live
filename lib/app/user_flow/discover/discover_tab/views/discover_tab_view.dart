import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/ui_utils/app_ui_utils.dart';

import '../controllers/discover_tab_controller.dart';
import '../models/discover_room_selection.dart';
import '../widgets/discover_audio_room_view.dart';
import '../widgets/discover_video_room_view.dart';

class DiscoverTabView extends StatelessWidget {
  const DiscoverTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final discoverController = _resolveController();
    final userSession = _resolveUserSession();

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
              _topHeader(userSession),
              Spacing.v16,
              _searchBar(discoverController),
              Spacing.v12,
              Obx(() {
                if (discoverController.searchQuery.value.isNotEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  children: [_roomModeRow(discoverController), Spacing.v16],
                );
              }),
              Expanded(
                child: Obx(() {
                  if (discoverController.searchQuery.value.isNotEmpty) {
                    return _searchResultsList(context, discoverController);
                  }

                  switch (discoverController.roomSelection.value) {
                    case DiscoverRoomSelection.video:
                      return DiscoverVideoRoomView(
                        rooms: discoverController.videoRooms,
                        isLoading: discoverController.isVideoRoomsLoading.value,
                        onJoinLive: (room) =>
                            discoverController.joinLiveRoom(context, room),
                      );
                    case DiscoverRoomSelection.audio:
                      return DiscoverAudioRoomView(
                        rooms: discoverController.audioRooms,
                        isLoading: discoverController.isAudioRoomsLoading.value,
                      );
                    case DiscoverRoomSelection.none:
                      return _defaultDiscoverFeed(
                        controller: discoverController,
                      );
                  }
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Header row (real profile image/name + location) matching Figma.
  Widget _topHeader(UserSessionController userSession) {
    return GetBuilder<UserSessionController>(
      init: userSession,
      builder: (session) {
        final avatarUrl = session.displayPictureUrl;
        return Row(
          children: [
            Container(
              width: 30,
              height: 30,
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: kColorWhite, width: 1),
              ),
              child: ClipOval(
                child: avatarUrl == null
                    ? _initialsAvatar(session.initials)
                    : Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _initialsAvatar(session.initials),
                      ),
              ),
            ),
            Spacing.h10,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SemiBoldText(
                    text: 'EXPLORE',
                    fontSize: TextStyles.k24FontSize - 2,
                    color: kColorWhite,
                  ),
                  AppText(
                    text: session.displayName,
                    fontSize: TextStyles.k10FontSize,
                    color: kColorWhite.withValues(alpha: 0.9),
                    align: TextAlign.center,
                  ),
                ],
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: kColorWhite,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Center(
                child: SvgPicture.asset(
                  kIconFilter,
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    kColorPrimary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _searchBar(DiscoverTabController discoverController) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: kColorDiscoverSearchBg,
        borderRadius: AppUIUtils.primaryBorderRadius,
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 16, color: kColorHint),
          Spacing.h6,
          Expanded(
            child: TextField(
              controller: discoverController.searchController,
              textInputAction: TextInputAction.search,
              style: TextStyles.kRegularPoppins(
                fontSize: TextStyles.k12FontSize,
                colors: kColorText,
              ),
              cursorColor: kColorPrimary,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search',
                hintStyle: TextStyles.kRegularPoppins(
                  fontSize: TextStyles.k12FontSize,
                  colors: kColorHint,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roomModeRow(DiscoverTabController controller) {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: _modeChip(
              icon: Icons.videocam_outlined,
              label: DiscoverVideoRoomView.roomLabel,
              isSelected:
                  controller.roomSelection.value == DiscoverRoomSelection.video,
              onTap: controller.selectVideoRoom,
            ),
          ),
          Spacing.h12,
          Expanded(
            child: _modeChip(
              icon: Icons.graphic_eq_rounded,
              label: DiscoverAudioRoomView.roomLabel,
              isSelected:
                  controller.roomSelection.value == DiscoverRoomSelection.audio,
              onTap: controller.selectAudioRoom,
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultDiscoverFeed({required DiscoverTabController controller}) {
    return const SizedBox.shrink();
  }

  Widget _modeChip({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? kColorDiscoverChip : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? kColorDiscoverModeBorder.withValues(alpha: 0.75)
                : kColorWhite.withValues(alpha: 0.9),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: kColorWhite),
            Spacing.h8,
            SemiBoldText(
              text: label,
              fontSize: TextStyles.k24FontSize - 11,
              color: kColorWhite,
            ),
          ],
        ),
      ),
    );
  }

  UserSessionController _resolveUserSession() {
    if (Get.isRegistered<UserSessionController>()) {
      return Get.find<UserSessionController>();
    }
    return Get.put(UserSessionController(), permanent: true);
  }

  DiscoverTabController _resolveController() {
    if (Get.isRegistered<DiscoverTabController>()) {
      return Get.find<DiscoverTabController>();
    }
    return Get.put(DiscoverTabController());
  }

  Widget _initialsAvatar(String initials) {
    return ColoredBox(
      color: kColorAvatarFallbackBg,
      child: Center(
        child: SemiBoldText(
          text: initials,
          fontSize: TextStyles.k12FontSize,
          color: kColorWhite,
        ),
      ),
    );
  }

  Widget _searchResultsList(
    BuildContext context,
    DiscoverTabController controller,
  ) {
    if (controller.isSearchLoading.value) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(kColorPrimary),
        ),
      );
    }

    if (controller.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              color: kColorWhite.withValues(alpha: 0.5),
              size: 48,
            ),
            Spacing.v12,
            AppText(
              text: 'No users found matching "${controller.searchQuery.value}"',
              fontSize: TextStyles.k14FontSize,
              color: kColorWhite.withValues(alpha: 0.7),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24, top: 8),
      itemCount: controller.searchResults.length,
      separatorBuilder: (_, __) =>
          const Divider(color: kColorDiscoverSearchBg, height: 1),
      itemBuilder: (context, index) {
        final user = controller.searchResults[index];
        final String name = user['name']?.toString() ?? 'User';
        final String? avatar = user['displayPicture']?.toString();
        final String id = user['id']?.toString() ?? '';

        final isFollowing = controller.followingUserIds.contains(id);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: kColorWhite.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: ClipOval(
                  child: avatar == null || avatar.isEmpty
                      ? _initialsAvatar(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        )
                      : Image.network(
                          ApiImageUtils.normalize(avatar) ?? avatar,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _initialsAvatar(
                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          ),
                        ),
                ),
              ),
              Spacing.h12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemiBoldText(
                      text: name,
                      fontSize: TextStyles.k16FontSize,
                      color: kColorWhite,
                    ),
                    Spacing.v2,
                    AppText(
                      text: 'ID: ${id.length > 8 ? id.substring(0, 8) : id}',
                      fontSize: TextStyles.k12FontSize,
                      color: kColorWhite.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => controller.toggleFollow(context, id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: isFollowing
                        ? null
                        : LinearGradient(
                            colors: [
                              kColorProfileActionPinkStart,
                              kColorProfileActionOrangeEnd,
                            ],
                          ),
                    color: isFollowing ? Colors.transparent : null,
                    borderRadius: BorderRadius.circular(20),
                    border: isFollowing
                        ? Border.all(
                            color: kColorWhite.withValues(alpha: 0.5),
                            width: 1,
                          )
                        : null,
                  ),
                  child: SemiBoldText(
                    text: isFollowing ? 'Following' : 'Follow',
                    fontSize: TextStyles.k12FontSize,
                    color: kColorWhite,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
