import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:flutter/material.dart';

class Font {
  static const Poppins = 'Poppins';

  // Legacy aliases kept to avoid breaking existing call sites.
  static const AsapRegular = Poppins;
  static const AsapMedium = Poppins;
  static const AsapSemiBold = Poppins;
  static const AsapBold = Poppins;
  static const AsapLight = Poppins;
  static const LatoRegular = Poppins;
  static const LatoLights = Poppins;
  static const LatoBold = Poppins;
}

class TextStyles {
  static const double k10FontSize = 10;
  static const double k12FontSize = 12;
  static const double k14FontSize = 14;
  static const double k16FontSize = 16;

  static const double k18FontSize = 18;
  static const double k20FontSize = 20;
  static const double k22FontSize = 22;

  static const double k24FontSize = 24;
  static const double k26FontSize = 26;
  static const double k28FontSize = 28;

  static const double k30FontSize = 30;
  static const double k32FontSize = 32;
  static const double k34FontSize = 34;
  static const double k36FontSize = 36;
  static const double k48FontSize = 48;

  /// Regular style using Poppins font family.
  static TextStyle kRegularPoppins(
      {double fontSize = k16FontSize,
      Color colors = kColorTextPrimary,
      FontWeight fontWeight = FontWeight.w400}) {
    return TextStyle(
      fontSize: fontSize,
      color: colors,
      fontWeight: fontWeight,
      fontFamily: Font.AsapRegular,
    );
  }

  /// Medium style using Poppins font family.
  static TextStyle kMediumPoppins(
      {double fontSize = k16FontSize,
      Color colors = kColorTextPrimary,
      FontWeight fontWeight = FontWeight.w500}) {
    return TextStyle(
      fontSize: fontSize,
      color: colors,
      fontWeight: fontWeight,
      fontFamily: Font.AsapMedium,
    );
  }

  /// Semibold style using Poppins font family.
  static TextStyle kSemiBoldPoppins(
      {double fontSize = k16FontSize,
      Color colors = kColorTextPrimary,
      FontWeight fontWeight = FontWeight.w600}) {
    return TextStyle(
      fontSize: fontSize,
      color: colors,
      fontWeight: fontWeight,
      fontFamily: Font.AsapSemiBold,
    );
  }

  /// Bold style using Poppins font family.
  static TextStyle kBoldPoppins(
      {double fontSize = k36FontSize,
      Color colors = kColorTextPrimary,
      FontWeight fontWeight = FontWeight.w700}) {
    return TextStyle(
      fontSize: fontSize,
      color: colors,
      fontWeight: fontWeight,
      fontFamily: Font.AsapBold,
    );
  }
}
