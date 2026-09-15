import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';

/// Leaderboard screen — lavender canvas + soft cards (light theme).
abstract final class LeaderBoardColors {
  LeaderBoardColors._();

  static const Color gradientTop = AppLightUi.bg;
  static const Color gradientBottom = AppLightUi.bg;

  static const Color rankBadgeGold = AppLightUi.gold;
  static const Color rankBadgeText = AppLightUi.title;

  static const Color headerIconBg = AppLightUi.card;
  static const Color listCardBg = AppLightUi.card;
  static const Color listRowHighlightBg = Color(0xFFFFF0F6);
  static const Color listRowHighlightText = AppLightUi.title;
  static const Color listRowHighlightSub = AppLightUi.subtitle;
}
