import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/discover_tab_controller.dart';
import '../models/discover_filter_state.dart';

/// Discover filters — country bottom sheet + gender chips.
class DiscoverFiltersBar extends StatelessWidget {
  const DiscoverFiltersBar({super.key, required this.controller});

  final DiscoverTabController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return SizedBox(
        height: 42,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 1),
          children: [
            _countryChip(context),
            Spacing.h8,
            _chip(
              label: 'Male',
              icon: Icons.male_rounded,
              selected:
                  controller.filters.value.gender ==
                  DiscoverFilterState.genderMale,
              onTap: () => controller.toggleGenderFilter(
                DiscoverFilterState.genderMale,
              ),
            ),
            Spacing.h8,
            _chip(
              label: 'Female',
              icon: Icons.female_rounded,
              selected:
                  controller.filters.value.gender ==
                  DiscoverFilterState.genderFemale,
              onTap: () => controller.toggleGenderFilter(
                DiscoverFilterState.genderFemale,
              ),
            ),
            Spacing.h8,
            _chip(
              label: 'New faces',
              icon: Icons.person_add_alt_1_rounded,
              selected: controller.filters.value.excludeFollowing,
              onTap: controller.toggleExcludeFollowingFilter,
            ),
          ],
        ),
      );
    });
  }

  Widget _countryChip(BuildContext context) {
    final selected = controller.selectedCountryOption;
    final isLoading =
        controller.isDiscoverFiltersLoading.value &&
        controller.filterCountries.isEmpty;
    final hasValue = selected != null;

    return _FilterPill(
      label: isLoading ? 'Loading...' : selected?.name ?? 'All countries',
      icon: Icons.public_rounded,
      selected: hasValue,
      trailing: Icons.keyboard_arrow_down_rounded,
      onTap: isLoading
          ? null
          : () => controller.openCountryFilterSheet(context),
    );
  }

  Widget _chip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return _FilterPill(
      label: label,
      icon: icon,
      selected: selected,
      onTap: onTap,
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.fromLTRB(12, 8, trailing == null ? 14 : 10, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      kColorLiveFilterChipGradientStart,
                      kColorLiveFilterChipGradientEnd,
                    ],
                  )
                : null,
            color: selected ? null : kColorWhite.withValues(alpha: 0.14),
            border: Border.all(
              color: selected
                  ? kColorWhite.withValues(alpha: 0.26)
                  : kColorWhite.withValues(alpha: 0.12),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: kColorPrimary.withValues(alpha: 0.20),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 17,
                color: kColorWhite.withValues(alpha: selected ? 1 : 0.82),
              ),
              Spacing.h6,
              SemiBoldText(
                text: label,
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite.withValues(alpha: selected ? 1 : 0.88),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (trailing != null) ...[
                Spacing.h4,
                Icon(
                  trailing,
                  size: 18,
                  color: kColorWhite.withValues(alpha: selected ? 0.95 : 0.78),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
