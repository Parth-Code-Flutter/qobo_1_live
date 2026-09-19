import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Figma `nav-bar-fresh-4tab` — dark navy dock, rainbow stroke, accent pills.
class SuperAdminFreshNavBar extends StatelessWidget {
  const SuperAdminFreshNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<SuperAdminFreshNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _radius = 32.0;
  static const _borderWidth = 1.8;
  static const _barHeight = 72.0;

  static const _navFill = Color(0xFF161022);
  static const _navFillTop = Color(0xFF1E1630);

  /// Cyan → magenta → green → orange (matches Figma stroke).
  static const _borderGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF00E8FF),
      Color(0xFFFF2D9B),
      Color(0xFF3DFF6E),
      Color(0xFFFF9F1A),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, bottomInset + 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          gradient: _borderGradient,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E8FF).withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(-4, 6),
            ),
            BoxShadow(
              color: const Color(0xFFFF2D9B).withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(4, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(_borderWidth),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius - _borderWidth),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_radius - _borderWidth),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_navFillTop, _navFill],
                ),
              ),
              child: SizedBox(
                height: _barHeight,
                child: Row(
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    final selected = selectedIndex == index;
                    return Expanded(
                      child: _FreshNavTab(
                        item: item,
                        selected: selected,
                        onTap: () => onSelected(index),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SuperAdminFreshNavItem {
  const SuperAdminFreshNavItem({
    required this.label,
    required this.accent,
    required this.kind,
  });

  final String label;
  final Color accent;
  final SuperAdminFreshNavIconKind kind;
}

enum SuperAdminFreshNavIconKind { dashboard, agency, host, settings }

class _FreshNavTab extends StatefulWidget {
  const _FreshNavTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final SuperAdminFreshNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_FreshNavTab> createState() => _FreshNavTabState();
}

class _FreshNavTabState extends State<_FreshNavTab>
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
        tween: Tween<double>(begin: 1, end: 1.14).chain(
          CurveTween(curve: Curves.easeOutBack),
        ),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.14, end: 1).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
        weight: 45,
      ),
    ]).animate(_bounce);
    if (widget.selected) _bounce.value = 1;
  }

  @override
  void didUpdateWidget(covariant _FreshNavTab oldWidget) {
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
    final accent = widget.item.accent;
    final selected = widget.selected;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        splashColor: accent.withValues(alpha: 0.18),
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _scale,
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CustomPaint(
                      painter: _FreshNavIconPainter(
                        kind: widget.item.kind,
                        color: selected
                            ? accent
                            : const Color(0xFFB8B0C4),
                        selected: selected,
                      ),
                    ),
                  ),
                ),
                Spacing.v4,
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  style: TextStyles.kSemiBoldPoppins(
                    fontSize: 10,
                    colors: selected
                        ? accent
                        : const Color(0xFFB8B0C4),
                  ),
                  child: Text(widget.item.label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Vector icons matching Figma tab-dashboard / agency / host / settings.
class _FreshNavIconPainter extends CustomPainter {
  const _FreshNavIconPainter({
    required this.kind,
    required this.color,
    required this.selected,
  });

  final SuperAdminFreshNavIconKind kind;
  final Color color;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 2.0 : 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (kind) {
      case SuperAdminFreshNavIconKind.dashboard:
        _paintDashboard(canvas, size, stroke, fill);
      case SuperAdminFreshNavIconKind.agency:
        _paintAgency(canvas, size, stroke, fill);
      case SuperAdminFreshNavIconKind.host:
        _paintHost(canvas, size, stroke, fill);
      case SuperAdminFreshNavIconKind.settings:
        _paintSettings(canvas, size, stroke, fill);
    }
  }

  void _paintDashboard(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final w = size.width;
    final h = size.height;
    final barW = w * 0.15;
    final gap = w * 0.08;
    final baseY = h * 0.86;
    final heights = [0.34, 0.52, 0.72];
    var x = w * 0.10;
    for (final frac in heights) {
      final top = baseY - h * frac;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barW, baseY - top),
        const Radius.circular(2.2),
      );
      canvas.drawRRect(rrect, selected ? fill : stroke);
      x += barW + gap;
    }
    // Growth arrow (up-right), matching Figma chart mark.
    final tip = Offset(w * 0.92, h * 0.12);
    final shaft = Offset(w * 0.68, h * 0.36);
    canvas.drawLine(shaft, tip, stroke);
    canvas.drawLine(tip, Offset(tip.dx - w * 0.14, tip.dy), stroke);
    canvas.drawLine(tip, Offset(tip.dx, tip.dy + h * 0.14), stroke);
  }

  void _paintAgency(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.40;
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = -math.pi / 2 + i * math.pi / 3;
      final p = Offset(cx + r * math.cos(angle), cy + r * math.sin(angle));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, stroke);
    canvas.drawCircle(Offset(cx, cy), size.width * 0.12, fill);
  }

  void _paintHost(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final micCenter = Offset(cx, h * 0.34);
    final micW = w * 0.26;
    final micH = h * 0.38;

    final wave = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 1.75 : 1.5
      ..strokeCap = StrokeCap.round;

    // Two concentric broadcast arcs on each side of the mic.
    void drawWaves(double side) {
      for (final t in [0.0, 1.0]) {
        final rx = w * (0.16 + t * 0.12);
        final ry = h * (0.18 + t * 0.12);
        final rect = Rect.fromCenter(
          center: Offset(cx + side * w * 0.06, micCenter.dy),
          width: rx * 2,
          height: ry * 2,
        );
        // Left: open to the left; right: open to the right.
        final start = side < 0 ? math.pi * 0.65 : -math.pi * 0.35;
        canvas.drawArc(rect, start, math.pi * 0.70, false, wave);
      }
    }

    drawWaves(-1);
    drawWaves(1);

    // Pill mic head.
    final mic = RRect.fromRectAndRadius(
      Rect.fromCenter(center: micCenter, width: micW, height: micH),
      Radius.circular(micW / 2),
    );
    canvas.drawRRect(mic, selected ? fill : stroke);

    // White mid stripe when selected (matches Figma Host asset).
    if (selected) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: micCenter,
            width: micW * 0.88,
            height: micH * 0.16,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xE6FFFFFF),
      );
    }

    // T-stand.
    final standTop = micCenter.dy + micH / 2;
    canvas.drawLine(Offset(cx, standTop), Offset(cx, h * 0.76), stroke);
    canvas.drawLine(
      Offset(w * 0.28, h * 0.84),
      Offset(w * 0.72, h * 0.84),
      stroke,
    );
  }

  void _paintSettings(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.36;
    for (var i = 0; i < 4; i++) {
      final start = -math.pi / 2 + i * (math.pi / 2) + 0.32;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        start,
        math.pi / 2 - 0.64,
        false,
        stroke,
      );
    }
    final tick = size.width * 0.07;
    final outer = r + size.width * 0.05;
    for (final angle in [0.0, math.pi / 2, math.pi, 3 * math.pi / 2]) {
      final dx = math.cos(angle);
      final dy = math.sin(angle);
      canvas.drawLine(
        Offset(cx + dx * (outer - tick), cy + dy * (outer - tick)),
        Offset(cx + dx * outer, cy + dy * outer),
        stroke,
      );
    }
    canvas.drawCircle(Offset(cx, cy), size.width * 0.11, fill);
  }

  @override
  bool shouldRepaint(covariant _FreshNavIconPainter oldDelegate) {
    return oldDelegate.kind != kind ||
        oldDelegate.color != color ||
        oldDelegate.selected != selected;
  }
}
