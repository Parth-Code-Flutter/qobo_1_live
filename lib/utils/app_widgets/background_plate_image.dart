import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:qobo_one_live/utils/svga_background_plate.dart';
import 'package:qobo_one_live/utils/svga_network_loader.dart';

/// Still of the largest picture inside an SVGA background.
///
/// Shop cards use this so a packed avatar-frame ring is not drawn on top of
/// the scene, and the grid does not decode every animation frame at once.
class BackgroundPlateImage extends StatefulWidget {
  const BackgroundPlateImage({
    super.key,
    required this.url,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.loading,
  });

  final String url;
  final BoxFit fit;
  final Widget fallback;
  final Widget? loading;

  @override
  State<BackgroundPlateImage> createState() => _BackgroundPlateImageState();
}

class _BackgroundPlateImageState extends State<BackgroundPlateImage> {
  Uint8List? _bytes;
  var _failed = false;
  var _token = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant BackgroundPlateImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _bytes = null;
      _failed = false;
      _load();
    }
  }

  Future<void> _load() async {
    final token = ++_token;
    final downloaded = await SvgaNetworkLoader.downloadBytes(widget.url);
    if (!mounted || token != _token) return;
    if (downloaded == null) {
      setState(() => _failed = true);
      return;
    }
    final plate = await compute(largestEmbeddedBitmap, downloaded);
    if (!mounted || token != _token) return;
    if (plate == null || plate.isEmpty) {
      setState(() => _failed = true);
      return;
    }
    setState(() {
      _bytes = plate;
      _failed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: widget.fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => widget.fallback,
      );
    }
    if (_failed) return widget.fallback;
    return widget.loading ??
        const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 1.8),
          ),
        );
  }
}
