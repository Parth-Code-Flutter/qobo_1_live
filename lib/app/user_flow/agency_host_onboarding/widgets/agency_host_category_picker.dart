import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_bottom_sheet.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../models/agency_host_interest.dart';

Future<AgencyHostInterest?> showAgencyHostCategoryPicker(
  BuildContext context, {
  AgencyHostInterest? selected,
}) {
  return showAppBottomSheet<AgencyHostInterest>(
    context: context,
    title: 'Select category',
    subtitle: 'Choose your main talent or interest as a host',
    child: Column(
      children: [
        for (var i = 0; i < AgencyHostInterest.values.length; i++) ...[
          if (i > 0) Spacing.v10,
          _CategoryOptionTile(
            interest: AgencyHostInterest.values[i],
            selected: selected == AgencyHostInterest.values[i],
            onTap: () => Navigator.of(context).pop(AgencyHostInterest.values[i]),
          ),
        ],
      ],
    ),
  );
}

class AgencyHostCategoryField extends StatelessWidget {
  const AgencyHostCategoryField({
    required this.selected,
    required this.onTap,
    this.errorText,
    super.key,
  });

  final AgencyHostInterest? selected;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;
    final borderColor = hasError
        ? kColorRed
        : selected != null
        ? kColorPrimary.withValues(alpha: 0.65)
        : kColorHint.withValues(alpha: 0.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: hasError || selected != null ? 1.2 : 1,
                ),
                color: selected != null
                    ? kColorPrimary.withValues(alpha: 0.04)
                    : kColorWhite,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    _leadingIcon(selected),
                    Expanded(
                      child: selected == null
                          ? AppText(
                              text: 'Select interest',
                              fontSize: TextStyles.k14FontSize,
                              color: kColorHint.withValues(alpha: 0.9),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SemiBoldText(
                                  text: selected!.label,
                                  fontSize: TextStyles.k14FontSize,
                                  color: kColorText,
                                ),
                                Spacing.v2,
                                AppText(
                                  text: selected!.subtitle,
                                  fontSize: TextStyles.k10FontSize,
                                  color: kColorHint,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: hasError ? kColorRed : kColorHint,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          Spacing.v6,
          AppText(
            text: errorText!,
            fontSize: TextStyles.k12FontSize,
            color: kColorRed,
          ),
        ],
      ],
    );
  }

  Widget _leadingIcon(AgencyHostInterest? value) {
    if (value == null) {
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Icon(
          Icons.interests_outlined,
          size: 20,
          color: kColorHint,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: value.accentColor.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(value.icon, size: 18, color: value.accentColor),
      ),
    );
  }
}

class _CategoryOptionTile extends StatelessWidget {
  const _CategoryOptionTile({
    required this.interest,
    required this.selected,
    required this.onTap,
  });

  final AgencyHostInterest interest;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: selected
                ? interest.accentColor.withValues(alpha: 0.1)
                : kColorWhite,
            border: Border.all(
              color: selected
                  ? interest.accentColor.withValues(alpha: 0.55)
                  : kColorHint.withValues(alpha: 0.35),
              width: selected ? 1.4 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: interest.accentColor.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      interest.accentColor.withValues(alpha: 0.9),
                      interest.accentColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(interest.icon, color: kColorWhite, size: 22),
              ),
              Spacing.h12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemiBoldText(
                      text: interest.label,
                      fontSize: TextStyles.k14FontSize,
                      color: kColorText,
                    ),
                    Spacing.v2,
                    AppText(
                      text: interest.subtitle,
                      fontSize: TextStyles.k12FontSize,
                      color: kColorHint,
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? interest.accentColor : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? interest.accentColor
                        : kColorHint.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check_rounded, size: 14, color: kColorWhite)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
