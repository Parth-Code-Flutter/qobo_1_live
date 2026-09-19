import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';

/// Shared palette + helpers for the coins-seller merchant UI (lavender canvas).
abstract final class CoinSellerUi {
  CoinSellerUi._();

  static const gold = AppLightUi.gold;
  static const goldDeep = Color(0xFFFF8F00);
  static const mint = Color(0xFF25D98F);
  static const sky = AppLightUi.cyan;
  static const pink = AppLightUi.pink;
  static const violet = AppLightUi.violet;

  /// Soft plum wash for accent tiles (not a dark page fill).
  static const plum = Color(0xFFF3E4F5);
  static const ink = AppLightUi.title;

  static const title = AppLightUi.title;
  static const body = AppLightUi.body;
  static const muted = AppLightUi.subtitle;
  static const faint = AppLightUi.muted;
  static const card = AppLightUi.card;
  static const cardSoft = AppLightUi.cardSoft;
  static const border = AppLightUi.border;
  static const borderStrong = AppLightUi.borderStrong;

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFBF5),
      Color(0xFFFFFBFE),
      Color(0xFFF8F2FF),
    ],
  );

  static const cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFBFE),
      Color(0xFFFDF4FA),
    ],
  );

  /// Merchant CTA — warm gold into brand pink/violet.
  static const sellButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFFFB020),
      Color(0xFFFF4F98),
      Color(0xFFB14DFF),
    ],
  );

  static const sellButtonColors = [
    Color(0xFFFFB020),
    Color(0xFFFF4F98),
  ];

  static String formatCoins(int value) {
    if (value >= 1000000) {
      final m = value / 1000000;
      return m >= 10 ? '${m.round()}M' : '${m.toStringAsFixed(1)}M';
    }
    if (value >= 100000) return '${(value / 1000).round()}K';
    if (value >= 10000) {
      final k = value / 1000;
      return k == k.roundToDouble()
          ? '${k.round()}K'
          : '${k.toStringAsFixed(1)}K';
    }
    final s = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  static String formatMoney(num value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(2);
  }

  static BoxDecoration glassCard({
    Color? borderColor,
    Gradient? gradient,
    double radius = 22,
  }) {
    return BoxDecoration(
      color: gradient == null ? card : null,
      gradient: gradient ?? cardGradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? border),
      boxShadow: AppLightUi.cardShadow,
    );
  }

  /// Glossy ring wrapper used for hero / premium panels.
  static Widget glossFrame({
    required Widget child,
    double radius = 24,
    EdgeInsetsGeometry padding = const EdgeInsets.all(1.4),
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: AppLightUi.glossRingGradient,
        boxShadow: [
          BoxShadow(
            color: pink.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }

  static Widget pageBackground({required Widget child}) {
    return ColoredBox(
      color: kColorLavenderBg,
      child: child,
    );
  }
}
