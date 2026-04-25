import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/ui_utils/app_ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Creates a customizable button widget with support for gradient and solid colors.
/// 
/// By default, buttons use a gradient effect with primary color variations.
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
/// - [gradientColors]: Custom gradient colors (defaults to primary color gradient)
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
  bool? isGradient = true, // Default to gradient for whole project
  List<Color>? gradientColors,
}) {
  return GestureDetector(
    onTap: onPressed,
    child: Container(
      height: buttonHeight ?? 50,
      width: buttonWidth ?? Get.width,
      decoration: isGradient == true
          ? _gradientDecoration(
              gradientColors, buttonColor, borderRadius, buttonBorderColor)
          : _simpleDecoration(buttonColor, borderRadius, buttonBorderColor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buttonIcon != null ? const SizedBox(width: 10) : Container(),
          buttonIcon ?? const SizedBox(),
          Text(
            buttonText,
            style: textStyle ??
                TextStyles.kBoldPoppins(
                  fontSize: TextStyles.k18FontSize,
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
    borderRadius:
        BorderRadius.circular(borderRadius ?? AppUIUtils.primaryRadius),
    border: Border.all(color: buttonBorderColor ?? kColorPrimary, width: 1),
  );
}

/// Creates a gradient decoration for buttons using primary color variations.
/// 
/// By default, creates a horizontal gradient from lighter primary color to darker primary color.
/// Custom gradient colors can be provided via [gradientColors] parameter.
/// 
/// Parameters:
/// - [gradientColors]: Custom gradient colors (defaults to primary color gradient)
/// - [buttonColor]: Base color (used for border if provided)
/// - [borderRadius]: Border radius (defaults to primary radius)
/// - [buttonBorderColor]: Border color (defaults to primary color)
BoxDecoration _gradientDecoration(
    gradientColors, buttonColor, borderRadius, buttonBorderColor) {
  // Premium gradient: Primary color (left) -> slightly lighter (middle) -> more lighter (right)
  // Creates a premium look with smooth color transition
  final defaultGradientColors = gradientColors ??
      [
        kColorPrimary, // Primary color on the left
        _getLighterPrimaryColor(0.15), // Slightly lighter in the middle
        _getLighterPrimaryColor(0.25), // More lighter on the right
      ];

  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.centerLeft, // Start from left
      end: Alignment.centerRight, // End at right (horizontal gradient)
      colors: defaultGradientColors,
    ),
    borderRadius:
        BorderRadius.circular(borderRadius ?? AppUIUtils.primaryRadius),
    border: Border.all(
        color: buttonBorderColor ?? kColorPrimary,
        width: 1),
  );
}

/// Generates a lighter shade of the primary color for gradient effects.
/// 
/// Creates a lighter version by blending the primary color with white.
/// The [lightnessFactor] parameter controls how light the color becomes:
/// - 0.0 = fully white
/// - 1.0 = fully primary color
/// 
/// Parameters:
/// - [lightnessFactor]: Factor controlling lightness (defaults to 0.2 for subtle effect)
Color _getLighterPrimaryColor([double lightnessFactor = 0.2]) {
  // Extract primary color
  final primary = kColorPrimary;
  
  // Create a lighter version by blending with white
  // Lower lightnessFactor = lighter color
  // Higher lightnessFactor = closer to primary color
  return Color.lerp(
    Colors.white,
    primary,
    1.0 - lightnessFactor, // Invert to make it lighter
  ) ?? kColorPrimary;
}
