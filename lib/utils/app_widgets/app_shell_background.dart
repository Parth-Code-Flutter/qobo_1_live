import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';

/// Same canvas as Messages / Discover — bare full-bleed [kImgBG], nothing else.
class AppShellBackground extends StatelessWidget {
  const AppShellBackground({
    super.key,
    required this.child,
    this.primaryGlow = const Color(0xFF9C6BFF),
    this.secondaryGlow = const Color(0xFFFF5CAB),
    this.showOrbs = false,
  });

  final Widget child;
  final Color primaryGlow;
  final Color secondaryGlow;
  final bool showOrbs;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(kImgBG),
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (showOrbs) ...[
          Positioned(
            top: -70,
            right: -50,
            child: _orb(primaryGlow, 220),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: _orb(secondaryGlow, 200),
          ),
        ],
        child,
      ],
    );
  }

  static Widget _orb(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.22),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

/// Solid panel on [kImgBG] — Profile-style, no frosted blur / washed alphas.
BoxDecoration appShellGlassDecoration({
  Color? glow,
  double radius = 22,
  bool showBorder = true,
}) {
  return BoxDecoration(
    color: const Color(0xFF2A1748),
    borderRadius: BorderRadius.circular(radius),
    border: showBorder
        ? Border.all(
            color: (glow ?? kColorWhite)
                .withValues(alpha: glow == null ? 0.22 : 0.45),
            width: 1.2,
          )
        : null,
    boxShadow: [
      if (glow != null && showBorder)
        BoxShadow(
          color: glow.withValues(alpha: 0.28),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      BoxShadow(
        color: kColorBlack.withValues(alpha: 0.35),
        blurRadius: 14,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

/// Vivid gradient panel — colorful fill, no outline (Agency / dashboard tiles).
BoxDecoration appShellColorPanelDecoration({
  required List<Color> gradientColors,
  double radius = 22,
  AlignmentGeometry begin = Alignment.topLeft,
  AlignmentGeometry end = Alignment.bottomRight,
}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: LinearGradient(
      begin: begin,
      end: end,
      colors: gradientColors,
    ),
    boxShadow: [
      BoxShadow(
        color: gradientColors.first.withValues(alpha: 0.32),
        blurRadius: 14,
        offset: const Offset(0, 6),
      ),
      BoxShadow(
        color: kColorBlack.withValues(alpha: 0.28),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
