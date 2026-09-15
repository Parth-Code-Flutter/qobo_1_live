import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';

/// Dating-app light theme on [kColorLavenderBg] (soft off-white canvas).
///
/// Use for shell screens (tabs, hubs, settings). Keep live-in-room / PK /
/// voice-call UIs on their dark palettes.
abstract final class AppLightUi {
  AppLightUi._();

  // —— Surface ——
  static const bg = kColorLavenderBg;
  static const card = Color(0xFFFFFFFF);
  static const cardSoft = Color(0xFFFFF6FA);
  static const cardElevated = Color(0xFFFFFFFF);

  // —— Type ——
  static const title = Color(0xFF2A1744);
  static const body = Color(0xFF3D2A52);
  static const subtitle = Color(0xFF8A769A);
  static const muted = Color(0xFFA894B0);
  static const hint = Color(0xFFB5A4C2);

  // —— Accents ——
  static const pink = Color(0xFFFF4F98);
  static const pinkSoft = Color(0xFFFF9AB8);
  static const violet = Color(0xFF9B6DFF);
  static const cyan = Color(0xFF5B8DEF);
  static const gold = Color(0xFFFFB020);
  static const rose = Color(0xFFFF6B8A);

  // —— Borders / washes ——
  static const border = Color(0xFFF0DCE8);
  static const borderStrong = Color(0xFFE2C8DC);
  static const unreadWash = Color(0x1AFF4F98);
  static const searchFill = Color(0xFFFFFFFF);

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: title.withValues(alpha: 0.07),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: title.withValues(alpha: 0.03),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  /// Soft pink→violet CTA used across dating chrome.
  static const ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF5C9A), Color(0xFFB14DFF)],
  );

  /// Open Family Chat / Family detail header — violet→pink.
  static const familyCtaGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF7B5CFF), Color(0xFFB35CFF), Color(0xFFFF2E83)],
  );

  static const familyCtaColors = [
    Color(0xFF7B5CFF),
    Color(0xFFFF2E83),
  ];

  static BoxDecoration cardDecoration({
    double radius = 20,
    bool elevated = true,
    Color? borderColor,
    Color? fill,
  }) {
    return BoxDecoration(
      color: fill ?? card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? border),
      boxShadow: elevated ? cardShadow : null,
    );
  }

  static BoxDecoration searchDecoration({double radius = 26}) {
    return BoxDecoration(
      color: searchFill,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: pinkSoft.withValues(alpha: 0.45), width: 1.2),
      boxShadow: cardShadow,
    );
  }

  /// Outer ring for glossy avatar / chip borders.
  static const glossRingGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFC46B),
      Color(0xFFFF4F98),
      Color(0xFFB35CFF),
      Color(0xFF7B5CFF),
    ],
  );

  static BoxDecoration iconTileDecoration(Color accent, {double radius = 12}) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          accent.withValues(alpha: 0.22),
          accent.withValues(alpha: 0.08),
        ],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: accent.withValues(alpha: 0.38), width: 1.1),
      boxShadow: [
        BoxShadow(
          color: title.withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}
