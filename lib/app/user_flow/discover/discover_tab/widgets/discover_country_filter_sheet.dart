import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/models/geo/country_state_models.dart';
import 'package:qobo_one_live/repo/geo/geo_repo.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/country_state_picker_sheet.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Returns selected country code/name, empty string to clear, or null if dismissed.
Future<String?> showDiscoverCountryFilterSheet({
  required BuildContext context,
  String? initialCountry,
}) {
  return showModalBottomSheet<String?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _DiscoverCountryFilterSheet(
        initialCountry: initialCountry,
        onClose: () => Navigator.of(sheetContext).pop(),
        onApply: (value) => Navigator.of(sheetContext).pop(value),
      );
    },
  );
}

class _DiscoverCountryFilterSheet extends StatefulWidget {
  const _DiscoverCountryFilterSheet({
    required this.initialCountry,
    required this.onClose,
    required this.onApply,
  });

  final String? initialCountry;
  final VoidCallback onClose;
  final ValueChanged<String?> onApply;

  @override
  State<_DiscoverCountryFilterSheet> createState() =>
      _DiscoverCountryFilterSheetState();
}

class _DiscoverCountryFilterSheetState
    extends State<_DiscoverCountryFilterSheet> {
  final GeoRepo _geoRepo = GeoRepo();
  final countries = <CountryOption>[].obs;
  final selected = Rxn<CountryOption>();
  final isLoading = true.obs;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    try {
      isLoading.value = true;
      final list = await _geoRepo.fetchCountries(isShowLoader: false);
      countries.assignAll(list);
      final initial = widget.initialCountry?.trim();
      if (initial != null && initial.isNotEmpty) {
        for (final country in list) {
          if (country.name.toLowerCase() == initial.toLowerCase() ||
              country.code.toLowerCase() == initial.toLowerCase()) {
            selected.value = country;
            break;
          }
        }
      }
    } finally {
      isLoading.value = false;
    }
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
          color: kColorWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SemiBoldText(
              text: 'Filter by country',
              fontSize: TextStyles.k18FontSize,
              color: kColorText,
            ),
            Spacing.v6,
            const AppText(
              text: 'Choose a country to filter the Explore feed.',
              fontSize: TextStyles.k12FontSize,
              color: kColorHint,
            ),
            Spacing.v16,
            Obx(() {
              if (isLoading.value) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return CountryStatePickerField(
                label: 'Country',
                value: selected.value?.name,
                hint: 'Select country',
                onTap: () async {
                  final picked = await showCountryPickerSheet(
                    context,
                    countries: countries,
                    selected: selected.value,
                  );
                  if (picked != null) selected.value = picked;
                },
              );
            }),
            Spacing.v16,
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onClose,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kColorText,
                      side: BorderSide(color: kColorHint.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const SemiBoldText(
                      text: 'Cancel',
                      fontSize: TextStyles.k14FontSize,
                      color: kColorText,
                    ),
                  ),
                ),
                Spacing.h10,
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => widget.onApply(''),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kColorText,
                      side: BorderSide(color: kColorHint.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const SemiBoldText(
                      text: 'Clear',
                      fontSize: TextStyles.k14FontSize,
                      color: kColorText,
                    ),
                  ),
                ),
                Spacing.h10,
                Expanded(
                  flex: 2,
                  child: appButton(
                    onPressed: () =>
                        widget.onApply(selected.value?.code ?? selected.value?.name),
                    buttonText: 'Apply',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
