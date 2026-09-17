import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/ui_utils/app_ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Creates a customizable button widget with support for gradient and solid colors.
///
/// By default, buttons use the login CTA gradient (violet → pink).
/// Set `isGradient: false` to use a solid color instead.
///
/// Parameters:
/// - [onPressed]: Callback function when button is tapped
/// - [buttonText]: Text to display on the button
/// - [textColor]: Color of the button text (defaults to white)
/// - [buttonColor]: Background color for solid buttons or base color for gradients
/// - [buttonBorderColor]: Color of the button border
/// - [buttonHeight]: Height of the button (defaults to 54)
/// - [buttonIcon]: Optional icon widget to display before the text
/// - [buttonWidth]: Width of the button (defaults to screen width)
/// - [textStyle]: Custom text style for the button text
/// - [borderRadius]: Border radius of the button
/// - [isGradient]: Whether to use gradient effect (defaults to true)
/// - [gradientColors]: Custom gradient colors (defaults to [AppLightUi.familyCtaColors])
Widget appButton({
  required VoidCallback onPressed,
  required String buttonText,
  Color? textColor,
  Color? buttonColor,
  Color? buttonBorderColor,
  double? buttonHeight,
  Widget? buttonIcon,
  double? buttonWidth,
  TextStyle? textStyle,
  double? borderRadius,
  bool? isGradient = true,
  List<Color>? gradientColors,
}) {
  return GestureDetector(
    onTap: () {
      FocusManager.instance.primaryFocus?.unfocus();
      onPressed();
    },
    child: Container(
      height: buttonHeight ?? 52,
      width: buttonWidth ?? Get.width,
      decoration: isGradient == true
          ? _gradientDecoration(
              gradientColors,
              buttonColor,
              borderRadius,
              buttonBorderColor,
            )
          : _simpleDecoration(buttonColor, borderRadius, buttonBorderColor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buttonIcon != null ? const SizedBox(width: 10) : Container(),
          buttonIcon ?? const SizedBox(),
          Text(
            buttonText,
            style:
                textStyle ??
                TextStyles.kBoldPoppins(
                  fontSize: TextStyles.k14FontSize,
                  colors: textColor ?? kColorWhite,
                ),
          ),
        ],
      ),
    ),
  );
}

/// Creates a simple solid color decoration for buttons.
///
/// Used when `isGradient` is set to `false`.
///
/// Parameters:
/// - [buttonColor]: Background color (defaults to primary color)
/// - [borderRadius]: Border radius (defaults to primary radius)
/// - [buttonBorderColor]: Border color (defaults to primary color)
BoxDecoration _simpleDecoration(buttonColor, borderRadius, buttonBorderColor) {
  return BoxDecoration(
    color: buttonColor ?? kColorPrimary,
    borderRadius: BorderRadius.circular(
      borderRadius ?? AppUIUtils.primaryRadius,
    ),
    border: Border.all(
      color: buttonBorderColor ?? buttonColor ?? kColorPrimary,
      width: 0.5,
    ),
  );
}

/// Creates a gradient decoration matching the login CTA (violet → pink).
BoxDecoration _gradientDecoration(
  gradientColors,
  buttonColor,
  borderRadius,
  buttonBorderColor,
) {
  final List<Color> colors =
      (gradientColors as List<Color>?) ?? AppLightUi.familyCtaColors;

  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: colors,
    ),
    borderRadius: BorderRadius.circular(
      borderRadius ?? AppUIUtils.primaryRadius,
    ),
    border: Border.all(
      color: buttonBorderColor ?? Colors.transparent,
      width: buttonBorderColor == null ? 0 : 1,
    ),
    boxShadow: [
      BoxShadow(
        color: AppLightUi.pink.withValues(alpha: 0.28),
        blurRadius: 14,
        offset: const Offset(0, 6),
      ),
    ],
  );
}
