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
            child: Stack(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                      child: Column(
                        children: [
                          _topHeader(context, userSession, controller),
                          Spacing.v16,
                          _categoryRow(categories),
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
                                  padding: const EdgeInsets.only(bottom: 74),
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
                                    color: Colors.transparent,
                                    child: GridView.builder(
                                      padding: const EdgeInsets.only(top: 2),
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
                                          onTap: () =>
                                              controller.joinRoom(room),
                                          child: CommonLiveRoomWidget(
                                            imageUrl: room['image'] as String,
                                            userNameAge:
                                                room['nameAge'] as String,
                                            badgeText: room['badge'] as String,
                                            locationText:
                                                room['location'] as String,
                                            pointsText:
                                                room['points'] as String,
                                            isFavorite:
                                                room['favorite'] as bool,
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
                Positioned(
                  right: 18,
                  bottom: 66,
                  child: _liveActionMenu(controller),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Compact action menu that replaces the large top CTA buttons.
  Widget _liveActionMenu(LiveRoomController controller) {
    var isOpen = false;

    return StatefulBuilder(
      builder: (context, setMenuState) {
        void closeMenu() => setMenuState(() => isOpen = false);

        return AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.bottomRight,
          child: SizedBox(
            width: 176,
            height: isOpen ? 160 : 54,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomRight,
              children: [
                Positioned(
                  right: 0,
                  bottom: 64,
                  child: IgnorePointer(
                    ignoring: !isOpen,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: isOpen ? 1 : 0,
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        offset: isOpen ? Offset.zero : const Offset(0, 0.08),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _liveActionOption(
                              label: LocaleKeys.liveRoomGoLive.tr,
                              icon: Icons.videocam_rounded,
                              filled: true,
                              onTap: () {
                                closeMenu();
                                controller.openGoLive();
                              },
                            ),
                            Spacing.v8,
                            _liveActionOption(
                              label: LocaleKeys.liveRoomJoinLive.tr,
                              icon: Icons.sensors_rounded,
                              filled: false,
                              onTap: () {
                                closeMenu();
                                controller.focusJoinLive();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _plusActionButton(
                  isOpen: isOpen,
                  onTap: () => setMenuState(() => isOpen = !isOpen),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _plusActionButton({
    required bool isOpen,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [
              LiveRoomUiColors.goLiveGradientStart,
              LiveRoomUiColors.goLiveGradientEnd,
            ],
          ),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: LiveRoomUiColors.goLiveGradientStart.withValues(
                alpha: 0.38,
              ),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: AnimatedRotation(
          duration: const Duration(milliseconds: 180),
          turns: isOpen ? 0.125 : 0,
          child: const Icon(Icons.add_rounded, color: kColorWhite, size: 30),
        ),
      ),
    );
  }

  Widget _liveActionOption({
    required String label,
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 44,
        width: 156,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
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
                ? kColorWhite.withValues(alpha: 0.12)
                : LiveRoomUiColors.joinLiveBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: kColorBlack.withValues(alpha: 0.22),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: kColorWhite, size: 18),
            Spacing.h8,
            Expanded(
              child: SemiBoldText(
                text: label,
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
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
                    color: LiveRoomUiColors.goLiveGradientStart.withValues(
                      alpha: 0.4,
                    ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            kColorWhite.withValues(alpha: 0.14),
            kColorWhite.withValues(alpha: 0.07),
          ],
        ),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: kColorBlack.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LiveRoomUiColors.liveDot.withValues(alpha: 0.16),
              border: Border.all(
                color: LiveRoomUiColors.liveDot.withValues(alpha: 0.35),
              ),
            ),
            child: const Icon(
              Icons.sensors_rounded,
              color: LiveRoomUiColors.liveDot,
              size: 18,
            ),
          ),
          Spacing.h10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: '$count ${LocaleKeys.liveRoomActiveNow.tr}',
                  fontSize: TextStyles.k12FontSize,
                  color: kColorWhite,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Spacing.v2,
                AppText(
                  text: LocaleKeys.liveRoomJoinHint.tr,
                  fontSize: TextStyles.k10FontSize,
                  color: kColorWhite.withValues(alpha: 0.68),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Spacing.h10,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: LiveRoomUiColors.liveDot.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: LiveRoomUiColors.liveDot.withValues(alpha: 0.24),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LivePulseDot(),
                Spacing.h6,
                SemiBoldText(
                  text: 'LIVE',
                  fontSize: TextStyles.k10FontSize,
                  color: LiveRoomUiColors.liveDot,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchEmptyState(LiveRoomController controller) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, color: kColorHint, size: 48),
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
    return Container(
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        gradient: LinearGradient(
          colors: [
            kColorWhite.withValues(alpha: 0.24),
            LiveRoomUiColors.joinLiveBorder.withValues(alpha: 0.28),
            kColorWhite.withValues(alpha: 0.06),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: kColorBlack.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 3.35,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Obx(() {
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
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      kColorBlack.withValues(alpha: 0.12),
                      Colors.transparent,
                      LiveRoomUiColors.goLiveGradientStart.withValues(
                        alpha: 0.16,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: kColorBlack.withValues(alpha: 0.34),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: kColorWhite.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: kColorWalletAmount,
                        size: 14,
                      ),
                      Spacing.h6,
                      SemiBoldText(
                        text: 'Featured rooms',
                        fontSize: TextStyles.k10FontSize,
                        color: kColorWhite.withValues(alpha: 0.92),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bannerFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF351B6C), Color(0xFF7A236D), Color(0xFF14155B)],
        ),
      ),
      alignment: Alignment.center,
      child: const SemiBoldText(
        text: 'Celebration Banner',
        fontSize: TextStyles.k14FontSize,
        color: kColorWhite,
      ),
    );
  }

  Widget _topHeader(
    BuildContext context,
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
                  border: Border.all(color: const Color(0xB3FFFFFF), width: 1),
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
              _headerIconButton(
                onTap: () => liveRoomController.openFilterSheet(context),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SvgPicture.asset(
                      kIconFilter,
                      width: 17,
                      height: 17,
                      colorFilter: const ColorFilter.mode(
                        kColorPrimary,
                        BlendMode.srcIn,
                      ),
                    ),
                    if (liveRoomController.hasActiveFilters)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: LiveRoomUiColors.goLiveGradientStart,
                            shape: BoxShape.circle,
                            border: Border.fromBorderSide(
                              BorderSide(color: kColorWhite, width: 1),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Spacing.h8,
              InkWell(
                onTap: () => Get.toNamed(Routes.LEADER_BOARD),
                borderRadius: BorderRadius.circular(22),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(child: SvgPicture.asset(kIconLeaderboard)),
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

  Widget _headerIconButton({
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Material(
      color: kColorWhite,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(width: 36, height: 36, child: Center(child: child)),
      ),
    );
  }

  Widget _categoryRow(List<String> categories) {
    final liveRoomController = _resolveController();
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, __) => Spacing.h8,
        itemBuilder: (context, index) {
          return _categoryChip(
            label: categories[index],
            isSelected: liveRoomController.selectedCategoryIndex == index,
            onTap: () => liveRoomController.onCategorySelected(index),
          );
        },
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

class _LivePulseDot extends StatelessWidget {
  const _LivePulseDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: LiveRoomUiColors.liveDot,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: LiveRoomUiColors.liveDot.withValues(alpha: 0.55),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
