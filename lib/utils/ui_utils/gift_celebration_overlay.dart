import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';

/// Full-screen celebration overlay shown after a successful gift send.
///
/// Prefer [svgaAsset] (e.g. [jellyfishGiftAsset]) for client SVGA gift clips.
/// Pass [gifAsset] only when a GIF is needed instead of SVGA.
class GiftCelebrationOverlay {
  GiftCelebrationOverlay._();

  static const String treeLoveGiftAsset = 'assets/gif/tree_love_gift_79.svga';
  static const String jellyfishGiftAsset = 'assets/gif/jellyfish_gift_49.svga';

  /// Optional GIF fallback (`assets/gif/love_gif.gif`).
  static const String loveGiftAsset = kGifLoveGift;

  static OverlayEntry? _activeEntry;

  /// Shows a non-blocking full-screen gift celebration over the current route.
  ///
  /// [gifAsset]  — local GIF (Image.asset animates .gif natively)
  /// [svgaAsset] — optional SVGA effect (used when no gifAsset is set)
  static void show({
    String? giftName,
    String? gifAsset,
    String? svgaAsset,
  }) {
    // Prefer navigator context — Get.overlayContext is the Overlay itself, and
    // Overlay.maybeOf(overlayContext) returns null (no Overlay ancestor).
    final context = Get.context ?? Get.key.currentContext;
    if (context == null) return;

    final overlay =
        Overlay.maybeOf(context, rootOverlay: true) ??
        Navigator.maybeOf(context, rootNavigator: true)?.overlay;
    if (overlay == null) return;

    // Replace any in-flight celebration so rapid gift sends stay stable.
    _activeEntry?.remove();
    _activeEntry = OverlayEntry(
      builder: (_) => _GiftCelebrationView(
        giftName: giftName?.trim().isNotEmpty == true
            ? giftName!.trim()
            : 'Gift',
        gifAsset: gifAsset,
        svgaAsset: svgaAsset,
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
    this.gifAsset,
    this.svgaAsset,
    required this.onCompleted,
  });

  final String giftName;
  final String? gifAsset;
  final String? svgaAsset;
  final VoidCallback onCompleted;

  @override
  State<_GiftCelebrationView> createState() => _GiftCelebrationViewState();
}

class _GiftCelebrationViewState extends State<_GiftCelebrationView>
    with TickerProviderStateMixin {
  // Long enough for love_gif.gif to play through at least once.
  static const _overlayDuration = Duration(milliseconds: 4500);
  static const _fadeStart = 0.88;

  late final AnimationController _controller;
  SVGAAnimationController? _svgaController;
  Timer? _removeTimer;
  bool _isSvgaReady = false;
  bool _svgaFailed = false;

  bool get _hasGifAsset =>
      widget.gifAsset != null && widget.gifAsset!.trim().isNotEmpty;

  bool get _shouldLoadSvga =>
      !_hasGifAsset &&
      widget.svgaAsset != null &&
      widget.svgaAsset!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _overlayDuration)
      ..forward();
    _removeTimer = Timer(_overlayDuration, widget.onCompleted);
    if (_shouldLoadSvga) {
      _loadSvgaAnimation();
    }
  }

  @override
  void dispose() {
    _removeTimer?.cancel();
    _svgaController?.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSvgaAnimation() async {
    final asset = widget.svgaAsset;
    if (asset == null || asset.trim().isEmpty) return;

    final controller = SVGAAnimationController(vsync: this);
    _svgaController = controller;
    try {
      final videoItem = await SVGAParser.shared.decodeFromAssets(asset);
      if (!mounted || _svgaController != controller) {
        videoItem.dispose();
        return;
      }
      controller.videoItem = videoItem;
      setState(() => _isSvgaReady = true);
      controller
        ..reset()
        ..repeat();
    } catch (_) {
      // Keep the UI usable if an SVGA asset fails to decode.
      if (mounted && _svgaController == controller) {
        setState(() {
          _isSvgaReady = false;
          _svgaFailed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 18;
    final size = MediaQuery.sizeOf(context);
    return Positioned.fill(
      child: IgnorePointer(
        // Touches pass through so hosts/viewers can keep using the room UI.
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final value = Curves.easeOutCubic.transform(_controller.value);
            final fade = _controller.value < _fadeStart
                ? 1.0
                : (1 - ((_controller.value - _fadeStart) / (1 - _fadeStart)))
                      .clamp(0.0, 1.0);
            return Opacity(
              opacity: fade,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Dimmed full-screen backdrop behind the gift GIF.
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(
                          alpha: _hasGifAsset ? 0.55 : 0.22,
                        ),
                      ),
                    ),
                  ),
                  // Preferred path: full-screen animated GIF.
                  if (_hasGifAsset) _buildFullScreenGif(size: size),
                  // Fallback path: SVGA effect (existing support).
                  if (!_hasGifAsset &&
                      _isSvgaReady &&
                      _svgaController != null)
                    Positioned.fill(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: size.width,
                          height: size.height,
                          child: SVGAImage(
                            _svgaController!,
                            fit: BoxFit.cover,
                            clearsAfterStop: false,
                          ),
                        ),
                      ),
                    ),
                  if (!_hasGifAsset)
                    CustomPaint(
                      painter: _GiftBurstPainter(progress: value),
                      size: Size.infinite,
                    ),
                  // Static gift badge only when neither GIF nor SVGA is ready.
                  if (!_hasGifAsset && (!_isSvgaReady || _svgaFailed))
                    Positioned(
                      top: top - (10 * value),
                      left: 18,
                      right: 18,
                      child: Transform.scale(
                        scale: 0.86 + (0.14 * value),
                        child: const _GiftCelebrationCard(),
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

  /// Renders [gifAsset] edge-to-edge (full screen) while preserving aspect ratio.
  Widget _buildFullScreenGif({required Size size}) {
    return Positioned.fill(
      child: Center(
        child: Image.asset(
          widget.gifAsset!,
          width: size.width,
          height: size.height,
          fit: BoxFit.contain,
          // Flutter animates .gif assets automatically.
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => const _GiftCelebrationCard(),
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
