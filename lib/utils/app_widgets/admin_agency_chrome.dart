import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_shell_background.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Shared Super Admin + Agency chrome — buttons, icons, bottom nav.
///
/// Keeps both shells on one look: colorful accent icons, gold CTAs, and the
/// navy glass bottom bar from the Super Admin dashboard.
abstract final class AdminAgencyUi {
  AdminAgencyUi._();

  static const violet = Color(0xFF9C6BFF);
  static const pink = Color(0xFFFF5CAB);
  static const mint = Color(0xFF4ADE80);
  static const gold = Color(0xFFFFD166);
  static const goldDeep = Color(0xFFFFB020);
  static const rose = Color(0xFFFF6B8A);
  static const sky = Color(0xFF7C9CFF);
  static const teal = Color(0xFF5CE1B0);
  static const cyan = Color(0xFF4FD1C5);

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xCCFFFFFF);
  static const textMuted = Color(0x99FFFFFF);
  static const textFaint = Color(0x66FFFFFF);
  static const ctaInk = Color(0xFF1A1200);

  static const goldButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFE8A8), Color(0xFFFFD166), Color(0xFFFFB84D)],
  );

  static const primaryButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF5CAB), Color(0xFF9C6BFF)],
  );

  /// Solid gradient icon tile — same language as Profile feature grid.
  /// White glyph on vivid gradient (no washed tint fill).
  static Widget glowIcon({
    required IconData icon,
    required Color accent,
    double size = 44,
    double iconSize = 22,
    Color? accentEnd,
  }) {
    final end = accentEnd ?? Color.lerp(accent, const Color(0xFFFFFFFF), 0.22)!;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, end],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(icon, color: kColorWhite, size: iconSize),
    );
  }

  /// Square header control — solid accent gradient, white icon.
  static Widget glassIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color accent = sky,
    double size = 44,
    double iconSize = 18,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent,
                Color.lerp(accent, const Color(0xFFFFFFFF), 0.22)!,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.32),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: kColorWhite, size: iconSize),
        ),
      ),
    );
  }
}

/// Gold gradient CTA — same shape as Super Admin "Generate".
class AdminGoldCtaButton extends StatelessWidget {
  const AdminGoldCtaButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.ios_share_rounded,
    this.busy = false,
    this.expanded = false,
    this.height = 48,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData icon;
  final bool busy;
  final bool expanded;
  final double height;

  @override
  Widget build(BuildContext context) {
    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: expanded ? height : null,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: AdminAgencyUi.goldButtonGradient,
            boxShadow: [
              BoxShadow(
                color: AdminAgencyUi.gold.withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(
            horizontal: expanded ? 16 : 14,
            vertical: expanded ? 0 : 12,
          ),
          child: busy
              ? Center(
                  child: SizedBox(
                    width: expanded ? 18 : 16,
                    height: expanded ? 18 : 16,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AdminAgencyUi.ctaInk,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: AdminAgencyUi.ctaInk),
                    Spacing.h6,
                    SemiBoldText(
                      text: label,
                      fontSize: TextStyles.k12FontSize,
                      color: AdminAgencyUi.ctaInk,
                    ),
                  ],
                ),
        ),
      ),
    );

    if (expanded) return SizedBox(width: double.infinity, child: child);
    return child;
  }
}

/// Pink→violet primary CTA for secondary emphasis actions.
class AdminPrimaryCtaButton extends StatelessWidget {
  const AdminPrimaryCtaButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.busy = false,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool busy;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: AdminAgencyUi.primaryButtonGradient,
            boxShadow: [
              BoxShadow(
                color: AdminAgencyUi.pink.withValues(alpha: 0.32),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: busy
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: kColorWhite,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: kColorWhite, size: 20),
                      Spacing.h8,
                    ],
                    SemiBoldText(
                      text: label,
                      fontSize: TextStyles.k14FontSize,
                      color: kColorWhite,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Navy glass bottom bar — same chrome as main [BottomNavView].
class AdminBottomNavBar extends StatelessWidget {
  const AdminBottomNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<({String label, IconData icon, Color accent})> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                // Match BottomNavView exactly.
                const Color(0xFF181A5A).withValues(alpha: 0.86),
                const Color(0xFF121644).withValues(alpha: 0.93),
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(26),
              topRight: Radius.circular(26),
            ),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
                width: 0.7,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: SizedBox(
              height: 84,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  return Expanded(
                    child: AdminBottomNavTab(
                      label: item.label,
                      icon: item.icon,
                      selected: selectedIndex == index,
                      onTap: () => onSelected(index),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tab item styled like main-app nav: white when selected, muted when not.
class AdminBottomNavTab extends StatelessWidget {
  const AdminBottomNavTab({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? kColorWhite : Colors.white.withValues(alpha: 0.42);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white.withValues(alpha: 0.08),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            Spacing.v6,
            AppText(
              text: label,
              fontSize: TextStyles.k10FontSize,
              style: selected
                  ? TextStyles.kSemiBoldPoppins(
                      fontSize: TextStyles.k12FontSize,
                      colors: kColorWhite,
                    )
                  : TextStyles.kRegularPoppins(
                      fontSize: TextStyles.k10FontSize,
                      colors: Colors.white.withValues(alpha: 0.45),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Solid accent panel on [kImgBG] — Profile / Super Admin style (no blur).
class AdminSolidPanel extends StatelessWidget {
  const AdminSolidPanel({
    super.key,
    required this.child,
    this.accent,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.showBorder = true,
  });

  final Widget child;
  final Color? accent;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final panel = Container(
      padding: padding,
      decoration: appShellGlassDecoration(
        glow: accent,
        radius: radius,
        showBorder: showBorder,
      ),
      child: child,
    );

    if (onTap == null) return panel;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: panel,
      ),
    );
  }
}

/// Gradient panel — vivid color, no border (Agency dashboard tiles).
class AdminColorPanel extends StatelessWidget {
  const AdminColorPanel({
    super.key,
    required this.child,
    required this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.onTap,
  });

  final Widget child;
  final List<Color> colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final panel = Container(
      padding: padding,
      decoration: appShellColorPanelDecoration(
        gradientColors: colors,
        radius: radius,
        begin: begin,
        end: end,
      ),
      child: child,
    );

    if (onTap == null) return panel;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: panel,
      ),
    );
  }
}
