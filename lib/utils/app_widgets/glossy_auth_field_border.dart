import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';

/// Continuous glossy gradient ring for auth text fields.
///
/// Uses a [SweepGradient] so the color wraps the rounded rect evenly —
/// a linear gradient looks "cut" at corners because each side samples
/// different stops abruptly.
class GlossyAuthFieldBorder extends StatelessWidget {
  const GlossyAuthFieldBorder({
    super.key,
    required this.child,
    this.radius = 18,
    this.borderWidth = 1.6,
    this.fill,
  });

  final Widget child;
  final double radius;
  final double borderWidth;
  final Color? fill;

  static const authSweepGradient = SweepGradient(
    center: Alignment.center,
    startAngle: 0,
    endAngle: 6.28318530718, // 2π
    colors: [
      Color(0xFFFF8EC8),
      Color(0xFFFF4F98),
      Color(0xFFB35CFF),
      Color(0xFF7B5CFF),
      Color(0xFF5B8CFF),
      Color(0xFFFF8EC8),
    ],
    stops: [0.0, 0.2, 0.42, 0.62, 0.82, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    final innerRadius = (radius - borderWidth).clamp(0.0, radius);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: authSweepGradient,
      ),
      padding: EdgeInsets.all(borderWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill ?? Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(innerRadius),
          border: Border.all(
            color: AppLightUi.border.withValues(alpha: 0.35),
            width: 0.5,
          ),
        ),
        child: child,
      ),
    );
  }
}
