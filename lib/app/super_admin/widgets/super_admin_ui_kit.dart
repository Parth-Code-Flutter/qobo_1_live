import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_ui.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Shared header for Super Admin tabs — glow icon badge + title/subtitle.
class SuperAdminTabHeader extends StatelessWidget {
  const SuperAdminTabHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          if (canPop) ...[
            Material(
              color: kColorWhite.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: Get.back,
                borderRadius: BorderRadius.circular(14),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: kColorWhite,
                    size: 18,
                  ),
                ),
              ),
            ),
            Spacing.h10,
          ],
          SuperAdminUi.glowIcon(
            icon: icon,
            accent: SuperAdminUi.violet,
            size: 46,
            iconSize: 22,
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
          if (trailing != null) trailing!,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SuperAdminUi.glowIcon(
            icon: icon,
            accent: SuperAdminUi.sky,
            size: 72,
            iconSize: 32,
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
      ),
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
        ? SuperAdminUi.gold
        : (value == 'approved' || value == 'active')
        ? SuperAdminUi.mint
        : value == 'suspended' || value == 'inactive'
        ? SuperAdminUi.warning
        : SuperAdminUi.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
            borderRadius: BorderRadius.circular(14),
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
      padding: const EdgeInsets.only(bottom: 10),
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

/// Section label with optional trailing widget.
class SuperAdminSectionTitle extends StatelessWidget {
  const SuperAdminSectionTitle({
    super.key,
    required this.icon,
    required this.title,
    this.accent = SuperAdminUi.violet,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Color accent;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SuperAdminUi.glowIcon(
          icon: icon,
          accent: accent,
          size: 30,
          iconSize: 16,
        ),
        Spacing.h10,
        Expanded(
          child: SemiBoldText(
            text: title,
            fontSize: TextStyles.k14FontSize,
            color: kColorWhite,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
