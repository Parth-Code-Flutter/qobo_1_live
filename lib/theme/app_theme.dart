import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/theme/app_theme_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(AppThemeColors.light, Brightness.light);

  static ThemeData get dark => _build(AppThemeColors.dark, Brightness.dark);

  static ThemeData _build(AppThemeColors colors, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: kColorPrimary,
      onPrimary: kColorWhite,
      secondary: kColorPrimary,
      onSecondary: kColorWhite,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      error: kColorRed,
      onError: kColorWhite,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.scaffold,
      canvasColor: colors.surface,
      cardColor: colors.surface,
      dividerColor: colors.divider,
      hintColor: colors.hint,
      extensions: [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: colors.textPrimary),
        titleTextStyle: TextStyle(
          color: colors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        titleTextStyle: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        contentTextStyle: TextStyle(color: colors.textSecondary, fontSize: 14),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        modalBackgroundColor: colors.surface,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? colors.surfaceMuted : colors.textPrimary,
        contentTextStyle: TextStyle(color: colors.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.searchFieldFill,
        hintStyle: TextStyle(color: colors.searchFieldHint),
        labelStyle: TextStyle(color: colors.textPrimary),
        prefixIconColor: colors.searchFieldHint,
        suffixIconColor: colors.iconMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.searchFieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.searchFieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kColorPrimary, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kColorRed),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: kColorPrimary,
        textColor: colors.textPrimary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? kColorWhite
              : colors.hint,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? kColorPrimary
              : colors.border,
        ),
      ),
    );
  }
}
