import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/safe_network_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Shared design tokens for the Super Admin shell.
///
/// Dark fintech-glass system: deep navy canvas, opaque-enough panels,
/// restrained accents, Poppins hierarchy (8px spacing grid).
abstract final class SuperAdminUi {
  SuperAdminUi._();

  // —— Canvas ——
  static const ink = Color(0xFF07061A);
  static const inkElevated = Color(0xFF12101F);
  static const sheet = Color(0xFF14122A);
  static const panel = Color(0xFF1A1730);

  // —— Accents (status / icons only — not full-card paint) ——
  static const gold = Color(0xFFFFD166);
  static const goldDeep = Color(0xFFFFB020);
  static const violet = Color(0xFF9C6BFF);
  static const mint = Color(0xFF4ADE80);
  static const rose = Color(0xFFFF6B8A);
  static const sky = Color(0xFF7C9CFF);
  static const pink = Color(0xFFFF8AD8);
  static const teal = Color(0xFF5CE1B0);
  static const danger = Color(0xFFFF8A80);
  static const warning = Color(0xFFFFB74D);
  static const success = Color(0xFF2E9E5B);

  // —— Type colors (cool-tinted, not pure white — avoids glass vibration) ——
  static const textPrimary = Color(0xFFF0EEF8);
  static const textSecondary = Color(0xFFB4B0C4);
  static const textMuted = Color(0xFF8A869C);
  static const textFaint = Color(0xFF6A6680);

  // —— Layout (8px grid) ——
  static const double pagePad = 20;
  static const double sectionGap = 16;
  static const double cardPad = 16;
  static const double cardRadius = 22;
  static const EdgeInsets pageInsets = EdgeInsets.fromLTRB(
    pagePad,
    4,
    pagePad,
    100,
  );
  static const EdgeInsets detailInsets = EdgeInsets.fromLTRB(
    pagePad,
    8,
    pagePad,
    32,
  );

  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      kColorLiveFilterChipGradientStart,
      kColorLiveFilterChipGradientMid,
      kColorLiveFilterChipGradientEnd,
    ],
  );

  static const goldButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFE8A8), Color(0xFFFFD166), Color(0xFFFFB84D)],
  );

  /// Opaque-enough dark glass — readable on any backdrop glow.
  static BoxDecoration glassDecoration({
    Color? glow,
    double radius = cardRadius,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          panel.withValues(alpha: 0.88),
          inkElevated.withValues(alpha: 0.92),
        ],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: kColorWhite.withValues(alpha: 0.10)),
      boxShadow: [
        if (glow != null)
          BoxShadow(
            color: glow.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        BoxShadow(
          color: kColorBlack.withValues(alpha: 0.32),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  /// Soft icon badge — single accent role, no stacked glow noise.
  static Widget glowIcon({
    required IconData icon,
    required Color accent,
    double size = 44,
    double iconSize = 22,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.30),
        color: accent.withValues(alpha: 0.14),
        border: Border.all(color: accent.withValues(alpha: 0.32)),
      ),
      child: Icon(icon, color: accent, size: iconSize),
    );
  }
}

/// Shared ambient canvas for every Super Admin screen (tabs + detail).
class SuperAdminPageBackdrop extends StatelessWidget {
  const SuperAdminPageBackdrop({
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
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: SuperAdminUi.ink),
        Opacity(
          opacity: 0.38,
          child: Image.asset(kImgBG, fit: BoxFit.cover),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                SuperAdminUi.ink.withValues(alpha: 0.35),
                SuperAdminUi.ink.withValues(alpha: 0.55),
                SuperAdminUi.ink.withValues(alpha: 0.82),
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primary.withValues(alpha: 0.16),
                Colors.transparent,
                secondary.withValues(alpha: 0.12),
              ],
              stops: const [0, 0.48, 1],
            ),
          ),
        ),
        Positioned(
          top: -60,
          right: -40,
          child: _blob(primary, 220),
        ),
        Positioned(
          bottom: 120,
          left: -70,
          child: _blob(secondary, 200),
        ),
        child,
      ],
    );
  }

  Widget _blob(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.22),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tab body shell: shared backdrop + safe area.
class SuperAdminPageScaffold extends StatelessWidget {
  const SuperAdminPageScaffold({
    super.key,
    required this.child,
    this.primary = SuperAdminUi.violet,
    this.secondary = SuperAdminUi.sky,
    this.bottom = false,
  });

  final Widget child;
  final Color primary;
  final Color secondary;
  final bool bottom;

  @override
  Widget build(BuildContext context) {
    return SuperAdminPageBackdrop(
      primary: primary,
      secondary: secondary,
      child: SafeArea(bottom: bottom, child: child),
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

    final clipped = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: blur
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: body,
            )
          : body,
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
        padding: const EdgeInsets.symmetric(horizontal: 14),
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: isSelected ? SuperAdminUi.headerGradient : null,
          color: isSelected
              ? null
              : SuperAdminUi.panel.withValues(alpha: 0.55),
          border: Border.all(
            color: isSelected
                ? kColorLiveFilterChipBorder
                : kColorWhite.withValues(alpha: 0.10),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: SuperAdminUi.violet.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? SuperAdminUi.textPrimary : SuperAdminUi.textMuted,
            ),
            Spacing.h6,
            SemiBoldText(
              text: label,
              fontSize: TextStyles.k12FontSize,
              color: isSelected
                  ? SuperAdminUi.textPrimary
                  : SuperAdminUi.textSecondary,
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
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            SuperAdminUi.pagePad,
            12,
            SuperAdminUi.pagePad,
            20 + MediaQuery.paddingOf(context).bottom,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                SuperAdminUi.sheet.withValues(alpha: 0.96),
                SuperAdminUi.ink.withValues(alpha: 0.98),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: kColorWhite.withValues(alpha: 0.10)),
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
                    color: SuperAdminUi.textFaint,
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
        color: SuperAdminUi.panel.withValues(alpha: 0.55),
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
              color: SuperAdminUi.ink,
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
                border: Border.all(color: SuperAdminUi.textPrimary, width: 1.5),
              ),
              child: const SemiBoldText(
                text: 'LIVE',
                fontSize: 8,
                color: SuperAdminUi.textPrimary,
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
        style: const TextStyle(
          color: SuperAdminUi.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 22,
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
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
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

/// Colorful 2-column stat tile for detail screens.
class SuperAdminStatTile extends StatelessWidget {
  const SuperAdminStatTile({
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: accent.withValues(alpha: 0.10),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SuperAdminUi.glowIcon(
            icon: icon,
            accent: accent,
            size: 34,
            iconSize: 16,
          ),
          Spacing.v10,
          BoldText(
            text: value,
            fontSize: TextStyles.k18FontSize,
            color: SuperAdminUi.textPrimary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Spacing.v2,
          AppText(
            text: label,
            fontSize: TextStyles.k10FontSize,
            color: SuperAdminUi.textMuted,
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
