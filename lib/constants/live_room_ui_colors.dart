import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';

/// Live Rooms hub / listing palette — light dating canvas on lavender.
///
/// In-room broadcast UI uses its own dark tokens; do not reuse these there.
abstract final class LiveRoomUiColors {
  static const screenGradientTop = AppLightUi.bg;
  static const screenGradientBottom = AppLightUi.bg;
  static const cardSurface = AppLightUi.card;
  static const cardBorder = AppLightUi.border;
  static const chipInactiveBg = Color(0x14FF5C9A);
  static const chipInactiveBorder = AppLightUi.borderStrong;
  static const liveDot = Color(0xFF25D98F);
  static const audioBadge = Color(0xFF9B6DFF);
  static const videoBadge = Color(0xFFFF5C9A);
  static const goLiveGradientStart = Color(0xFFE6252F);
  static const goLiveGradientEnd = Color(0xFFFF6B4A);
  static const joinLiveBorder = Color(0xFFC4A0F0);
}
