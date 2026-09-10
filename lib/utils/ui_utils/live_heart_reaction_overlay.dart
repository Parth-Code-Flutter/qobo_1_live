import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/user_flow/live_broadcast/controllers/live_broadcast_controller.dart';

/// Colorful floating hearts for live streaming reactions.
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
              _FloatingHeartBubble(
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

class _FloatingHeartBubble extends StatefulWidget {
  const _FloatingHeartBubble({
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
    _startX = widget.screenSize.width - 32 - _random.nextDouble() * 18;
    _startBottom = 120 + _random.nextDouble() * 28;
    _drift = (_random.nextDouble() - 0.5) * 24;
    _size = 22 + _random.nextDouble() * 16;
    _delayFactor = _random.nextDouble() * 0.35;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 4300 + _random.nextInt(900)),
    );

    Future<void>.delayed(
      Duration(milliseconds: (120 * _delayFactor).round()),
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

  @override
  Widget build(BuildContext context) {
    final travel = math.max(
      0.0,
      widget.screenSize.height - widget.topInset - 180 - _startBottom - _size,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_controller.value);
        final fade =
            (1 -
            Curves.easeIn.transform(
              ((_controller.value - 0.72) / 0.28).clamp(0.0, 1.0),
            ));
        final scale = 0.55 + (math.sin(t * math.pi) * 0.45);

        return Positioned(
          left: _startX + (_drift * t) - (_size * scale / 2),
          bottom: _startBottom + (travel * t),
          child: Opacity(
            opacity: fade.clamp(0.0, 1.0),
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: Icon(
        Icons.favorite_rounded,
        size: _size,
        color:
            LiveHeartReactionLayer.reactionColors[widget.token %
                LiveHeartReactionLayer.reactionColors.length],
        shadows: const [
          Shadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
    );
  }
}
