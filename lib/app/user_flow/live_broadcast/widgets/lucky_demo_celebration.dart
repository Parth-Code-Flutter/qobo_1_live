import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Floating presentation only; reward amounts come from confirmed send responses.
class LuckyDemoCelebration extends StatefulWidget {
  const LuckyDemoCelebration({
    super.key,
    required this.reward,
    required this.onComplete,
    this.preview = false,
    this.total = 0,
    this.bonus = 0,
    this.combo = 0,
  });
  final bool preview;
  final bool reward;
  final int total, bonus, combo;
  final VoidCallback onComplete;
  static OverlayEntry? _entry;
  static bool _rewardPlaying = false;
  static int _token = 0;
  static bool get rewardVisible => _rewardPlaying;
  static void show(
    BuildContext context, {
    required bool reward,
    bool preview = false,
    int total = 0,
    int bonus = 0,
    int combo = 0,
  }) {
    if (_rewardPlaying && !reward) return;
    final token = ++_token;
    _dropEntry();
    _rewardPlaying = reward;
    _entry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: LuckyDemoCelebration(
          reward: reward,
          preview: preview,
          total: total,
          bonus: bonus,
          combo: combo,
          onComplete: () => _finish(token),
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }

  /// Ends this celebration only. A newer coin or heart overlay keeps playing.
  static void _finish(int token) {
    if (token != _token) return;
    _rewardPlaying = false;
    _dropEntry();
  }

  static void dismiss() {
    _token++;
    _rewardPlaying = false;
    _dropEntry();
  }

  /// Remove after this frame. Disposing the ticker from its own listener
  /// throws and used to leave [rewardVisible] stuck, which blocked gift flights.
  static void _dropEntry() {
    final entry = _entry;
    _entry = null;
    if (entry == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (entry.mounted) entry.remove();
    });
  }

  @override
  State<LuckyDemoCelebration> createState() => _LuckyDemoCelebrationState();
}

class _LuckyDemoCelebrationState extends State<LuckyDemoCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation =
      AnimationController(
          vsync: this,
          duration: Duration(milliseconds: widget.reward ? 2000 : 2300),
        )
        ..addStatusListener((s) {
          if (s != AnimationStatus.completed) return;
          // Clear the gate now. The overlay itself is removed on the next frame
          // so this ticker is not disposed from inside its own callback.
          widget.onComplete();
        })
        ..forward();
  @override
  void dispose() {
    _animation.stop();
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _animation,
    builder: (_, _) {
      final t = _animation.value;
      final size = MediaQuery.sizeOf(context);
      final fade = ((1 - t) / .15).clamp(0.0, 1.0);
      // easeOutBack overshoots past 1. Opacity rejects that and draws the error.
      final revealRaw = Curves.easeOutBack.transform(
        ((t + .05) / .14).clamp(0.0, 1.0),
      );
      final reveal = revealRaw.clamp(0.0, 1.0);
      final merge = Curves.easeInOutCubic.transform(
        ((t - .16) / .22).clamp(0.0, 1.0),
      );
      return Material(
        type: MaterialType.transparency,
        child: Opacity(
          opacity: fade,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _BurstPainter(t, widget.reward)),
              ),
              // Float over the room: no card, border, modal barrier or dark backdrop.
              for (var i = 0; i < 9; i++)
                Positioned(
                  left:
                      size.width * ((i + .5) / 9) -
                      24 +
                      math.sin(t * 8 + i) * 14,
                  top: size.height * (.55 - t * .8) + (i % 3) * 30,
                  child: Transform.rotate(
                    angle: math.sin(t * 6 + i) * .2,
                    child: widget.reward
                        ? Transform.scale(
                            scaleX: .45 + .55 * math.cos(t * 16 + i).abs(),
                            child: Image.asset(
                              'assets/lucky_demo/coin.png',
                              width: 42,
                            ),
                          )
                        : i.isEven
                        ? Image.asset(
                            'assets/lucky_demo/balloon.png',
                            width: 54,
                          )
                        : const Icon(
                            Icons.favorite_rounded,
                            size: 30,
                            color: Color(0xFFFF73BC),
                            shadows: [
                              Shadow(color: Colors.pinkAccent, blurRadius: 18),
                            ],
                          ),
                  ),
                ),
              if (widget.reward) ...[
                for (var side = -1; side <= 1; side += 2)
                  Positioned(
                    top: size.height * (.24 - .025 * math.sin(merge * math.pi)),
                    left:
                        size.width / 2 +
                        side * size.width * .25 * (1 - merge) -
                        48,
                    child: Opacity(
                      opacity: (1 - merge),
                      child: Image.asset(
                        'assets/lucky_demo/coin.png',
                        width: 88,
                      ),
                    ),
                  ),
                Positioned(
                  top: size.height * .16,
                  left: 20,
                  right: 20,
                  child: Opacity(
                    opacity: reveal,
                    child: Transform.scale(
                      scale: revealRaw.clamp(0.01, 1.12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _glowText('LUCKY COMBO ×${widget.combo}', 16),
                          if (widget.total > 0) ...[
                            const SizedBox(height: 4),
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xFFFFFFDA),
                                      Color(0xFFFFE58B),
                                      Color(0xFFFFA82E),
                                    ],
                                  ).createShader(bounds),
                              child: Text(
                                '${widget.total}',
                                textScaler: TextScaler.noScaling,
                                style: const TextStyle(
                                  fontSize: 72,
                                  height: 1.05,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Color(0xFFFFA62B),
                                      blurRadius: 25,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            _glowText(
                              widget.preview
                                  ? 'Preview: ${widget.total} coins'
                                  : 'You get ${widget.total} coins!',
                              22,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            widget.preview
                                ? 'Preview only • Wallet unchanged'
                                : 'Reward confirmed',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              shadows: [
                                Shadow(color: Colors.black, blurRadius: 8),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Positioned(
                  top: size.height * .20,
                  left: 24,
                  right: 24,
                  child: Transform.scale(
                    scale: Curves.easeOutBack.transform(
                      (t / .2).clamp(0.0, 1.0),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.rotate(
                          angle: math.sin(t * 8) * .12,
                          child: const Icon(
                            Icons.favorite_rounded,
                            size: 108,
                            color: Color(0xFFFF85C0),
                            shadows: [
                              Shadow(color: Color(0xFFFF228E), blurRadius: 38),
                              Shadow(color: Colors.white54, blurRadius: 12),
                            ],
                          ),
                        ),
                        _glowText('A little love, a lot of magic!', 20),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );

  Widget _glowText(String text, double size) => Text(
    text,
    textAlign: TextAlign.center,
    style: TextStyle(
      color: const Color(0xFFFFE9B2),
      fontSize: size,
      fontWeight: FontWeight.w800,
      shadows: const [
        Shadow(color: Color(0xFF52133F), blurRadius: 6, offset: Offset(0, 2)),
        Shadow(color: Color(0xFFFF588D), blurRadius: 18),
      ],
    ),
  );
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.t, this.reward);
  final double t;
  final bool reward;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * .27);
    final burst = Curves.easeOutCubic.transform((t / .55).clamp(0.0, 1.0));
    final paint = Paint();
    const colors = [
      Color(0xFFFFD46B),
      Color(0xFFFF65B9),
      Color(0xFFAF81FF),
      Color(0xFF66E7FF),
    ];
    for (var i = 0; i < 64; i++) {
      final angle = i * 2.399;
      final distance = (45 + (i % 9) * 26) * burst;
      final point =
          center +
          Offset(
            math.cos(angle) * distance,
            math.sin(angle) * distance + t * t * 110,
          );
      paint.color = colors[i % 4].withValues(alpha: (1 - t).clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.rotate(angle + t * 5);
      if (i % 3 == 0) {
        final path = Path()
          ..moveTo(0, -6)
          ..lineTo(2, -2)
          ..lineTo(6, 0)
          ..lineTo(2, 2)
          ..lineTo(0, 6)
          ..lineTo(-2, 2)
          ..lineTo(-6, 0)
          ..lineTo(-2, -2)
          ..close();
        canvas.drawPath(path, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-3, -5, 6, 10),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFFFD46B).withValues(alpha: (1 - burst) * .8);
    canvas.drawCircle(center, 20 + burst * 160, paint);
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) =>
      old.t != t || old.reward != reward;
}
