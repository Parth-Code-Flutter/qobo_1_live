import 'package:flutter/material.dart';

/// Leaderboard screen (Figma) — gradient + podium + list.
abstract final class LeaderBoardColors {
  LeaderBoardColors._();

  static const Color gradientTop = Color(0xFF6A0DAD);
  static const Color gradientBottom = Color(0xFF0A0E21);

  static const Color rankBadgeGold = Color(0xFFFFD700);
  static const Color rankBadgeText = Color(0xFF1A202C);

  static const Color headerIconBg = Color(0xCC2D1B45);
  static const Color listCardBg = Color(0x9928143F);
  static const Color listRowHighlightBg = Color(0xFFF3F3F5);
  static const Color listRowHighlightText = Color(0xFF1A202C);
  static const Color listRowHighlightSub = Color(0xFF4A5568);
}
