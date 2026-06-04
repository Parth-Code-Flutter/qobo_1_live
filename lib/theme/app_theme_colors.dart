import 'package:flutter/material.dart';

/// Semantic colors for light/dark mode (use via [Theme.of(context).extension]).
@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.scaffold,
    required this.surface,
    required this.surfaceMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.hint,
    required this.divider,
    required this.border,
    required this.iconMuted,
    required this.listTileLeadingBg,
    required this.heroGradientTop,
    required this.heroGradientBottom,
    required this.onHeroPrimary,
    required this.onHeroSecondary,
    required this.onHeroMuted,
    required this.chipSelected,
    required this.chipUnselectedBorder,
    required this.searchFieldFill,
    required this.searchFieldBorder,
    required this.searchFieldHint,
    required this.navBarTop,
    required this.navBarBottom,
    required this.navBarBorder,
    required this.navLabelSelected,
    required this.navLabelUnselected,
    required this.profileFeatureBorder,
    required this.isDark,
  });

  final Color scaffold;
  final Color surface;
  final Color surfaceMuted;
  final Color textPrimary;
  final Color textSecondary;
  final Color hint;
  final Color divider;
  final Color border;
  final Color iconMuted;
  final Color listTileLeadingBg;
  final Color heroGradientTop;
  final Color heroGradientBottom;
  final Color onHeroPrimary;
  final Color onHeroSecondary;
  final Color onHeroMuted;
  final Color chipSelected;
  final Color chipUnselectedBorder;
  final Color searchFieldFill;
  final Color searchFieldBorder;
  final Color searchFieldHint;
  final Color navBarTop;
  final Color navBarBottom;
  final Color navBarBorder;
  final Color navLabelSelected;
  final Color navLabelUnselected;
  final Color profileFeatureBorder;
  final bool isDark;

  static const light = AppThemeColors(
    scaffold: Color(0xFFF5F5F7),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF0EDF5),
    textPrimary: Color(0xFF1A202C),
    textSecondary: Color(0xFF4A5568),
    hint: Color(0xFF718096),
    divider: Color(0xFFE4E4EA),
    border: Color(0xFFDFDFDF),
    iconMuted: Color(0xFF718096),
    listTileLeadingBg: Color(0xFFF0EDF5),
    heroGradientTop: Color(0xFFEDE4F8),
    heroGradientBottom: Color(0xFFF8F6FC),
    onHeroPrimary: Color(0xFF1A202C),
    onHeroSecondary: Color(0xFF4A5568),
    onHeroMuted: Color(0xFF718096),
    chipSelected: Color(0xFF5D2D84),
    chipUnselectedBorder: Color(0xFF7E4EA8),
    searchFieldFill: Color(0xFFF7F8FB),
    searchFieldBorder: Color(0xFFD0D5DD),
    searchFieldHint: Color(0xFF4A5568),
    navBarTop: Color(0xFFFFFFFF),
    navBarBottom: Color(0xFFF5F5F7),
    navBarBorder: Color(0xFFE4E4EA),
    navLabelSelected: Color(0xFF1A202C),
    navLabelUnselected: Color(0xFF718096),
    profileFeatureBorder: Color(0xFFE0D8EC),
    isDark: false,
  );

  static const dark = AppThemeColors(
    scaffold: Color(0xFF0E0E18),
    surface: Color(0xFF1A1A28),
    surfaceMuted: Color(0xFF242436),
    textPrimary: Color(0xFFF5F5F7),
    textSecondary: Color(0xFFB8B8C8),
    hint: Color(0xFF8E8EA0),
    divider: Color(0xFF2E2E42),
    border: Color(0xFF3A3A52),
    iconMuted: Color(0xFF9A9AB0),
    listTileLeadingBg: Color(0xFF242436),
    heroGradientTop: Color(0xFF1E0B36),
    heroGradientBottom: Color(0xFF050A19),
    onHeroPrimary: Color(0xFFFFFFFF),
    onHeroSecondary: Color(0xE6FFFFFF),
    onHeroMuted: Color(0xB3FFFFFF),
    chipSelected: Color(0xFF5D2D84),
    chipUnselectedBorder: Color(0xE6FFFFFF),
    searchFieldFill: Color(0xFF242436),
    searchFieldBorder: Color(0xFF3A3A52),
    searchFieldHint: Color(0xFF8E8EA0),
    navBarTop: Color(0xE6181A5A),
    navBarBottom: Color(0xED121644),
    navBarBorder: Color(0x33FFFFFF),
    navLabelSelected: Color(0xFFFFFFFF),
    navLabelUnselected: Color(0x6BFFFFFF),
    profileFeatureBorder: Color(0x33FFFFFF),
    isDark: true,
  );

  @override
  AppThemeColors copyWith({
    Color? scaffold,
    Color? surface,
    Color? surfaceMuted,
    Color? textPrimary,
    Color? textSecondary,
    Color? hint,
    Color? divider,
    Color? border,
    Color? iconMuted,
    Color? listTileLeadingBg,
    Color? heroGradientTop,
    Color? heroGradientBottom,
    Color? onHeroPrimary,
    Color? onHeroSecondary,
    Color? onHeroMuted,
    Color? chipSelected,
    Color? chipUnselectedBorder,
    Color? searchFieldFill,
    Color? searchFieldBorder,
    Color? searchFieldHint,
    Color? navBarTop,
    Color? navBarBottom,
    Color? navBarBorder,
    Color? navLabelSelected,
    Color? navLabelUnselected,
    Color? profileFeatureBorder,
    bool? isDark,
  }) {
    return AppThemeColors(
      scaffold: scaffold ?? this.scaffold,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      hint: hint ?? this.hint,
      divider: divider ?? this.divider,
      border: border ?? this.border,
      iconMuted: iconMuted ?? this.iconMuted,
      listTileLeadingBg: listTileLeadingBg ?? this.listTileLeadingBg,
      heroGradientTop: heroGradientTop ?? this.heroGradientTop,
      heroGradientBottom: heroGradientBottom ?? this.heroGradientBottom,
      onHeroPrimary: onHeroPrimary ?? this.onHeroPrimary,
      onHeroSecondary: onHeroSecondary ?? this.onHeroSecondary,
      onHeroMuted: onHeroMuted ?? this.onHeroMuted,
      chipSelected: chipSelected ?? this.chipSelected,
      chipUnselectedBorder: chipUnselectedBorder ?? this.chipUnselectedBorder,
      searchFieldFill: searchFieldFill ?? this.searchFieldFill,
      searchFieldBorder: searchFieldBorder ?? this.searchFieldBorder,
      searchFieldHint: searchFieldHint ?? this.searchFieldHint,
      navBarTop: navBarTop ?? this.navBarTop,
      navBarBottom: navBarBottom ?? this.navBarBottom,
      navBarBorder: navBarBorder ?? this.navBarBorder,
      navLabelSelected: navLabelSelected ?? this.navLabelSelected,
      navLabelUnselected: navLabelUnselected ?? this.navLabelUnselected,
      profileFeatureBorder: profileFeatureBorder ?? this.profileFeatureBorder,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      scaffold: Color.lerp(scaffold, other.scaffold, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      hint: Color.lerp(hint, other.hint, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      border: Color.lerp(border, other.border, t)!,
      iconMuted: Color.lerp(iconMuted, other.iconMuted, t)!,
      listTileLeadingBg:
          Color.lerp(listTileLeadingBg, other.listTileLeadingBg, t)!,
      heroGradientTop: Color.lerp(heroGradientTop, other.heroGradientTop, t)!,
      heroGradientBottom:
          Color.lerp(heroGradientBottom, other.heroGradientBottom, t)!,
      onHeroPrimary: Color.lerp(onHeroPrimary, other.onHeroPrimary, t)!,
      onHeroSecondary: Color.lerp(onHeroSecondary, other.onHeroSecondary, t)!,
      onHeroMuted: Color.lerp(onHeroMuted, other.onHeroMuted, t)!,
      chipSelected: Color.lerp(chipSelected, other.chipSelected, t)!,
      chipUnselectedBorder:
          Color.lerp(chipUnselectedBorder, other.chipUnselectedBorder, t)!,
      searchFieldFill: Color.lerp(searchFieldFill, other.searchFieldFill, t)!,
      searchFieldBorder:
          Color.lerp(searchFieldBorder, other.searchFieldBorder, t)!,
      searchFieldHint: Color.lerp(searchFieldHint, other.searchFieldHint, t)!,
      navBarTop: Color.lerp(navBarTop, other.navBarTop, t)!,
      navBarBottom: Color.lerp(navBarBottom, other.navBarBottom, t)!,
      navBarBorder: Color.lerp(navBarBorder, other.navBarBorder, t)!,
      navLabelSelected:
          Color.lerp(navLabelSelected, other.navLabelSelected, t)!,
      navLabelUnselected:
          Color.lerp(navLabelUnselected, other.navLabelUnselected, t)!,
      profileFeatureBorder:
          Color.lerp(profileFeatureBorder, other.profileFeatureBorder, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}
