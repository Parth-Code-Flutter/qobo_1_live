import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/user_flow/live_broadcast/controllers/live_broadcast_controller.dart';

/// Colorful floating hearts, glass bubbles, and glossy balloons for live.
///
/// Uses existing [LiveBroadcastController.heartReactionTokens] — no API change.
/// Particles are spread across a wider lane so the mix feels airy, not stacked.
class LiveHeartReactionLayer extends StatelessWidget {
  const LiveHeartReactionLayer({super.key});

  static const Color whatsAppHeartGreen = Color(0xFF25D366);
  static const Color liveHeartRed = Color(0xFFFF3B5C);
  static const reactionColors = <Color>[
    Color(0xFFFF3B87),
    Color(0xFFE84DFF),
    Color(0xFFAA78FF),
    Color(0xFFFFCA55),
    Color(0xFF5EDBFF),
    Color(0xFFFF795E),
    Color(0xFFFF2D55),
    Color(0xFF00E5A8),
    Color(0xFFFF8A00),
    Color(0xFF4D9FFF),
    Color(0xFFFF4DD2),
    Color(0xFFB8FF3C),
    Color(0xFFFF6B6B),
    Color(0xFF7B61FF),
    Color(0xFFFFD166),
    Color(0xFF06D6A0),
    Color(0xFFFF1493),
    Color(0xFF00C2FF),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LiveBroadcastController>();
    final size = MediaQuery.sizeOf(context);

    return Obx(() {
      final tokens = controller.heartReactionTokens.toList(growable: false);
      if (tokens.isEmpty) return const SizedBox.shrink();

      return IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (final token in tokens)
              _FloatingReactionParticle(
                key: ValueKey(token),
                token: token,
                screenSize: size,
                topInset: MediaQuery.paddingOf(context).top,
                onFinished: controller.removeHeartReactionToken,
              ),
          ],
        ),
      );
    });
  }
}

enum _ReactionShape { heart, bubble, balloon }

class _FloatingReactionParticle extends StatefulWidget {
  const _FloatingReactionParticle({
    super.key,
    required this.token,
    required this.screenSize,
    required this.topInset,
    required this.onFinished,
  });

  final int token;
  final Size screenSize;
  final double topInset;
  final void Function(int token) onFinished;

  @override
  State<_FloatingReactionParticle> createState() =>
      _FloatingReactionParticleState();
}

class _FloatingReactionParticleState extends State<_FloatingReactionParticle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final math.Random _random;
  late final double _startX;
  late final double _drift;
  late final double _size;
  late final double _delayFactor;
  late final double _startBottom;
  late final Color _color;
  late final _ReactionShape _shape;
  late final double _tilt;

  @override
  void initState() {
    super.initState();
    _random = math.Random(widget.token * 9973);

    // Spread across ~45% of screen width on the right (not a tight gutter).
    final laneLeft = widget.screenSize.width * 0.48;
    final laneWidth = widget.screenSize.width * 0.46;
    _startX = laneLeft + _random.nextDouble() * laneWidth;

    // Stagger start heights so particles don't launch from one band.
    _startBottom = 160 + _random.nextDouble() * 120;
    // Wider sideways drift so the float looks airy / spread.
    _drift = (_random.nextDouble() - 0.5) * 72;
    _tilt = (_random.nextDouble() - 0.5) * 0.35;

    // Mix: heart / balloon / bubble — token bucket keeps all three in bursts.
    final bucket = widget.token % 3;
    final roll = _random.nextDouble();
    if (bucket == 0) {
      _shape = roll < 0.78 ? _ReactionShape.heart : _ReactionShape.balloon;
    } else if (bucket == 1) {
      _shape = roll < 0.78 ? _ReactionShape.balloon : _ReactionShape.bubble;
    } else {
      _shape = roll < 0.72 ? _ReactionShape.bubble : _ReactionShape.heart;
    }

    switch (_shape) {
      case _ReactionShape.heart:
        _size = 26 + _random.nextDouble() * 16;
      case _ReactionShape.bubble:
        _size = 14 + _random.nextDouble() * 16;
      case _ReactionShape.balloon:
        _size = 30 + _random.nextDouble() * 18;
    }

    _delayFactor = _random.nextDouble() * 0.55;
    final palette = LiveHeartReactionLayer.reactionColors;
    _color = palette[_random.nextInt(palette.length)];

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 4600 + _random.nextInt(1100)),
    );

    Future<void>.delayed(
      Duration(milliseconds: (180 * _delayFactor).round()),
      () {
        if (!mounted) return;
        _controller.forward().whenComplete(() {
          if (mounted) widget.onFinished(widget.token);
        });
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildParticle() {
    switch (_shape) {
      case _ReactionShape.heart:
        return Icon(
          Icons.favorite_rounded,
          size: _size,
          color: _color,
          shadows: [
            Shadow(
              color: _color.withValues(alpha: 0.55),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
            const Shadow(
              color: Color(0x66000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        );
      case _ReactionShape.bubble:
        return Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.35, -0.4),
              radius: 0.95,
              colors: [
                Colors.white.withValues(alpha: 0.6),
                _color.withValues(alpha: 0.5),
                _color.withValues(alpha: 0.18),
              ],
              stops: const [0.0, 0.42, 1.0],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.7),
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: _color.withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 0.4,
              ),
            ],
          ),
        );
      case _ReactionShape.balloon:
        // Body + string; painter matches the glossy pink reference look.
        final w = _size;
        final h = _size * 1.55;
        return SizedBox(
          width: w,
          height: h,
          child: CustomPaint(
            painter: _GlossyBalloonPainter(color: _color),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final travel = math.max(
      0.0,
      widget.screenSize.height - widget.topInset - 140 - _startBottom - _size,
    );
    final particleW = _shape == _ReactionShape.balloon ? _size : _size;
    final particleH =
        _shape == _ReactionShape.balloon ? _size * 1.55 : _size;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_controller.value);
        final fade = (1 -
            Curves.easeIn.transform(
              ((_controller.value - 0.7) / 0.3).clamp(0.0, 1.0),
            ));
        final scale = 0.62 + (math.sin(t * math.pi) * 0.42);
        final sway = math.sin(t * math.pi * 2.2) * 10;
        final spin = _tilt + math.sin(t * math.pi * 1.4) * 0.12;

        return Positioned(
          left: _startX + (_drift * t) + sway - (particleW * scale / 2),
          bottom: _startBottom + (travel * t),
          child: Opacity(
            opacity: fade.clamp(0.0, 1.0),
            child: Transform.rotate(
              angle: spin,
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: particleW,
                  height: particleH,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
      child: _buildParticle(),
    );
  }
}

/// Glossy party balloon: oval body, highlight, knot, and wavy string.
class _GlossyBalloonPainter extends CustomPainter {
  _GlossyBalloonPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final bodyH = size.height * 0.62;
    final bodyW = size.width * 0.92;
    final cx = size.width / 2;
    final cy = bodyH * 0.48;
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: bodyW, height: bodyH),
      Radius.circular(bodyW * 0.5),
    );

    final darker = Color.lerp(color, const Color(0xFF4A0030), 0.28)!;
    final lighter = Color.lerp(color, Colors.white, 0.22)!;

    final fill = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.35),
        radius: 1.05,
        colors: [lighter, color, darker],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(body.outerRect);
    canvas.drawRRect(body, fill);

    // Soft left-edge shade (volume).
    final shade = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.black.withValues(alpha: 0.18),
          Colors.transparent,
        ],
      ).createShader(body.outerRect);
    canvas.save();
    canvas.clipRRect(body);
    canvas.drawRect(body.outerRect, shade);
    canvas.restore();

    // Glossy crescent highlight (reference balloon).
    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.78)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6);
    final hiRect = Rect.fromLTWH(
      cx + bodyW * 0.08,
      cy - bodyH * 0.32,
      bodyW * 0.22,
      bodyH * 0.34,
    );
    canvas.drawOval(hiRect, highlight);

    // Knot / tie.
    final knotY = cy + bodyH * 0.48;
    final knot = Path()
      ..moveTo(cx - 4, knotY)
      ..lineTo(cx, knotY + 7)
      ..lineTo(cx + 4, knotY)
      ..close();
    canvas.drawPath(
      knot,
      Paint()..color = Color.lerp(color, darker, 0.35)!,
    );

    // Wavy string.
    final stringPath = Path()..moveTo(cx, knotY + 6);
    final stringEnd = size.height - 2;
    final mid = (knotY + 6 + stringEnd) / 2;
    stringPath.cubicTo(
      cx + 7,
      mid - 6,
      cx - 8,
      mid + 8,
      cx + 2,
      stringEnd,
    );
    canvas.drawPath(
      stringPath,
      Paint()
        ..color = Color.lerp(color, darker, 0.25)!.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.35
        ..strokeCap = StrokeCap.round,
    );

    // Outer glow.
    canvas.drawRRect(
      body,
      Paint()
        ..color = color.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _GlossyBalloonPainter oldDelegate) =>
      oldDelegate.color != color;
}
