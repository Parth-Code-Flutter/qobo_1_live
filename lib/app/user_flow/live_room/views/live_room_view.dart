import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/constants/live_room_ui_colors.dart';
import 'package:qobo_one_live/generated/locales.g.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/safe_network_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/live_room_controller.dart';
import '../widgets/common_live_room_widget.dart';

class LiveRoomView extends StatelessWidget {
  const LiveRoomView({super.key});

  @override
  Widget build(BuildContext context) {
    final liveRoomController = _resolveController();
    final userSession = _resolveUserSession();
    final categories = <String>[
      LocaleKeys.liveRoomTabSab.tr,
      LocaleKeys.liveRoomTabShresth.tr,
      LocaleKeys.liveRoomTabNaya.tr,
      LocaleKeys.liveRoomTabBangladesh.tr,
    ];

    return GetBuilder<LiveRoomController>(
      init: liveRoomController,
      builder: (controller) {
        return Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(kImgBG),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Column(
                    children: [
                      _topHeader(userSession, controller),
                      Spacing.v16,
                      _actionCtas(controller),
                      Spacing.v16,
                      _filterAndCategoryRow(context, categories),
                      Spacing.v12,
                      _topBanner(controller),
                      Spacing.v12,
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 40),
                    child: Obx(() {
                      if (controller.isLoading.value) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: kColorPrimary,
                          ),
                        );
                      }
                      if (controller.rooms.isEmpty) {
                        if (controller.isSearching) {
                          return _searchEmptyState(controller);
                        }
                        return _emptyState(controller);
                      }
                      final highlight = controller.highlightJoinGrid.value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _liveCountStrip(controller.rooms.length),
                          Spacing.v10,
                          Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: highlight
                                      ? LiveRoomUiColors.joinLiveBorder
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: ColoredBox(
                                color: LiveRoomUiColors.screenGradientBottom,
                                child: GridView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: controller.rooms.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 12,
                                        crossAxisSpacing: 12,
                                        childAspectRatio: 0.8,
                                      ),
                                  itemBuilder: (context, index) {
                                    final room = controller.rooms[index];
                                    return GestureDetector(
                                      onTap: () => controller.joinRoom(room),
                                      child: CommonLiveRoomWidget(
                                        imageUrl: room['image'] as String,
                                        userNameAge: room['nameAge'] as String,
                                        badgeText: room['badge'] as String,
                                        locationText:
                                            room['location'] as String,
                                        pointsText: room['points'] as String,
                                        isFavorite: room['favorite'] as bool,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Primary actions: start broadcasting or jump into an existing room.
  Widget _actionCtas(LiveRoomController controller) {
    return Row(
      children: [
        Expanded(
          child: _ctaButton(
            label: LocaleKeys.liveRoomGoLive.tr,
            icon: Icons.videocam_rounded,
            filled: true,
            onTap: controller.openGoLive,
          ),
        ),
        Spacing.h12,
        Expanded(
          child: _ctaButton(
            label: LocaleKeys.liveRoomJoinLive.tr,
            icon: Icons.sensors_rounded,
            filled: false,
            onTap: controller.focusJoinLive,
          ),
        ),
      ],
    );
  }

  Widget _ctaButton({
    required String label,
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: filled
              ? const LinearGradient(
                  colors: [
                    LiveRoomUiColors.goLiveGradientStart,
                    LiveRoomUiColors.goLiveGradientEnd,
                  ],
                )
              : null,
          color: filled ? null : LiveRoomUiColors.chipInactiveBg,
          border: Border.all(
            color: filled
                ? Colors.transparent
                : LiveRoomUiColors.joinLiveBorder,
            width: 1.2,
          ),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: LiveRoomUiColors.goLiveGradientStart
                        .withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: kColorWhite, size: 20),
            Spacing.h8,
            SemiBoldText(
              text: label,
              fontSize: TextStyles.k14FontSize,
              color: kColorWhite,
            ),
          ],
        ),
      ),
    );
  }

  /// Small "x rooms live now" strip above the listing grid.
  Widget _liveCountStrip(int count) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: LiveRoomUiColors.liveDot,
            shape: BoxShape.circle,
          ),
        ),
        Spacing.h8,
        SemiBoldText(
          text: '$count ${LocaleKeys.liveRoomActiveNow.tr}',
          fontSize: TextStyles.k12FontSize,
          color: kColorWhite,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Spacing.h8,
        Expanded(
          child: AppText(
            text: LocaleKeys.liveRoomJoinHint.tr,
            fontSize: TextStyles.k12FontSize,
            color: kColorHint,
            align: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _searchEmptyState(LiveRoomController controller) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.search_off_rounded,
            color: kColorHint,
            size: 48,
          ),
          Spacing.v12,
          SemiBoldText(
            text: 'No rooms match "${controller.searchQuery.value}"',
            fontSize: TextStyles.k14FontSize,
            color: kColorWhite,
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _emptyState(LiveRoomController controller) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: LiveRoomUiColors.chipInactiveBg,
              shape: BoxShape.circle,
              border: Border.all(color: LiveRoomUiColors.joinLiveBorder),
            ),
            child: const Icon(
              Icons.live_tv_rounded,
              color: kColorWhite,
              size: 38,
            ),
          ),
          Spacing.v16,
          SemiBoldText(
            text: LocaleKeys.liveRoomEmptyTitle.tr,
            fontSize: TextStyles.k16FontSize,
            color: kColorWhite,
          ),
          Spacing.v8,
          AppText(
            text: LocaleKeys.liveRoomEmptySubtitle.tr,
            fontSize: TextStyles.k12FontSize,
            color: kColorHint,
            align: TextAlign.center,
          ),
          Spacing.v20,
          SizedBox(
            width: 180,
            child: _ctaButton(
              label: LocaleKeys.liveRoomGoLive.tr,
              icon: Icons.videocam_rounded,
              filled: true,
              onTap: controller.openGoLive,
            ),
          ),
        ],
      ),
    );
  }

  /// Promo banner shown above the live-room listing.
  Widget _topBanner(LiveRoomController controller) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 3.2,
        child: Obx(() {
          final bannerUrl = controller.promoBannerImageUrl.value;
          if (bannerUrl != null && bannerUrl.isNotEmpty) {
            return Image.network(
              bannerUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _bannerFallback(),
            );
          }
          return Image.asset(
            kImgTemp1,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _bannerFallback(),
          );
        }),
      ),
    );
  }

  Widget _bannerFallback() {
    return Container(
      color: const Color(0x66351B6C),
      alignment: Alignment.center,
      child: const SemiBoldText(
        text: 'Celebration Banner',
        fontSize: TextStyles.k14FontSize,
        color: kColorWhite,
      ),
    );
  }

  Widget _topHeader(
    UserSessionController userSession,
    LiveRoomController liveRoomController,
  ) {
    return Obx(() {
      if (liveRoomController.isSearchExpanded.value) {
        return _expandedSearchBar(liveRoomController);
      }

      return GetBuilder<UserSessionController>(
        init: userSession,
        builder: (session) {
          final avatarUrl = session.displayPictureUrl;
          return Row(
            children: [
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: kColorWhite,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xB3FFFFFF),
                    width: 1,
                  ),
                ),
                child: ClipOval(
                  child: SafeNetworkAvatar(
                    url: avatarUrl,
                    size: 40,
                    fallback: _initialsAvatar(session.initials),
                  ),
                ),
              ),
              Spacing.h10,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      text: LocaleKeys.liveRoomWelcome.tr,
                      fontSize: TextStyles.k14FontSize,
                      color: kColorWhite,
                    ),
                    SemiBoldText(
                      text: session.displayName,
                      fontSize: TextStyles.k14FontSize,
                      color: kColorWhite,
                    ),
                  ],
                ),
              ),
              Material(
                color: kColorWhite,
                borderRadius: BorderRadius.circular(22),
                child: InkWell(
                  onTap: liveRoomController.openSearch,
                  borderRadius: BorderRadius.circular(22),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Center(
                      child: SvgPicture.asset(
                        kIconSearch,
                        width: 18,
                        height: 18,
                        colorFilter: const ColorFilter.mode(
                          kColorPrimary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Spacing.h8,
              InkWell(
                onTap: () => Get.toNamed(Routes.LEADER_BOARD),
                borderRadius: BorderRadius.circular(22),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(
                    child: SvgPicture.asset(kIconLeaderboard),
                  ),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  Widget _expandedSearchBar(LiveRoomController controller) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Material(
            color: LiveRoomUiColors.chipInactiveBg,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: controller.closeSearch,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: kColorWhite,
                  size: 18,
                ),
              ),
            ),
          ),
          Spacing.h10,
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: kColorWhite,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: LiveRoomUiColors.joinLiveBorder.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    kIconSearch,
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(
                      kColorPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                  Spacing.h10,
                  Expanded(
                    child: TextField(
                      controller: controller.searchController,
                      focusNode: controller.searchFocusNode,
                      textInputAction: TextInputAction.search,
                      style: TextStyles.kRegularPoppins(
                        fontSize: TextStyles.k14FontSize,
                        colors: kColorText,
                      ),
                      cursorColor: kColorPrimary,
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Search live rooms...',
                        hintStyle: TextStyles.kRegularPoppins(
                          fontSize: TextStyles.k14FontSize,
                          colors: kColorHint,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  Obx(() {
                    if (controller.searchQuery.value.isEmpty) {
                      return Spacing.shrink;
                    }
                    return GestureDetector(
                      onTap: controller.searchController.clear,
                      child: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: kColorHint,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterAndCategoryRow(
    BuildContext context,
    List<String> categories,
  ) {
    final liveRoomController = _resolveController();
    return SizedBox(
      height: 44,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _filterButton(
            hasActiveFilters: liveRoomController.hasActiveFilters,
            onTap: () => liveRoomController.openFilterSheet(context),
          ),
          Spacing.h12,
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: categories.length,
              separatorBuilder: (_, __) => Spacing.h8,
              itemBuilder: (context, index) {
                return _categoryChip(
                  label: categories[index],
                  isSelected:
                      liveRoomController.selectedCategoryIndex == index,
                  onTap: () => liveRoomController.onCategorySelected(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterButton({
    required bool hasActiveFilters,
    required VoidCallback onTap,
  }) {
    return Material(
      color: kColorWhite,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SvgPicture.asset(
                kIconFilter,
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  kColorPrimary,
                  BlendMode.srcIn,
                ),
              ),
              if (hasActiveFilters)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: LiveRoomUiColors.goLiveGradientStart,
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                        BorderSide(color: kColorWhite, width: 1.2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      kColorLiveFilterChipGradientStart,
                      kColorLiveFilterChipGradientMid,
                      kColorLiveFilterChipGradientEnd,
                    ],
                  )
                : null,
            color: isSelected ? null : LiveRoomUiColors.chipInactiveBg,
            border: Border.all(
              color: isSelected
                  ? kColorLiveFilterChipBorder
                  : LiveRoomUiColors.cardBorder,
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: kColorPrimary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: SemiBoldText(
              text: label,
              fontSize: TextStyles.k12FontSize,
              color: isSelected ? kColorWhite : const Color(0xFFB8B8D0),
            ),
          ),
        ),
      ),
    );
  }

  LiveRoomController _resolveController() {
    if (Get.isRegistered<LiveRoomController>()) {
      return Get.find<LiveRoomController>();
    }
    // Defensive fallback: prevents intermittent null lookup crashes.
    return Get.put(LiveRoomController());
  }

  UserSessionController _resolveUserSession() {
    if (Get.isRegistered<UserSessionController>()) {
      return Get.find<UserSessionController>();
    }
    return Get.put(UserSessionController(), permanent: true);
  }

  Widget _initialsAvatar(String initials) {
    return ColoredBox(
      color: const Color(0xFF2A2A2A),
      child: Center(
        child: SemiBoldText(
          text: initials,
          fontSize: TextStyles.k14FontSize,
          color: kColorWhite,
        ),
      ),
    );
  }
}
