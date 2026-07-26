import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/app_widgets/network_svga_widget.dart';
import 'package:qobo_one_live/utils/app_widgets/profile_background_media.dart';

/// Full-screen VIP entrance shown when `vip_user_joined` fires in a room.
class VipEntranceOverlay {
  VipEntranceOverlay._();

  static BuildContext? _dialogContext;

  static void show({
    required String userName,
    String? avatarUrl,
    String? vipFrameUrl,
    Duration displayFor = const Duration(milliseconds: 4200),
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

    Get.dialog<void>(
      barrierColor: Colors.black54,
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

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
    _loadSvga();
    _timer = Timer(widget.displayFor, () {
      if (!mounted) return;
      _fade.reverse().whenComplete(widget.onCompleted);
    });
  }

  Future<void> _loadSvga() async {
    final url = widget.vipFrameUrl?.trim() ?? '';
    if (url.isEmpty || !ProfileBackgroundMedia.isSvgaUrl(url)) return;
    if (!url.startsWith('http')) return;

    final controller = SVGAAnimationController(vsync: this);
    _svgaController = controller;
    try {
      final item = await SVGAParser.shared.decodeFromURL(url);
      if (!mounted || _svgaController != controller) {
        item.dispose();
        return;
      }
      controller.videoItem = item;
      controller.muted = true;
      controller.repeat();
      setState(() => _svgaReady = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _svgaReady = false);
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
    final frameUrl = widget.vipFrameUrl?.trim() ?? '';

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
                  height: size.height * 0.55,
                  child: SVGAImage(
                    _svgaController!,
                    fit: BoxFit.contain,
                    clearsAfterStop: false,
                  ),
                ),
              )
            else if (frameUrl.isNotEmpty &&
                !ProfileBackgroundMedia.isSvgaUrl(frameUrl))
              Center(
                child: NetworkSvgaWidget(
                  url: frameUrl,
                  width: size.width * 0.7,
                  height: size.width * 0.7,
                  fit: BoxFit.contain,
                  showLoadingIndicator: false,
                  fallback: Image.network(
                    frameUrl,
                    width: size.width * 0.55,
                    height: size.width * 0.55,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            Align(
              alignment: const Alignment(0, 0.72),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FramedUserAvatar(
                    name: widget.userName,
                    imageUrl: widget.avatarUrl,
                    size: 72,
                    frameUrl: frameUrl.isNotEmpty ? frameUrl : null,
                    frameSeed: widget.userName,
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
