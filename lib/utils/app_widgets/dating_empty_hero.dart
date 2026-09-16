import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';

/// Trending dating empty-state illustration styles.
enum DatingEmptyHeroStyle { audio, video, live, messages, sparks }

/// Soft animated hero graphic — floating orbs, hearts, and a themed center.
///
/// Pure Flutter (no Lottie) so it ships with the white dating canvas.
class DatingEmptyHero extends StatefulWidget {
  const DatingEmptyHero({
    super.key,
    required this.style,
    this.size = 168,
    this.accentColors = const [AppLightUi.pink, AppLightUi.violet],
  });

  final DatingEmptyHeroStyle style;
  final double size;
  final List<Color> accentColors;

  @override
  State<DatingEmptyHero> createState() => _DatingEmptyHeroState();
}

class _DatingEmptyHeroState extends State<DatingEmptyHero>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _spin.dispose();
    super.dispose();
  }

  Color get _a => widget.accentColors.first;
  Color get _b =>
      widget.accentColors.length > 1 ? widget.accentColors[1] : AppLightUi.violet;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulse, _spin]),
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_pulse.value);
          final spin = _spin.value * math.pi * 2;
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.hardEdge,
            children: [
              // Soft blush backdrop
              Container(
                width: widget.size * 0.92,
                height: widget.size * 0.92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _a.withValues(alpha: 0.16 + t * 0.06),
                      _b.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Orbit ring
              Transform.rotate(
                angle: spin * 0.35,
                child: CustomPaint(
                  size: Size(widget.size * 0.78, widget.size * 0.78),
                  painter: _DashedRingPainter(
                    color: _a.withValues(alpha: 0.28),
                    strokeWidth: 1.4,
                  ),
                ),
              ),
              // Floating hearts / sparkles
              ..._orbitDecor(t, spin),
              // Center badge
              _centerBadge(t),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _orbitDecor(double t, double spin) {
    final items = <Widget>[];
    final icons = switch (widget.style) {
      DatingEmptyHeroStyle.audio => const [
        Icons.favorite_rounded,
        Icons.music_note_rounded,
        Icons.favorite_rounded,
      ],
      DatingEmptyHeroStyle.video => const [
        Icons.favorite_rounded,
        Icons.auto_awesome_rounded,
        Icons.favorite_rounded,
      ],
      DatingEmptyHeroStyle.live => const [
        Icons.favorite_rounded,
        Icons.sensors_rounded,
        Icons.favorite_rounded,
      ],
      DatingEmptyHeroStyle.messages || DatingEmptyHeroStyle.sparks => const [
        Icons.favorite_rounded,
        Icons.chat_bubble_rounded,
        Icons.favorite_rounded,
      ],
    };

            for (var i = 0; i < icons.length; i++) {
      final angle = spin + (i * 2 * math.pi / icons.length);
      final radius = widget.size * (0.34 + t * 0.02);
      final dx = math.cos(angle) * radius;
      final dy = math.sin(angle) * radius;
      final size = (widget.size * (i == 1 ? 0.14 : 0.11)).clamp(10.0, 18.0);
      items.add(
        Transform.translate(
          offset: Offset(dx, dy),
          child: Container(
            width: size + 8,
            height: size + 8,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kColorWhite.withValues(alpha: 0.92),
              boxShadow: [
                BoxShadow(
                  color: _a.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icons[i],
              size: size,
              color: i.isEven ? _a : _b,
            ),
          ),
        ),
      );
    }
    return items;
  }

  Widget _centerBadge(double t) {
    final core = widget.size * 0.42;
    // Limit pulse growth on small heroes so the glyph Column never overflows.
    final pulse = (t * (widget.size < 90 ? 1.5 : 4));
    return Container(
      width: core + pulse,
      height: core + pulse,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_a, _b],
        ),
        boxShadow: [
          BoxShadow(
            color: _a.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: kColorWhite.withValues(alpha: 0.85), width: 2.5),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: EdgeInsets.all(core * 0.08),
            child: _centerGlyph(),
          ),
        ),
      ),
    );
  }

  Widget _centerGlyph() {
    final core = widget.size * 0.42;
    switch (widget.style) {
      case DatingEmptyHeroStyle.audio:
        return const _WaveformGlyph();
      case DatingEmptyHeroStyle.video:
        return Icon(
          Icons.videocam_rounded,
          color: kColorWhite,
          size: (core * 0.55).clamp(16.0, 34.0),
        );
      case DatingEmptyHeroStyle.live:
        // Scale glyph to the circle — fixed 26px icon overflowed small heroes.
        final iconSize = (core * 0.42).clamp(12.0, 22.0);
        final labelSize = (core * 0.22).clamp(7.0, 9.0);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sensors_rounded, color: kColorWhite, size: iconSize),
            SizedBox(height: core * 0.04),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: (core * 0.12).clamp(4.0, 7.0),
                vertical: (core * 0.04).clamp(1.0, 2.0),
              ),
              decoration: BoxDecoration(
                color: kColorWhite.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'LIVE',
                style: TextStyle(
                  color: kColorWhite,
                  fontSize: labelSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  height: 1.0,
                ),
              ),
            ),
          ],
        );
      case DatingEmptyHeroStyle.messages:
        return Icon(
          Icons.forum_rounded,
          color: kColorWhite,
          size: (core * 0.55).clamp(16.0, 32.0),
        );
      case DatingEmptyHeroStyle.sparks:
        return Icon(
          Icons.favorite_rounded,
          color: kColorWhite,
          size: (core * 0.55).clamp(16.0, 32.0),
        );
    }
  }
}

class _WaveformGlyph extends StatelessWidget {
  const _WaveformGlyph();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 28,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(5, (i) {
          final h = switch (i) {
            0 || 4 => 10.0,
            1 || 3 => 18.0,
            _ => 26.0,
          };
          return Container(
            width: 4,
            height: h,
            decoration: BoxDecoration(
              color: kColorWhite,
              borderRadius: BorderRadius.circular(99),
            ),
          );
        }),
      ),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  _DashedRingPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Offset.zero & size;
    const dashCount = 28;
    const gapFactor = 0.45;
    for (var i = 0; i < dashCount; i++) {
      final start = (i / dashCount) * 2 * math.pi;
      final sweep = (2 * math.pi / dashCount) * (1 - gapFactor);
      canvas.drawArc(rect.deflate(2), start, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
