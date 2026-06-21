import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
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
      final controller = TextEditingController(text: initialCountry ?? '');
      final bottomInset = MediaQuery.paddingOf(sheetContext).bottom;

      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
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
                text: 'Enter a country code (e.g. IN, US) or country name.',
                fontSize: TextStyles.k12FontSize,
                color: kColorHint,
              ),
              Spacing.v16,
              AppTextField(
                controller: controller,
                hintText: 'Country',
                borderColor: kColorHint,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.characters,
                prefix: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 12),
                  child: Icon(
                    Icons.public_outlined,
                    size: 20,
                    color: kColorHint.withValues(alpha: 0.9),
                  ),
                ),
              ),
              Spacing.v16,
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(''),
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
                          Navigator.of(sheetContext).pop(controller.text.trim()),
                      buttonText: 'Apply',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
