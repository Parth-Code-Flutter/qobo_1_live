import 'package:flutter/material.dart';

/// Host interest / talent category for agency onboarding.
enum AgencyHostInterest {
  singing(
    'Singing',
    'singing',
    Icons.mic_rounded,
    'Perform songs and vocals',
  ),
  dancing(
    'Dancing',
    'dancing',
    Icons.music_note_rounded,
    'Show dance and movement',
  ),
  gaming(
    'Gaming',
    'gaming',
    Icons.sports_esports_rounded,
    'Stream gameplay and interact',
  ),
  chatting(
    'Chatting',
    'chatting',
    Icons.chat_bubble_rounded,
    'Talk, connect, and entertain',
  );

  const AgencyHostInterest(
    this.label,
    this.apiValue,
    this.icon,
    this.subtitle,
  );

  final String label;
  final String apiValue;
  final IconData icon;
  final String subtitle;

  Color get accentColor {
    switch (this) {
      case AgencyHostInterest.singing:
        return const Color(0xFFFF5EA7);
      case AgencyHostInterest.dancing:
        return const Color(0xFF8F55FF);
      case AgencyHostInterest.gaming:
        return const Color(0xFFFF8748);
      case AgencyHostInterest.chatting:
        return const Color(0xFF2FA9FF);
    }
  }

  static AgencyHostInterest? fromApiValue(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.trim().toLowerCase();
    for (final item in AgencyHostInterest.values) {
      if (item.apiValue == normalized || item.label.toLowerCase() == normalized) {
        return item;
      }
    }
    return null;
  }
}
