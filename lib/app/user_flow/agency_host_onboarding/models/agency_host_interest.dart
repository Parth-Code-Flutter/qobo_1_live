import 'package:flutter/material.dart';

/// Host category for agency onboarding.
enum AgencyHostInterest {
  normalHost(
    'Normal Host',
    'Normal Host',
    Icons.person_outline_rounded,
    'General live hosting',
  ),
  comedy(
    'Comedy',
    'Comedy',
    Icons.sentiment_very_satisfied_outlined,
    'Comedy and entertainment',
  ),
  makeup(
    'Makeup',
    'Makeup',
    Icons.brush_outlined,
    'Beauty and makeup content',
  ),
  singing(
    'Singing',
    'Singing',
    Icons.mic_rounded,
    'Perform songs and vocals',
  ),
  yoga(
    'Yoga',
    'Yoga',
    Icons.self_improvement_outlined,
    'Yoga and wellness sessions',
  ),
  dance(
    'Dance',
    'Dance',
    Icons.music_note_rounded,
    'Show dance and movement',
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
      case AgencyHostInterest.normalHost:
        return const Color(0xFF5C6BC0);
      case AgencyHostInterest.comedy:
        return const Color(0xFFFF8748);
      case AgencyHostInterest.makeup:
        return const Color(0xFFFF5EA7);
      case AgencyHostInterest.singing:
        return const Color(0xFF8F55FF);
      case AgencyHostInterest.yoga:
        return const Color(0xFF35C759);
      case AgencyHostInterest.dance:
        return const Color(0xFF2FA9FF);
    }
  }

  static AgencyHostInterest? fromApiValue(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.trim().toLowerCase();
    for (final item in AgencyHostInterest.values) {
      if (item.apiValue.toLowerCase() == normalized ||
          item.label.toLowerCase() == normalized) {
        return item;
      }
    }
    return null;
  }
}
