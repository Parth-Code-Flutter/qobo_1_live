import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_coin_icon.dart';
import 'package:qobo_one_live/utils/app_widgets/app_shell_background.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/glossy_auth_field_border.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Shared Super Admin + Agency chrome — buttons, icons, bottom nav.
///
/// Keeps both shells on one look: colorful accent icons, gold CTAs, and the
/// floating glossy light bottom dock (AppLightUi / main dating nav).
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

  static const textPrimary = Color(0xFF2A1744);
  static const textSecondary = Color(0xFF7A668C);
  static const textMuted = Color(0xFF9A86A8);
  static const textFaint = Color(0xFFB5A4C2);
  static const ctaInk = Color(0xFF1A1200);

  static const goldButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFE8A8), Color(0xFFFFD166), Color(0xFFFFB84D)],
  );

  /// Violet→pink CTA — matches AppLightUi.familyCtaGradient.
  static const primaryButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF7B5CFF), Color(0xFFB35CFF), Color(0xFFFF2E83)],
  );

  /// Solid gradient icon tile — same language as Profile feature grid.
  /// White glyph on vivid gradient (no washed tint fill).
  static Widget glowIcon({
    IconData? icon,
    Widget? child,
    required Color accent,
    double size = 44,
    double iconSize = 22,
    Color? accentEnd,
  }) {
    assert(icon != null || child != null);
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
      child:
          child ??
          Icon(icon!, color: kColorWhite, size: iconSize),
    );
  }

  /// Gradient tile with the standard coin SVG (no currency symbol).
  static Widget glowCoinIcon({
    required Color accent,
    double size = 44,
    double iconSize = 22,
    Color? accentEnd,
  }) {
    return glowIcon(
      accent: accent,
      accentEnd: accentEnd,
      size: size,
      child: AppCoinIcon(size: iconSize, color: kColorWhite),
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

/// Floating glossy bottom bar — matches main dating [BottomNavView] dock.
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

  static const _radius = 30.0;
  static const _borderWidth = 1.7;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          gradient: GlossyAuthFieldBorder.authSweepGradient,
        ),
        padding: const EdgeInsets.all(_borderWidth),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius - _borderWidth),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_radius - _borderWidth),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.94),
                    const Color(0xFFFFF5FA).withValues(alpha: 0.9),
                    Colors.white.withValues(alpha: 0.9),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.65),
                  width: 0.6,
                ),
              ),
              child: SizedBox(
                height: 66,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final tabCount = items.length;
                    final tabW = constraints.maxWidth / tabCount;
                    final accent = items[selectedIndex].accent;

                    return Stack(
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 340),
                          curve: Curves.easeOutBack,
                          left: (selectedIndex * tabW) + 5,
                          top: 7,
                          width: tabW - 10,
                          height: 52,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  accent.withValues(alpha: 0.22),
                                  accent.withValues(alpha: 0.08),
                                ],
                              ),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.32),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.18),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: List.generate(items.length, (index) {
                            final item = items[index];
                            return Expanded(
                              child: AdminBottomNavTab(
                                label: item.label,
                                icon: item.icon,
                                accent: item.accent,
                                selected: selectedIndex == index,
                                onTap: () => onSelected(index),
                              ),
                            );
                          }),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Colorful tab item — bounce + color morph on select (pill slides in parent).
class AdminBottomNavTab extends StatefulWidget {
  const AdminBottomNavTab({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.accent = AdminAgencyUi.violet,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;

  @override
  State<AdminBottomNavTab> createState() => _AdminBottomNavTabState();
}

class _AdminBottomNavTabState extends State<AdminBottomNavTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 1.22).chain(
          CurveTween(curve: Curves.easeOutBack),
        ),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.22, end: 1).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
        weight: 45,
      ),
    ]).animate(_bounce);
    if (widget.selected) _bounce.value = 1;
  }

  @override
  void didUpdateWidget(covariant AdminBottomNavTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.selected && widget.selected) {
      _bounce.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor =
        widget.selected ? widget.accent : widget.accent.withValues(alpha: 0.62);
    final labelColor = widget.selected
        ? widget.accent
        : AdminAgencyUi.textMuted.withValues(alpha: 0.95);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        splashColor: widget.accent.withValues(alpha: 0.14),
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scale,
              child: Icon(
                widget.icon,
                size: widget.selected ? 22 : 20,
                color: iconColor,
              ),
            ),
            Spacing.v4,
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: widget.selected
                  ? TextStyles.kSemiBoldPoppins(
                      fontSize: TextStyles.k10FontSize,
                      colors: labelColor,
                    )
                  : TextStyles.kRegularPoppins(
                      fontSize: TextStyles.k10FontSize,
                      colors: labelColor,
                    ),
              child: Text(widget.label),
            ),
          ],
        ),
      ),
    );
  }
}

/// Solid accent panel on [kColorLavenderBg] — Profile / Super Admin style (no blur).
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
