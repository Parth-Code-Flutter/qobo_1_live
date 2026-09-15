import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/discover_tab_controller.dart';
import '../models/discover_feed_layout.dart';
import '../widgets/discover_country_filter_sheet.dart';
import '../widgets/discover_users_feed.dart';

class DiscoverTabView extends StatelessWidget {
  const DiscoverTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final discoverController = _resolveController();

    return Container(
      decoration: const BoxDecoration(
        color: kColorLavenderBg,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topHeader(context, discoverController),
              Spacing.v10,
              Expanded(
                child: Obx(() {
                  if (discoverController.searchQuery.value.isNotEmpty) {
                    return DiscoverUsersFeed(
                      controller: discoverController,
                      users: discoverController.searchResults.toList(),
                      isLoading: discoverController.isSearchLoading.value,
                      emptyMessage:
                          'No users found matching "${discoverController.searchQuery.value}"',
                      enablePullToRefresh: false,
                    );
                  }
                  return DiscoverUsersFeed(controller: discoverController);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topHeader(
    BuildContext context,
    DiscoverTabController discoverController,
  ) {
    return Obx(() {
      if (discoverController.isSearchExpanded.value) {
        return _expandedSearchBar(discoverController);
      }

      return SizedBox(
        height: 58,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SemiBoldText(
                    text: 'Discover',
                    fontSize: TextStyles.k24FontSize,
                    color: AppLightUi.title,
                  ),
                  AppText(
                    text: 'Find your next spark',
                    fontSize: TextStyles.k12FontSize,
                    color: AppLightUi.subtitle,
                  ),
                ],
              ),
            ),
            _headerIconButton(
              onTap: discoverController.openSearch,
              icon: const Icon(
                Icons.search_rounded,
                size: 21,
                color: AppLightUi.pink,
              ),
            ),
            Spacing.h6,
            Obx(() {
              final hasFilter = discoverController.hasActiveDiscoverFilters;
              return _headerIconButton(
                onTap: () =>
                    _openCountryFilter(context, discoverController),
                icon: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    SvgPicture.asset(
                      kIconFilter,
                      width: 21,
                      height: 21,
                      colorFilter: const ColorFilter.mode(
                        AppLightUi.pink,
                        BlendMode.srcIn,
                      ),
                    ),
                    if (hasFilter)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppLightUi.pink,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
            Spacing.h6,
            _feedLayoutToggle(discoverController),
          ],
        ),
      );
    });
  }

  /// Grid / single-profile switch in the AppBar (rightmost).
  /// Hidden while searching so results stay full-width without layout noise.
  Widget _feedLayoutToggle(DiscoverTabController discoverController) {
    return Obx(() {
      if (discoverController.isSearchExpanded.value ||
          discoverController.searchQuery.value.isNotEmpty) {
        return const SizedBox.shrink();
      }

      final selected = discoverController.feedLayout.value;
      return DecoratedBox(
        decoration: AppLightUi.cardDecoration(radius: 12),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _layoutToggleButton(
                icon: Icons.grid_view_rounded,
                selected: selected == DiscoverFeedLayout.grid,
                onTap: () =>
                    discoverController.setFeedLayout(DiscoverFeedLayout.grid),
              ),
              Spacing.h4,
              _layoutToggleButton(
                icon: Icons.view_agenda_rounded,
                selected: selected == DiscoverFeedLayout.single,
                onTap: () => discoverController.setFeedLayout(
                  DiscoverFeedLayout.single,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _layoutToggleButton({
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          width: 36,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            gradient: selected ? AppLightUi.ctaGradient : null,
            color: selected ? null : Colors.transparent,
          ),
          child: Icon(
            icon,
            size: 18,
            color: selected ? kColorWhite : AppLightUi.muted,
          ),
        ),
      ),
    );
  }

  Widget _headerIconButton({
    required VoidCallback onTap,
    required Widget icon,
  }) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppLightUi.card,
            border: Border.all(color: AppLightUi.border),
            boxShadow: AppLightUi.cardShadow,
          ),
          child: Center(child: icon),
        ),
      ),
    );
  }

  Widget _expandedSearchBar(DiscoverTabController discoverController) {
    return Row(
      children: [
        Material(
          color: AppLightUi.card,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: discoverController.closeSearch,
            customBorder: const CircleBorder(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppLightUi.border),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppLightUi.title,
                size: 18,
              ),
            ),
          ),
        ),
        Spacing.h10,
        Expanded(
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(26),
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: AppLightUi.searchDecoration(),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    size: 22,
                    color: AppLightUi.hint,
                  ),
                  Spacing.h10,
                  Expanded(
                    child: TextField(
                      controller: discoverController.searchController,
                      focusNode: discoverController.searchFocusNode,
                      textInputAction: TextInputAction.search,
                      style: TextStyles.kRegularPoppins(
                        fontSize: TextStyles.k14FontSize,
                        colors: AppLightUi.body,
                      ),
                      cursorColor: AppLightUi.pink,
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Search people',
                        hintStyle: TextStyles.kRegularPoppins(
                          fontSize: TextStyles.k14FontSize,
                          colors: AppLightUi.hint,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  Obx(() {
                    if (discoverController.searchQuery.value.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return GestureDetector(
                      onTap: discoverController.searchController.clear,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppLightUi.pink.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppLightUi.muted,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openCountryFilter(
    BuildContext context,
    DiscoverTabController controller,
  ) async {
    final result = await showDiscoverFilterSheet(
      context: context,
      initial: controller.filters.value,
    );
    if (result == null) return;
    await controller.applyDiscoverFilters(result);
  }

  DiscoverTabController _resolveController() {
    if (Get.isRegistered<DiscoverTabController>()) {
      return Get.find<DiscoverTabController>();
    }
    return Get.put(DiscoverTabController());
  }
}
