import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/user_flow/live_broadcast/controllers/live_broadcast_controller.dart';

/// WhatsApp-status-style floating hearts for live streaming reactions.
class LiveHeartReactionLayer extends StatelessWidget {
  const LiveHeartReactionLayer({super.key});

  static const Color whatsAppHeartGreen = Color(0xFF25D366);

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
              _FloatingHeartBubble(
                key: ValueKey(token),
                token: token,
                screenSize: size,
                onFinished: controller.removeHeartReactionToken,
              ),
          ],
        ),
      );
    });
  }
}

class _FloatingHeartBubble extends StatefulWidget {
  const _FloatingHeartBubble({
    super.key,
    required this.token,
    required this.screenSize,
    required this.onFinished,
  });

  final int token;
  final Size screenSize;
  final void Function(int token) onFinished;

  @override
  State<_FloatingHeartBubble> createState() => _FloatingHeartBubbleState();
}

class _FloatingHeartBubbleState extends State<_FloatingHeartBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final math.Random _random;
  late final double _startX;
  late final double _drift;
  late final double _size;
  late final double _delayFactor;
  late final double _startBottom;

  @override
  void initState() {
    super.initState();
    _random = math.Random(widget.token);
    _startX = widget.screenSize.width * (0.72 + _random.nextDouble() * 0.18);
    _startBottom = 96 + _random.nextDouble() * 28;
    _drift = (_random.nextDouble() - 0.5) * 72;
    _size = 22 + _random.nextDouble() * 16;
    _delayFactor = _random.nextDouble() * 0.18;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2200 + _random.nextInt(600)),
    );

    Future<void>.delayed(Duration(milliseconds: (120 * _delayFactor).round()), () {
      if (!mounted) return;
      _controller.forward().whenComplete(() {
        if (mounted) widget.onFinished(widget.token);
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final travel = widget.screenSize.height * 0.42;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_controller.value);
        final fade = (1 - Curves.easeIn.transform(
          ((_controller.value - 0.55) / 0.45).clamp(0.0, 1.0),
        ));
        final scale = 0.55 + (math.sin(t * math.pi) * 0.45);

        return Positioned(
          left: _startX + (_drift * t) - (_size * scale / 2),
          bottom: _startBottom + (travel * t),
          child: Opacity(
            opacity: fade.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
        );
      },
      child: Icon(
        Icons.favorite_rounded,
        size: _size,
        color: LiveHeartReactionLayer.whatsAppHeartGreen,
        shadows: const [
          Shadow(
            color: Color(0x66000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
