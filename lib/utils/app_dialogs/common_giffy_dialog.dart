import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Reusable success/failure dialogs with a consistent, native Flutter layout.
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
      title: title ?? 'Congratulations!',
      subtitle: subtitle,
      buttonText: buttonText,
      onPressed: onPressed,
      gifAssetPath: gifAssetPath,
      barrierDismissible: barrierDismissible,
      variant: _DialogVariant.success,
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
      title: title ?? 'Something went wrong',
      subtitle: subtitle,
      buttonText: buttonText,
      onPressed: onPressed,
      gifAssetPath: gifAssetPath,
      barrierDismissible: barrierDismissible,
      variant: _DialogVariant.failure,
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
      title: title ?? 'Notice',
      subtitle: subtitle,
      buttonText: buttonText,
      onPressed: onPressed,
      gifAssetPath: gifAssetPath,
      barrierDismissible: barrierDismissible,
      variant: _DialogVariant.custom,
      accentColor: accentColor,
    );
  }

  static Future<void> _show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
    required String gifAssetPath,
    required _DialogVariant variant,
    Color accentColor = kColorPrimary,
    required bool barrierDismissible,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: kColorWhite,
          shadowColor: kColorPrimary.withValues(alpha: 0.24),
          surfaceTintColor: kColorWhite,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(
              color: kColorPrimary.withValues(alpha: 0.10),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _heroIcon(
                  variant: variant,
                  accentColor: accentColor,
                  gifAssetPath: gifAssetPath,
                ),
                Spacing.v20,
                SemiBoldText(
                  text: title,
                  fontSize: TextStyles.k20FontSize,
                  color: kColorText,
                  align: TextAlign.center,
                ),
                Spacing.v10,
                _subtitleContent(subtitle),
                Spacing.v24,
                appButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    onPressed();
                  },
                  buttonText: buttonText,
                  buttonHeight: 48,
                  isGradient: variant != _DialogVariant.failure,
                  buttonColor: variant == _DialogVariant.failure
                      ? kColorRed
                      : kColorPrimary,
                  buttonBorderColor: variant == _DialogVariant.failure
                      ? kColorRed
                      : kColorPrimary,
                  textStyle: TextStyles.kSemiBoldPoppins(
                    fontSize: TextStyles.k14FontSize,
                    colors: kColorWhite,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _heroIcon({
    required _DialogVariant variant,
    required Color accentColor,
    required String gifAssetPath,
  }) {
    final isSuccess = variant == _DialogVariant.success;
    final isFailure = variant == _DialogVariant.failure;
    final iconColor = isFailure ? kColorRed : accentColor;
    final iconData = isSuccess
        ? Icons.check_rounded
        : isFailure
        ? Icons.close_rounded
        : Icons.info_outline_rounded;

    return SizedBox(
      height: 104,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (isSuccess) ..._confettiDots(),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isSuccess
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF9B3D86), kColorPrimary],
                    )
                  : null,
              color: isSuccess ? null : iconColor.withValues(alpha: 0.12),
              boxShadow: isSuccess
                  ? [
                      BoxShadow(
                        color: kColorPrimary.withValues(alpha: 0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: isSuccess && gifAssetPath.trim().isNotEmpty
                ? Image.asset(
                    gifAssetPath,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => Icon(
                      iconData,
                      color: kColorWhite,
                      size: 40,
                    ),
                  )
                : Icon(
                    iconData,
                    color: isSuccess ? kColorWhite : iconColor,
                    size: 40,
                  ),
          ),
        ],
      ),
    );
  }

  static List<Widget> _confettiDots() {
    const dots = <({double dx, double dy, Color color, double size})>[
      (dx: -52, dy: -18, color: Color(0xFF9B3D86), size: 7),
      (dx: 54, dy: -12, color: Color(0xFF5C1364), size: 6),
      (dx: -44, dy: 24, color: Color(0xFFE6252F), size: 5),
      (dx: 48, dy: 20, color: Color(0xFF7C4DFF), size: 6),
      (dx: -8, dy: -34, color: Color(0xFF4ADE80), size: 5),
      (dx: 12, dy: 30, color: Color(0xFF9B3D86), size: 5),
    ];

    return dots
        .map(
          (dot) => Transform.translate(
            offset: Offset(dot.dx, dot.dy),
            child: Container(
              width: dot.size,
              height: dot.size,
              decoration: BoxDecoration(
                color: dot.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        )
        .toList();
  }

  static Widget _subtitleContent(String subtitle) {
    final lines = subtitle
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) return const SizedBox.shrink();
    if (lines.length == 1) {
      return AppText(
        text: lines.first,
        fontSize: TextStyles.k14FontSize,
        color: kColorTextGrey,
        align: TextAlign.center,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SemiBoldText(
          text: lines.first,
          fontSize: TextStyles.k16FontSize,
          color: kColorText,
          align: TextAlign.center,
        ),
        Spacing.v4,
        AppText(
          text: lines.sublist(1).join('\n'),
          fontSize: TextStyles.k12FontSize,
          color: kColorTextGrey,
          align: TextAlign.center,
        ),
      ],
    );
  }
}

enum _DialogVariant { success, failure, custom }
