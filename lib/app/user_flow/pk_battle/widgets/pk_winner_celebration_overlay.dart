import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/models/v1/pk_v1_models.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Full-screen PK winner celebration — colorful particle blast + glass card.
///
/// Auto-dismisses after [displayDuration].
class PkWinnerCelebrationOverlay {
  PkWinnerCelebrationOverlay._();

  static const displayDuration = Duration(seconds: 5);

  static BuildContext? _dialogContext;
  static Timer? _dismissTimer;
  static bool _showing = false;

  static bool get isShowing => _showing;

  static void show({
    required PkResult result,
    PkSession? session,
    required VoidCallback onFinished,
  }) {
    dismiss();
    _showing = true;

    final winnerSide = result.winnerSide;
    final winnerInfo = _winnerInfo(result: result, session: session);
    final title = winnerSide == PkBattleSide.tie
        ? "IT'S A TIE!"
        : winnerSide == PkBattleSide.none
            ? 'PK ENDED'
            : 'VICTORY';
    final subtitle = winnerSide == PkBattleSide.tie
        ? '${result.scoreA} — ${result.scoreB}'
        : '${winnerInfo.name} · ${winnerSide == PkBattleSide.a ? result.scoreA : result.scoreB} pts';

    void finish() {
      _dismissTimer?.cancel();
      _dismissTimer = null;
      if (_dialogContext != null &&
          _dialogContext!.mounted &&
          Navigator.of(_dialogContext!).canPop()) {
        Navigator.of(_dialogContext!).pop();
      }
      _dialogContext = null;
      _showing = false;
      onFinished();
    }

    _dismissTimer = Timer(displayDuration, finish);

    BuildContext? navigatorContext;
    try {
      navigatorContext = Get.context ?? Get.key.currentContext;
    } catch (_) {
      navigatorContext = null;
    }
    if (navigatorContext == null) {
      _showing = false;
      onFinished();
      return;
    }

    Get.dialog<void>(
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      useSafeArea: false,
      Builder(
        builder: (dialogContext) {
          _dialogContext = dialogContext;
          return _PkWinnerCelebrationView(
            title: title,
            subtitle: subtitle,
            winnerName: winnerInfo.name,
            winnerAvatar: winnerInfo.avatarUrl,
            scoreA: result.scoreA,
            scoreB: result.scoreB,
            winnerSide: winnerSide,
            onCompleted: finish,
          );
        },
      ),
    );
  }

  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (_dialogContext != null &&
        _dialogContext!.mounted &&
        Navigator.of(_dialogContext!).canPop()) {
      Navigator.of(_dialogContext!).pop();
    }
    _dialogContext = null;
    _showing = false;
  }

  static ({String name, String avatarUrl}) _winnerInfo({
    required PkResult result,
    PkSession? session,
  }) {
    if (session == null) {
      return (name: 'Champion', avatarUrl: '');
    }
    switch (result.winnerSide) {
      case PkBattleSide.a:
        return (
          name: session.sideA.displayName.isEmpty
              ? 'Side A'
              : session.sideA.displayName,
          avatarUrl: session.sideA.avatarUrl,
        );
      case PkBattleSide.b:
        return (
          name: session.sideB.displayName.isEmpty
              ? 'Side B'
              : session.sideB.displayName,
          avatarUrl: session.sideB.avatarUrl,
        );
      default:
        return (name: 'Great battle', avatarUrl: '');
    }
  }
}

class _PkWinnerCelebrationView extends StatefulWidget {
  const _PkWinnerCelebrationView({
    required this.title,
    required this.subtitle,
    required this.winnerName,
    required this.winnerAvatar,
    required this.scoreA,
    required this.scoreB,
    required this.winnerSide,
    required this.onCompleted,
  });

  final String title;
  final String subtitle;
  final String winnerName;
  final String winnerAvatar;
  final int scoreA;
  final int scoreB;
  final PkBattleSide winnerSide;
  final VoidCallback onCompleted;

  @override
  State<_PkWinnerCelebrationView> createState() =>
      _PkWinnerCelebrationViewState();
}

class _PkWinnerCelebrationViewState extends State<_PkWinnerCelebrationView>
    with TickerProviderStateMixin {
  static const _pink = Color(0xFFFF2D87);
  static const _hotPink = Color(0xFFFF5AC8);
  static const _blue = Color(0xFF2F6BFF);
  static const _cyan = Color(0xFF00E5FF);
  static const _gold = Color(0xFFFFC857);
  static const _orange = Color(0xFFFF8A3D);
  static const _lime = Color(0xFFB8FF4A);
  static const _violet = Color(0xFFB44DFF);
  static const _magenta = Color(0xFFFF3DCE);

  static const _partyColors = <Color>[
    _gold,
    _pink,
    _hotPink,
    _blue,
    _cyan,
    _violet,
    _orange,
    _lime,
    _magenta,
    Colors.white,
  ];

  late final AnimationController _burst;
  late final AnimationController _pulse;
  late final AnimationController _cardIn;
  late final AnimationController _shimmer;
  late final AnimationController _rain;
  late final List<_BurstParticle> _particles;
  late final List<_RainSpark> _sparks;
  final _rng = math.Random(17);

  @override
  void initState() {
    super.initState();
    _particles = List.generate(110, (_) => _BurstParticle.random(_rng));
    _sparks = List.generate(48, (_) => _RainSpark.random(_rng));
    _burst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..forward();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _cardIn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..forward();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _rain = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _burst.dispose();
    _pulse.dispose();
    _cardIn.dispose();
    _shimmer.dispose();
    _rain.dispose();
    super.dispose();
  }

  Color get _accent {
    switch (widget.winnerSide) {
      case PkBattleSide.a:
        return _pink;
      case PkBattleSide.b:
        return _blue;
      default:
        return _gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final cardScale = CurvedAnimation(
      parent: _cardIn,
      curve: Curves.easeOutBack,
    );
    final cardFade = CurvedAnimation(
      parent: _cardIn,
      curve: Curves.easeOut,
    );

    return Material(
      color: Colors.transparent,
      child: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Deep colorful base.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2A0A3D).withValues(alpha: 0.94),
                      const Color(0xFF0A1028).withValues(alpha: 0.96),
                      const Color(0xFF1A0530).withValues(alpha: 0.95),
                    ],
                  ),
                ),
              ),
            ),
            // Team-colored side washes.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      _pink.withValues(alpha: 0.42),
                      Colors.transparent,
                      _blue.withValues(alpha: 0.42),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            // Animated multi-orb aurora.
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([_pulse, _shimmer]),
                builder: (_, __) {
                  final t = _pulse.value;
                  final s = _shimmer.value;
                  return Stack(
                    children: [
                      Positioned(
                        left: -40 + s * 30,
                        top: size.height * 0.12,
                        child: _orb(_pink, 190 + t * 24, 0.38),
                      ),
                      Positioned(
                        right: -50 + (1 - s) * 28,
                        top: size.height * 0.18,
                        child: _orb(_cyan, 170 + t * 20, 0.34),
                      ),
                      Positioned(
                        left: size.width * 0.22,
                        bottom: size.height * 0.08,
                        child: _orb(_violet, 200 + t * 18, 0.30),
                      ),
                      Positioned(
                        right: size.width * 0.18,
                        bottom: size.height * 0.12,
                        child: _orb(_orange, 150 + t * 16, 0.28),
                      ),
                      Positioned(
                        left: size.width * 0.35,
                        top: size.height * 0.28 + t * 10,
                        child: _orb(_gold, 130, 0.26),
                      ),
                    ],
                  );
                },
              ),
            ),
            // Center accent bloom.
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) {
                  final t = _pulse.value;
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0, -0.12 + t * 0.04),
                        radius: 0.62 + t * 0.10,
                        colors: [
                          _accent.withValues(alpha: 0.34 + t * 0.10),
                          _gold.withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Burst fireworks.
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _burst,
                builder: (_, __) {
                  return CustomPaint(
                    painter: _BurstPainter(
                      particles: _particles,
                      progress: Curves.easeOutCubic.transform(_burst.value),
                      colors: _partyColors,
                    ),
                  );
                },
              ),
            ),
            // Continuous colorful spark rain.
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _rain,
                builder: (_, __) {
                  return CustomPaint(
                    painter: _RainPainter(
                      sparks: _sparks,
                      progress: _rain.value,
                      colors: _partyColors,
                    ),
                  );
                },
              ),
            ),
            FadeTransition(
              opacity: cardFade,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.72, end: 1.0).animate(cardScale),
                child: _buildHeroCard(size),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orb(Color color, double size, double alpha) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(Size size) {
    final showWinner = widget.winnerSide != PkBattleSide.tie &&
        widget.winnerSide != PkBattleSide.none;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        width: math.min(size.width - 56, 340),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _gold,
              _pink,
              _violet,
              _cyan,
              _blue,
              _orange,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: _pink.withValues(alpha: 0.45),
              blurRadius: 28,
              spreadRadius: 1,
              offset: const Offset(-6, 8),
            ),
            BoxShadow(
              color: _cyan.withValues(alpha: 0.40),
              blurRadius: 28,
              spreadRadius: 1,
              offset: const Offset(6, 8),
            ),
            BoxShadow(
              color: _gold.withValues(alpha: 0.35),
              blurRadius: 40,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        padding: const EdgeInsets.all(2.4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2A1248).withValues(alpha: 0.82),
                    const Color(0xFF121B3A).withValues(alpha: 0.78),
                    const Color(0xFF1E0A36).withValues(alpha: 0.84),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.94, end: 1.08).animate(
                      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const SweepGradient(
                          colors: [
                            _gold,
                            _orange,
                            _pink,
                            _violet,
                            _cyan,
                            _blue,
                            _gold,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _gold.withValues(alpha: 0.65),
                            blurRadius: 26,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: _pink.withValues(alpha: 0.40),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF140A28),
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedBuilder(
                    animation: _shimmer,
                    builder: (_, __) {
                      return ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) {
                          final slide = _shimmer.value * 2 - 0.5;
                          return LinearGradient(
                            begin: Alignment(-1.2 + slide, 0),
                            end: Alignment(1.2 + slide, 0),
                            colors: const [
                              _gold,
                              _orange,
                              Colors.white,
                              _pink,
                              _violet,
                              _cyan,
                              _gold,
                            ],
                          ).createShader(bounds);
                        },
                        child: BoldText(
                          text: widget.title,
                          fontSize: 32,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  if (showWinner) ...[
                    Container(
                      padding: const EdgeInsets.all(3.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const SweepGradient(
                          colors: [
                            _gold,
                            _pink,
                            _violet,
                            _cyan,
                            _blue,
                            _orange,
                            _gold,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _accent.withValues(alpha: 0.55),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF12081F),
                        ),
                        child: AppUserAvatar(
                          name: widget.winnerName,
                          imageUrl: widget.winnerAvatar,
                          size: 76,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SemiBoldText(
                    text: widget.subtitle,
                    fontSize: TextStyles.k16FontSize,
                    color: kColorWhite.withValues(alpha: 0.95),
                    maxLines: 2,
                    align: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          _pink.withValues(alpha: 0.22),
                          _violet.withValues(alpha: 0.18),
                          _blue.withValues(alpha: 0.22),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _scoreChip(
                          label: 'A',
                          score: widget.scoreA,
                          color: _pink,
                          highlight: widget.winnerSide == PkBattleSide.a,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: BoldText(
                            text: 'VS',
                            fontSize: 12,
                            color: _gold,
                          ),
                        ),
                        _scoreChip(
                          label: 'B',
                          score: widget.scoreB,
                          color: _cyan,
                          highlight: widget.winnerSide == PkBattleSide.b,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _scoreChip({
    required String label,
    required int score,
    required Color color,
    required bool highlight,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: highlight
            ? LinearGradient(
                colors: [
                  color,
                  Color.lerp(color, Colors.white, 0.25)!,
                ],
              )
            : null,
        color: highlight ? null : color.withValues(alpha: 0.38),
        border: highlight
            ? Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.4)
            : Border.all(color: color.withValues(alpha: 0.55)),
        boxShadow: highlight
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.65),
                  blurRadius: 14,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BoldText(text: label, fontSize: 11, color: kColorWhite),
          const SizedBox(width: 6),
          BoldText(text: '$score', fontSize: 13, color: kColorWhite),
        ],
      ),
    );
  }
}

class _BurstParticle {
  _BurstParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.spin,
    required this.colorIndex,
    required this.kind,
    required this.delay,
  });

  factory _BurstParticle.random(math.Random rng) {
    return _BurstParticle(
      angle: rng.nextDouble() * math.pi * 2,
      speed: 0.24 + rng.nextDouble() * 0.82,
      size: 3.2 + rng.nextDouble() * 8.5,
      spin: (rng.nextDouble() - 0.5) * 10,
      colorIndex: rng.nextInt(10),
      kind: rng.nextInt(3),
      delay: rng.nextDouble() * 0.16,
    );
  }

  final double angle;
  final double speed;
  final double size;
  final double spin;
  final int colorIndex;
  final int kind;
  final double delay;
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({
    required this.particles,
    required this.progress,
    required this.colors,
  });

  final List<_BurstParticle> particles;
  final double progress;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.40);
    final maxRadius = size.shortestSide * 0.78;
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final local = ((progress - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;

      final travel = Curves.easeOutQuart.transform(local);
      final fade = (1.0 - local).clamp(0.0, 1.0);
      final radius = maxRadius * p.speed * travel;
      final pos = Offset(
        center.dx + math.cos(p.angle) * radius,
        center.dy + math.sin(p.angle) * radius - travel * 42,
      );

      paint.color = colors[p.colorIndex % colors.length]
          .withValues(alpha: 0.22 + fade * 0.78);

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.spin * local * math.pi);

      switch (p.kind) {
        case 1:
          final path = Path()
            ..moveTo(0, -p.size)
            ..lineTo(p.size * 0.75, 0)
            ..lineTo(0, p.size)
            ..lineTo(-p.size * 0.75, 0)
            ..close();
          canvas.drawPath(path, paint);
        case 2:
          paint.strokeWidth = math.max(1.3, p.size * 0.38);
          paint.style = PaintingStyle.stroke;
          canvas.drawLine(
            Offset(-p.size * 0.2, -p.size * 1.5),
            Offset(p.size * 0.2, p.size * 1.5),
            paint,
          );
          paint.style = PaintingStyle.fill;
        default:
          canvas.drawCircle(Offset.zero, p.size * (0.75 + fade * 0.35), paint);
      }
      canvas.restore();
    }

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..shader = SweepGradient(
        colors: colors.take(6).toList(),
      ).createShader(
        Rect.fromCircle(
          center: center,
          radius: maxRadius * 0.22,
        ),
      );
    final ringAlpha = (1.0 - progress).clamp(0.0, 1.0);
    if (ringAlpha > 0.05) {
      canvas.saveLayer(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white.withValues(alpha: ringAlpha),
      );
      canvas.drawCircle(
        center,
        maxRadius * 0.22 * Curves.easeOut.transform(progress.clamp(0.0, 1.0)),
        ringPaint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _RainSpark {
  _RainSpark({
    required this.x,
    required this.phase,
    required this.speed,
    required this.size,
    required this.colorIndex,
  });

  factory _RainSpark.random(math.Random rng) {
    return _RainSpark(
      x: rng.nextDouble(),
      phase: rng.nextDouble(),
      speed: 0.55 + rng.nextDouble() * 0.9,
      size: 2.0 + rng.nextDouble() * 4.5,
      colorIndex: rng.nextInt(10),
    );
  }

  final double x;
  final double phase;
  final double speed;
  final double size;
  final int colorIndex;
}

class _RainPainter extends CustomPainter {
  _RainPainter({
    required this.sparks,
    required this.progress,
    required this.colors,
  });

  final List<_RainSpark> sparks;
  final double progress;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final s in sparks) {
      final t = (progress * s.speed + s.phase) % 1.0;
      final y = -20 + t * (size.height + 40);
      final x = s.x * size.width + math.sin(t * math.pi * 4) * 10;
      final fade = t < 0.12
          ? t / 0.12
          : t > 0.85
              ? (1 - t) / 0.15
              : 1.0;
      paint.color =
          colors[s.colorIndex % colors.length].withValues(alpha: 0.55 * fade);
      canvas.drawCircle(Offset(x, y), s.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
