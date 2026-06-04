import 'package:flutter/material.dart';
import 'package:qobo_one_live/theme/app_theme_colors.dart';

extension ThemeContext on BuildContext {
  AppThemeColors get appColors =>
      Theme.of(this).extension<AppThemeColors>() ?? AppThemeColors.light;

  bool get isDarkTheme => appColors.isDark;
}
