import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Shared header for Super Admin tabs — gradient icon badge + title/subtitle.
class SuperAdminTabHeader extends StatelessWidget {
  const SuperAdminTabHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  kColorLiveFilterChipGradientStart,
                  kColorLiveFilterChipGradientEnd,
                ],
              ),
              border: Border.all(color: kColorWhite.withValues(alpha: 0.22)),
              boxShadow: [
                BoxShadow(
                  color: kColorPrimary.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: kColorWhite, size: 22),
          ),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: title,
                  fontSize: TextStyles.k20FontSize,
                  color: kColorWhite,
                ),
                Spacing.v2,
                AppText(
                  text: subtitle,
                  fontSize: TextStyles.k12FontSize,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared empty-state placeholder for Super Admin lists.
class SuperAdminEmptyState extends StatelessWidget {
  const SuperAdminEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: kColorWhite.withValues(alpha: 0.08),
            border: Border.all(color: kColorWhite.withValues(alpha: 0.14)),
          ),
          child: Icon(icon, color: Colors.white54, size: 32),
        ),
        Spacing.v16,
        SemiBoldText(
          text: title,
          fontSize: TextStyles.k14FontSize,
          color: kColorWhite,
        ),
        Spacing.v6,
        AppText(
          text: subtitle,
          fontSize: TextStyles.k12FontSize,
          color: Colors.white60,
          align: TextAlign.center,
        ),
      ],
    );
  }
}

/// Colored status pill used on Super Admin list + detail screens.
class SuperAdminStatusPill extends StatelessWidget {
  const SuperAdminStatusPill({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final value = status.toLowerCase();
    final color = value == 'pending'
        ? const Color(0xFFFFD166)
        : (value == 'approved' || value == 'active')
        ? const Color(0xFF4ADE80)
        : value == 'suspended' || value == 'inactive'
        ? const Color(0xFFFFB74D)
        : const Color(0xFFFF8A80);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: SemiBoldText(
        text: status,
        fontSize: TextStyles.k10FontSize,
        color: color,
      ),
    );
  }
}

/// Small network doc / image preview tile.
class SuperAdminDocThumb extends StatelessWidget {
  const SuperAdminDocThumb({super.key, required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            text: label,
            fontSize: TextStyles.k10FontSize,
            color: Colors.white70,
          ),
          Spacing.v6,
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 1.4,
              child: url.isEmpty
                  ? Container(
                      color: kColorWhite.withValues(alpha: 0.08),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.white38,
                      ),
                    )
                  : Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: kColorWhite.withValues(alpha: 0.08),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white38,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Key/value row for detail screens.
class SuperAdminInfoRow extends StatelessWidget {
  const SuperAdminInfoRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: AppText(
              text: label,
              fontSize: TextStyles.k12FontSize,
              color: Colors.white54,
            ),
          ),
          Expanded(
            child: SemiBoldText(
              text: value,
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite,
            ),
          ),
        ],
      ),
    );
  }
}
