import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Shared header for Super Admin tabs — gradient icon badge + title/subtitle.
class SuperAdminTabHeader extends StatelessWidget {
  const SuperAdminTabHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  kColorLiveFilterChipGradientStart,
                  kColorLiveFilterChipGradientEnd,
                ],
              ),
              border: Border.all(color: kColorWhite.withValues(alpha: 0.22)),
              boxShadow: [
                BoxShadow(
                  color: kColorPrimary.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: kColorWhite, size: 22),
          ),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: title,
                  fontSize: TextStyles.k20FontSize,
                  color: kColorWhite,
                ),
                Spacing.v2,
                AppText(
                  text: subtitle,
                  fontSize: TextStyles.k12FontSize,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared empty-state placeholder for Super Admin lists.
class SuperAdminEmptyState extends StatelessWidget {
  const SuperAdminEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: kColorWhite.withValues(alpha: 0.08),
            border: Border.all(color: kColorWhite.withValues(alpha: 0.14)),
          ),
          child: Icon(icon, color: Colors.white54, size: 32),
        ),
        Spacing.v16,
        SemiBoldText(
          text: title,
          fontSize: TextStyles.k14FontSize,
          color: kColorWhite,
        ),
        Spacing.v6,
        AppText(
          text: subtitle,
          fontSize: TextStyles.k12FontSize,
          color: Colors.white60,
          align: TextAlign.center,
        ),
      ],
    );
  }
}
