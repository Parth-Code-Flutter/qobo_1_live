import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';

/// Full-screen celebration overlay shown after a successful gift send.
///
/// Prefer [svgaUrl] from the gift-list API `animationUrl` field.
/// Local SVGA / GIF assets remain available as optional fallbacks only.
class GiftCelebrationOverlay {
  GiftCelebrationOverlay._();

  // --- Local assets (kept for reference; prefer API animationUrl) ---
  // static const String treeLoveGiftAsset = 'assets/gif/tree_love_gift_79.svga';
  // static const String jellyfishGiftAsset = 'assets/gif/jellyfish_gift_49.svga';
  static const String loveGiftAsset = kGifLoveGift;

  static OverlayEntry? _activeEntry;

  /// Shows a non-blocking full-screen gift celebration over the current route.
  ///
  /// Priority: [svgaUrl] (network) → [svgaAsset] (local) → [gifAsset] → badge.
  static void show({
    String? giftName,
    String? svgaUrl,
    String? soundUrl,
    String? svgaAsset,
    String? gifAsset,
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
        svgaUrl: svgaUrl?.trim(),
        soundUrl: soundUrl?.trim(),
        // Local SVGA asset path kept for optional fallback; prefer svgaUrl.
        svgaAsset: svgaAsset?.trim(),
        gifAsset: gifAsset,
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
    this.svgaUrl,
    this.soundUrl,
    this.svgaAsset,
    this.gifAsset,
    required this.onCompleted,
  });

  final String giftName;
  final String? svgaUrl;
  final String? soundUrl;
  final String? svgaAsset;
  final String? gifAsset;
  final VoidCallback onCompleted;

  @override
  State<_GiftCelebrationView> createState() => _GiftCelebrationViewState();
}

class _GiftCelebrationViewState extends State<_GiftCelebrationView>
    with TickerProviderStateMixin {
  // Default on-screen time once media is ready (network SVGA may load slower).
  static const _overlayDuration = Duration(milliseconds: 5200);
  static const _fadeStart = 0.88;

  late final AnimationController _controller;
  SVGAAnimationController? _svgaController;
  just_audio.AudioPlayer? _audioPlayer;
  Timer? _removeTimer;
  bool _isSvgaReady = false;
  bool _svgaFailed = false;
  bool _isLoadingSvga = false;
  bool _soundStarted = false;

  bool get _hasGifAsset =>
      widget.gifAsset != null && widget.gifAsset!.trim().isNotEmpty;

  bool get _hasNetworkSvga {
    final url = widget.svgaUrl?.trim() ?? '';
    return url.startsWith('http://') || url.startsWith('https://');
  }

  bool get _hasLocalSvga =>
      widget.svgaAsset != null && widget.svgaAsset!.trim().isNotEmpty;

  bool get _hasNetworkSound {
    final url = widget.soundUrl?.trim() ?? '';
    return url.startsWith('http://') || url.startsWith('https://');
  }

  bool get _shouldLoadSvga =>
      !_hasGifAsset && (_hasNetworkSvga || _hasLocalSvga);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _overlayDuration)
      ..forward();

    if (_shouldLoadSvga) {
      _isLoadingSvga = true;
      _loadSvgaAnimation();
    } else if (_hasGifAsset) {
      unawaited(_playGiftSound());
      _scheduleDismiss();
    } else {
      // No media — still show a brief badge celebration.
      unawaited(_playGiftSound());
      _scheduleDismiss();
    }
  }

  @override
  void dispose() {
    _removeTimer?.cancel();
    final audioPlayer = _audioPlayer;
    _audioPlayer = null;
    if (audioPlayer != null) {
      unawaited(audioPlayer.stop().catchError((_) {}));
      unawaited(audioPlayer.dispose().catchError((_) {}));
    }
    _svgaController?.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleDismiss() {
    _removeTimer?.cancel();
    _removeTimer = Timer(_overlayDuration, widget.onCompleted);
  }

  Future<void> _loadSvgaAnimation() async {
    final controller = SVGAAnimationController(vsync: this);
    _svgaController = controller;

    try {
      final videoItem = _hasNetworkSvga
          // Gift-list API `animationUrl` (Cloudinary / CDN SVGA bytes).
          ? await SVGAParser.shared.decodeFromURL(widget.svgaUrl!)
          // Local asset fallback (optional; callers may pass svgaAsset).
          : await SVGAParser.shared.decodeFromAssets(widget.svgaAsset!);

      if (!mounted || _svgaController != controller) {
        videoItem.dispose();
        return;
      }

      controller.videoItem = videoItem;
      setState(() {
        _isSvgaReady = true;
        _isLoadingSvga = false;
        _svgaFailed = false;
      });
      controller
        ..reset()
        ..repeat();
      // Start sound only when the visual is ready so both feel synchronized.
      unawaited(_playGiftSound());
      // Start dismiss clock only after the clip is ready to play.
      _scheduleDismiss();
    } catch (_) {
      // Keep the UI usable if network / local SVGA fails to decode.
      if (mounted && _svgaController == controller) {
        setState(() {
          _isSvgaReady = false;
          _isLoadingSvga = false;
          _svgaFailed = true;
        });
        // A failed animation must not prevent the API-provided sound effect.
        unawaited(_playGiftSound());
        _scheduleDismiss();
      }
    }
  }

  Future<void> _playGiftSound() async {
    if (!_hasNetworkSound || _soundStarted || !mounted) return;
    _soundStarted = true;
    // Reuse the app's existing audio session instead of activating or changing
    // it, which keeps Zego room/call audio routing untouched.
    final player = just_audio.AudioPlayer(
      handleInterruptions: false,
      handleAudioSessionActivation: false,
      androidApplyAudioAttributes: false,
    );
    _audioPlayer = player;

    try {
      await player.setUrl(widget.soundUrl!);
      if (!mounted || _audioPlayer != player) return;
      await player.setVolume(1);
      unawaited(player.play().catchError((_) {}));
    } catch (_) {
      // Sound is optional; an invalid URL must never break gift animation flow.
      if (_audioPlayer == player) {
        _audioPlayer = null;
        await player.dispose();
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
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(
                          alpha: _hasGifAsset || _hasNetworkSvga ? 0.45 : 0.22,
                        ),
                      ),
                    ),
                  ),
                  if (_hasGifAsset) _buildFullScreenGif(size: size),
                  if (!_hasGifAsset && _isSvgaReady && _svgaController != null)
                    Positioned.fill(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: size.width,
                          height: size.height,
                          child: SVGAImage(
                            _svgaController!,
                            fit: BoxFit.contain,
                            clearsAfterStop: false,
                          ),
                        ),
                      ),
                    ),
                  if (_isLoadingSvga && !_isSvgaReady)
                    const Center(
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          color: kColorWhite,
                        ),
                      ),
                    ),
                  if (!_hasGifAsset && !_hasNetworkSvga && !_hasLocalSvga)
                    CustomPaint(
                      painter: _GiftBurstPainter(progress: value),
                      size: Size.infinite,
                    ),
                  // Fallback badge when SVGA cannot be loaded.
                  if (!_hasGifAsset &&
                      (!_isSvgaReady || _svgaFailed) &&
                      !_isLoadingSvga)
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

  Widget _buildFullScreenGif({required Size size}) {
    return Positioned.fill(
      child: Center(
        child: Image.asset(
          widget.gifAsset!,
          width: size.width,
          height: size.height,
          fit: BoxFit.contain,
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
