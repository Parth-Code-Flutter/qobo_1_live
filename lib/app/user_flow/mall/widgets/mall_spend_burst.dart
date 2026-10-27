import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/utils/app_widgets/app_coin_icon.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Floating spend on the mall screen, anchored over the balance bar.
class MallSpendBurst extends StatefulWidget {
  const MallSpendBurst({super.key, required this.price, required this.onDone});

  final int price;
  final VoidCallback onDone;

  @override
  State<MallSpendBurst> createState() => _MallSpendBurstState();
}

class _MallSpendBurstState extends State<MallSpendBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flight;

  @override
  void initState() {
    super.initState();
    _flight = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _flight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _flight,
        builder: (context, child) {
          final t = _flight.value;
          final rise = Curves.easeOutCubic.transform(t);
          final fade = t < 0.62 ? 1.0 : (1 - ((t - 0.62) / 0.38)).clamp(0.0, 1.0);
          return Opacity(
            opacity: fade,
            child: Transform.translate(
              offset: Offset(0, -18 * rise),
              child: child,
            ),
          );
        },
        child: SizedBox(
          height: 86,
          width: 210,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < 4; i++) _spark(i),
              Align(alignment: Alignment.bottomLeft, child: _chip()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _spark(int index) {
    return AnimatedBuilder(
      animation: _flight,
      builder: (context, child) {
        final phase = (_flight.value + index * 0.18) % 1;
        final rise = math.sin(phase * math.pi);
        return Positioned(
          left: 36.0 + (index * 28),
          bottom: 18 + (rise * 48),
          child: Opacity(
            opacity: rise.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Icon(
        index.isEven ? Icons.favorite_rounded : Icons.diamond_rounded,
        size: 13,
        color: index.isEven ? AppLightUi.pink : const Color(0xFFE8A317),
      ),
    );
  }

  Widget _chip() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppLightUi.gold.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: AppLightUi.gold.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppCoinIcon(size: 22, color: AppLightUi.gold),
          Spacing.h6,
          SemiBoldText(
            text: '-${widget.price}',
            fontSize: TextStyles.k18FontSize,
            color: const Color(0xFF9A5B00),
          ),
        ],
      ),
    );
  }
}
