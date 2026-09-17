import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/bottom_nav/controllers/bottom_nav_controller.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/widgets/in_room_pk_stage_overlay.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/widgets/live_room_pk_stage_slot.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/controllers/pk_v1_controller.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/constants/live_room_ui_colors.dart';
import 'package:qobo_one_live/generated/locales.g.dart';
import 'package:qobo_one_live/repo/banner/models/promo_banner.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/pk/pk_v1_coordinator.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/app_widgets/dating_empty_hero.dart';
import 'package:qobo_one_live/utils/app_widgets/glossy_dating_card.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/live_room_controller.dart';
import '../models/live_room_filter_state.dart';
import '../widgets/compact_live_room_tile.dart';

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
        // Light status icons over purple→pink header (extends under status bar).
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Container(
            decoration: const BoxDecoration(
              color: kColorLavenderBg,
            ),
            child: Column(
              children: [
                _topHeader(context, userSession, controller),
                Expanded(
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                          child: Column(
                            children: [
                              Spacing.v10,
                              _categoryRow(categories),
                              Spacing.v8,
                              _regionRow(controller),
                              Spacing.v10,
                              _topBanner(controller),
                              Spacing.v12,
                              // Landing CTAs — always above grid / empty.
                              _hubActionRow(controller),
                              Spacing.v10,
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
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
                              final highlight =
                                  controller.highlightJoinGrid.value;
                              return AnimatedContainer(
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
                                child: RefreshIndicator(
                                  color: kColorPrimary,
                                  onRefresh: controller.refreshLiveRoom,
                                  child: GridView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                      0,
                                      2,
                                      0,
                                      24,
                                    ),
                                    physics:
                                        const AlwaysScrollableScrollPhysics(
                                      parent: BouncingScrollPhysics(),
                                    ),
                                    itemCount: controller.rooms.length,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      mainAxisSpacing: 9,
                                      crossAxisSpacing: 9,
                                      // Framed avatar tiles — room for crowns.
                                      childAspectRatio: 0.88,
                                    ),
                                    itemBuilder: (context, index) {
                                      final room = controller.rooms[index];
                                      final name = room['nameAge'] as String? ??
                                          'Live';
                                      final imageUrl =
                                          _roomHostAvatarUrl(room);
                                      // Prefer API host frame; if missing and this
                                      // is the current user's room, use session
                                      // frame (same as AppBar) — avoids mock fallback.
                                      final frameUrl =
                                          _roomHostFrameUrl(room) ??
                                              _sessionFrameIfOwnRoom(room);
                                      final frameSeed =
                                          _roomHostFrameSeed(room) ?? name;
                                      final heat =
                                          room['points']?.toString();
                                      return CompactLiveRoomTile(
                                        displayName: name,
                                        imageUrl: imageUrl,
                                        frameUrl: frameUrl,
                                        frameSeed: frameSeed,
                                        viewerLabel: heat,
                                        onTap: () =>
                                            controller.joinRoom(room),
                                      );
                                    },
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Equal-width Go Live + Join Live strip under the promo banner.
  Widget _hubActionRow(LiveRoomController controller) {
    return Row(
      children: [
        Expanded(
          child: _hubActionButton(
            label: LocaleKeys.liveRoomGoLive.tr,
            icon: Icons.videocam_rounded,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                LiveRoomUiColors.goLiveGradientStart,
                LiveRoomUiColors.goLiveGradientEnd,
              ],
            ),
            onTap: controller.openGoLive,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: _hubActionButton(
            label: 'Join Live',
            icon: Icons.sensors_rounded,
            gradient: AppLightUi.familyCtaGradient,
            onTap: controller.focusJoinLive,
          ),
        ),
      ],
    );
  }

  Widget _hubActionButton({
    required String label,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return _HubPressScale(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: gradient,
          border: Border.all(
            color: kColorWhite.withValues(alpha: 0.42),
            width: 1.2,
          ),
          boxShadow: [
            ...AppLightUi.cardShadow,
            BoxShadow(
              color: AppLightUi.title.withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Top gloss highlight
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      kColorWhite.withValues(alpha: 0.28),
                      kColorWhite.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Row(
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
          ],
        ),
      ),
    );
  }

  Widget _searchEmptyState(LiveRoomController controller) {
    return _slotSafeEmpty(
      onRefresh: controller.refreshLiveRoom,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, color: AppLightUi.muted, size: 36),
          Spacing.v8,
          SemiBoldText(
            text: 'No rooms match "${controller.searchQuery.value}"',
            fontSize: TextStyles.k14FontSize,
            color: AppLightUi.title,
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _emptyState(LiveRoomController controller) {
    return _slotSafeEmpty(
      onRefresh: controller.refreshLiveRoom,
      // Compact card — FittedBox scales it down on short devices.
      child: Container(
        width: 280,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: AppLightUi.cardDecoration(radius: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DatingEmptyHero(
              style: DatingEmptyHeroStyle.live,
              size: 72,
              accentColors: [AppLightUi.pink, AppLightUi.violet],
            ),
            Spacing.v6,
            SemiBoldText(
              text: LocaleKeys.liveRoomEmptyTitle.tr,
              fontSize: TextStyles.k14FontSize,
              color: AppLightUi.title,
              align: TextAlign.center,
            ),
            Spacing.v2,
            AppText(
              text: LocaleKeys.liveRoomEmptySubtitle.tr,
              fontSize: TextStyles.k10FontSize,
              color: AppLightUi.subtitle,
              align: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Empty listing that never overflows: fills the Expanded slot and scales
  /// [child] down with [FittedBox] when the slot is shorter than the card.
  Widget _slotSafeEmpty({
    required Future<void> Function() onRefresh,
    required Widget child,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight.isFinite ? constraints.maxHeight : 240.0;
        final w = constraints.maxWidth.isFinite ? constraints.maxWidth : 320.0;
        return RefreshIndicator(
          color: kColorPrimary,
          onRefresh: onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: SizedBox(
              height: h,
              width: w,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Promo banner shown above the live-room listing.
  /// Height factor 0.45 ≈ 20% shorter than prior 9/16 (~0.5625).
  static const double _bannerHeightFactor = 0.45;

  Widget _topBanner(LiveRoomController controller) {
    return Obx(() {
      final banners = controller.promoBanners.toList(growable: false);
      final selectedIndex = banners.isEmpty
          ? 0
          : controller.currentPromoBannerIndex.value.clamp(
              0,
              banners.length - 1,
            );

      return LayoutBuilder(
        builder: (context, constraints) => GlossyDatingCard(
          padding: EdgeInsets.zero,
          radius: 18,
          borderWidth: 1.6,
          borderGradient: AppLightUi.glossRingGradient,
          fill: const Color(0xFF351B6C),
          child: SizedBox(
            height: constraints.maxWidth * _bannerHeightFactor,
            child: Stack(
              fit: StackFit.expand,
              children: [
                banners.isEmpty
                    ? _staticBannerFallback()
                    : _networkBanner(banners[selectedIndex]),
                // Soft glass sheen along the top edge.
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          kColorWhite.withValues(alpha: 0.18),
                          kColorWhite.withValues(alpha: 0.0),
                        ],
                        stops: const [0, 0.42],
                      ),
                    ),
                  ),
                ),
                if (banners.length > 1)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 8,
                    child: Center(
                      child: _bannerPageIndicator(
                        count: banners.length,
                        selected: selectedIndex,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _networkBanner(PromoBanner banner) {
    // Banner click-through stays disabled until product enables target URLs.
    return Semantics(
      image: true,
      label: banner.title.isEmpty ? 'Promotional banner' : banner.title,
      child: Image.network(
        banner.imageUrl,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Stack(
            fit: StackFit.expand,
            children: [
              _bannerFallback(),
              const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: kColorWhite,
                  ),
                ),
              ),
            ],
          );
        },
        errorBuilder: (_, __, ___) => _bannerFallback(),
      ),
    );
  }

  Widget _staticBannerFallback() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          kImgTemp1,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _bannerFallback(),
        ),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  kColorBlack.withValues(alpha: 0.12),
                  Colors.transparent,
                  LiveRoomUiColors.goLiveGradientStart.withValues(alpha: 0.16),
                ],
              ),
            ),
          ),
        ),
        Positioned(left: 12, bottom: 10, child: _bannerLabel('Featured rooms')),
      ],
    );
  }

  Widget _bannerLabel(String title) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 330),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kColorBlack.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.14)),
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
          Flexible(
            child: SemiBoldText(
              text: title.isEmpty ? 'Featured rooms' : title,
              fontSize: TextStyles.k10FontSize,
              color: kColorWhite.withValues(alpha: 0.96),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerPageIndicator({required int count, required int selected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: kColorBlack.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: AppLightUi.title.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(count, (index) {
          final active = index == selected;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: active ? 14 : 5,
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: active ? kColorWhite : kColorWhite.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
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

  /// Family-style purple→pink header — local copy of CommonAppBar look (no shared widget).
  ///
  /// Square gradient fill sits behind the rounded face so Scaffold lavender never
  /// peeks through the transparent corner pixels of the ~22 radius.
  Widget _topHeader(
    BuildContext context,
    UserSessionController userSession,
    LiveRoomController liveRoomController,
  ) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Obx(() {
      final searching = liveRoomController.isSearchExpanded.value;
      return Stack(
        children: [
          // Anti-grey-strip: same-size square fill under rounded face.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppLightUi.familyCtaGradient,
              ),
            ),
          ),
          DecoratedBox(
            decoration: _liveHubHeaderDecoration(),
            child: Padding(
              padding: EdgeInsets.fromLTRB(14, topInset + 10, 14, 16),
              child: searching
                  ? _expandedSearchBar(liveRoomController)
                  : GetBuilder<UserSessionController>(
                      init: userSession,
                      builder: (session) {
                        return _welcomeHeaderRow(
                          context: context,
                          session: session,
                          liveRoomController: liveRoomController,
                        );
                      },
                    ),
            ),
          ),
        ],
      );
    });
  }

  /// Mirrors CommonAppBar `_buildGradientAppBar` flexibleSpace (gradient + shadow + radius).
  BoxDecoration _liveHubHeaderDecoration() {
    return BoxDecoration(
      gradient: AppLightUi.familyCtaGradient,
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(22),
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF2A1744).withValues(alpha: 0.10),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _welcomeHeaderRow({
    required BuildContext context,
    required UserSessionController session,
    required LiveRoomController liveRoomController,
  }) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            if (!Get.isRegistered<BottomNavController>()) return;
            Get.find<BottomNavController>().openOwnProfileSheet(context);
          },
          behavior: HitTestBehavior.opaque,
          child: _headerAvatar(
            name: session.displayName,
            imageUrl: session.displayPictureUrl,
            frameUrl: session.profileFrameUrl,
            frameSeed: session.userId,
          ),
        ),
        Spacing.h12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                text: LocaleKeys.liveRoomWelcome.tr.toUpperCase(),
                fontSize: TextStyles.k10FontSize,
                color: kColorWhite.withValues(alpha: 0.78),
                style: TextStyles.kRegularPoppins(
                  fontSize: TextStyles.k10FontSize,
                  colors: kColorWhite.withValues(alpha: 0.78),
                ).copyWith(letterSpacing: 1.1),
              ),
              const SizedBox(height: 2),
              SemiBoldText(
                text: session.displayName,
                fontSize: TextStyles.k18FontSize,
                color: kColorWhite,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 11,
                    color: kColorWhite.withValues(alpha: 0.90),
                  ),
                  Spacing.h4,
                  Expanded(
                    child: AppText(
                      text: 'Rooms are live · pick your vibe',
                      fontSize: TextStyles.k10FontSize,
                      color: kColorWhite.withValues(alpha: 0.82),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Spacing.h6,
        _headerIconButton(
          onTap: liveRoomController.openSearch,
          child: SvgPicture.asset(
            kIconSearch,
            width: 17,
            height: 17,
            colorFilter: ColorFilter.mode(
              kColorWhite.withValues(alpha: 0.95),
              BlendMode.srcIn,
            ),
          ),
        ),
        Spacing.h6,
        _headerIconButton(
          onTap: () => liveRoomController.openFilterSheet(context),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SvgPicture.asset(
                  kIconFilter,
                  width: 16,
                  height: 16,
                  colorFilter: ColorFilter.mode(
                    kColorWhite.withValues(alpha: 0.95),
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
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD45B),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: kColorWhite.withValues(alpha: 0.9),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Spacing.h6,
        // TEMP: preview new PK battle stage UI — commented for now.
        // _headerIconButton(
        //   onTap: () => _openPkBattleUiPreview(),
        //   child: const Icon(
        //     Icons.sports_mma_rounded,
        //     size: 18,
        //     color: Color(0xFFFF2D55),
        //   ),
        // ),
        // Spacing.h6,
        _headerIconButton(
          onTap: () => Get.toNamed(Routes.LEADER_BOARD),
          goldAccent: true,
          child: SvgPicture.asset(
            kIconLeaderboard,
            width: 17,
            height: 17,
            colorFilter: const ColorFilter.mode(
              kColorWhite,
              BlendMode.srcIn,
            ),
          ),
        ),
      ],
    );
  }

  /// Gloss ring + soft glow for white chrome on gradient.
  Widget _headerAvatar({
    required String name,
    required String? imageUrl,
    required String? frameUrl,
    required String? frameSeed,
  }) {
    return Container(
      padding: const EdgeInsets.all(2.6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppLightUi.glossRingGradient,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A1744).withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: kColorWhite.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: kColorWhite.withValues(alpha: 0.96),
          border: Border.all(
            color: kColorWhite.withValues(alpha: 0.9),
            width: 1.2,
          ),
        ),
        child: FramedUserAvatar(
          name: name,
          imageUrl: imageUrl,
          frameUrl: frameUrl,
          frameSeed: frameSeed,
          size: 44,
          fontSize: TextStyles.k10FontSize,
        ),
      ),
    );
  }

  Widget _expandedSearchBar(LiveRoomController controller) {
    return GlossyDatingCard(
      radius: 22,
      borderWidth: 1.4,
      padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
      fill: kColorWhite.withValues(alpha: 0.92),
      borderGradient: LinearGradient(
        colors: [
          kColorWhite.withValues(alpha: 0.55),
          kColorWhite.withValues(alpha: 0.22),
        ],
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            _headerIconButton(
              onTap: controller.closeSearch,
              onLightSurface: true,
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppLightUi.title,
                size: 16,
              ),
            ),
            Spacing.h8,
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppLightUi.searchFill.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppLightUi.borderStrong.withValues(alpha: 0.65),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppLightUi.title.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      kIconSearch,
                      width: 17,
                      height: 17,
                      colorFilter: const ColorFilter.mode(
                        AppLightUi.violet,
                        BlendMode.srcIn,
                      ),
                    ),
                    Spacing.h8,
                    Expanded(
                      child: TextField(
                        controller: controller.searchController,
                        focusNode: controller.searchFocusNode,
                        textInputAction: TextInputAction.search,
                        style: TextStyles.kRegularPoppins(
                          fontSize: TextStyles.k14FontSize,
                          colors: AppLightUi.body,
                        ),
                        cursorColor: AppLightUi.violet,
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Search live rooms...',
                          hintStyle: TextStyles.kRegularPoppins(
                            fontSize: TextStyles.k14FontSize,
                            colors: AppLightUi.hint,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
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
                          color: AppLightUi.muted,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Glass / gold circle action — white chrome on gradient; dark chrome on light search card.
  Widget _headerIconButton({
    required VoidCallback onTap,
    required Widget child,
    bool goldAccent = false,
    bool onLightSurface = false,
  }) {
    final glassFill = onLightSurface
        ? [
            kColorWhite.withValues(alpha: 0.96),
            AppLightUi.cardSoft.withValues(alpha: 0.88),
          ]
        : [
            kColorWhite.withValues(alpha: 0.28),
            kColorWhite.withValues(alpha: 0.12),
          ];
    final borderColor = onLightSurface
        ? kColorWhite.withValues(alpha: 0.95)
        : kColorWhite.withValues(alpha: 0.38);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        splashColor: kColorWhite.withValues(alpha: 0.18),
        highlightColor: kColorWhite.withValues(alpha: 0.08),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: goldAccent
                  ? const [Color(0xFFFFC239), Color(0xFFFF9D1D)]
                  : glassFill,
            ),
            border: Border.all(
              color: goldAccent
                  ? kColorWhite.withValues(alpha: 0.14)
                  : borderColor,
              width: goldAccent ? 1.0 : 1.35,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2A1744).withValues(alpha: 0.16),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (!goldAccent)
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          kColorWhite.withValues(
                            alpha: onLightSurface ? 0.55 : 0.28,
                          ),
                          kColorWhite.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              Center(child: child),
            ],
          ),
        ),
      ),
    );
  }

  /// Cool region chips under categories — same ids as former filter sheet.
  Widget _regionRow(LiveRoomController controller) {
    const regions = <_RegionChipData>[
      _RegionChipData(
        id: LiveRoomFilterState.allRegions,
        label: 'All',
        icon: Icons.apps_rounded,
        accent: AppLightUi.violet,
        selectedGradient: AppLightUi.familyCtaGradient,
      ),
      _RegionChipData(
        id: 'IN',
        label: 'India',
        icon: Icons.flag_rounded,
        accent: Color(0xFFFF8A1F),
        selectedGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFB020), Color(0xFFFF6B4A)],
        ),
      ),
      _RegionChipData(
        id: 'BD',
        label: 'Bangladesh',
        icon: Icons.outlined_flag_rounded,
        accent: Color(0xFF2DBE6C),
        selectedGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3DD68C), Color(0xFF1FA85A)],
        ),
      ),
      _RegionChipData(
        id: 'GLOBAL',
        label: 'Global',
        icon: Icons.public_rounded,
        accent: AppLightUi.cyan,
        selectedGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5B8DEF), Color(0xFF7B5CFF)],
        ),
      ),
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: regions.length,
        separatorBuilder: (_, __) => Spacing.h8,
        itemBuilder: (context, index) {
          final region = regions[index];
          final selected = controller.filters.region == region.id;
          return _regionChip(
            data: region,
            isSelected: selected,
            onTap: () => controller.onRegionSelected(region.id),
          );
        },
      ),
    );
  }

  Widget _regionChip({
    required _RegionChipData data,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: isSelected
                ? data.selectedGradient
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      kColorWhite.withValues(alpha: 0.92),
                      AppLightUi.cardSoft.withValues(alpha: 0.88),
                    ],
                  ),
            border: Border.all(
              color: isSelected
                  ? kColorWhite.withValues(alpha: 0.38)
                  : data.accent.withValues(alpha: 0.32),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppLightUi.title.withValues(
                  alpha: isSelected ? 0.12 : 0.05,
                ),
                blurRadius: isSelected ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                data.icon,
                size: 15,
                color: isSelected ? kColorWhite : data.accent,
              ),
              Spacing.h6,
              SemiBoldText(
                text: data.label,
                fontSize: TextStyles.k12FontSize,
                color: isSelected ? kColorWhite : AppLightUi.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryRow(List<String> categories) {
    final liveRoomController = _resolveController();
    const accents = <_CategoryAccent>[
      _CategoryAccent(
        icon: Icons.local_fire_department_rounded,
        color: Color(0xFFFF6B4A),
        selectedGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF7A59), Color(0xFFE6252F)],
        ),
      ),
      _CategoryAccent(
        icon: Icons.star_rounded,
        color: AppLightUi.gold,
        selectedGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFC84A), Color(0xFFFF8A1F)],
        ),
      ),
      _CategoryAccent(
        icon: Icons.auto_awesome_rounded,
        color: AppLightUi.violet,
        selectedGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppLightUi.violet, AppLightUi.pink],
        ),
      ),
      _CategoryAccent(
        icon: Icons.location_on_rounded,
        color: AppLightUi.cyan,
        selectedGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5B8DEF), Color(0xFF3D6FE8)],
        ),
      ),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, __) => Spacing.h8,
        itemBuilder: (context, index) {
          final accent = accents[index.clamp(0, accents.length - 1)];
          return _categoryChip(
            label: categories[index],
            accent: accent,
            isSelected: liveRoomController.selectedCategoryIndex == index,
            onTap: () => liveRoomController.onCategorySelected(index),
          );
        },
      ),
    );
  }

  Widget _categoryChip({
    required String label,
    required _CategoryAccent accent,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: isSelected
                ? accent.selectedGradient
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppLightUi.card,
                      AppLightUi.cardSoft.withValues(alpha: 0.92),
                    ],
                  ),
            border: Border.all(
              color: isSelected
                  ? kColorWhite.withValues(alpha: 0.32)
                  : accent.color.withValues(alpha: 0.28),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppLightUi.title.withValues(
                  alpha: isSelected ? 0.12 : 0.06,
                ),
                blurRadius: isSelected ? 14 : 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                accent.icon,
                size: 16,
                color: isSelected ? kColorWhite : accent.color,
              ),
              Spacing.h6,
              SemiBoldText(
                text: label,
                fontSize: TextStyles.k12FontSize,
                color: isSelected ? kColorWhite : AppLightUi.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// TEMP: full-screen mock of the new PK battle stage (no API).
  void _openPkBattleUiPreview() {
    final session = Get.isRegistered<UserSessionController>()
        ? Get.find<UserSessionController>()
        : null;
    final pk = PkV1Coordinator.ensureController();
    pk.bindLiveRoomContext(
      roomId: 'ui_preview_room',
      name: session?.displayName ?? 'You',
      avatar: session?.displayPictureUrl,
    );
    pk.loadUiPreview(
      selfName: session?.displayName,
      selfAvatar: session?.displayPictureUrl,
      selfRoomId: 'ui_preview_room',
    );

    Get.to(
      () => const _PkBattleUiPreviewPage(),
      transition: Transition.fadeIn,
      fullscreenDialog: true,
    )?.whenComplete(pk.clearEmbeddedBattle);
  }

  LiveRoomController _resolveController() {
    if (Get.isRegistered<LiveRoomController>()) {
      return Get.find<LiveRoomController>();
    }
    // Defensive fallback: prevents intermittent null lookup crashes.
    return Get.put(LiveRoomController());
  }

  /// Host profile photo preferred over room cover for hub tiles.
  String? _roomHostAvatarUrl(Map<String, dynamic> room) {
    final nestedMap = _nestedRoomMap(room);
    final hostMap = _hostMap(room, nestedMap);

    return ApiImageUtils.normalize(
      _firstNonEmpty([
        room['hostDisplayPicture'],
        room['hostAvatar'],
        room['displayPicture'],
        hostMap['displayPicture'],
        hostMap['avatar'],
        hostMap['avatarUrl'],
        nestedMap['hostDisplayPicture'],
        nestedMap['hostAvatar'],
        nestedMap['displayPicture'],
        // Cover last — only when no host photo exists.
        room['image'],
        room['coverImage'],
        nestedMap['coverImage'],
      ]),
    );
  }

  String? _roomHostFrameUrl(Map<String, dynamic> room) {
    final nestedMap = _nestedRoomMap(room);
    final hostMap = _hostMap(room, nestedMap);

    return ApiImageUtils.normalize(
      _readFrameUrl(room['avatarFrame']) ??
          _firstNonEmpty([
            room['avatarFrameUrl'],
            room['hostAvatarFrame'],
            room['hostAvatarFrameUrl'],
            room['profileFrameUrl'],
            room['frameUrl'],
          ]) ??
          _readFrameUrl(hostMap['avatarFrame']) ??
          _firstNonEmpty([
            hostMap['avatarFrameUrl'],
            hostMap['profileFrameUrl'],
            hostMap['frameUrl'],
          ]) ??
          _readFrameUrl(nestedMap['avatarFrame']) ??
          _readFrameUrl(nestedMap['hostAvatarFrame']) ??
          _firstNonEmpty([
            nestedMap['avatarFrameUrl'],
            nestedMap['hostAvatarFrameUrl'],
            nestedMap['profileFrameUrl'],
            nestedMap['frameUrl'],
          ]),
    );
  }

  /// When listing omits host frame but the room is yours, reuse AppBar frame.
  String? _sessionFrameIfOwnRoom(Map<String, dynamic> room) {
    final session = _resolveUserSession();
    final sessionFrame = session.profileFrameUrl.trim();
    if (sessionFrame.isEmpty) return null;

    final myId = session.userId.trim();
    if (myId.isEmpty) return null;

    final hostId = _roomHostFrameSeed(room)?.trim() ?? '';
    if (hostId.isNotEmpty && hostId == myId) {
      return ApiImageUtils.normalize(sessionFrame);
    }

    // Title often matches display name for own live rooms.
    final myName = session.userName.trim().toLowerCase();
    final title = (room['nameAge'] as String? ?? '').trim().toLowerCase();
    if (myName.isNotEmpty &&
        (title == myName || title.startsWith('$myName,'))) {
      return ApiImageUtils.normalize(sessionFrame);
    }
    return null;
  }

  String? _roomHostFrameSeed(Map<String, dynamic> room) {
    final nestedMap = _nestedRoomMap(room);
    final hostMap = _hostMap(room, nestedMap);

    return _firstNonEmpty([
      room['hostId'],
      room['userId'],
      hostMap['id'],
      hostMap['userId'],
      hostMap['_id'],
      nestedMap['hostId'],
      nestedMap['userId'],
      nestedMap['createdBy'],
      room['id'],
    ]);
  }

  Map<String, dynamic> _nestedRoomMap(Map<String, dynamic> room) {
    final nested = room['roomData'];
    if (nested is Map) return Map<String, dynamic>.from(nested);
    return const <String, dynamic>{};
  }

  Map<String, dynamic> _hostMap(
    Map<String, dynamic> room,
    Map<String, dynamic> nestedMap,
  ) {
    final host = room['host'] ??
        nestedMap['host'] ??
        nestedMap['owner'] ??
        nestedMap['user'] ??
        nestedMap['hostUser'];
    if (host is Map) return Map<String, dynamic>.from(host);
    return const <String, dynamic>{};
  }

  String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty && text != 'null') return text;
    }
    return null;
  }

  String? _readFrameUrl(dynamic frame) {
    if (frame == null) return null;
    if (frame is String) return _firstNonEmpty([frame]);
    if (frame is Map) {
      return _firstNonEmpty([
        frame['image'],
        frame['imageUrl'],
        frame['url'],
        frame['frameUrl'],
        frame['svga'],
      ]);
    }
    return _firstNonEmpty([frame]);
  }

  UserSessionController _resolveUserSession() {
    if (Get.isRegistered<UserSessionController>()) {
      return Get.find<UserSessionController>();
    }
    return Get.put(UserSessionController(), permanent: true);
  }
}

class _HubPressScale extends StatefulWidget {
  const _HubPressScale({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_HubPressScale> createState() => _HubPressScaleState();
}

class _HubPressScaleState extends State<_HubPressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class _PkBattleUiPreviewPage extends StatelessWidget {
  const _PkBattleUiPreviewPage();

  // TEMP mock chat lines for PK UI preview only.
  static const _mockChat = <(String, String, bool)>[
    ('AlexG', 'Team Blue let\'s go! (GIFT: Star)', true),
    ('GamerPro', 'Mike finish strong!', false),
    ('SarahFan', 'Level 5 Firework! (Gift)', true),
    ('Leo', 'WOW — clock is ticking!', false),
    ('System', 'Mike got an ELITE Gift!', true),
  ];

  @override
  Widget build(BuildContext context) {
    final pk = Get.isRegistered<PkV1Controller>()
        ? Get.find<PkV1Controller>()
        : PkV1Coordinator.ensureController();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const LiveRoomPkBattleBackdrop(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          pk.clearEmbeddedBattle();
                          Get.back();
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const Expanded(
                        child: SemiBoldText(
                          text: 'PK UI preview (temp)',
                          fontSize: TextStyles.k14FontSize,
                          color: kColorWhite,
                          align: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Stage fills remaining space above the mock dock.
                      Positioned(
                        left: 8,
                        right: 8,
                        top: 0,
                        bottom: 118,
                        child: InRoomPkStageOverlay(
                          controller: pk,
                          showEndButton: false,
                        ),
                      ),
                      // Mock chat + floating reactions (preview only).
                      Positioned(
                        left: 12,
                        right: 72,
                        bottom: 72,
                        height: 140,
                        child: IgnorePointer(
                          child: ListView.separated(
                            reverse: true,
                            padding: EdgeInsets.zero,
                            itemCount: _mockChat.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 6),
                            itemBuilder: (context, index) {
                              final item =
                                  _mockChat[_mockChat.length - 1 - index];
                              return _MockChatBubble(
                                name: item.$1,
                                message: item.$2,
                                isGift: item.$3,
                              );
                            },
                          ),
                        ),
                      ),
                      const Positioned(
                        right: 14,
                        bottom: 90,
                        child: IgnorePointer(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.favorite_rounded,
                                  color: Color(0xFFFF4F98), size: 18),
                              SizedBox(height: 8),
                              Icon(Icons.star_rounded,
                                  color: Color(0xFFFFC857), size: 16),
                              SizedBox(height: 8),
                              Icon(Icons.monetization_on_rounded,
                                  color: Color(0xFFFFB020), size: 18),
                              SizedBox(height: 8),
                              Icon(Icons.favorite_rounded,
                                  color: Color(0xFF2F6BFF), size: 14),
                            ],
                          ),
                        ),
                      ),
                      // Viewer chip (preview mock — matches reference).
                      Positioned(
                        left: 12,
                        bottom: 58,
                        child: IgnorePointer(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Text(
                              '@Sarah_Live (13,450 Views)',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: _MockPkBottomBar(
                          onClose: () {
                            pk.clearEmbeddedBattle();
                            Get.back();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MockChatBubble extends StatelessWidget {
  const _MockChatBubble({
    required this.name,
    required this.message,
    required this.isGift,
  });

  final String name;
  final String message;
  final bool isGift;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(14),
        ),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '@$name ',
                style: TextStyle(
                  color: isGift
                      ? const Color(0xFFFFC857)
                      : const Color(0xFF7CFFB2),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              TextSpan(
                text: message,
                style: TextStyle(
                  color: isGift ? const Color(0xFFFFE08A) : Colors.white,
                  fontSize: 11,
                  fontWeight: isGift ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MockPkBottomBar extends StatelessWidget {
  const _MockPkBottomBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24),
          ),
          child: const Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _circleIcon(Icons.add_rounded),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    'Type a message...',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
                Icon(Icons.emoji_emotions_outlined,
                    color: Colors.white54, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF2D55), Color(0xFF2F6BFF)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF2D55).withValues(alpha: 0.45),
                blurRadius: 12,
              ),
            ],
          ),
          child: const Icon(Icons.card_giftcard_rounded,
              color: Colors.white, size: 20),
        ),
        const SizedBox(width: 8),
        _circleIcon(Icons.ios_share_rounded),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: onClose,
          child: _circleIcon(Icons.favorite_border_rounded),
        ),
      ],
    );
  }

  Widget _circleIcon(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.45),
        border: Border.all(color: Colors.white24),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

class _CategoryAccent {
  const _CategoryAccent({
    required this.icon,
    required this.color,
    required this.selectedGradient,
  });

  final IconData icon;
  final Color color;
  final Gradient selectedGradient;
}

class _RegionChipData {
  const _RegionChipData({
    required this.id,
    required this.label,
    required this.icon,
    required this.accent,
    required this.selectedGradient,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color accent;
  final Gradient selectedGradient;
}

