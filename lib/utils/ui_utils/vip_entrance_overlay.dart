import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/app_widgets/profile_background_media.dart';
import 'package:qobo_one_live/utils/svga_network_loader.dart';

/// Full-screen VIP entrance (gift-style) when a VIP joins audio/video/live.
class VipEntranceOverlay {
  VipEntranceOverlay._();

  static BuildContext? _dialogContext;

  static void show({
    required String userName,
    String? avatarUrl,
    String? vipFrameUrl,
    Duration displayFor = const Duration(milliseconds: 5200),
  }) {
    dismiss();

    final name = userName.trim().isNotEmpty ? userName.trim() : 'VIP Member';
    final frame =
        ApiImageUtils.normalize(vipFrameUrl?.trim()) ?? vipFrameUrl?.trim() ?? '';
    final avatar =
        ApiImageUtils.normalize(avatarUrl?.trim()) ?? avatarUrl?.trim();

    BuildContext? navigatorContext;
    try {
      navigatorContext = Get.context ?? Get.key.currentContext;
    } catch (_) {
      navigatorContext = null;
    }
    if (navigatorContext == null) return;

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
}

class _VipEntranceView extends StatefulWidget {
  const _VipEntranceView({
    required this.userName,
    required this.onCompleted,
    required this.displayFor,
    this.avatarUrl,
    this.vipFrameUrl,
  });

  final String userName;
  final String? avatarUrl;
  final String? vipFrameUrl;
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
  bool _svgaReady = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    )..forward();
    unawaited(_loadSvga());
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

      // Bundled fallback when Render/CDN upload is missing (common 404).
      videoItem ??= await SVGAParser.shared.decodeFromAssets(
        ProfileBackgroundMedia.kProfileSvgaFallbackAsset,
      );

      if (!mounted || _svgaController != controller) {
        videoItem.dispose();
        return;
      }

      controller.videoItem = videoItem;
      controller.muted = true;
      controller
        ..reset()
        ..repeat();
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

  @override
  void dispose() {
    _timer?.cancel();
    _svgaController?.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

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
                      'VIP · ${widget.userName} joined',
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
}
