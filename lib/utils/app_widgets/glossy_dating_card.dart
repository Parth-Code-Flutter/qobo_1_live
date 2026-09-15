import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';

/// Glossy pink→violet border card — dating-app chrome for lists & hubs.
class GlossyDatingCard extends StatelessWidget {
  const GlossyDatingCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
    this.radius = 22,
    this.borderWidth = 1.6,
    this.fill,
    this.emphasized = false,
    this.borderGradient,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double borderWidth;
  final Color? fill;

  /// Stronger glow + brighter border (e.g. unread / selected).
  final bool emphasized;

  final Gradient? borderGradient;

  static const defaultBorderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF8EC8),
      Color(0xFFFF4F98),
      Color(0xFFB35CFF),
      Color(0xFF7B5CFF),
    ],
    stops: [0.0, 0.35, 0.7, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    final innerRadius = (radius - borderWidth).clamp(0.0, radius);
    final gradient = borderGradient ??
        (emphasized
            ? AppLightUi.familyCtaGradient
            : defaultBorderGradient);

    final card = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: AppLightUi.title.withValues(
              alpha: emphasized ? 0.10 : 0.07,
            ),
            blurRadius: emphasized ? 18 : 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.all(borderWidth),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(innerRadius),
        child: Stack(
          children: [
            ColoredBox(
              color: fill ?? AppLightUi.card,
              child: Padding(padding: padding, child: child),
            ),
            // Top gloss highlight
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 28,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        kColorWhite.withValues(alpha: 0.55),
                        kColorWhite.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        splashColor: AppLightUi.pink.withValues(alpha: 0.12),
        highlightColor: AppLightUi.pink.withValues(alpha: 0.05),
        child: card,
      ),
    );
  }
}

/// Compact circular glossy action (chat / join / heart).
class GlossyCircleAction extends StatelessWidget {
  const GlossyCircleAction({
    super.key,
    required this.icon,
    this.size = 44,
    this.iconSize = 20,
    this.onTap,
    this.gradient = AppLightUi.familyCtaGradient,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final VoidCallback? onTap;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        border: Border.all(color: kColorWhite.withValues(alpha: 0.45), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppLightUi.title.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: kColorWhite, size: iconSize),
    );

    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: child,
      ),
    );
  }
}
