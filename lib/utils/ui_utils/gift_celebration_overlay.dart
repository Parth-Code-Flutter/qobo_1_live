import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

class GiftCelebrationOverlay {
  GiftCelebrationOverlay._();

  static OverlayEntry? _activeEntry;

  static void show({String? giftName}) {
    final context = Get.overlayContext ?? Get.context;
    if (context == null) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    _activeEntry?.remove();
    _activeEntry = OverlayEntry(
      builder: (_) => _GiftCelebrationView(
        giftName: giftName?.trim().isNotEmpty == true
            ? giftName!.trim()
            : 'Gift',
        onCompleted: () {
          _activeEntry?.remove();
          _activeEntry = null;
        },
      ),
    );
    overlay.insert(_activeEntry!);
  }
}

class _GiftCelebrationView extends StatefulWidget {
  const _GiftCelebrationView({
    required this.giftName,
    required this.onCompleted,
  });

  final String giftName;
  final VoidCallback onCompleted;

  @override
  State<_GiftCelebrationView> createState() => _GiftCelebrationViewState();
}

class _GiftCelebrationViewState extends State<_GiftCelebrationView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _removeTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    )..forward();
    _removeTimer = Timer(
      const Duration(milliseconds: 2600),
      widget.onCompleted,
    );
  }

  @override
  void dispose() {
    _removeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 18;
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final value = Curves.easeOutCubic.transform(_controller.value);
            final fade = _controller.value < 0.78
                ? 1.0
                : (1 - ((_controller.value - 0.78) / 0.22)).clamp(0.0, 1.0);
            return Opacity(
              opacity: fade,
              child: Stack(
                children: [
                  CustomPaint(
                    painter: _GiftBurstPainter(progress: value),
                    size: Size.infinite,
                  ),
                  Positioned(
                    top: top - (10 * value),
                    left: 18,
                    right: 18,
                    child: Transform.scale(
                      scale: 0.86 + (0.14 * value),
                      child: const _GiftCelebrationCard(),
                    ),
                  ),
                  Positioned(
                    top: top + 64,
                    left: 28,
                    right: 28,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.48),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: kColorWhite.withValues(alpha: 0.12),
                          ),
                        ),
                        child: AppText(
                          text: '${widget.giftName} sent successfully',
                          fontSize: TextStyles.k12FontSize,
                          color: kColorWhite,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          align: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GiftCelebrationCard extends StatelessWidget {
  const _GiftCelebrationCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFD84D), Color(0xFFFF3F7F), Color(0xFF7D5BFF)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF3F7F).withValues(alpha: 0.34),
              blurRadius: 34,
              spreadRadius: 8,
            ),
          ],
        ),
        child: const Icon(
          Icons.card_giftcard_rounded,
          color: kColorWhite,
          size: 42,
        ),
      ),
    );
  }
}

class _GiftBurstPainter extends CustomPainter {
  _GiftBurstPainter({required this.progress});

  final double progress;

  static const _colors = [
    Color(0xFFFFD84D),
    Color(0xFFFF3F7F),
    Color(0xFF7D5BFF),
    Color(0xFF24C08A),
    Color(0xFFFFFFFF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final center = Offset(size.width / 2, size.height * 0.17);
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < 28; i++) {
      final angle = (math.pi * 2 / 28) * i;
      final distance = (36 + (i % 5) * 12) * progress;
      final wave = math.sin((progress * math.pi) + i);
      final point =
          center +
          Offset(
            math.cos(angle) * distance,
            math.sin(angle) * distance + (wave * 8),
          );
      final radius = (3.0 + (i % 3)) * (1 - (progress * 0.35));
      paint.color = _colors[i % _colors.length].withValues(alpha: 0.9);
      canvas.drawCircle(point, radius.clamp(1.8, 5.2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GiftBurstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
