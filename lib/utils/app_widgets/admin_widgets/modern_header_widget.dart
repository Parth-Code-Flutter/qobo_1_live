import 'package:aligned_rewards/constants/color_constants.dart';
import 'package:aligned_rewards/utils/app_widgets/app_spaces.dart';
import 'package:aligned_rewards/utils/text_utils/app_text.dart';
import 'package:aligned_rewards/utils/text_utils/text_styles.dart';
import 'package:flutter/material.dart';

/// Modern header widget matching app store design
/// 
/// Displays a title, optional subtitle, and an optional action widget (like filter icon)
/// Used across different admin views for consistent header design
class ModernHeaderWidget extends StatelessWidget {
  /// Title text to display (required)
  final String title;
  
  /// Subtitle text to display below title (optional)
  final String? subtitle;
  
  /// Action widget to display on the right side (optional)
  /// Typically used for filter icons or other action buttons
  final Widget? actionWidget;
  
  /// Title font size (default: 28)
  final double? titleFontSize;
  
  /// Subtitle font size (default: 14)
  final double? subtitleFontSize;
  
  /// Title color (default: kColorBlack)
  final Color? titleColor;
  
  /// Subtitle color (default: kColorGrey76)
  final Color? subtitleColor;
  
  /// Background color (default: kColorWhite)
  final Color? backgroundColor;
  
  /// Horizontal padding (default: 18)
  final double? horizontalPadding;
  
  /// Vertical padding (default: 20)
  final double? verticalPadding;

  const ModernHeaderWidget({
    Key? key,
    required this.title,
    this.subtitle,
    this.actionWidget,
    this.titleFontSize,
    this.subtitleFontSize,
    this.titleColor,
    this.subtitleColor,
    this.backgroundColor,
    this.horizontalPadding,
    this.verticalPadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding ?? 18,
        vertical: verticalPadding ?? 20,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? kColorWhite,
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: title,
                  fontSize: titleFontSize ?? 24,
                  color: titleColor ?? kColorBlack,
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  Spacing.v2,
                  AppText(
                    text: subtitle!,
                    fontSize: subtitleFontSize ?? 12,
                    color: subtitleColor ?? kColorGrey76,
                  ),
                ],
              ],
            ),
          ),
          // Action widget (filter icon, etc.)
          if (actionWidget != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: actionWidget!,
            ),
          ],
        ],
      ),
    );
  }
}

