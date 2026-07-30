import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_ui.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Shared helpers for Super Admin detail screens.
abstract final class SuperAdminDetailFormat {
  SuperAdminDetailFormat._();

  static final _date = DateFormat('MMM d, yyyy');
  static final _dateTime = DateFormat('MMM d, yyyy · h:mm a');

  /// Turns ISO / raw API timestamps into readable local dates.
  static String date(String? raw, {bool withTime = false}) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return '—';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      if (!value.contains('T') && value.length < 24) return value;
      return value.split('T').first;
    }
    final local = parsed.toLocal();
    return withTime ? _dateTime.format(local) : _date.format(local);
  }

  static String phone(String countryCode, String phone) {
    return [countryCode.trim(), phone.trim()]
        .where((e) => e.isNotEmpty)
        .join(' ');
  }

  static String location(Iterable<String> parts) {
    final cleaned = parts.map((e) => e.trim()).where((e) => e.isNotEmpty);
    return cleaned.isEmpty ? '' : cleaned.join(', ');
  }
}

/// Detail-screen backdrop — same canvas language as tab screens.
class SuperAdminDetailBackdrop extends StatelessWidget {
  const SuperAdminDetailBackdrop({
    super.key,
    required this.child,
    this.primary = SuperAdminUi.violet,
    this.secondary = SuperAdminUi.sky,
  });

  final Widget child;
  final Color primary;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    return SuperAdminPageBackdrop(
      primary: primary,
      secondary: secondary,
      child: child,
    );
  }
}

/// Clean label/value row with divider — no nested boxes.
class SuperAdminCleanInfoRow extends StatelessWidget {
  const SuperAdminCleanInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.accent = SuperAdminUi.sky,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.14),
                ),
                child: Icon(icon, size: 16, color: accent),
              ),
              Spacing.h12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      text: label,
                      fontSize: TextStyles.k10FontSize,
                      color: SuperAdminUi.textMuted,
                    ),
                    Spacing.v4,
                    SemiBoldText(
                      text: value,
                      fontSize: TextStyles.k14FontSize,
                      color: SuperAdminUi.textPrimary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: SuperAdminUi.textPrimary.withValues(alpha: 0.08),
          ),
      ],
    );
  }
}

/// Compact section header used inside detail cards.
class SuperAdminCleanSectionHeader extends StatelessWidget {
  const SuperAdminCleanSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: accent),
        Spacing.h8,
        SemiBoldText(
          text: title,
          fontSize: TextStyles.k14FontSize,
          color: SuperAdminUi.textPrimary,
        ),
      ],
    );
  }
}
