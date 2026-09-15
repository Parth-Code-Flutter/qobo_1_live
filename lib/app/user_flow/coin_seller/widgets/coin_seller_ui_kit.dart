import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';

/// Shared palette + helpers for the coins-seller merchant UI (lavender canvas).
abstract final class CoinSellerUi {
  CoinSellerUi._();

  static const gold = Color(0xFFFFC107);
  static const goldDeep = Color(0xFFFF8F00);
  static const mint = Color(0xFF4ADE80);
  static const sky = Color(0xFF60A5FA);

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

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFF8E7),
      Color(0xFFFFFBFE),
      Color(0xFFFDF4FA),
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

  static const sellButtonGradient = LinearGradient(
    colors: [Color(0xFFFF8F00), Color(0xFFFF4081)],
  );

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

  static BoxDecoration glassCard({Color? borderColor, Gradient? gradient}) {
    return BoxDecoration(
      color: gradient == null ? card : null,
      gradient: gradient ?? cardGradient,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor ?? border),
      boxShadow: AppLightUi.cardShadow,
    );
  }
}
