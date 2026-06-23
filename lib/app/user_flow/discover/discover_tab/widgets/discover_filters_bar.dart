import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/live_room_ui_colors.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/ui_utils/app_ui_utils.dart';

import '../controllers/discover_tab_controller.dart';
import '../models/discover_filter_state.dart';

/// Discover filters — country bottom sheet + gender chips.
class DiscoverFiltersBar extends StatelessWidget {
  const DiscoverFiltersBar({super.key, required this.controller});

  final DiscoverTabController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _countryPickerField(context),
          Spacing.v8,
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              itemCount: 3,
              separatorBuilder: (_, __) => Spacing.h8,
              itemBuilder: (context, index) {
                switch (index) {
                  case 0:
                    return _chip(
                      label: 'Male',
                      selected: controller.filters.value.gender ==
                          DiscoverFilterState.genderMale,
                      onTap: () => controller.toggleGenderFilter(
                        DiscoverFilterState.genderMale,
                      ),
                    );
                  case 1:
                    return _chip(
                      label: 'Female',
                      selected: controller.filters.value.gender ==
                          DiscoverFilterState.genderFemale,
                      onTap: () => controller.toggleGenderFilter(
                        DiscoverFilterState.genderFemale,
                      ),
                    );
                  default:
                    return _chip(
                      label: 'Not following',
                      selected: controller.filters.value.excludeFollowing,
                      onTap: controller.toggleExcludeFollowingFilter,
                    );
                }
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _countryPickerField(BuildContext context) {
    final selected = controller.selectedCountryOption;
    final isLoading =
        controller.isDiscoverFiltersLoading.value &&
        controller.filterCountries.isEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : () => controller.openCountryFilterSheet(context),
        borderRadius: AppUIUtils.primaryBorderRadius,
        child: Ink(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: kColorDiscoverSearchBg,
            borderRadius: AppUIUtils.primaryBorderRadius,
            border: Border.all(
              color: selected != null
                  ? kColorPrimary.withValues(alpha: 0.45)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.public_outlined, size: 18, color: kColorHint),
              Spacing.h8,
              Expanded(
                child: isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : SemiBoldText(
                        text: selected?.name ?? 'All countries',
                        fontSize: TextStyles.k12FontSize,
                        color: selected != null ? kColorText : kColorHint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: kColorHint,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
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
