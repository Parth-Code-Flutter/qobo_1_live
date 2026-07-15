import 'package:flutter/material.dart';
import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';

/// Reusable network SVGA player for API-driven animated assets.
///
/// The clip loops automatically. If download or SVGA decoding fails, [fallback]
/// is rendered so callers can safely support older PNG/SVG responses.
class NetworkSvgaWidget extends StatefulWidget {
  const NetworkSvgaWidget({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    required this.fallback,
    this.fit = BoxFit.contain,
    this.loading,
  });

  final String url;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget fallback;
  final Widget? loading;

  @override
  State<NetworkSvgaWidget> createState() => _NetworkSvgaWidgetState();
}

class _NetworkSvgaWidgetState extends State<NetworkSvgaWidget>
    with SingleTickerProviderStateMixin {
  SVGAAnimationController? _controller;
  bool _isLoading = true;
  bool _hasFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant NetworkSvgaWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _controller?.dispose();
      _controller = null;
      _isLoading = true;
      _hasFailed = false;
      _load();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final url = widget.url.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasFailed = true;
        });
      }
      return;
    }

    final controller = SVGAAnimationController(vsync: this);
    _controller = controller;

    try {
      final videoItem = await SVGAParser.shared.decodeFromURL(url);
      if (!mounted || _controller != controller) {
        videoItem.dispose();
        return;
      }

      controller.videoItem = videoItem;
      controller
        ..reset()
        ..repeat();
      setState(() {
        _isLoading = false;
        _hasFailed = false;
      });
    } catch (_) {
      // Older frame records may still contain SVG/PNG URLs.
      if (!mounted || _controller != controller) return;
      setState(() {
        _isLoading = false;
        _hasFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child:
            widget.loading ??
            const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 1.8),
              ),
            ),
      );
    }

    if (_hasFailed || _controller == null) return widget.fallback;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: SVGAImage(
        _controller!,
        fit: widget.fit,
        preferredSize: Size(widget.width, widget.height),
        clearsAfterStop: false,
      ),
    );
  }
}
