import 'package:aligned_rewards/constants/color_constants.dart';
import 'package:flutter/material.dart';

class Font {
  // Asap font family constants
  static const AsapRegular = "AsapRegular";
  static const AsapMedium = "AsapMedium";
  static const AsapSemiBold = "AsapSemiBold";
  static const AsapBold = "AsapBold";
  static const AsapLight = "AsapLight";
  
  // Legacy Lato font constants (deprecated - kept for backward compatibility)
  // @deprecated Use AsapRegular instead
  static const LatoRegular = "AsapRegular";
  // @deprecated Use AsapLight instead
  static const LatoLights = "AsapLight";
  // @deprecated Use AsapBold instead
  static const LatoBold = "AsapBold";
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

  /// Regular Asap font style (replaces Lato Regular)
  /// Uses Asap-Regular.ttf font file
  static TextStyle kRegularLato(
      {double fontSize = k16FontSize,
      Color colors = kColorWhite,
      FontWeight fontWeight = FontWeight.w400}) {
    return TextStyle(
      fontSize: fontSize,
      color: colors,
      fontWeight: fontWeight,
      fontFamily: Font.AsapRegular,
    );
  }

  /// Medium Asap font style (replaces Lato Medium)
  /// Uses Asap-Medium.ttf font file
  static TextStyle kMediumLato(
      {double fontSize = k16FontSize,
      Color colors = kColorWhite,
      FontWeight fontWeight = FontWeight.w500}) {
    return TextStyle(
      fontSize: fontSize,
      color: colors,
      fontWeight: fontWeight,
      fontFamily: Font.AsapMedium,
    );
  }

  /// SemiBold Asap font style (replaces Lato SemiBold)
  /// Uses Asap-SemiBold.ttf font file
  static TextStyle kSemiBoldLato(
      {double fontSize = k16FontSize,
      Color colors = kColorWhite,
      FontWeight fontWeight = FontWeight.w600}) {
    return TextStyle(
      fontSize: fontSize,
      color: colors,
      fontWeight: fontWeight,
      fontFamily: Font.AsapSemiBold,
    );
  }

  /// Bold Asap font style (replaces Lato Bold)
  /// Uses Asap-Bold.ttf font file
  static TextStyle kBoldLato(
      {double fontSize = k36FontSize,
      Color colors = kColorWhite,
      FontWeight fontWeight = FontWeight.w700}) {
    return TextStyle(
      fontSize: fontSize,
      color: colors,
      fontWeight: fontWeight,
      fontFamily: Font.AsapBold,
    );
  }
}
