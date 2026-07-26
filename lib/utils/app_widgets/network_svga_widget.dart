import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:qobo_one_live/utils/svga_network_loader.dart';

/// Reusable SVGA player for API-driven animated assets.
///
/// Matches gift / VIP-frame SVGA lifecycle: dispose the previous controller
/// before creating a new one, then decode and [repeat]. Optional
/// [fallbackAsset] is only for non-catalog surfaces (e.g. VIP entrance).
class NetworkSvgaWidget extends StatefulWidget {
  const NetworkSvgaWidget({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    required this.fallback,
    this.fit = BoxFit.contain,
    this.loading,
    this.showLoadingIndicator = true,
    this.fallbackAsset,
    this.onRetry,
  });

  final String url;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget fallback;
  final Widget? loading;

  /// Bundled `.svga` used only when the network URL cannot be decoded.
  final String? fallbackAsset;

  /// When false, loading keeps [loading] / empty box instead of a spinner.
  final bool showLoadingIndicator;

  /// Optional tap-to-retry when load failed.
  final VoidCallback? onRetry;

  @override
  State<NetworkSvgaWidget> createState() => _NetworkSvgaWidgetState();
}

class _NetworkSvgaWidgetState extends State<NetworkSvgaWidget>
    with TickerProviderStateMixin {
  SVGAAnimationController? _controller;
  bool _isLoading = true;
  bool _hasFailed = false;
  int _loadToken = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant NetworkSvgaWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.fallbackAsset != widget.fallbackAsset) {
      _isLoading = true;
      _hasFailed = false;
      _load();
    }
  }

  @override
  void dispose() {
    _loadToken++;
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  Future<void> _load() async {
    final token = ++_loadToken;

    // Same as gift icons / avatar frames: release the old ticker first.
    // Creating a new controller before dispose crashes SingleTicker / leaks
    // tickers when the user taps "retry" while a load is in flight.
    _controller?.dispose();
    _controller = null;

    final controller = SVGAAnimationController(vsync: this);
    _controller = controller;

    try {
      final videoItem = await _decodeBestSource();
      if (!mounted || token != _loadToken || _controller != controller) {
        videoItem.dispose();
        controller.dispose();
        return;
      }

      controller.videoItem = videoItem;
      // Catalog / cover SVGAs are decorative — mute embedded audio.
      controller.muted = true;
      controller
        ..reset()
        ..repeat();
      setState(() {
        _isLoading = false;
        _hasFailed = false;
      });
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('NetworkSvgaWidget failed for ${widget.url}: $error');
        debugPrint('$stack');
      }
      if (!mounted || token != _loadToken) return;
      if (_controller == controller) {
        controller.dispose();
        _controller = null;
      }
      setState(() {
        _isLoading = false;
        _hasFailed = true;
      });
    }
  }

  Future<MovieEntity> _decodeBestSource() async {
    final url =
        ApiImageUtils.normalize(widget.url)?.trim() ?? widget.url.trim();
    if (url.startsWith('http://') || url.startsWith('https://')) {
      try {
        // SvgaNetworkLoader already tries https/http variants and never
        // caches error bodies. Do NOT fall back to the package's own
        // `decodeFromURL` here — it skips status-code checks and always
        // writes the (possibly 404 HTML) response into the shared SVGA
        // cache, which just adds noisy FormatExceptions for a URL that is
        // genuinely missing on the server.
        return await SvgaNetworkLoader.decode(url);
      } catch (error) {
        if (kDebugMode) {
          debugPrint('SVGA network decode failed, trying asset fallback: $error');
        }
      }
    }

    final asset = widget.fallbackAsset?.trim() ?? '';
    if (asset.isNotEmpty) {
      return SVGAParser.shared.decodeFromAssets(asset);
    }

    throw StateError('No playable SVGA source for $url');
  }

  void _retry() {
    setState(() {
      _isLoading = true;
      _hasFailed = false;
    });
    widget.onRetry?.call();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      if (!widget.showLoadingIndicator) {
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: widget.loading,
        );
      }
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

    if (_hasFailed || _controller == null) {
      return GestureDetector(
        onTap: _retry,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: widget.fallback,
        ),
      );
    }

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
