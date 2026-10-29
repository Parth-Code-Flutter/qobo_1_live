import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/svga_network_loader.dart';
import 'package:qobo_one_live/utils/ui_utils/gift_sound_player.dart';

/// Full-screen VIP / patti entrance (gift-style) when a user joins audio/video/live.
class VipEntranceOverlay {
  VipEntranceOverlay._();

  static BuildContext? _dialogContext;

  /// Returns false when there is nothing to show or the room route is not ready.
  static bool show({
    required String userName,
    String? avatarUrl,
    String? vipFrameUrl,
    String? pattiStyle,
    String? soundUrl,
    Duration displayFor = const Duration(milliseconds: 5200),
  }) {
    dismiss();

    final name = userName.trim().isNotEmpty ? userName.trim() : 'VIP Member';
    final frame =
        ApiImageUtils.normalize(vipFrameUrl?.trim()) ?? vipFrameUrl?.trim() ?? '';
    final avatar =
        ApiImageUtils.normalize(avatarUrl?.trim()) ?? avatarUrl?.trim();
    final patti = pattiStyle?.trim() ?? '';

    // Need at least a VIP frame URL or a patti style label to show.
    if (frame.isEmpty && patti.isEmpty) return false;

    BuildContext? navigatorContext;
    try {
      navigatorContext =
          Get.overlayContext ?? Get.context ?? Get.key.currentContext;
    } catch (_) {
      navigatorContext = null;
    }
    if (navigatorContext == null || !navigatorContext.mounted) return false;

    // Transparent barrier (same as gifts) so SVGA sits above Zego PlatformViews.
    Get.dialog<void>(
      barrierColor: Colors.black45,
      barrierDismissible: true,
      useSafeArea: false,
      Builder(
        builder: (dialogContext) {
          _dialogContext = dialogContext;
          return _VipEntranceView(
            userName: name,
            avatarUrl: avatar,
            vipFrameUrl: frame,
            pattiStyle: patti,
            soundUrl: soundUrl,
            displayFor: displayFor,
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
    return true;
  }

  static void dismiss() {
    final dialogContext = _dialogContext;
    _dialogContext = null;
    try {
      if (dialogContext != null &&
          dialogContext.mounted &&
          Navigator.of(dialogContext).canPop()) {
        Navigator.of(dialogContext).pop();
      }
    } catch (_) {}
  }

  /// Title-case a backend style slug (`golden` → `Golden`).
  static String formatPattiLabel(String? style) {
    final raw = style?.trim() ?? '';
    if (raw.isEmpty) return '';
    final parts = raw
        .split(RegExp(r'[_\s-]+'))
        .where((p) => p.isNotEmpty)
        .map((p) => '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
        .toList();
    return parts.join(' ');
  }
}

class _VipEntranceView extends StatefulWidget {
  const _VipEntranceView({
    required this.userName,
    required this.onCompleted,
    required this.displayFor,
    this.avatarUrl,
    this.vipFrameUrl,
    this.pattiStyle = '',
    this.soundUrl,
  });

  final String userName;
  final String? avatarUrl;
  final String? vipFrameUrl;
  final String pattiStyle;
  final String? soundUrl;
  final Duration displayFor;
  final VoidCallback onCompleted;

  @override
  State<_VipEntranceView> createState() => _VipEntranceViewState();
}

class _VipEntranceViewState extends State<_VipEntranceView>
    with TickerProviderStateMixin {
  late final AnimationController _fade;
  Timer? _timer;
  SVGAAnimationController? _svgaController;
  GiftSoundPlayer? _sound;
  bool _svgaReady = false;
  bool _isLoading = false;

  bool get _hasVipFrame {
    final url = widget.vipFrameUrl?.trim() ?? '';
    return url.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    )..forward();
    if (_hasVipFrame) {
      _isLoading = true;
      unawaited(_loadSvga());
    } else {
      // Patti-only: no SVGA — start dismiss clock immediately.
      _scheduleDismiss();
    }
  }

  /// Start the dismiss clock only after media is ready (or failed) — gifts do this.
  void _scheduleDismiss() {
    _timer?.cancel();
    _timer = Timer(widget.displayFor, () {
      if (!mounted) return;
      _fade.reverse().whenComplete(widget.onCompleted);
    });
  }

  Future<void> _loadSvga() async {
    final raw = widget.vipFrameUrl?.trim() ?? '';
    final url = ApiImageUtils.normalize(raw)?.trim() ?? raw;
    final controller = SVGAAnimationController(vsync: this);
    _svgaController = controller;

    try {
      MovieEntity? videoItem;

      // Prefer network VIP entrance URL (any http(s) path — Cloudinary often
      // omits `.svga` in the path).
      if (url.startsWith('http://') || url.startsWith('https://')) {
        try {
          videoItem = await SvgaNetworkLoader.decode(url);
        } catch (error) {
          if (kDebugMode) {
            debugPrint('VIP entrance network SVGA failed: $error');
          }
        }
      }

      if (videoItem == null) {
        if (!mounted || _svgaController != controller) return;
        controller.dispose();
        _svgaController = null;
        setState(() {
          _svgaReady = false;
          _isLoading = false;
        });
        _scheduleDismiss();
        return;
      }

      if (!mounted || _svgaController != controller) {
        videoItem.dispose();
        return;
      }

      // Entry files carry their own mp3 (the track the admin panel plays).
      // Muting it leaves the car animation silent. A separate soundUrl is
      // only used when the file has no audio of its own.
      final movie = videoItem;
      final hasEmbeddedAudio = movie.audios.any((audio) {
        final bytes = movie.audiosData[audio.audioKey];
        return bytes != null && bytes.isNotEmpty;
      });
      if (hasEmbeddedAudio) {
        await GiftSoundPlayer.allowMixWithRoomAudio();
        if (!mounted || _svgaController != controller) {
          videoItem.dispose();
          return;
        }
      }
      controller.videoItem = videoItem;
      controller
        ..volume = 1
        ..muted = !hasEmbeddedAudio
        ..reset()
        ..repeat();
      if (!hasEmbeddedAudio) _startEntranceSound();
      setState(() {
        _svgaReady = true;
        _isLoading = false;
      });
      _scheduleDismiss();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('VIP entrance SVGA failed entirely: $error');
      }
      if (!mounted || _svgaController != controller) return;
      controller.dispose();
      _svgaController = null;
      setState(() {
        _svgaReady = false;
        _isLoading = false;
      });
      _scheduleDismiss();
    }
  }

  void _startEntranceSound() {
    final url = widget.soundUrl?.trim() ?? '';
    if (url.isEmpty) return;
    final player = GiftSoundPlayer();
    _sound = player;
    unawaited(player.play(url));
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_sound?.dispose());
    _sound = null;
    _svgaController?.dispose();
    _fade.dispose();
    super.dispose();
  }

  String get _bannerText {
    final pattiLabel = VipEntranceOverlay.formatPattiLabel(widget.pattiStyle);
    final parts = <String>[];
    if (_hasVipFrame) parts.add('VIP');
    if (pattiLabel.isNotEmpty) parts.add(pattiLabel);
    if (parts.isEmpty) parts.add('VIP');
    return '${parts.join(' · ')} · ${widget.userName} joined';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pattiLabel = VipEntranceOverlay.formatPattiLabel(widget.pattiStyle);

    return FadeTransition(
      opacity: _fade,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_svgaReady && _svgaController != null)
              Center(
                child: SizedBox(
                  width: size.width,
                  height: size.height * 0.72,
                  child: SVGAImage(
                    _svgaController!,
                    fit: BoxFit.contain,
                    preferredSize: Size(size.width, size.height * 0.72),
                    clearsAfterStop: false,
                  ),
                ),
              )
            else if (_isLoading)
              const Center(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Color(0xFFFFD700),
                  ),
                ),
              ),
            Align(
              alignment: const Alignment(0, 0.78),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Do not pass vipFrameUrl as avatar ring — it's a full entrance.
                  AppUserAvatar(
                    name: widget.userName,
                    imageUrl: widget.avatarUrl,
                    size: 72,
                  ),
                  const SizedBox(height: 12),
                  if (pattiLabel.isNotEmpty) ...[
                    _pattiBanner(pattiLabel),
                    const SizedBox(height: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.7),
                      ),
                    ),
                    child: Text(
                      _bannerText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: kColorWhite,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pattiBanner(String label) {
    final raw = widget.pattiStyle.toLowerCase();
    final colors = raw.contains('neon')
        ? const [Color(0xFF7C5CFF), Color(0xFFFF2D95), Color(0xFF5CE1FF)]
        : raw.contains('diamond') || raw.contains('crown')
        ? const [Color(0xFFF4FBFF), Color(0xFF8EC9FF), Color(0xFFE7F3FF)]
        : const [Color(0xFFFFDF00), Color(0xFFD4AF37), Color(0xFFFFF1A8)];
    final textColor = raw.contains('neon')
        ? kColorWhite
        : const Color(0xFF2A1A12);
    var title = label.trim();
    if (title.toLowerCase().endsWith(' patti')) {
      title = title.substring(0, title.length - 6).trim();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(colors: colors),
        border: Border.all(color: const Color(0xFFFFF6C8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: colors[1].withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        '$title Patti',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
