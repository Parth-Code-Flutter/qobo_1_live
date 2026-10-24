import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'gift_icon_widget.dart';

/// Decorative repetitions only: one user tap still produces one gift request.
class LuckyGiftTrail extends StatefulWidget {
  const LuckyGiftTrail({
    super.key,
    required this.origin,
    required this.target,
    required this.icon,
    required this.onComplete,
  });
  final Offset origin, target;
  final String icon;
  final VoidCallback onComplete;
  static final List<OverlayEntry> _entries = [];

  static void show(
    BuildContext context, {
    required Offset origin,
    required Offset target,
    required String icon,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final box = overlay.context.findRenderObject() as RenderBox;
    // Bound rapid taps without building a delayed animation backlog.
    if (_entries.length >= 4) _entries.removeAt(0).remove();
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: LuckyGiftTrail(
          origin: box.globalToLocal(origin),
          target: box.globalToLocal(target),
          icon: icon,
          onComplete: () {
            if (_entries.remove(entry)) entry.remove();
          },
        ),
      ),
    );
    _entries.add(entry);
    overlay.insert(entry);
  }

  static void dismiss() {
    for (final entry in _entries) {
      entry.remove();
    }
    _entries.clear();
  }

  @override
  State<LuckyGiftTrail> createState() => _LuckyGiftTrailState();
}

class _LuckyGiftTrailState extends State<LuckyGiftTrail>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller =
      AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1600),
        )
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) widget.onComplete();
        })
        ..forward();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (_, _) => Stack(children: [for (var i = 0; i < 4; i++) _image(i)]),
  );

  Widget _image(int index) {
    final raw = (controller.value - index * .105) / .685;
    if (raw <= 0 || raw >= 1) return const SizedBox.shrink();
    final t = Curves.easeInOutCubic.transform(raw);
    final control = Offset(
      widget.origin.dx + (widget.target.dx - widget.origin.dx) * .25,
      widget.origin.dy - (widget.origin.dy - widget.target.dy) * .65,
    );
    final position =
        widget.origin * ((1 - t) * (1 - t)) +
        control * (2 * (1 - t) * t) +
        widget.target * (t * t);
    final size = (112 - index * 8) * (1 - .78 * t);
    final opacity =
        (raw / .08).clamp(0.0, 1.0) * ((1 - raw) / .18).clamp(0.0, 1.0);
    return Positioned(
      key: ValueKey('lucky-trail-$index'),
      left: position.dx - size / 2,
      top: position.dy - size / 2,
      width: size,
      height: size,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: math.sin(raw * math.pi) * .06 * (index.isEven ? 1 : -1),
          child: GiftIconWidget(icon: widget.icon, size: size, animate: false),
        ),
      ),
    );
  }
}
