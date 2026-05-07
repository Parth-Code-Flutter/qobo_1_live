import 'package:flutter/material.dart';
import 'package:giffy_dialog/giffy_dialog.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Reusable Giffy dialog API to keep success/failure/custom dialogs consistent.
class CommonGiffyDialog {
  CommonGiffyDialog._();

  static Future<void> showSuccess(
    BuildContext context, {
    String? title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
    required String gifAssetPath,
    bool barrierDismissible = false,
  }) {
    return _show(
      context,
      title: title,
      subtitle: subtitle,
      buttonText: buttonText,
      onPressed: onPressed,
      gifAssetPath: gifAssetPath,
      barrierDismissible: barrierDismissible,
      accentColor: kColorWhite,
    );
  }

  static Future<void> showFailure(
    BuildContext context, {
    String? title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
    required String gifAssetPath,
    bool barrierDismissible = true,
  }) {
    return _show(
      context,
      title: title,
      subtitle: subtitle,
      buttonText: buttonText,
      onPressed: onPressed,
      gifAssetPath: gifAssetPath,
      barrierDismissible: barrierDismissible,
      accentColor: kColorRed,
    );
  }

  static Future<void> showCustom(
    BuildContext context, {
    String? title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
    required String gifAssetPath,
    Color accentColor = kColorPrimary,
    bool barrierDismissible = true,
  }) {
    return _show(
      context,
      title: title,
      subtitle: subtitle,
      buttonText: buttonText,
      onPressed: onPressed,
      gifAssetPath: gifAssetPath,
      barrierDismissible: barrierDismissible,
      accentColor: accentColor,
    );
  }

  /// Omits title row when [title] is null or only whitespace — matches [GiffyDialog] optional title.
  static Widget? _titleWidget(String? title) {
    final t = title?.trim();
    if (t == null || t.isEmpty) return null;
    return Text(
      t,
      textAlign: TextAlign.center,
      style: TextStyles.kSemiBoldPoppins(
        fontSize: TextStyles.k20FontSize,
        colors: kColorText,
      ),
    );
  }

  static Future<void> _show(
    BuildContext context, {
    String? title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
    required String gifAssetPath,
    required Color accentColor,
    required bool barrierDismissible,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) {
        return GiffyDialog.image(
          Image.asset(gifAssetPath, fit: BoxFit.cover),
          backgroundColor: kColorWhite,
          surfaceTintColor: kColorWhite,
          giffyBuilder: (context, giffy) => ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(height: 220, width: double.infinity, child: giffy),
          ),
          entryAnimation: EntryAnimation.bottom,
          scrollable: true,
          title: _titleWidget(title),
          content: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyles.kRegularPoppins(
              fontSize: TextStyles.k14FontSize,
              colors: kColorTextGrey,
            ),
          ),
          actions: [
            Center(
              child: appButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  onPressed();
                },
                textColor: kColorPrimary,
                buttonText: buttonText,
                isGradient: false,
                buttonColor: accentColor,
                buttonBorderColor: kColorPrimary,
                buttonHeight: 40,
                buttonWidth: 140,
                borderRadius: 12,
              ),
            ),
          ],
        );
      },
    );
  }
}
