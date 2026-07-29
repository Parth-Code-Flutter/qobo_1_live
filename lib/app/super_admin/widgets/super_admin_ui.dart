import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Shared palette + chrome for the Super Admin shell.
abstract final class SuperAdminUi {
  SuperAdminUi._();

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
  static const ink = Color(0xFF0B0918);
  static const sheet = Color(0xFF14132E);

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
    colors: [Color(0xFFFFE08A), Color(0xFFFFD166)],
  );

  static BoxDecoration glassDecoration({
    Color? glow,
    double radius = 20,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          kColorWhite.withValues(alpha: 0.16),
          kColorWhite.withValues(alpha: 0.05),
          const Color(0xFF1A1030).withValues(alpha: 0.35),
        ],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: kColorWhite.withValues(alpha: 0.18)),
      boxShadow: [
        BoxShadow(
          color: (glow ?? violet).withValues(alpha: 0.18),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: kColorBlack.withValues(alpha: 0.22),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  /// Rounded icon badge with soft glow (stats, section headers, CTA rows).
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
        borderRadius: BorderRadius.circular(size * 0.32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.42),
            accent.withValues(alpha: 0.10),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: accent, size: iconSize),
    );
  }
}

/// Premium glass panel with optional blur for Super Admin cards.
class SuperAdminGlassCard extends StatelessWidget {
  const SuperAdminGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.glow,
    this.onTap,
    this.radius = 20,
    this.blur = true,
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
      padding: padding ?? const EdgeInsets.all(14),
      decoration: SuperAdminUi.glassDecoration(glow: glow, radius: radius),
      child: child,
    );

    final clipped = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: blur
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
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
          color: isSelected ? null : kColorWhite.withValues(alpha: 0.10),
          border: Border.all(
            color: isSelected
                ? kColorLiveFilterChipBorder
                : kColorWhite.withValues(alpha: 0.14),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: SuperAdminUi.violet.withValues(alpha: 0.4),
                    blurRadius: 12,
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
              color: isSelected ? kColorWhite : Colors.white60,
            ),
            Spacing.h6,
            SemiBoldText(
              text: label,
              fontSize: TextStyles.k12FontSize,
              color: isSelected ? kColorWhite : Colors.white70,
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
            16,
            12,
            16,
            20 + MediaQuery.paddingOf(context).bottom,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                SuperAdminUi.sheet.withValues(alpha: 0.94),
                const Color(0xFF0C0B1C).withValues(alpha: 0.98),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: kColorWhite.withValues(alpha: 0.12)),
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
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Spacing.v12,
              SemiBoldText(
                text: title,
                fontSize: TextStyles.k16FontSize,
                color: kColorWhite,
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                Spacing.v4,
                AppText(
                  text: subtitle!,
                  fontSize: TextStyles.k12FontSize,
                  color: Colors.white60,
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
        color: kColorWhite.withValues(alpha: 0.06),
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
                    color: kColorWhite,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white38,
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
