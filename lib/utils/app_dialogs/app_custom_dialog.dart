import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/ui_utils/app_ui_utils.dart';
import 'package:flutter/material.dart';

/// A reusable two‑button dialog that accepts any custom [content] widget.
///
/// Usage:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (_) => AppCustomDialog(
///     title: 'Create New Folder',
///     content: AppTextField(...),
///     primaryButtonText: 'Create',
///     secondaryButtonText: 'Cancel',
///     onPrimaryPressed: () { ... },
///     onSecondaryPressed: () { Get.back(); },
///   ),
/// );
/// ```
class AppCustomDialog extends StatelessWidget {
  const AppCustomDialog({
    super.key,
    required this.title,
    required this.content,
    required this.primaryButtonText,
    required this.secondaryButtonText,
    required this.onPrimaryPressed,
    required this.onSecondaryPressed,
    this.bottomContent,
  });

  final String title;
  final Widget content;
  final String primaryButtonText;
  final String secondaryButtonText;
  final VoidCallback onPrimaryPressed;
  final VoidCallback onSecondaryPressed;
  // Optional widget rendered below [content] but above the action buttons.
  // This is useful for auxiliary controls such as media upload selectors
  // that should share the same dialog shell.
  final Widget? bottomContent;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kColorWhite,
      shadowColor: Colors.transparent,
      surfaceTintColor: kColorWhite,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: AppUIUtils.primaryBorderRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              text: title,
              style: TextStyles.kSemiBoldPoppins(
                fontSize: TextStyles.k16FontSize,
                colors: kColorBlack,
              ),
            ),
            Spacing.v16,
            content,
            if (bottomContent != null) ...[
              Spacing.v12,
              bottomContent!,
            ],
            Spacing.v20,
            Row(
              children: [
                Expanded(
                  child: appButton(
                    onPressed: onPrimaryPressed,
                    buttonText: primaryButtonText,
                    buttonHeight: 44,
                  ),
                ),
                Spacing.h12,
                Expanded(
                  child: appButton(
                    onPressed: onSecondaryPressed,
                    buttonText: secondaryButtonText,
                    buttonHeight: 44,
                    buttonColor: kColorHint,
                    buttonBorderColor: kColorHint,
                    isGradient: false,
                    textStyle: TextStyles.kSemiBoldPoppins(
                      fontSize: TextStyles.k14FontSize,
                      colors: kColorBlack,
                    ),
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

