import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';

/// Shared glass panel used across Super Admin tabs.
class SuperAdminGlassCard extends StatelessWidget {
  const SuperAdminGlassCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        // Soft diagonal sheen instead of a flat tint for a glassier look.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kColorWhite.withValues(alpha: 0.14),
            kColorWhite.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: kColorBlack.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
