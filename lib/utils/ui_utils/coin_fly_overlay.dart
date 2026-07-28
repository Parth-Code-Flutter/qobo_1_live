import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Gullak-style coin transfer: coins stream from the gift area toward the
/// session-earnings badge in the app bar.
///
/// Uses a transparent [Get.dialog] route (same as [GiftCelebrationOverlay]) so
/// coins render above Zego PlatformViews and the audio-room overlay stack.
class CoinFlyOverlay {
  CoinFlyOverlay._();

  static BuildContext? _dialogContext;

  /// Flies visual coins into [targetKey]'s center.
  ///
  /// [earnedAmount] > 0 shows a brief "+N" flash near the target.
  static Future<void> show({
    required GlobalKey targetKey,
    int coinCount = 10,
    int earnedAmount = 0,
    Offset? startFrom,
    Duration delay = const Duration(milliseconds: 650),
  }) async {
    dismiss();

    BuildContext? navigatorContext;
    try {
      navigatorContext = Get.context ?? Get.key.currentContext;
    } catch (_) {
      navigatorContext = null;
    }
    if (navigatorContext == null) return;

    await Future<void>.delayed(delay);

    if (!navigatorContext.mounted) return;

    final target = await _resolveTarget(targetKey);
    if (!navigatorContext.mounted) return;

    if (target == null) {
      final media = MediaQuery.sizeOf(navigatorContext);
      final padding = MediaQuery.paddingOf(navigatorContext);
      // Fallback: top-right app-bar coin pill when the key is not laid out yet.
      final fallback = Offset(media.width - 56, padding.top + 28);
      _openDialog(
        navigatorContext: navigatorContext,
        origin: startFrom ?? _defaultOrigin(navigatorContext),
        target: fallback,
        coinCount: coinCount,
        earnedAmount: earnedAmount,
      );
      return;
    }

    _openDialog(
      navigatorContext: navigatorContext,
      origin: startFrom ?? _defaultOrigin(navigatorContext),
      target: target,
      coinCount: coinCount,
      earnedAmount: earnedAmount,
    );
  }

  static Offset _defaultOrigin(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    // Bottom gift-button area in audio rooms.
    return Offset(media.width * 0.78, media.height - 96);
  }

  static Future<Offset?> _resolveTarget(
    GlobalKey targetKey, {
    int retries = 8,
  }) async {
    for (var i = 0; i < retries; i++) {
      final box =
          targetKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize && box.attached) {
        return box.localToGlobal(
          Offset(box.size.width / 2, box.size.height / 2),
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 60));
    }
    return null;
  }

  static void _openDialog({
    required BuildContext navigatorContext,
    required Offset origin,
    required Offset target,
    required int coinCount,
    required int earnedAmount,
  }) {
    if (!navigatorContext.mounted) return;

    Get.dialog<void>(
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      useSafeArea: false,
      Builder(
        builder: (dialogContext) {
          _dialogContext = dialogContext;
          return _CoinFlyLayer(
            origin: origin,
            target: target,
            coinCount: coinCount.clamp(6, 18),
            earnedAmount: earnedAmount,
            onCompleted: () {
              if (dialogContext.mounted &&
                  Navigator.of(dialogContext).canPop()) {
                Navigator.of(dialogContext).pop();
              }
              if (_dialogContext == dialogContext) {
                _dialogContext = null;
              }
            },
          );
        },
      ),
    );
  }

  static void dismiss() {
    final ctx = _dialogContext;
    if (ctx != null && ctx.mounted && Navigator.of(ctx).canPop()) {
      Navigator.of(ctx).pop();
    }
    _dialogContext = null;
  }
}

class _CoinFlyLayer extends StatefulWidget {
  const _CoinFlyLayer({
    required this.origin,
    required this.target,
    required this.coinCount,
    required this.earnedAmount,
    required this.onCompleted,
  });

  final Offset origin;
  final Offset target;
  final int coinCount;
  final int earnedAmount;
  final VoidCallback onCompleted;

  @override
  State<_CoinFlyLayer> createState() => _CoinFlyLayerState();
}

class _CoinFlyLayerState extends State<_CoinFlyLayer>
    with TickerProviderStateMixin {
  late final List<_CoinFlight> _flights;
  late final AnimationController _burst;
  late final AnimationController _flash;
  late final AnimationController _targetPulse;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _flights = List.generate(widget.coinCount, _buildFlight);
    _burst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    _flash = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _targetPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    Future<void>.delayed(const Duration(milliseconds: 680), () {
      if (mounted) {
        _flash.forward();
        _targetPulse.forward();
      }
    });
    _burst.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCompleted();
      }
    });
  }

  _CoinFlight _buildFlight(int index) {
    final spread = 110.0 + _random.nextDouble() * 40;
    final start = Offset(
      widget.origin.dx + (_random.nextDouble() - 0.5) * spread,
      widget.origin.dy + (_random.nextDouble() - 0.5) * 28,
    );
    final end = Offset(
      widget.target.dx + (_random.nextDouble() - 0.5) * 14,
      widget.target.dy + (_random.nextDouble() - 0.5) * 10,
    );
    final lift = 100 + _random.nextDouble() * 120;
    final mid = Offset(
      (start.dx + end.dx) / 2 + (_random.nextDouble() - 0.5) * 80,
      math.min(start.dy, end.dy) - lift,
    );
    final delay = index * 0.038 + _random.nextDouble() * 0.05;
    return _CoinFlight(
      start: start,
      mid: mid,
      end: end,
      delay: delay.clamp(0.0, 0.62),
      size: 22 + _random.nextDouble() * 14,
      spin: (_random.nextBool() ? 1 : -1) * (2 + _random.nextDouble() * 2.5),
    );
  }

  @override
  void dispose() {
    _burst.dispose();
    _flash.dispose();
    _targetPulse.dispose();
    super.dispose();
  }

  Offset _quad(Offset a, Offset b, Offset c, double t) {
    final u = 1 - t;
    return Offset(
      u * u * a.dx + 2 * u * t * b.dx + t * t * c.dx,
      u * u * a.dy + 2 * u * t * b.dy + t * t * c.dy,
    );
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox.expand(
          child: AnimatedBuilder(
            animation: Listenable.merge([_burst, _flash, _targetPulse]),
            builder: (context, _) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final flight in _flights) _coin(flight),
                  _targetGlow(),
                  if (widget.earnedAmount > 0) _amountFlash(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _coin(_CoinFlight flight) {
    final denom = (1 - flight.delay).clamp(0.05, 1.0);
    final raw = ((_burst.value - flight.delay) / denom).clamp(0.0, 1.0);
    if (raw <= 0) return const SizedBox.shrink();

    final t = Curves.easeInOutCubic.transform(raw);
    final pos = _quad(flight.start, flight.mid, flight.end, t);
    final scale = 1.35 - (0.75 * t);
    final opacity = t < 0.88 ? 1.0 : (1 - ((t - 0.88) / 0.12));

    return Positioned(
      left: pos.dx - flight.size / 2,
      top: pos.dy - flight.size / 2,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: flight.spin * t * math.pi,
          child: Transform.scale(
            scale: scale,
            child: _CoinVisual(size: flight.size),
          ),
        ),
      ),
    );
  }

  Widget _targetGlow() {
    final pulse = Curves.easeOut.transform(_targetPulse.value.clamp(0.0, 1.0));
    if (pulse <= 0) return const SizedBox.shrink();
    final size = 28 + (36 * pulse);
    return Positioned(
      left: widget.target.dx - size / 2,
      top: widget.target.dy - size / 2,
      child: Opacity(
        opacity: (1 - pulse) * 0.85,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFFFD54F).withValues(alpha: 0.75),
                const Color(0xFFFFA10A).withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _amountFlash() {
    final t = Curves.easeOutBack.transform(_flash.value.clamp(0.0, 1.0));
    final fade = _flash.value < 0.5
        ? 1.0
        : (1 - ((_flash.value - 0.5) / 0.5)).clamp(0.0, 1.0);
    return Positioned(
      left: widget.target.dx - 34,
      top: widget.target.dy - 44 - (22 * t),
      child: Opacity(
        opacity: fade,
        child: Transform.scale(
          scale: 0.65 + (0.55 * t),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFE082), Color(0xFFFFA10A)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFA10A).withValues(alpha: 0.55),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              '+${widget.earnedAmount}',
              style: const TextStyle(
                color: Color(0xFF1A0A00),
                fontWeight: FontWeight.w800,
                fontSize: 14,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CoinFlight {
  const _CoinFlight({
    required this.start,
    required this.mid,
    required this.end,
    required this.delay,
    required this.size,
    required this.spin,
  });

  final Offset start;
  final Offset mid;
  final Offset end;
  final double delay;
  final double size;
  final double spin;
}

class _CoinVisual extends StatelessWidget {
  const _CoinVisual({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.35, -0.4),
          radius: 0.95,
          colors: [
            Color(0xFFFFF8E1),
            Color(0xFFFFD54F),
            Color(0xFFFF8F00),
          ],
        ),
        border: Border.all(color: const Color(0xFFFFE082), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFA000).withValues(alpha: 0.65),
            blurRadius: 10,
            spreadRadius: 0.5,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.monetization_on_rounded,
        size: size * 0.72,
        color: const Color(0xFF8D4E00),
      ),
    );
  }
}
