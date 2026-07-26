import 'package:flutter/material.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:qobo_one_live/utils/app_widgets/network_svga_widget.dart';

/// Profile / cover background that plays SVGA when the URL is animated,
/// otherwise shows a normal network image.
///
/// Shop/backpack return both types in the same `image` field — detect by
/// extension (`.svga` vs jpg/png/…). Parent must give a tight height so SVGA
/// and static images share the same banner size.
class ProfileBackgroundMedia extends StatelessWidget {
  const ProfileBackgroundMedia({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.showLoadingIndicator = true,
    this.svgaFallbackAsset = kProfileSvgaFallbackAsset,
  });

  /// Bundled SVGA used when the API/CDN `.svga` URL is missing (404).
  /// Render ephemeral disks often lose uploaded backgrounds after redeploy.
  static const String kProfileSvgaFallbackAsset =
      'assets/gif/profile_cover_fallback.svga';

  final String url;
  final BoxFit fit;

  /// When true, SVGA shows a spinner while bytes download/decode.
  final bool showLoadingIndicator;

  /// Optional bundled `.svga` played when [url] cannot be downloaded.
  final String? svgaFallbackAsset;

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
    final source = ApiImageUtils.normalize(url)?.trim() ?? url.trim();
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

        Widget placeholder({required IconData icon}) {
          return ColoredBox(
            color: Colors.black26,
            child: SizedBox(
              width: width,
              height: height,
              child: Center(
                child: Icon(icon, color: Colors.white54, size: 28),
              ),
            ),
          );
        }

        // Lock both media types to the parent box so layout never jumps.
        if (isSvgaUrl(source)) {
          return SizedBox(
            width: width,
            height: height,
            child: ClipRect(
              child: NetworkSvgaWidget(
                url: source,
                width: width,
                height: height,
                fit: fit,
                fallbackAsset: svgaFallbackAsset,
                fallback: placeholder(icon: Icons.broken_image_outlined),
                showLoadingIndicator: showLoadingIndicator,
                loading: showLoadingIndicator
                    ? null
                    : placeholder(icon: Icons.auto_awesome_outlined),
              ),
            ),
          );
        }

        return SizedBox(
          width: width,
          height: height,
          child: ClipRect(
            child: Image.network(
              source,
              fit: fit,
              width: width,
              height: height,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) =>
                  placeholder(icon: Icons.broken_image_outlined),
            ),
          ),
        );
      },
    );
  }
}
