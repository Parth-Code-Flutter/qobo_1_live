import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_ui.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Shared header for Super Admin tabs.
class SuperAdminTabHeader extends StatelessWidget {
  const SuperAdminTabHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.accent = SuperAdminUi.violet,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Container(
      padding: const EdgeInsets.fromLTRB(
        SuperAdminUi.pagePad,
        14,
        SuperAdminUi.pagePad,
        14,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: accent.withValues(alpha: 0.18)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (canPop) ...[_SuperAdminBackButton(accent: accent), Spacing.h12],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BoldText(
                  text: title,
                  fontSize: TextStyles.k22FontSize,
                  color: SuperAdminUi.textPrimary,
                ),
                Spacing.v4,
                AppText(
                  text: subtitle,
                  fontSize: TextStyles.k12FontSize,
                  color: SuperAdminUi.textMuted,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Spacing.v8,
                Container(
                  width: 34,
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      colors: [accent, SuperAdminUi.pink],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[Spacing.h12, trailing!],
        ],
      ),
    );
  }
}

class _SuperAdminBackButton extends StatelessWidget {
  const _SuperAdminBackButton({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: Get.back,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: SuperAdminUi.panel.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.42)),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: SuperAdminUi.textPrimary,
          ),
        ),
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
            color: SuperAdminUi.textPrimary,
          ),
          Spacing.v6,
          AppText(
            text: subtitle,
            fontSize: TextStyles.k12FontSize,
            color: SuperAdminUi.textMuted,
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
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.38)),
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
            color: SuperAdminUi.textMuted,
          ),
          Spacing.v6,
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 1.4,
              child: url.isEmpty
                  ? Container(
                      color: SuperAdminUi.panel.withValues(alpha: 0.7),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: SuperAdminUi.textFaint,
                      ),
                    )
                  : Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: SuperAdminUi.panel.withValues(alpha: 0.7),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: SuperAdminUi.textFaint,
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
              color: SuperAdminUi.textMuted,
            ),
          ),
          Expanded(
            child: SemiBoldText(
              text: value,
              fontSize: TextStyles.k12FontSize,
              color: SuperAdminUi.textPrimary,
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
            color: SuperAdminUi.textPrimary,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
