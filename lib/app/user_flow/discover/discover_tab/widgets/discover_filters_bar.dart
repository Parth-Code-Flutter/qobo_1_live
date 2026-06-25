import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/live_room_ui_colors.dart';
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _countryPickerField(context),
          Spacing.v6,
          SizedBox(
            height: 36,
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
    final hasValue = selected != null;

    return GestureDetector(
      onTap: isLoading ? null : () => controller.openCountryFilterSheet(context),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: _filterCapsuleDecoration(selected: hasValue),
        child: Row(
          children: [
            Icon(
              Icons.public_outlined,
              size: 14,
              color: kColorWhite.withValues(alpha: hasValue ? 1 : 0.85),
            ),
            Spacing.h8,
            Expanded(
              child: isLoading
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: kColorWhite.withValues(alpha: 0.85),
                        ),
                      ),
                    )
                  : SemiBoldText(
                      text: selected?.name ?? 'All countries',
                      fontSize: TextStyles.k12FontSize,
                      color: kColorWhite.withValues(alpha: hasValue ? 1 : 0.85),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: kColorWhite.withValues(alpha: 0.85),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _filterCapsuleDecoration({required bool selected}) {
    return BoxDecoration(
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: _filterCapsuleDecoration(selected: selected),
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
