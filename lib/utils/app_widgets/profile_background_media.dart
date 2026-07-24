import 'package:flutter/material.dart';
import 'package:qobo_one_live/utils/app_widgets/network_svga_widget.dart';

/// Profile / cover background that plays SVGA when the URL is animated,
/// otherwise shows a normal network image.
///
/// Only `.svga` URLs use the SVGA player (avoids slow failed decodes on
/// extensionless image CDNs). Parent must give a tight height so SVGA and
/// static images share the same banner size.
class ProfileBackgroundMedia extends StatelessWidget {
  const ProfileBackgroundMedia({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.showLoadingIndicator = false,
  });

  final String url;
  final BoxFit fit;

  /// Cover banners stay quiet while SVGA bytes load (use sheet spinner only).
  final bool showLoadingIndicator;

  static bool isKnownStaticMedia(String value) {
    final path = _pathOf(value);
    return path.endsWith('.svg') ||
        path.endsWith('.png') ||
        path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.webp') ||
        path.endsWith('.gif');
  }

  static bool isSvgaUrl(String value) => _pathOf(value).endsWith('.svga');

  static String _pathOf(String value) {
    final uri = Uri.tryParse(value.trim());
    final path = (uri?.path.isNotEmpty == true ? uri!.path : value).trim();
    return path.toLowerCase().split('?').first;
  }

  @override
  Widget build(BuildContext context) {
    final source = url.trim();
    if (source.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final height =
            constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : 150.0;

        final image = Image.network(
          source,
          fit: fit,
          width: width,
          height: height,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => ColoredBox(
            color: Colors.black26,
            child: SizedBox(width: width, height: height),
          ),
        );

        // Lock both media types to the parent box so layout never jumps.
        final child = isSvgaUrl(source)
            ? NetworkSvgaWidget(
                url: source,
                width: width,
                height: height,
                fit: fit,
                fallback: image,
                showLoadingIndicator: showLoadingIndicator,
                loading: showLoadingIndicator
                    ? null
                    : ColoredBox(
                        color: Colors.black26,
                        child: SizedBox(width: width, height: height),
                      ),
              )
            : image;

        return SizedBox(
          width: width,
          height: height,
          child: ClipRect(child: child),
        );
      },
    );
  }
}
