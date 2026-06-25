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
          Spacing.v8,
          SizedBox(
            height: 38,
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
                      icon: Icons.male_rounded,
                      selected:
                          controller.filters.value.gender ==
                          DiscoverFilterState.genderMale,
                      onTap: () => controller.toggleGenderFilter(
                        DiscoverFilterState.genderMale,
                      ),
                    );
                  case 1:
                    return _chip(
                      label: 'Female',
                      icon: Icons.female_rounded,
                      selected:
                          controller.filters.value.gender ==
                          DiscoverFilterState.genderFemale,
                      onTap: () => controller.toggleGenderFilter(
                        DiscoverFilterState.genderFemale,
                      ),
                    );
                  default:
                    return _chip(
                      label: 'Not following',
                      icon: Icons.person_off_outlined,
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
      onTap: isLoading
          ? null
          : () => controller.openCountryFilterSheet(context),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 40,
        padding: const EdgeInsets.fromLTRB(10, 4, 8, 4),
        decoration: _countryCapsuleDecoration(selected: hasValue),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: kColorWhite.withValues(alpha: hasValue ? 0.20 : 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.public_rounded,
                size: 15,
                color: kColorWhite.withValues(alpha: hasValue ? 1 : 0.86),
              ),
            ),
            Spacing.h10,
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
                      color: kColorWhite.withValues(alpha: hasValue ? 1 : 0.9),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: kColorWhite.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: kColorWhite.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _countryCapsuleDecoration({required bool selected}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: selected
            ? const [
                kColorLiveFilterChipGradientStart,
                kColorLiveFilterChipGradientEnd,
              ]
            : [
                kColorWhite.withValues(alpha: 0.17),
                kColorWhite.withValues(alpha: 0.10),
              ],
      ),
      border: Border.all(
        color: selected
            ? kColorWhite.withValues(alpha: 0.26)
            : kColorWhite.withValues(alpha: 0.08),
      ),
      boxShadow: [
        BoxShadow(
          color: kColorPrimary.withValues(alpha: selected ? 0.18 : 0.10),
          blurRadius: 12,
          offset: const Offset(0, 5),
        ),
      ],
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
            ? kColorWhite.withValues(alpha: 0.22)
            : kColorWhite.withValues(alpha: 0.08),
      ),
      boxShadow: selected
          ? [
              BoxShadow(
                color: kColorPrimary.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ]
          : null,
    );
  }

  Widget _chip({
    required String label,
    required IconData icon,
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: _filterCapsuleDecoration(selected: selected),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: kColorWhite.withValues(alpha: selected ? 1 : 0.84),
              ),
              Spacing.h6,
              SemiBoldText(
                text: label,
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite.withValues(alpha: selected ? 1 : 0.9),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
