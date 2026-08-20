import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/utils/app_widgets/app_coin_icon.dart';

/// Gullak-style coin transfer: coins stream toward (earn) or away from (deduct)
/// a badge target.
///
/// Uses a root [OverlayEntry] with [IgnorePointer] so call controls stay
/// tappable while coins animate (unlike a modal [Get.dialog] barrier).
class CoinFlyOverlay {
  CoinFlyOverlay._();

  static OverlayEntry? _entry;
  static Completer<void>? _activeCompleter;
  static final List<_QueuedCoinFly> _queue = [];

  /// True from [show] until that flight finishes — covers the pre-overlay delay.
  static var _reserved = false;

  static bool get isShowing =>
      _activeCompleter != null && !_activeCompleter!.isCompleted;

  static bool get _isBusy => _reserved || isShowing;

  /// Flies visual coins into [targetKey]'s center (earn) or away from it (deduct).
  ///
  /// [earnedAmount] > 0 shows a brief "+N" / "-N" flash near the target.
  /// Set [isDeduction] for spend — coins burst outward with a red "-N".
  /// [enqueueIfBusy] plays after the current flight (audience seats after host).
  static Future<void> show({
    required GlobalKey targetKey,
    int coinCount = 10,
    int earnedAmount = 0,
    Offset? startFrom,
    Offset? endAt,
    bool isDeduction = false,
    Duration delay = const Duration(milliseconds: 650),
    bool enqueueIfBusy = false,
    bool fallbackIfMissing = true,
  }) async {
    if (enqueueIfBusy && _isBusy) {
      _queue.add(
        _QueuedCoinFly(
          targetKey: targetKey,
          coinCount: coinCount,
          earnedAmount: earnedAmount,
          startFrom: startFrom,
          endAt: endAt,
          isDeduction: isDeduction,
          delay: delay,
          fallbackIfMissing: fallbackIfMissing,
        ),
      );
      return;
    }
    if (!enqueueIfBusy) _queue.clear();
    dismiss(clearQueue: false);
    _reserved = true;

    BuildContext? navigatorContext;
    try {
      navigatorContext = Get.context ?? Get.key.currentContext;
    } catch (_) {
      navigatorContext = null;
    }
    if (navigatorContext == null) {
      _reserved = false;
      _playNextQueued();
      return;
    }

    await Future<void>.delayed(delay);

    if (!navigatorContext.mounted) {
      _reserved = false;
      _playNextQueued();
      return;
    }

    final target = await _resolveTarget(targetKey);
    if (!navigatorContext.mounted) {
      _reserved = false;
      _playNextQueued();
      return;
    }
    if (target == null && !fallbackIfMissing) {
      _reserved = false;
      _playNextQueued();
      return;
    }

    final resolvedTarget =
        target ??
        () {
          final media = MediaQuery.sizeOf(navigatorContext!);
          final padding = MediaQuery.paddingOf(navigatorContext);
          return Offset(media.width - 56, padding.top + 28);
        }();

    await _openOverlay(
      navigatorContext: navigatorContext,
      origin: startFrom ?? _defaultOrigin(navigatorContext),
      target: resolvedTarget,
      endAt: endAt,
      coinCount: coinCount,
      earnedAmount: earnedAmount,
      isDeduction: isDeduction,
    );
  }

  static Offset _defaultOrigin(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    return Offset(media.width * 0.78, media.height - 96);
  }

  static Future<Offset?> _resolveTarget(
    GlobalKey targetKey, {
    int retries = 8,
  }) async {
    for (var i = 0; i < retries; i++) {
      final box = targetKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize && box.attached) {
        return box.localToGlobal(
          Offset(box.size.width / 2, box.size.height / 2),
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 60));
    }
    return null;
  }

  static Future<void> _openOverlay({
    required BuildContext navigatorContext,
    required Offset origin,
    required Offset target,
    Offset? endAt,
    required int coinCount,
    required int earnedAmount,
    required bool isDeduction,
  }) {
    if (!navigatorContext.mounted) {
      _reserved = false;
      _playNextQueued();
      return Future<void>.value();
    }

    final overlay =
        Overlay.maybeOf(navigatorContext, rootOverlay: true) ??
        Navigator.maybeOf(navigatorContext, rootNavigator: true)?.overlay;
    if (overlay == null) {
      _reserved = false;
      _playNextQueued();
      return Future<void>.value();
    }

    final completer = Completer<void>();
    _activeCompleter = completer;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: _CoinFlyLayer(
          origin: origin,
          target: target,
          endAt: endAt,
          coinCount: coinCount.clamp(6, 18),
          earnedAmount: earnedAmount,
          isDeduction: isDeduction,
          onCompleted: () {
            entry.remove();
            if (_entry == entry) _entry = null;
            if (!completer.isCompleted) completer.complete();
            if (_activeCompleter == completer) _activeCompleter = null;
            _reserved = false;
            _playNextQueued();
          },
        ),
      ),
    );
    _entry = entry;
    overlay.insert(entry);
    return completer.future;
  }

  static void dismiss({bool clearQueue = true}) {
    if (clearQueue) _queue.clear();
    _reserved = false;
    final entry = _entry;
    _entry = null;
    entry?.remove();
    final completer = _activeCompleter;
    _activeCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  static void _playNextQueued() {
    if (_queue.isEmpty || _isBusy) return;
    final next = _queue.removeAt(0);
    unawaited(
      show(
        targetKey: next.targetKey,
        coinCount: next.coinCount,
        earnedAmount: next.earnedAmount,
        startFrom: next.startFrom,
        endAt: next.endAt,
        isDeduction: next.isDeduction,
        delay: next.delay,
        enqueueIfBusy: true,
        fallbackIfMissing: next.fallbackIfMissing,
      ),
    );
  }
}

class _QueuedCoinFly {
  const _QueuedCoinFly({
    required this.targetKey,
    required this.coinCount,
    required this.earnedAmount,
    required this.startFrom,
    required this.endAt,
    required this.isDeduction,
    required this.delay,
    required this.fallbackIfMissing,
  });

  final GlobalKey targetKey;
  final int coinCount;
  final int earnedAmount;
  final Offset? startFrom;
  final Offset? endAt;
  final bool isDeduction;
  final Duration delay;
  final bool fallbackIfMissing;
}

class _CoinFlyLayer extends StatefulWidget {
  const _CoinFlyLayer({
    required this.origin,
    required this.target,
    this.endAt,
    required this.coinCount,
    required this.earnedAmount,
    required this.isDeduction,
    required this.onCompleted,
  });

  final Offset origin;
  final Offset target;
  final Offset? endAt;
  final int coinCount;
  final int earnedAmount;
  final bool isDeduction;
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
    final flyOrigin = widget.isDeduction ? widget.target : widget.origin;
    final flyTarget = widget.isDeduction
        ? (widget.endAt ??
              Offset(
                widget.target.dx + (_random.nextDouble() - 0.5) * 90,
                widget.target.dy + 120 + _random.nextDouble() * 80,
              ))
        : widget.target;
    final start = Offset(
      flyOrigin.dx +
          (_random.nextDouble() - 0.5) * (widget.isDeduction ? 24 : spread),
      flyOrigin.dy +
          (_random.nextDouble() - 0.5) * (widget.isDeduction ? 16 : 28),
    );
    final end = Offset(
      flyTarget.dx + (_random.nextDouble() - 0.5) * 14,
      flyTarget.dy + (_random.nextDouble() - 0.5) * 10,
    );
    final lift = 100 + _random.nextDouble() * 120;
    final mid = widget.isDeduction
        ? Offset(
            (start.dx + end.dx) / 2 + (_random.nextDouble() - 0.5) * 60,
            (start.dy + end.dy) / 2 - lift * 0.35,
          )
        : Offset(
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
    return Material(
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
    final deduct = widget.isDeduction;
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
              gradient: LinearGradient(
                colors: deduct
                    ? const [Color(0xFFFF8A80), Color(0xFFE62572)]
                    : const [Color(0xFFFFE082), Color(0xFFFFA10A)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color:
                      (deduct
                              ? const Color(0xFFE62572)
                              : const Color(0xFFFFA10A))
                          .withValues(alpha: 0.55),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              '${deduct ? '-' : '+'}${widget.earnedAmount}',
              style: TextStyle(
                color: deduct ? Colors.white : const Color(0xFF1A0A00),
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
          colors: [Color(0xFFFFF8E1), Color(0xFFFFD54F), Color(0xFFFF8F00)],
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
      child: AppCoinIcon(size: size * 0.72),
    );
  }
}
