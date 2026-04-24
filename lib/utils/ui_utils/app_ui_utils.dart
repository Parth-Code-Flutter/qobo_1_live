import 'package:aligned_rewards/constants/color_constants.dart';
import 'package:aligned_rewards/utils/text_utils/text_styles.dart';
import 'package:flutter/material.dart';

class AppUIUtils {
  static double get primaryRadius => 16;

  static BorderRadius get primaryBorderRadius =>
      BorderRadius.circular(primaryRadius);

  static BorderRadius get homeBorderRadius => BorderRadius.circular(14);

  static BorderRadius get calendarBorderRadius => BorderRadius.circular(10);

  static BorderRadius get textFieldBorderRadius => BorderRadius.circular(12);

  static BorderRadius get productClipRadius => BorderRadius.circular(12);

  static BorderRadius get productQtyContainerRadius => BorderRadius.circular(4);

  static BorderRadius get imageCornerRadius => BorderRadius.circular(5);

  static BorderRadius get productContainerRadius => BorderRadius.circular(26);

  static BorderRadius get borderRadius8 => BorderRadius.circular(8);

  static double get productHeight => 170;

  static double get homeIconSize => 36;

  static double get homeScreenCardHeight => 120;

  static double get headerShadowElevation => 4;

  static double dropdownFontSize = TextStyles.k16FontSize;

  static double globalHorizontalPadding = 18;

  static double iconHeight = 22;
  static double iconWidth = 22;

  static double defaultHeight = 54;

  static double borderWidth = 1.5;

  /// padding & margin
  static EdgeInsets horizontalPadding =
      const EdgeInsets.symmetric(horizontal: 20);

  /// text styles
  static TextStyle globalTextStyle = TextStyles.kMediumLato(
    fontSize: TextStyles.k14FontSize,
    colors: kColorBlack,
  );

  static TextStyle labelTextFieldTextStyle = TextStyles.kSemiBoldLato(
    fontSize: TextStyles.k14FontSize,
    colors: kColorBlack,
  );

  static TextStyle hintTextFieldTextStyle = TextStyles.kRegularLato(
    fontSize: TextStyles.k14FontSize,
    colors: kColorHintTextGray,
  );

  static TextStyle headerBoldTextStyle = TextStyles.kBoldLato(
    fontSize: TextStyles.k18FontSize,
    colors: kColorBlack,
  );

  static TextStyle dropdownHintTextStyleMedium = TextStyles.kSemiBoldLato(
    fontSize: TextStyles.k14FontSize,
    colors: kColorBlack,
  );
}
