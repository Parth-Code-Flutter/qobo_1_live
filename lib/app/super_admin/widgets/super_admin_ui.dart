import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/admin_agency_chrome.dart';
import 'package:qobo_one_live/utils/app_widgets/app_coin_icon.dart';
import 'package:qobo_one_live/utils/app_widgets/app_shell_background.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/app_widgets/safe_network_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Shared design tokens for the Super Admin shell.
///
/// Aligned with [AppLightUi] dating canvas (lavender bg, white cards,
/// violet→pink CTAs). Button / icon / nav chrome shared via [AdminAgencyUi].
abstract final class SuperAdminUi {
  SuperAdminUi._();

  // —— Canvas ——
  static const ink = AppLightUi.title;
  static const inkElevated = AppLightUi.body;
  static const sheet = AppLightUi.card;
  static const panel = AppLightUi.cardSoft;
  static const bg = AppLightUi.bg;

  // —— Accents ——
  static const gold = AdminAgencyUi.gold;
  static const goldDeep = AdminAgencyUi.goldDeep;
  static const violet = AdminAgencyUi.violet;
  static const mint = AdminAgencyUi.mint;
  static const rose = AdminAgencyUi.rose;
  static const sky = AdminAgencyUi.sky;
  static const pink = AdminAgencyUi.pink;
  static const teal = AdminAgencyUi.teal;
  static const danger = Color(0xFFFF6B6B);
  static const warning = Color(0xFFFFB020);
  static const success = Color(0xFF2E9E5B);

  // —— Type ——
  static const textPrimary = AppLightUi.title;
  static const textSecondary = AppLightUi.body;
  static const textMuted = AppLightUi.subtitle;
  static const textFaint = AppLightUi.muted;

  // —— Layout ——
  static const double pagePad = 16;
  static const double sectionGap = 12;
  static const double cardPad = 14;
  static const double cardRadius = 18;
  static const EdgeInsets pageInsets = EdgeInsets.fromLTRB(
    pagePad,
    10,
    pagePad,
    100,
  );
  static const EdgeInsets detailInsets = EdgeInsets.fromLTRB(
    pagePad,
    8,
    pagePad,
    32,
  );

  static const headerGradient = AppLightUi.familyCtaGradient;
  static const goldButtonGradient = AdminAgencyUi.goldButtonGradient;
  static const primaryButtonGradient = AdminAgencyUi.primaryButtonGradient;

  static BoxDecoration glassDecoration({
    Color? glow,
    double radius = cardRadius,
  }) {
    return appShellGlassDecoration(glow: glow, radius: radius);
  }

  static Widget glowIcon({
    required IconData icon,
    required Color accent,
    double size = 44,
    double iconSize = 22,
  }) {
    return AdminAgencyUi.glowIcon(
      icon: icon,
      accent: accent,
      size: size,
      iconSize: iconSize,
    );
  }

  static Widget glowCoinIcon({
    required Color accent,
    double size = 44,
    double iconSize = 22,
  }) {
    return AdminAgencyUi.glowCoinIcon(
      accent: accent,
      size: size,
      iconSize: iconSize,
    );
  }
}

/// Shared ambient canvas for every Super Admin screen (tabs + detail).
class SuperAdminPageBackdrop extends StatelessWidget {
  const SuperAdminPageBackdrop({
    super.key,
    required this.child,
    this.primary = SuperAdminUi.violet,
    this.secondary = SuperAdminUi.pink,
  });

  final Widget child;
  final Color primary;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    // Exact same canvas as MessagesTabView — bare [kColorLavenderBg], no wash/orbs.
    return AppShellBackground(
      showOrbs: false,
      child: child,
    );
  }
}

/// Tab body shell: shared backdrop + [CommonAppBarWidget] + safe body.
class SuperAdminPageScaffold extends StatelessWidget {
  const SuperAdminPageScaffold({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.appBarActions,
    this.primary = SuperAdminUi.violet,
    this.secondary = SuperAdminUi.pink,
    this.bottom = false,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final List<Widget>? appBarActions;
  final Color primary;
  final Color secondary;
  final bool bottom;

  @override
  Widget build(BuildContext context) {
    final hasAppBar = title != null && title!.trim().isNotEmpty;
    return SuperAdminPageBackdrop(
      primary: primary,
      secondary: secondary,
      child: hasAppBar
          ? Scaffold(
              backgroundColor: Colors.transparent,
              appBar: CommonAppBarWidget(
                title: title!,
                subtitle: subtitle,
                toolbarHeight: 56,
                showBackButton: Navigator.of(context).canPop(),
                actions: appBarActions,
              ),
              body: SafeArea(top: false, bottom: bottom, child: child),
            )
          : SafeArea(top: false, bottom: bottom, child: child),
    );
  }
}

/// Premium glass panel — blur reserved for sheets; cards stay opaque-enough.
class SuperAdminGlassCard extends StatelessWidget {
  const SuperAdminGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.glow,
    this.onTap,
    this.radius = SuperAdminUi.cardRadius,
    this.blur = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? glow;
  final VoidCallback? onTap;
  final double radius;
  final bool blur;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(SuperAdminUi.cardPad),
      decoration: SuperAdminUi.glassDecoration(glow: glow, radius: radius),
      child: child,
    );

    // Never blur — solid Profile-style cards only.
    final clipped = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: body,
    );

    if (onTap == null) return clipped;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: clipped,
      ),
    );
  }
}

/// Status filter pill used on Agency / Host tabs.
class SuperAdminFilterPill extends StatelessWidget {
  const SuperAdminFilterPill({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: isSelected ? SuperAdminUi.headerGradient : null,
          color: isSelected ? null : AppLightUi.card,
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppLightUi.borderStrong,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: SuperAdminUi.pink.withValues(alpha: 0.24),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : AppLightUi.cardShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? kColorWhite : SuperAdminUi.textMuted,
            ),
            Spacing.h6,
            SemiBoldText(
              text: label,
              fontSize: TextStyles.k10FontSize,
              color: isSelected ? kColorWhite : SuperAdminUi.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Frosted bottom sheet chrome with drag handle.
class SuperAdminSheetScaffold extends StatelessWidget {
  const SuperAdminSheetScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            SuperAdminUi.pagePad,
            12,
            SuperAdminUi.pagePad,
            20 + MediaQuery.paddingOf(context).bottom,
          ),
          decoration: BoxDecoration(
            color: AppLightUi.card.withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: AppLightUi.borderStrong),
            boxShadow: [
              BoxShadow(
                color: AppLightUi.title.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: SuperAdminUi.headerGradient,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Spacing.v12,
              SemiBoldText(
                text: title,
                fontSize: TextStyles.k16FontSize,
                color: SuperAdminUi.textPrimary,
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                Spacing.v4,
                AppText(
                  text: subtitle!,
                  fontSize: TextStyles.k12FontSize,
                  color: SuperAdminUi.textMuted,
                ),
              ],
              Spacing.v12,
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// One row action inside [SuperAdminSheetScaffold].
class SuperAdminSheetAction extends StatelessWidget {
  const SuperAdminSheetAction({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppLightUi.cardSoft,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                SuperAdminUi.glowIcon(
                  icon: icon,
                  accent: color,
                  size: 36,
                  iconSize: 18,
                ),
                Spacing.h12,
                Expanded(
                  child: SemiBoldText(
                    text: label,
                    fontSize: TextStyles.k12FontSize,
                    color: SuperAdminUi.textPrimary,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: SuperAdminUi.textFaint,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact approve / reject style button.
class SuperAdminActionButton extends StatelessWidget {
  const SuperAdminActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.borderColor,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: borderColor != null
                ? Border.all(color: borderColor!)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: foreground),
              Spacing.h6,
              SemiBoldText(
                text: label,
                fontSize: TextStyles.k12FontSize,
                color: foreground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gradient ring avatar used on dating-style list / detail heroes.
class SuperAdminAvatarRing extends StatelessWidget {
  const SuperAdminAvatarRing({
    super.key,
    required this.url,
    required this.fallbackLetter,
    this.size = 72,
    this.accent = SuperAdminUi.pink,
    this.live = false,
  });

  final String url;
  final String fallbackLetter;
  final double size;
  final Color accent;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final inner = size - 6;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent,
                SuperAdminUi.gold,
                SuperAdminUi.violet,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.30),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipOval(
            child: ColoredBox(
              color: AppLightUi.card,
              child: url.trim().isNotEmpty
                  ? SafeNetworkAvatar(
                      url: url,
                      size: inner,
                      fit: BoxFit.cover,
                      fallback: _fallback(inner),
                    )
                  : _fallback(inner),
            ),
          ),
        ),
        if (live)
          Positioned(
            right: 0,
            bottom: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: SuperAdminUi.rose,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kColorWhite, width: 1.5),
              ),
              child: const SemiBoldText(
                text: 'LIVE',
                fontSize: 8,
                color: kColorWhite,
              ),
            ),
          ),
      ],
    );
  }

  Widget _fallback(double inner) {
    return Container(
      width: inner,
      height: inner,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.85),
            SuperAdminUi.violet.withValues(alpha: 0.75),
          ],
        ),
      ),
      child: Text(
        fallbackLetter.isNotEmpty
            ? fallbackLetter.characters.first.toUpperCase()
            : '?',
        style: TextStyle(
          color: kColorWhite,
          fontWeight: FontWeight.w700,
          fontSize: size >= 64 ? 22 : (size >= 48 ? 18 : 16),
          fontFamily: Font.Poppins,
        ),
      ),
    );
  }
}

/// Soft colorful metric / tag chip for list cards.
class SuperAdminMetricChip extends StatelessWidget {
  const SuperAdminMetricChip({
    super.key,
    required this.label,
    required this.accent,
    this.icon,
    this.coinIcon = false,
  }) : assert(icon != null || coinIcon);

  final IconData? icon;
  final String label;
  final Color accent;
  final bool coinIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          coinIcon
              ? AppCoinIcon(size: 12, color: accent)
              : Icon(icon!, size: 12, color: accent),
          Spacing.h4,
          SemiBoldText(
            text: label,
            fontSize: TextStyles.k10FontSize,
            color: accent,
          ),
        ],
      ),
    );
  }
}

/// Colorful stat tile for detail screens — compact + readable labels.
class SuperAdminStatTile extends StatelessWidget {
  const SuperAdminStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.accent,
    this.icon,
    this.coinIcon = false,
    this.compact = false,
  }) : assert(icon != null || coinIcon);

  final IconData? icon;
  final String label;
  final String value;
  final Color accent;
  final bool coinIcon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: accent.withValues(alpha: 0.10),
          border: Border.all(color: accent.withValues(alpha: 0.32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            coinIcon
                ? SuperAdminUi.glowCoinIcon(
                    accent: accent,
                    size: 26,
                    iconSize: 12,
                  )
                : Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [
                          accent,
                          accent.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                    child: Icon(icon, size: 13, color: kColorWhite),
                  ),
            Spacing.v6,
            BoldText(
              text: value,
              fontSize: TextStyles.k14FontSize,
              color: SuperAdminUi.textPrimary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Spacing.v2,
            AppText(
              text: label,
              fontSize: TextStyles.k8FontSize,
              color: SuperAdminUi.textSecondary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              align: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: accent.withValues(alpha: 0.10),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          coinIcon
              ? SuperAdminUi.glowCoinIcon(
                  accent: accent,
                  size: 30,
                  iconSize: 14,
                )
              : SuperAdminUi.glowIcon(
                  icon: icon!,
                  accent: accent,
                  size: 30,
                  iconSize: 14,
                ),
          Spacing.v8,
          BoldText(
            text: value,
            fontSize: TextStyles.k16FontSize,
            color: SuperAdminUi.textPrimary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Spacing.v2,
          AppText(
            text: label,
            fontSize: TextStyles.k10FontSize,
            color: SuperAdminUi.textSecondary,
          ),
        ],
      ),
    );
  }
}

/// Soft labeled pill for contact / profile details.
class SuperAdminDetailChip extends StatelessWidget {
  const SuperAdminDetailChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: accent.withValues(alpha: 0.10),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: accent),
          Spacing.h10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: label,
                  fontSize: TextStyles.k10FontSize,
                  color: SuperAdminUi.textMuted,
                ),
                Spacing.v2,
                SemiBoldText(
                  text: value,
                  fontSize: TextStyles.k12FontSize,
                  color: SuperAdminUi.textPrimary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
