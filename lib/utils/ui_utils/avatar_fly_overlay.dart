import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Single-person floor join: one avatar pops in, arcs up with a soft trail,
/// then absorbs into the AppBar audience badge (not a coin-style multi burst).
class AvatarFlyOverlay {
  AvatarFlyOverlay._();

  static BuildContext? _dialogContext;

  static Future<void> show({
    required GlobalKey targetKey,
    required String name,
    String? avatarUrl,
    Offset? startFrom,
    Duration delay = const Duration(milliseconds: 140),
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

    final media = MediaQuery.sizeOf(navigatorContext);
    final padding = MediaQuery.paddingOf(navigatorContext);
    final resolvedTarget =
        target ?? Offset(media.width - 108, padding.top + 28);

    _openDialog(
      navigatorContext: navigatorContext,
      origin: startFrom ?? _defaultOrigin(navigatorContext),
      target: resolvedTarget,
      name: name,
      avatarUrl: avatarUrl,
    );
  }

  static Offset _defaultOrigin(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    // Near the chat / former floor-strip area.
    return Offset(media.width * 0.28, media.height - 150);
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

  static void _openDialog({
    required BuildContext navigatorContext,
    required Offset origin,
    required Offset target,
    required String name,
    required String? avatarUrl,
  }) {
    if (!navigatorContext.mounted) return;

    Get.dialog<void>(
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      useSafeArea: false,
      Builder(
        builder: (dialogContext) {
          _dialogContext = dialogContext;
          return _AvatarFlyLayer(
            origin: origin,
            target: target,
            name: name,
            avatarUrl: avatarUrl,
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

class _AvatarFlyLayer extends StatefulWidget {
  const _AvatarFlyLayer({
    required this.origin,
    required this.target,
    required this.name,
    required this.avatarUrl,
    required this.onCompleted,
  });

  final Offset origin;
  final Offset target;
  final String name;
  final String? avatarUrl;
  final VoidCallback onCompleted;

  @override
  State<_AvatarFlyLayer> createState() => _AvatarFlyLayerState();
}

class _AvatarFlyLayerState extends State<_AvatarFlyLayer>
    with TickerProviderStateMixin {
  static const _accent = Color(0xFFFF3EA5);
  static const _accentSoft = Color(0xFFB16CFF);

  late final AnimationController _flight;
  late final AnimationController _intro;
  late final AnimationController _landing;
  late final Offset _mid;
  late final List<Offset> _trailOffsets;

  @override
  void initState() {
    super.initState();

    // Soft S-curve toward the AppBar badge.
    final dx = widget.target.dx - widget.origin.dx;
    _mid = Offset(
      widget.origin.dx + dx * 0.42 + (dx.abs() < 40 ? 48 : 0),
      math.min(widget.origin.dy, widget.target.dy) - 130,
    );

    _trailOffsets = List.generate(5, (i) {
      final t = (i + 1) / 7.0;
      return _quad(widget.origin, _mid, widget.target, t);
    });

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _flight = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 980),
    );
    _landing = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );

    _intro.forward().whenComplete(() {
      if (!mounted) return;
      _flight.forward();
    });

    _flight.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _landing.forward();
      }
    });
    _landing.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCompleted();
      }
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _flight.dispose();
    _landing.dispose();
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
            animation: Listenable.merge([_intro, _flight, _landing]),
            builder: (context, _) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  ..._buildTrail(),
                  _buildFlyer(),
                  _buildNameChip(),
                  _buildLandingBurst(),
                  _buildJoinedToast(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTrail() {
    if (_flight.value <= 0.04) return const [];
    final widgets = <Widget>[];
    for (var i = 0; i < _trailOffsets.length; i++) {
      final lag = (i + 1) * 0.065;
      final raw = (_flight.value - lag).clamp(0.0, 1.0);
      if (raw <= 0) continue;
      final t = Curves.easeInOutCubic.transform(raw);
      final pos = _quad(widget.origin, _mid, widget.target, t);
      final fade = (1 - (i / _trailOffsets.length)) * (1 - t) * 0.55;
      final size = 34.0 - (i * 3.2);
      widgets.add(
        Positioned(
          left: pos.dx - size / 2,
          top: pos.dy - size / 2,
          child: Opacity(
            opacity: fade.clamp(0.0, 0.55),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _accent.withValues(alpha: 0.55),
                    _accentSoft.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _buildFlyer() {
    final intro = Curves.easeOutBack.transform(_intro.value.clamp(0.0, 1.0));
    final flightT = Curves.easeInOutCubic.transform(_flight.value.clamp(0.0, 1.0));
    final landing = _landing.value.clamp(0.0, 1.0);

    final pos = _flight.value <= 0
        ? widget.origin
        : _quad(widget.origin, _mid, widget.target, flightT);

    // Pop in big → travel → shrink into the badge.
    double scale;
    if (_flight.value <= 0) {
      scale = 0.35 + (0.95 * intro);
    } else if (flightT < 0.82) {
      scale = 1.3 - (0.35 * flightT);
    } else {
      final absorb = ((flightT - 0.82) / 0.18).clamp(0.0, 1.0);
      scale = 0.95 - (0.7 * absorb);
    }
    if (landing > 0) {
      scale *= (1 - landing).clamp(0.0, 1.0);
    }

    final opacity = landing > 0.55
        ? (1 - ((landing - 0.55) / 0.45)).clamp(0.0, 1.0)
        : (_intro.value < 0.15 ? (_intro.value / 0.15) : 1.0);

    const size = 52.0;
    return Positioned(
      left: pos.dx - size / 2,
      top: pos.dy - size / 2,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: scale.clamp(0.05, 1.5),
          child: _heroAvatar(size: size),
        ),
      ),
    );
  }

  Widget _heroAvatar({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_accent, _accentSoft],
        ),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.55),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(color: kColorWhite.withValues(alpha: 0.92), width: 2),
      ),
      padding: const EdgeInsets.all(2.5),
      child: ClipOval(
        child: AppUserAvatar(
          name: widget.name,
          imageUrl: widget.avatarUrl,
          size: size - 5,
        ),
      ),
    );
  }

  Widget _buildNameChip() {
    // Show name only during the intro pop, then fade as flight starts.
    final visible = _flight.value < 0.22
        ? Curves.easeOut.transform(_intro.value.clamp(0.0, 1.0))
        : (1 - ((_flight.value - 0.05) / 0.2)).clamp(0.0, 1.0);
    if (visible <= 0.02) return const SizedBox.shrink();

    final label = widget.name.trim().isEmpty ? 'Someone' : widget.name.trim();
    final short = label.length > 14 ? '${label.substring(0, 14)}…' : label;

    return Positioned(
      left: widget.origin.dx - 54,
      top: widget.origin.dy + 34,
      child: Opacity(
        opacity: visible,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - visible)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xCC1A0B2E),
                  border: Border.all(color: _accent.withValues(alpha: 0.45)),
                ),
                child: Text(
                  '👋 $short joined',
                  style: TextStyle(
                    color: kColorWhite,
                    fontSize: TextStyles.k12FontSize,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLandingBurst() {
    final t = Curves.easeOut.transform(_landing.value.clamp(0.0, 1.0));
    if (t <= 0) return const SizedBox.shrink();
    final size = 28 + (52 * t);
    return Positioned(
      left: widget.target.dx - size / 2,
      top: widget.target.dy - size / 2,
      child: Opacity(
        opacity: (1 - t) * 0.95,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _accent.withValues(alpha: 0.75 * (1 - t)),
              width: 2.2,
            ),
            gradient: RadialGradient(
              colors: [
                _accent.withValues(alpha: 0.35 * (1 - t)),
                _accentSoft.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJoinedToast() {
    final t = _landing.value.clamp(0.0, 1.0);
    if (t <= 0.08) return const SizedBox.shrink();
    final appear = Curves.easeOutBack.transform(((t - 0.08) / 0.4).clamp(0.0, 1.0));
    final fade = t < 0.55 ? 1.0 : (1 - ((t - 0.55) / 0.45)).clamp(0.0, 1.0);
    final label = widget.name.trim().isEmpty ? 'Guest' : widget.name.trim();
    final short = label.length > 12 ? '${label.substring(0, 12)}…' : label;

    return Positioned(
      left: widget.target.dx - 52,
      top: widget.target.dy + 22 - (10 * appear),
      child: Opacity(
        opacity: fade * appear.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.85 + (0.2 * appear),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6AD5), Color(0xFF9B1FE8)],
              ),
              boxShadow: [
                BoxShadow(
                  color: _accent.withValues(alpha: 0.4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Text(
              '+$short',
              style: const TextStyle(
                color: kColorWhite,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
