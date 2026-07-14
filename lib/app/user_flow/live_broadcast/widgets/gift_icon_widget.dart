import 'package:flutter/material.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/utils/live_room_profile_utils.dart';
import 'package:qobo_one_live/utils/app_widgets/safe_network_avatar.dart';
import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';

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
  });

  final String? icon;
  final double size;
  final double emojiSize;

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
        ),
      );
    }

    return Text(raw, style: TextStyle(fontSize: emojiSize), maxLines: 1);
  }
}

/// Loads and loops a remote gift SVGA; falls back to image / emoji if needed.
class _NetworkGiftIcon extends StatefulWidget {
  const _NetworkGiftIcon({
    required this.url,
    required this.size,
    required this.emojiSize,
  });

  final String url;
  final double size;
  final double emojiSize;

  @override
  State<_NetworkGiftIcon> createState() => _NetworkGiftIconState();
}

class _NetworkGiftIconState extends State<_NetworkGiftIcon>
    with SingleTickerProviderStateMixin {
  SVGAAnimationController? _svgaController;
  bool _isLoading = true;
  bool _svgaFailed = false;

  @override
  void initState() {
    super.initState();
    _loadSvga();
  }

  @override
  void didUpdateWidget(covariant _NetworkGiftIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _svgaController?.dispose();
      _svgaController = null;
      _isLoading = true;
      _svgaFailed = false;
      _loadSvga();
    }
  }

  @override
  void dispose() {
    _svgaController?.dispose();
    super.dispose();
  }

  Future<void> _loadSvga() async {
    final controller = SVGAAnimationController(vsync: this);
    _svgaController = controller;

    try {
      final videoItem = await SVGAParser.shared.decodeFromURL(widget.url);
      if (!mounted || _svgaController != controller) {
        videoItem.dispose();
        return;
      }
      controller.videoItem = videoItem;
      controller
        ..reset()
        ..repeat();
      setState(() {
        _isLoading = false;
        _svgaFailed = false;
      });
    } catch (_) {
      // Not a valid SVGA (e.g. legacy PNG icon) — fall back to image.
      if (!mounted || _svgaController != controller) return;
      setState(() {
        _isLoading = false;
        _svgaFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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

    if (!_svgaFailed && _svgaController != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SVGAImage(
          _svgaController!,
          fit: BoxFit.contain,
          preferredSize: Size.square(widget.size),
          clearsAfterStop: false,
        ),
      );
    }

    // Fallback for static image icons still returned by older gifts.
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SafeNetworkAvatar(
        url: widget.url,
        size: widget.size,
        fit: BoxFit.contain,
        fallback: Text('🎁', style: TextStyle(fontSize: widget.emojiSize)),
      ),
    );
  }
}
