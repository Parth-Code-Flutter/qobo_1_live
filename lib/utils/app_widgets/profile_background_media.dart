import 'package:flutter/material.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:qobo_one_live/utils/app_widgets/network_svga_widget.dart';

/// Profile / cover background that plays SVGA when the URL is animated,
/// otherwise shows a normal network image.
///
/// Shop/backpack return both types in the same `image` field — detect by
/// extension (`.svga` vs jpg/png/…). Each URL is loaded/cached independently
/// so different backpack items never share one fallback animation.
class ProfileBackgroundMedia extends StatelessWidget {
  const ProfileBackgroundMedia({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.showLoadingIndicator = true,
    this.svgaFallbackAsset,
    this.previewImageUrl,
  });

  final String url;
  final BoxFit fit;

  /// When true, SVGA shows a spinner while bytes download/decode.
  final bool showLoadingIndicator;

  /// Optional bundled `.svga` when [url] cannot be downloaded.
  /// Prefer API/network SVGAs only — leave null in catalog surfaces.
  final String? svgaFallbackAsset;

  /// Real, item-specific static thumbnail (never `.svga`). Shown instead of
  /// the generic placeholder when the animated [url] 404s, so backpack tiles
  /// still show distinct art instead of one shared fallback animation.
  final String? previewImageUrl;

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

  Color _accentForUrl(String source) {
    final hash = source.hashCode;
    final hue = (hash % 360).abs().toDouble();
    return HSLColor.fromAHSL(1, hue, 0.45, 0.28).toColor();
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

        Widget placeholder({required IconData icon, String? label}) {
          return ColoredBox(
            color: _accentForUrl(source),
            child: SizedBox(
              width: width,
              height: height,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white70, size: 28),
                    if (label != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }

        if (isSvgaUrl(source)) {
          final preview =
              ApiImageUtils.normalize(previewImageUrl)?.trim() ?? '';
          final retryPlaceholder = placeholder(
            icon: Icons.refresh_rounded,
            label: 'Tap to retry SVGA',
          );
          // Prefer a real static thumbnail over the generic placeholder so
          // different backpack items still look distinct when the `.svga`
          // upload 404s (Render's ephemeral disk can lose uploaded files).
          final svgaFallback = (preview.isNotEmpty && !isSvgaUrl(preview))
              ? Image.network(
                  preview,
                  fit: fit,
                  width: width,
                  height: height,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => retryPlaceholder,
                )
              : retryPlaceholder;

          return SizedBox(
            width: width,
            height: height,
            child: ClipRect(
              child: NetworkSvgaWidget(
                key: ValueKey('svga_$source'),
                url: source,
                width: width,
                height: height,
                fit: fit,
                fallbackAsset: svgaFallbackAsset,
                fallback: svgaFallback,
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
              errorBuilder: (_, __, ___) => placeholder(
                icon: Icons.broken_image_outlined,
                label: 'Image unavailable',
              ),
            ),
          ),
        );
      },
    );
  }
}
