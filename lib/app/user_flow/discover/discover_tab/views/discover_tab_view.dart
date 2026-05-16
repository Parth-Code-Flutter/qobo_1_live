import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
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
    const suggestedUsers = <({String name, String image})>[
      (name: 'Jessica', image: kImgTemp2),
      (name: 'Parth', image: kImgTemp3),
      (name: 'Jessica', image: kImgTemp4),
      (name: 'Parth', image: kImgTemp5),
    ];

    const trendingRooms = <({String title, String subtitle, String image})>[
      (
        title: 'Techno & Chill',
        subtitle: '1.2 k Lorium Ipsum',
        image: kImgTemp2,
      ),
      (
        title: 'Late Night Jazz Talk',
        subtitle: '1.2 k Lorium Ipsum',
        image: kImgTemp3,
      ),
    ];

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
              _roomModeRow(discoverController),
              Spacing.v16,
              Expanded(
                child: Obx(() {
                  switch (discoverController.roomSelection.value) {
                    case DiscoverRoomSelection.video:
                      return const DiscoverVideoRoomView();
                    case DiscoverRoomSelection.audio:
                      return const DiscoverAudioRoomView();
                    case DiscoverRoomSelection.none:
                      return _defaultDiscoverFeed(
                        suggestedUsers: suggestedUsers,
                        trendingRooms: trendingRooms,
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

  Widget _defaultDiscoverFeed({
    required List<({String name, String image})> suggestedUsers,
    required List<({String title, String subtitle, String image})>
    trendingRooms,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _agencyHostEntryCard(),
          Spacing.v12,
          _agencyOwnerEntryCard(),
          Spacing.v16,
          _sectionHeader(title: 'Suggested Users', trailing: 'SEE ALL'),
          Spacing.v10,
          _suggestedUsersGrid(suggestedUsers),
          Spacing.v16,
          _sectionHeader(title: 'Trending Rooms', trailing: 'ACTIVE NOW'),
          Spacing.v8,
          _trendingCard(trendingRooms[0]),
          Spacing.v12,
          _sectionHeader(title: 'Trending Rooms', trailing: 'ACTIVE NOW'),
          Spacing.v8,
          _trendingCard(trendingRooms[1]),
        ],
      ),
    );
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

  /// Entry to AGENCY-01 from Discover default feed (UI only; API later).
  Widget _agencyHostEntryCard() {
    return GestureDetector(
      onTap: () => Get.toNamed(Routes.AGENCY_HOST_ONBOARDING),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              kColorProfileActionPinkStart.withValues(alpha: 0.95),
              kColorProfileActionOrangeEnd.withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: kColorWhite.withValues(alpha: 0.22),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: kColorWhite.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic_rounded, color: kColorWhite, size: 24),
            ),
            Spacing.h12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SemiBoldText(
                    text: 'Become an Agency Host',
                    fontSize: TextStyles.k16FontSize,
                    color: kColorWhite,
                  ),
                  Spacing.v4,
                  const AppText(
                    text: 'Apply with your details and host photo',
                    fontSize: TextStyles.k12FontSize,
                    color: kColorWhite,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: kColorWhite.withValues(alpha: 0.9),
            ),
          ],
        ),
      ),
    );
  }

  /// Entry to AGENCY-03 from Discover default feed (UI only).
  Widget _agencyOwnerEntryCard() {
    return GestureDetector(
      onTap: () => Get.toNamed(Routes.AGENCY_OWNER_REGISTER),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.orange.withValues(alpha: 0.95),
              Colors.deepOrange.withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: kColorWhite.withValues(alpha: 0.22),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: kColorWhite.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.business_center_rounded, color: kColorWhite, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SemiBoldText(
                    text: 'Agency Owner Portal',
                    fontSize: TextStyles.k16FontSize,
                    color: kColorWhite,
                  ),
                  const SizedBox(height: 4),
                  const AppText(
                    text: 'Register your agency and manage hosts',
                    fontSize: TextStyles.k12FontSize,
                    color: kColorWhite,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: kColorWhite.withValues(alpha: 0.9),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader({required String title, required String trailing}) {
    return Row(
      children: [
        SemiBoldText(
          text: title,
          fontSize: TextStyles.k14FontSize,
          color: kColorWhite,
        ),
        const Spacer(),
        SemiBoldText(
          text: trailing,
          fontSize: TextStyles.k12FontSize,
          color: kColorWhite,
        ),
      ],
    );
  }

  Widget _suggestedUsersGrid(List<({String name, String image})> users) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: LayoutBuilder(
        builder: (_, constraints) {
          // Slightly tighter card height on narrow devices prevents text clipping.
          final isNarrow = constraints.maxWidth < 360;
          return GridView.builder(
            itemCount: users.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 16,
              mainAxisExtent: isNarrow ? 148 : 160,
            ),
            itemBuilder: (_, index) =>
                _userCard(users[index], isCompact: isNarrow),
          );
        },
      ),
    );
  }

  Widget _userCard(
    ({String name, String image}) user, {
    required bool isCompact,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kColorDiscoverCard.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isCompact ? 82 : 92,
            height: isCompact ? 82 : 92,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: ClipOval(child: Image.asset(user.image, fit: BoxFit.cover)),
          ),
          if (isCompact) Spacing.v8 else Spacing.v10,
          SemiBoldText(
            text: user.name,
            fontSize: TextStyles.k14FontSize,
            color: kColorWhite,
          ),
        ],
      ),
    );
  }

  Widget _trendingCard(({String title, String subtitle, String image}) room) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kColorDiscoverCard.withValues(alpha: 0.96),
            kColorBottomNavGradientBottom.withValues(alpha: 0.78),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: kColorWhite.withValues(alpha: 0.08),
          width: 0.6,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 104,
            height: 88,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(room.image, fit: BoxFit.cover),
            ),
          ),
          Spacing.h12,
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: room.title,
                  fontSize: TextStyles.k18FontSize,
                  color: kColorWhite,
                ),
                Spacing.v2,
                AppText(
                  text: room.subtitle,
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite.withValues(alpha: 0.85),
                ),
                Spacing.v8,
                Container(
                  width: 100,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: kColorDiscoverJoinNow,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const SemiBoldText(
                    text: 'Join Room',
                    fontSize: TextStyles.k14FontSize,
                    color: kColorWhite,
                  ),
                ),
              ],
            ),
          ),
        ],
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
}
