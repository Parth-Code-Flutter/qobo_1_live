import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/models/geo/country_state_models.dart';
import 'package:qobo_one_live/utils/app_widgets/app_bottom_sheet.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

Future<CountryOption?> showCountryPickerSheet(
  BuildContext context, {
  required List<CountryOption> countries,
  CountryOption? selected,
}) {
  return showAppBottomSheet<CountryOption>(
    context: context,
    title: 'Select country',
    subtitle: 'Choose your country',
    child: countries.isEmpty
        ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: AppText(
              text: 'No countries available',
              fontSize: TextStyles.k14FontSize,
              color: kColorHint,
              align: TextAlign.center,
            ),
          )
        : Column(
            children: [
              for (var i = 0; i < countries.length; i++) ...[
                if (i > 0) Spacing.v8,
                _GeoOptionTile(
                  label: countries[i].name,
                  subtitle: countries[i].code,
                  selected: selected?.id == countries[i].id,
                  onTap: () => Navigator.of(context).pop(countries[i]),
                ),
              ],
            ],
          ),
  );
}

/// Result from explore country filter sheet — clear all or a specific country.
class CountryFilterSheetResult {
  const CountryFilterSheetResult.clearAll() : clearAll = true, country = null;
  const CountryFilterSheetResult.selected(this.country) : clearAll = false;

  final bool clearAll;
  final CountryOption? country;
}

/// Explore discover tab — country list with "All countries" (`GET /api/auth/countries`).
Future<CountryFilterSheetResult?> showDiscoverCountryFilterSheet(
  BuildContext context, {
  required List<CountryOption> countries,
  CountryOption? selected,
}) {
  return showAppBottomSheet<CountryFilterSheetResult>(
    context: context,
    title: 'Filter by country',
    subtitle: 'Choose a country for the Explore feed',
    child: countries.isEmpty
        ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: AppText(
              text: 'No countries available',
              fontSize: TextStyles.k14FontSize,
              color: kColorHint,
              align: TextAlign.center,
            ),
          )
        : Column(
            children: [
              _GeoOptionTile(
                label: 'All countries',
                subtitle: 'Show users from every country',
                selected: selected == null,
                onTap: () => Navigator.of(context).pop(
                  const CountryFilterSheetResult.clearAll(),
                ),
              ),
              for (var i = 0; i < countries.length; i++) ...[
                Spacing.v8,
                _GeoOptionTile(
                  label: countries[i].name,
                  subtitle: countries[i].code,
                  selected: selected?.id == countries[i].id,
                  onTap: () => Navigator.of(context).pop(
                    CountryFilterSheetResult.selected(countries[i]),
                  ),
                ),
              ],
            ],
          ),
  );
}

Future<StateOption?> showStatePickerSheet(
  BuildContext context, {
  required List<StateOption> states,
  StateOption? selected,
}) {
  return showAppBottomSheet<StateOption>(
    context: context,
    title: 'Select state',
    subtitle: 'Choose your state',
    child: states.isEmpty
        ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: AppText(
              text: 'No states available for this country',
              fontSize: TextStyles.k14FontSize,
              color: kColorHint,
              align: TextAlign.center,
            ),
          )
        : Column(
            children: [
              for (var i = 0; i < states.length; i++) ...[
                if (i > 0) Spacing.v8,
                _GeoOptionTile(
                  label: states[i].name,
                  selected: selected?.id == states[i].id,
                  onTap: () => Navigator.of(context).pop(states[i]),
                ),
              ],
            ],
          ),
  );
}

class CountryStatePickerField extends StatelessWidget {
  const CountryStatePickerField({
    required this.label,
    required this.value,
    required this.hint,
    required this.onTap,
    this.errorText,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final String? value;
  final String hint;
  final VoidCallback onTap;
  final String? errorText;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;
    final hasValue = value != null && value!.trim().isNotEmpty;
    final borderColor = hasError
        ? kColorRed
        : hasValue
        ? kColorPrimary.withValues(alpha: 0.65)
        : kColorHint.withValues(alpha: 0.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          text: label,
          fontSize: TextStyles.k12FontSize,
          color: kColorText,
        ),
        Spacing.v6,
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: hasValue ? 1.2 : 1),
                color: hasValue
                    ? kColorPrimary.withValues(alpha: 0.04)
                    : kColorWhite,
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.public_outlined,
                      size: 20,
                      color: hasValue ? kColorPrimary : kColorHint,
                    ),
                    Spacing.h10,
                    Expanded(
                      child: hasValue
                          ? SemiBoldText(
                              text: value!,
                              fontSize: TextStyles.k14FontSize,
                              color: kColorText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : AppText(
                              text: hint,
                              fontSize: TextStyles.k14FontSize,
                              color: kColorHint.withValues(alpha: 0.9),
                            ),
                    ),
                    if (isLoading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: kColorHint.withValues(alpha: 0.9),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          Spacing.v4,
          AppText(
            text: errorText!,
            fontSize: TextStyles.k10FontSize,
            color: kColorRed,
          ),
        ],
      ],
    );
  }
}

class _GeoOptionTile extends StatelessWidget {
  const _GeoOptionTile({
    required this.label,
    required this.onTap,
    this.subtitle,
    this.selected = false,
  });

  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: selected
                ? kColorPrimary.withValues(alpha: 0.12)
                : const Color(0xFFF7F8FA),
            border: Border.all(
              color: selected
                  ? kColorPrimary.withValues(alpha: 0.55)
                  : kColorHint.withValues(alpha: 0.25),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SemiBoldText(
                        text: label,
                        fontSize: TextStyles.k14FontSize,
                        color: kColorText,
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        Spacing.v2,
                        AppText(
                          text: subtitle!,
                          fontSize: TextStyles.k10FontSize,
                          color: kColorTextGrey,
                        ),
                      ],
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_rounded, color: kColorPrimary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
