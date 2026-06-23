import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/live_room_ui_colors.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/discover_tab_controller.dart';
import '../models/discover_filter_state.dart';

/// Horizontal discover filters above the Explore user grid.
class DiscoverFiltersBar extends StatelessWidget {
  const DiscoverFiltersBar({super.key, required this.controller});

  final DiscoverTabController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isDiscoverFiltersLoading.value &&
          controller.filterCountries.isEmpty) {
        return const SizedBox(
          height: 40,
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(kColorPrimary),
              ),
            ),
          ),
        );
      }

      final chips = <Widget>[
        _chip(
          label: 'All',
          selected: !controller.filters.value.hasActiveFilters,
          onTap: controller.clearDiscoverFilters,
        ),
        _chip(
          label: 'Male',
          selected: controller.filters.value.gender ==
              DiscoverFilterState.genderMale,
          onTap: () => controller.toggleGenderFilter(
            DiscoverFilterState.genderMale,
          ),
        ),
        _chip(
          label: 'Female',
          selected: controller.filters.value.gender ==
              DiscoverFilterState.genderFemale,
          onTap: () => controller.toggleGenderFilter(
            DiscoverFilterState.genderFemale,
          ),
        ),
        _chip(
          label: 'Not following',
          selected: controller.filters.value.excludeFollowing,
          onTap: controller.toggleExcludeFollowingFilter,
        ),
        for (final country in controller.filterCountries)
          _chip(
            label: country.name,
            selected: controller.filters.value.country == country.code ||
                controller.filters.value.country?.toLowerCase() ==
                    country.name.toLowerCase(),
            onTap: () => controller.toggleCountryFilter(country),
          ),
      ];

      return SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          itemCount: chips.length,
          separatorBuilder: (_, __) => Spacing.h8,
          itemBuilder: (_, index) => chips[index],
        ),
      );
    });
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: selected
                ? const LinearGradient(
                    colors: [
                      kColorLiveFilterChipGradientStart,
                      kColorLiveFilterChipGradientEnd,
                    ],
                  )
                : null,
            color: selected ? null : LiveRoomUiColors.chipInactiveBg,
            border: Border.all(
              color: selected
                  ? kColorLiveFilterChipBorder
                  : LiveRoomUiColors.cardBorder,
            ),
          ),
          child: Center(
            child: SemiBoldText(
              text: label,
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
