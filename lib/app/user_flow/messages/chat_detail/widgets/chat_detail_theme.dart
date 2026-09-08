import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';

/// Direct-chat colors aligned with the family group conversation screen.
abstract final class ChatDetailTheme {
  static const scaffold = Color(0xFFFFF6FB);
  static const incomingBubble = kColorWhite;
  static const composerField = Color(0xFFFFF5FA);
  static const rose = Color(0xFFFF2E83);
  static const plum = Color(0xFF7A1B76);
  static const lilac = Color(0xFF8B5CFF);
  static const textMuted = Color(0xFF77849D);
  static const paleBorder = Color(0xFFFFD4E8);

  static const bodyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF8FC), Color(0xFFFFF1F8), Color(0xFFF7F2FF)],
  );

  static const headerGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [plum, lilac, rose],
  );

  static const outgoingGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [rose, plum],
  );
}
