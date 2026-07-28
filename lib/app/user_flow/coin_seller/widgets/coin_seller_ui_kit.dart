import 'package:flutter/material.dart';

/// Shared palette + helpers for the coins-seller merchant UI.
abstract final class CoinSellerUi {
  CoinSellerUi._();

  static const gold = Color(0xFFFFC107);
  static const goldDeep = Color(0xFFFF8F00);
  static const mint = Color(0xFF4ADE80);
  static const sky = Color(0xFF60A5FA);
  static const plum = Color(0xFF2A1538);
  static const ink = Color(0xFF0E0B18);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3D2200),
      Color(0xFF1A1030),
      Color(0xFF0D0818),
    ],
  );

  static const cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x33FFC107),
      Color(0x1AFFFFFF),
      Color(0x12000000),
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
      gradient: gradient ?? cardGradient,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: borderColor ?? Colors.white.withValues(alpha: 0.12),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.28),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
