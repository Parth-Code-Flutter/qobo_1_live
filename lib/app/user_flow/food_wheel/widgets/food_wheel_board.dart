import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/food_wheel_controller.dart';
import '../models/food_wheel_item.dart';

/// Carnival wheel. Lights, spokes, and food bubbles are drawn in code.
class FoodWheelBoard extends StatefulWidget {
  const FoodWheelBoard({super.key, required this.controller});

  final FoodWheelController controller;

  @override
  State<FoodWheelBoard> createState() => _FoodWheelBoardState();
}

class _FoodWheelBoardState extends State<FoodWheelBoard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final phase = widget.controller.phase.value;
      final highlight = widget.controller.highlightIndex.value;
      final winner = widget.controller.winnerIndex.value;
      final seconds = widget.controller.secondsLeft.value;
      final bets = <int, int>{
        for (final entry in widget.controller.bets.entries) entry.key: entry.value,
      };

      return AnimatedBuilder(
        animation: _clock,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final side = math.min(constraints.maxWidth, constraints.maxHeight);
              final hub = side * 0.32;
              final orbit = side * 0.33;
              final bubble = side * 0.20;

              return Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: side,
                  height: side,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      CustomPaint(
                        size: Size(side, side),
                        painter: _WheelStandPainter(
                          orbit: orbit,
                          hub: hub,
                          clock: _clock.value,
                          spinning: phase == FoodWheelPhase.revealing,
                        ),
                      ),
                      _Hub(
                        size: hub,
                        phase: phase,
                        secondsLeft: seconds,
                        clock: _clock.value,
                        shown: _shownItem(phase, highlight, winner),
                      ),
                      for (var i = 0; i < kFoodWheelItems.length; i++)
                        _placedBubble(
                          index: i,
                          orbit: orbit,
                          bubble: bubble,
                          item: kFoodWheelItems[i],
                          stake: bets[i] ?? 0,
                          highlighted: highlight == i,
                          isWinner:
                              winner == i && phase == FoodWheelPhase.result,
                          clock: _clock.value,
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    });
  }

  FoodWheelItem? _shownItem(
    FoodWheelPhase phase,
    int highlight,
    int? winner,
  ) {
    if (phase == FoodWheelPhase.result && winner != null) {
      return kFoodWheelItems[winner];
    }
    if (phase == FoodWheelPhase.revealing &&
        highlight >= 0 &&
        highlight < kFoodWheelItems.length) {
      return kFoodWheelItems[highlight];
    }
    return null;
  }

  Widget _placedBubble({
    required int index,
    required double orbit,
    required double bubble,
    required FoodWheelItem item,
    required int stake,
    required bool highlighted,
    required bool isWinner,
    required double clock,
  }) {
    final angle = -math.pi / 2 + index * (math.pi / 4);
    return Transform.translate(
      offset: Offset(math.cos(angle) * orbit, math.sin(angle) * orbit),
      child: _FoodBubble(
        item: item,
        size: bubble,
        stake: stake,
        highlighted: highlighted,
        isWinner: isWinner,
        clock: clock,
        showHot: item.multiplier >= 45,
        onTap: () => widget.controller.placeBet(index),
      ),
    );
  }
}

class _Hub extends StatelessWidget {
  const _Hub({
    required this.size,
    required this.phase,
    required this.secondsLeft,
    required this.clock,
    required this.shown,
  });

  final double size;
  final FoodWheelPhase phase;
  final int secondsLeft;
  final double clock;
  final FoodWheelItem? shown;

  @override
  Widget build(BuildContext context) {
    final pulse = phase == FoodWheelPhase.counting
        ? 1 + 0.06 * math.sin(clock * math.pi * 2)
        : 1 + 0.025 * math.sin(clock * math.pi * 2);

    final String title;
    final String subtitle;
    switch (phase) {
      case FoodWheelPhase.betting:
        title = 'PICK';
        subtitle = 'Tap a food';
      case FoodWheelPhase.counting:
        title = '$secondsLeft';
        subtitle = 'Bets closing';
      case FoodWheelPhase.revealing:
        title = shown?.emoji ?? '...';
        subtitle = 'Spinning';
      case FoodWheelPhase.result:
        title = shown?.emoji ?? 'Done';
        subtitle = 'Winner';
    }

    return Transform.scale(
      scale: pulse,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0xFFFF7A9A), Color(0xFFE2184E), Color(0xFFB0103A)],
            stops: [0.15, 0.7, 1],
          ),
          border: Border.all(color: const Color(0xFFFFE082), width: 4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66E2184E),
              blurRadius: 22,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Text(
                title,
                key: ValueKey(title),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: phase == FoodWheelPhase.counting ? 36 : 22,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFFFFF3C4),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodBubble extends StatefulWidget {
  const _FoodBubble({
    required this.item,
    required this.size,
    required this.stake,
    required this.highlighted,
    required this.isWinner,
    required this.clock,
    required this.showHot,
    required this.onTap,
  });

  final FoodWheelItem item;
  final double size;
  final int stake;
  final bool highlighted;
  final bool isWinner;
  final double clock;
  final bool showHot;
  final VoidCallback onTap;

  @override
  State<_FoodBubble> createState() => _FoodBubbleState();
}

class _FoodBubbleState extends State<_FoodBubble>
    with TickerProviderStateMixin {
  late final AnimationController _pop;
  late final AnimationController _plus;
  int _plusAmount = 0;

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _plus = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
  }

  @override
  void didUpdateWidget(covariant _FoodBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stake > oldWidget.stake) {
      _plusAmount = widget.stake - oldWidget.stake;
      _pop.forward(from: 0);
      _plus.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    _plus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ring = widget.isWinner
        ? const Color(0xFFFFE082)
        : widget.highlighted
        ? Colors.white
        : widget.item.color;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pop, _plus]),
        builder: (context, _) {
          final pop = math.sin(_pop.value * math.pi) * 0.16;
          final idle = widget.isWinner
              ? 0.08 * math.sin(widget.clock * math.pi * 2)
              : widget.highlighted
              ? 0.05
              : 0.0;
          return Transform.scale(
            scale: 1 + pop + idle,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: widget.size,
                    height: widget.size,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: ring,
                        width: widget.highlighted ? 4 : 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.isWinner
                                  ? const Color(0xFFFFE082)
                                  : widget.item.color)
                              .withValues(alpha: widget.highlighted ? 0.55 : 0.28),
                          blurRadius: widget.isWinner ? 16 : 8,
                          spreadRadius: widget.isWinner ? 2 : 0,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.item.emoji,
                          style: TextStyle(fontSize: widget.size * 0.34),
                        ),
                        Text(
                          'x${widget.item.multiplier}',
                          style: TextStyle(
                            fontSize: widget.size * 0.14,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF5C3B16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.showHot)
                    const Positioned(top: -6, child: _HotTag()),
                  if (widget.stake > 0)
                    Positioned(
                      bottom: -10,
                      child: _StakeCoin(
                        stake: widget.stake,
                        payout: widget.stake * widget.item.multiplier,
                      ),
                    ),
                  Positioned(
                    top: -14,
                    child: Opacity(
                      opacity: (1 - _plus.value).clamp(0, 1),
                      child: Transform.translate(
                        offset: Offset(0, -16 * _plus.value),
                        child: _plusAmount == 0
                            ? const SizedBox.shrink()
                            : Text(
                                '+$_plusAmount',
                                style: const TextStyle(
                                  color: Color(0xFFB86E00),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HotTag extends StatelessWidget {
  const _HotTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFE2184E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: const Text(
        'HOT',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _StakeCoin extends StatelessWidget {
  const _StakeCoin({required this.stake, required this.payout});

  final int stake;
  final int payout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC107),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB86E00)),
      ),
      child: Text(
        '$stake → $payout',
        style: const TextStyle(
          color: Color(0xFF5C3B16),
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _WheelStandPainter extends CustomPainter {
  const _WheelStandPainter({
    required this.orbit,
    required this.hub,
    required this.clock,
    required this.spinning,
  });

  final double orbit;
  final double hub;
  final double clock;
  final bool spinning;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(
      center,
      orbit + 6,
      Paint()..color = const Color(0xFFFFE29A),
    );
    canvas.drawCircle(
      center,
      orbit + 6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = const Color(0xFFF0B429),
    );

    final spoke = Paint()
      ..color = const Color(0xFF7EC8E3)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final spokeStart = hub / 2 + 16;
    for (var i = 0; i < 8; i++) {
      final angle = -math.pi / 2 + i * (math.pi / 4);
      final dir = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + dir * spokeStart,
        center + dir * (orbit - 4),
        spoke,
      );
    }

    final bulbRadius = hub / 2 + 14;
    const bulbs = 16;
    final shift = spinning ? clock * bulbs : clock * 2;
    for (var i = 0; i < bulbs; i++) {
      final angle = -math.pi / 2 + (i / bulbs) * math.pi * 2;
      final on = ((i + shift.floor()) % 2 == 0);
      final color = on ? const Color(0xFFFFF8DC) : const Color(0xFFFFC107);
      final point =
          center + Offset(math.cos(angle) * bulbRadius, math.sin(angle) * bulbRadius);
      canvas.drawCircle(
        point,
        on ? 4.2 : 3.2,
        Paint()..color = color.withValues(alpha: on ? 1 : 0.75),
      );
    }

    const rimBulbs = 24;
    final rimShift = spinning ? clock * rimBulbs : clock * 4;
    for (var i = 0; i < rimBulbs; i++) {
      final angle = (i / rimBulbs) * math.pi * 2;
      final on = ((i + rimShift.floor()) % 3 != 0);
      final point =
          center + Offset(math.cos(angle) * (orbit + 6), math.sin(angle) * (orbit + 6));
      canvas.drawCircle(
        point,
        on ? 3.4 : 2.4,
        Paint()
          ..color = on ? const Color(0xFFFFF8E1) : const Color(0xFFE6910A),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WheelStandPainter oldDelegate) =>
      oldDelegate.clock != clock || oldDelegate.spinning != spinning;
}
