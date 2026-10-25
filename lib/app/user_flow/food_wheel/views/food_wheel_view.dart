import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';

import '../controllers/food_wheel_controller.dart';
import '../models/food_wheel_item.dart';
import '../widgets/food_wheel_board.dart';
import '../widgets/food_wheel_help_sheet.dart';

/// Client preview of the food wheel. Play coins stay on this phone.
class FoodWheelView extends GetView<FoodWheelController> {
  const FoodWheelView({super.key});

  static const _bg = Color(0xFFFFF1B8);
  static const _ink = Color(0xFF5C3B16);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: CommonAppBarWidget(
        title: 'Food Wheel',
        subtitle: 'Client demo · play coins only',
        trailingIcon: Icons.help_outline_rounded,
        onTrailingTap: FoodWheelHelpSheet.show,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: _DotBackground()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Column(
                children: [
                  _statusRow(),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        FoodWheelBoard(controller: controller),
                        _resultSplash(),
                      ],
                    ),
                  ),
                  _hint(),
                  const SizedBox(height: 8),
                  _chips(),
                  const SizedBox(height: 10),
                  _actionButton(),
                  const SizedBox(height: 10),
                  _balances(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusRow() {
    return Obx(
      () => Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFD54F)),
            ),
            child: Text(
              'Round ${controller.round.value}',
              style: const TextStyle(
                color: _ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: controller.refillCoins,
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFFFE082),
              foregroundColor: _ink,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Refill 5000',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hint() {
    return Obx(() {
      if (controller.phase.value == FoodWheelPhase.result) {
        return const SizedBox(height: 18);
      }
      final stake = controller.totalStake;
      final chip = controller.selectedChip.value;
      return Text(
        stake == 0
            ? 'Each tap spends $chip. You can back more than one food.'
            : 'Spent $stake. The gold label shows what that food pays if it wins.',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _ink,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      );
    });
  }

  Widget _resultSplash() {
    return Obx(() {
      if (controller.phase.value != FoodWheelPhase.result) {
        return const SizedBox.shrink();
      }
      final winner = controller.winnerIndex.value;
      if (winner == null) return const SizedBox.shrink();
      final item = kFoodWheelItems[winner];
      final payout = controller.lastPayout.value;
      return _ResultSplash(
        key: ValueKey('result-${controller.round.value}'),
        item: item,
        payout: payout,
      );
    });
  }

  Widget _chips() {
    return Obx(() {
      final selected = controller.selectedChip.value;
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final chip in FoodWheelController.chips)
            _CoinChip(
              amount: chip,
              selected: selected == chip,
              emphasized: chip == 1000,
              onTap: () => controller.selectChip(chip),
            ),
        ],
      );
    });
  }

  Widget _actionButton() {
    return Obx(() {
      final phase = controller.phase.value;
      final waiting =
          phase == FoodWheelPhase.counting ||
          phase == FoodWheelPhase.revealing;
      final onResult = phase == FoodWheelPhase.result;
      return _ShinyBar(
        label: onResult
            ? 'Next round'
            : waiting
            ? 'Round in progress'
            : 'Start round',
        onPressed: waiting
            ? null
            : onResult
            ? controller.nextRound
            : controller.startRound,
      );
    });
  }

  Widget _balances() {
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF9A2458), Color(0xFF5C1238)],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x335C1238),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _balanceLine('Play coins', '${controller.coins.value}'),
            ),
            Container(width: 1, height: 28, color: Colors.white24),
            Expanded(
              child: _balanceLine(
                'This demo',
                '${controller.profit.value >= 0 ? '+' : ''}${controller.profit.value}',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceLine(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFFFFE082), fontSize: 11),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _CoinChip extends StatelessWidget {
  const _CoinChip({
    required this.amount,
    required this.selected,
    required this.emphasized,
    required this.onTap,
  });

  final int amount;
  final bool selected;
  final bool emphasized;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final face = emphasized
        ? const [Color(0xFFFF8A80), Color(0xFFE2184E)]
        : const [Color(0xFFFFF3B0), Color(0xFFFFC107), Color(0xFFE6910A)];

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.12 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: face,
              stops: emphasized ? const [0.2, 1] : const [0.15, 0.62, 1],
            ),
            border: Border.all(
              color: selected ? Colors.white : const Color(0xFFB86E00),
              width: selected ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (emphasized
                        ? const Color(0xFFE2184E)
                        : const Color(0xFFE6910A))
                    .withValues(alpha: selected ? 0.45 : 0.25),
                blurRadius: selected ? 12 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            '$amount',
            style: TextStyle(
              color: emphasized ? Colors.white : const Color(0xFF5C3B16),
              fontWeight: FontWeight.w900,
              fontSize: amount > 99 ? 14 : 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShinyBar extends StatefulWidget {
  const _ShinyBar({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  State<_ShinyBar> createState() => _ShinyBarState();
}

class _ShinyBarState extends State<_ShinyBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shine;

  @override
  void initState() {
    super.initState();
    _shine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return GestureDetector(
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _shine,
        builder: (context, _) {
          final slide = -1.4 + _shine.value * 2.8;
          return Opacity(
            opacity: enabled ? 1 : 0.55,
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment(slide, 0),
                  end: Alignment(slide + 0.8, 0),
                  colors: const [
                    Color(0xFFFFB300),
                    Color(0xFFFFF6C8),
                    Color(0xFFFFC107),
                  ],
                ),
                border: Border.all(color: const Color(0xFFB86E00)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x44E6910A),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                widget.label,
                style: const TextStyle(
                  color: Color(0xFF5C3B16),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ResultSplash extends StatelessWidget {
  const _ResultSplash({super.key, required this.item, required this.payout});

  final FoodWheelItem item;
  final int payout;

  @override
  Widget build(BuildContext context) {
    final won = payout > 0;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutBack,
      builder: (context, t, child) {
        final fade = t.clamp(0.0, 1.0);
        return Opacity(
          opacity: fade,
          child: Transform.scale(
            scale: 0.7 + 0.3 * fade,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (won)
                  for (var i = 0; i < 8; i++)
                    _burstCoin(i, fade),
                if (child != null) child,
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: won ? const Color(0xFFFFE082) : const Color(0xFFFF8A80),
            width: 3,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              won ? 'YOU WIN' : 'NO WIN',
              style: TextStyle(
                color: won ? const Color(0xFFE2184E) : const Color(0xFF8A4B3A),
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${item.emoji}  ${item.name}  x${item.multiplier}',
              style: const TextStyle(
                color: Color(0xFF5C3B16),
                fontWeight: FontWeight.w800,
              ),
            ),
            if (won)
              Text(
                '+$payout play coins',
                style: const TextStyle(
                  color: Color(0xFF1B8A5A),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _burstCoin(int index, double t) {
    final angle = -math.pi / 2 + index * (math.pi / 4);
    final distance = 78 * t;
    return Transform.translate(
      offset: Offset(math.cos(angle) * distance, math.sin(angle) * distance),
      child: Opacity(
        opacity: (1 - t).clamp(0.0, 1.0),
        child: const Text('🪙', style: TextStyle(fontSize: 16)),
      ),
    );
  }
}

class _DotBackground extends StatelessWidget {
  const _DotBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DotPainter());
  }
}

class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x33E2B100);
    const gap = 22.0;
    for (var y = 8.0; y < size.height; y += gap) {
      for (var x = 8.0; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 1.6, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
