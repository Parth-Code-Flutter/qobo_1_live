import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/models/geo/country_state_models.dart';
import 'package:qobo_one_live/repo/geo/geo_repo.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/country_state_picker_sheet.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../models/discover_filter_state.dart';

/// Returns updated filters, or null if dismissed.
Future<DiscoverFilterState?> showDiscoverFilterSheet({
  required BuildContext context,
  required DiscoverFilterState initial,
}) {
  return showModalBottomSheet<DiscoverFilterState?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _DiscoverFilterSheet(
        initial: initial,
        onClose: () => Navigator.of(sheetContext).pop(),
        onApply: (value) => Navigator.of(sheetContext).pop(value),
      );
    },
  );
}

class _DiscoverFilterSheet extends StatefulWidget {
  const _DiscoverFilterSheet({
    required this.initial,
    required this.onClose,
    required this.onApply,
  });

  final DiscoverFilterState initial;
  final VoidCallback onClose;
  final ValueChanged<DiscoverFilterState> onApply;

  @override
  State<_DiscoverFilterSheet> createState() => _DiscoverFilterSheetState();
}

class _DiscoverFilterSheetState extends State<_DiscoverFilterSheet> {
  final GeoRepo _geoRepo = GeoRepo();
  final countries = <CountryOption>[].obs;
  final selectedCountry = Rxn<CountryOption>();
  final selectedGender = RxnString();
  final excludeFollowing = false.obs;
  final isLoading = true.obs;

  @override
  void initState() {
    super.initState();
    selectedGender.value = widget.initial.gender;
    excludeFollowing.value = widget.initial.excludeFollowing;
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    try {
      isLoading.value = true;
      final list = await _geoRepo.fetchCountries(isShowLoader: false);
      countries.assignAll(list);
      final initial = widget.initial.country?.trim();
      if (initial != null && initial.isNotEmpty) {
        for (final country in list) {
          if (country.code.toLowerCase() == initial.toLowerCase() ||
              country.name.toLowerCase() == initial.toLowerCase()) {
            selectedCountry.value = country;
            break;
          }
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  DiscoverFilterState _buildResult() {
    final country = selectedCountry.value;
    return DiscoverFilterState(
      country: country?.code ?? country?.name,
      gender: selectedGender.value,
      excludeFollowing: excludeFollowing.value,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomInset),
        decoration: const BoxDecoration(
          color: AppLightUi.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: AppLightUi.border),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppLightUi.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SemiBoldText(
              text: 'Explore filters',
              fontSize: TextStyles.k18FontSize,
              color: AppLightUi.title,
            ),
            Spacing.v6,
            const AppText(
              text:
                  'Filter users by country, gender, or hide people you already follow.',
              fontSize: TextStyles.k12FontSize,
              color: AppLightUi.subtitle,
            ),
            Spacing.v16,
            const AppText(
              text: 'Gender',
              fontSize: TextStyles.k12FontSize,
              color: AppLightUi.body,
            ),
            Spacing.v8,
            Obx(
              () => Row(
                children: [
                  _genderChip('All', selectedGender.value == null, () {
                    selectedGender.value = null;
                  }),
                  Spacing.h8,
                  _genderChip(
                    'Male',
                    selectedGender.value == DiscoverFilterState.genderMale,
                    () => selectedGender.value = DiscoverFilterState.genderMale,
                  ),
                  Spacing.h8,
                  _genderChip(
                    'Female',
                    selectedGender.value == DiscoverFilterState.genderFemale,
                    () =>
                        selectedGender.value = DiscoverFilterState.genderFemale,
                  ),
                ],
              ),
            ),
            Spacing.v16,
            Obx(() {
              if (isLoading.value) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(color: AppLightUi.pink),
                  ),
                );
              }
              return CountryStatePickerField(
                label: 'Country',
                value: selectedCountry.value?.name,
                hint: 'All countries',
                onTap: () async {
                  final picked = await showCountryPickerSheet(
                    context,
                    countries: countries.toList(),
                    selected: selectedCountry.value,
                  );
                  selectedCountry.value = picked;
                },
              );
            }),
            Spacing.v12,
            Obx(
              () => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const SemiBoldText(
                  text: 'Hide users I follow',
                  fontSize: TextStyles.k14FontSize,
                  color: AppLightUi.title,
                ),
                subtitle: const AppText(
                  text: 'Show only users you have not followed yet',
                  fontSize: TextStyles.k10FontSize,
                  color: AppLightUi.muted,
                ),
                value: excludeFollowing.value,
                activeThumbColor: kColorWhite,
                activeTrackColor: AppLightUi.pink,
                onChanged: (v) => excludeFollowing.value = v,
              ),
            ),
            Spacing.v16,
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onClose,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppLightUi.title,
                      side: const BorderSide(color: AppLightUi.borderStrong),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const SemiBoldText(
                      text: 'Cancel',
                      fontSize: TextStyles.k14FontSize,
                      color: AppLightUi.title,
                    ),
                  ),
                ),
                Spacing.h10,
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      selectedCountry.value = null;
                      selectedGender.value = null;
                      excludeFollowing.value = false;
                      widget.onApply(const DiscoverFilterState());
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppLightUi.title,
                      side: const BorderSide(color: AppLightUi.borderStrong),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const SemiBoldText(
                      text: 'Clear',
                      fontSize: TextStyles.k14FontSize,
                      color: AppLightUi.title,
                    ),
                  ),
                ),
                Spacing.h10,
                Expanded(
                  flex: 2,
                  child: appButton(
                    onPressed: () => widget.onApply(_buildResult()),
                    buttonText: 'Apply',
                    isGradient: true,
                    gradientColors: const [AppLightUi.pink, AppLightUi.violet],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _genderChip(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: selected
                  ? AppLightUi.pink.withValues(alpha: 0.12)
                  : AppLightUi.cardSoft,
              border: Border.all(
                color: selected
                    ? AppLightUi.pink.withValues(alpha: 0.55)
                    : AppLightUi.border,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: SemiBoldText(
                  text: label,
                  fontSize: TextStyles.k12FontSize,
                  color: selected ? AppLightUi.pink : AppLightUi.title,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Legacy entry — opens full filter sheet and returns country code only.
Future<String?> showDiscoverCountryFilterSheet({
  required BuildContext context,
  String? initialCountry,
}) async {
  final result = await showDiscoverFilterSheet(
    context: context,
    initial: DiscoverFilterState(country: initialCountry),
  );
  if (result == null) return null;
  return result.country ?? '';
}
