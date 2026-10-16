import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/utils/live_room_profile_utils.dart';
import 'package:qobo_one_live/services/gifts/gift_icon_preview_store.dart';
import 'package:qobo_one_live/utils/app_widgets/safe_network_avatar.dart';
import 'package:qobo_one_live/utils/svga_network_loader.dart';

/// Renders a gift icon from:
/// - network SVGA / animated clip URL (`icon` from gift-list API)
/// - network static image URL (legacy PNG/JPG fallback)
/// - emoji / plain text
class GiftIconWidget extends StatelessWidget {
  const GiftIconWidget({
    super.key,
    required this.icon,
    this.size = 36,
    this.emojiSize = 28,
    this.animate = false,
  });

  final String? icon;
  final double size;
  final double emojiSize;

  /// Catalogs use cached stills. Full animations belong in celebrations.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final raw = icon?.trim() ?? '';
    if (raw.isEmpty) {
      return Text('🎁', style: TextStyle(fontSize: emojiSize));
    }

    // Gift-list `icon` is treated as a network SVGA/animated clip.
    if (isNetworkGiftIcon(raw)) {
      return SizedBox(
        width: size,
        height: size,
        child: _NetworkGiftIcon(
          url: raw,
          size: size,
          emojiSize: emojiSize,
          animate: animate,
        ),
      );
    }

    return Text(raw, style: TextStyle(fontSize: emojiSize), maxLines: 1);
  }
}

/// Uses a cached still by default. Animation is an explicit opt-in.
class _NetworkGiftIcon extends StatefulWidget {
  const _NetworkGiftIcon({
    required this.url,
    required this.size,
    required this.emojiSize,
    required this.animate,
  });

  final String url;
  final double size;
  final double emojiSize;
  final bool animate;

  @override
  State<_NetworkGiftIcon> createState() => _NetworkGiftIconState();
}

class _NetworkGiftIconState extends State<_NetworkGiftIcon>
    with SingleTickerProviderStateMixin {
  SVGAAnimationController? _svgaController;
  String? _previewPath;
  bool _isLoading = true;
  bool _svgaFailed = false;
  int _loadToken = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _NetworkGiftIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.animate != widget.animate) {
      GiftIconPreviewStore.release(oldWidget.url);
      _previewPath = null;
      _isLoading = true;
      _svgaFailed = false;
      _load();
    }
  }

  @override
  void dispose() {
    _loadToken++;
    GiftIconPreviewStore.release(widget.url);
    _svgaController?.dispose();
    _svgaController = null;
    super.dispose();
  }

  Future<void> _load() async {
    final token = ++_loadToken;
    _svgaController?.dispose();
    _svgaController = null;

    final previewFuture = GiftIconPreviewStore.ensure(widget.url);
    if (!widget.animate) {
      final path = await previewFuture;
      if (!mounted || token != _loadToken) return;
      setState(() {
        _previewPath = path;
        _isLoading = false;
        _svgaFailed = true;
      });
      return;
    }
    unawaited(
      previewFuture.then((path) {
        if (!mounted || token != _loadToken) return;
        if (_svgaController?.videoItem != null) return;
        if (path == null || path.isEmpty) return;
        setState(() => _previewPath = path);
      }),
    );

    if (_isStaticImage(widget.url)) {
      if (!mounted || token != _loadToken) return;
      setState(() {
        _isLoading = false;
        _svgaFailed = true;
      });
      return;
    }

    final controller = SVGAAnimationController(vsync: this);
    _svgaController = controller;

    try {
      final videoItem = await SvgaNetworkLoader.decode(widget.url);
      if (!mounted || token != _loadToken || _svgaController != controller) {
        videoItem.dispose();
        return;
      }
      controller.videoItem = videoItem;
      // Catalog icons are decorative — never play embedded gift SFX here.
      controller.muted = true;
      controller
        ..reset()
        ..repeat();
      if (!mounted || token != _loadToken) return;
      setState(() {
        _isLoading = false;
        _svgaFailed = false;
      });
    } catch (_) {
      if (!mounted || token != _loadToken) return;
      if (_svgaController == controller) {
        controller.dispose();
        _svgaController = null;
      }
      setState(() {
        _isLoading = false;
        _svgaFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _svgaController;
    if (!_svgaFailed && controller?.videoItem != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SVGAImage(
          controller!,
          fit: BoxFit.contain,
          preferredSize: Size.square(widget.size),
          clearsAfterStop: false,
        ),
      );
    }

    final preview = _previewPath;
    if (preview != null && preview.isNotEmpty) {
      return Image.file(
        File(preview),
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        cacheWidth: 192,
        errorBuilder: (_, __, ___) => _emoji(),
      );
    }

    if (_isLoading) {
      return Center(
        child: SizedBox(
          width: widget.size * 0.35,
          height: widget.size * 0.35,
          child: const CircularProgressIndicator(
            strokeWidth: 1.6,
            color: Colors.white54,
          ),
        ),
      );
    }

    if (!_isStaticImage(widget.url)) return _emoji();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SafeNetworkAvatar(
        url: widget.url,
        size: widget.size,
        fit: BoxFit.contain,
        fallback: _emoji(),
      ),
    );
  }

  Widget _emoji() {
    return Text('🎁', style: TextStyle(fontSize: widget.emojiSize));
  }

  bool _isStaticImage(String url) {
    final path = url.toLowerCase().split('?').first;
    return path.endsWith('.png') ||
        path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.webp') ||
        path.endsWith('.gif');
  }
}
