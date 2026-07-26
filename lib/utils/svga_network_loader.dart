import 'dart:typed_data';

import 'package:flutter_svga/flutter_svga.dart';
import 'package:http/http.dart' as http;
import 'package:qobo_one_live/utils/api_image_utils.dart';

/// Safe network SVGA decode that avoids [SVGAParser.decodeFromURL] cache poison.
///
/// Upstream `decodeFromURL` stores every HTTP body (including 404 HTML) in
/// [SVGACache]. Later loads then keep failing even after the real file is fixed.
class SvgaNetworkLoader {
  const SvgaNetworkLoader._();

  /// Downloads + decodes [url], only caching successful SVGA payloads.
  static Future<MovieEntity> decode(String url) async {
    final candidates = <String>[];
    final normalized =
        ApiImageUtils.normalize(url)?.trim() ?? url.trim();
    final raw = url.trim();
    if (normalized.isNotEmpty) candidates.add(normalized);
    if (raw.isNotEmpty && raw != normalized) candidates.add(raw);

    Object? lastError;
    for (final candidate in candidates) {
      try {
        return await _decodeSingle(candidate);
      } catch (error) {
        lastError = error;
      }
    }
    throw lastError ?? StateError('SVGA decode failed for $url');
  }

  static Future<MovieEntity> _decodeSingle(String normalized) async {
    if (normalized.isEmpty) {
      throw ArgumentError('SVGA url is empty');
    }
    if (!normalized.startsWith('http://') &&
        !normalized.startsWith('https://')) {
      throw ArgumentError('SVGA url must be http(s): $normalized');
    }

    // Drop poisoned error bodies (404 HTML) cached by flutter_svga.
    final cached = await SVGACache.shared.getRawBytes(normalized);
    if (cached != null) {
      if (_looksLikeSvga(cached)) {
        try {
          return await SVGAParser.shared.decodeFromBuffer(cached);
        } catch (_) {
          await SVGACache.shared.remove(normalized);
        }
      } else {
        await SVGACache.shared.remove(normalized);
      }
    }

    final response = await http
        .get(Uri.parse(normalized))
        .timeout(const Duration(seconds: 45));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'SVGA download failed (${response.statusCode}) for $normalized',
      );
    }

    final bytes = Uint8List.fromList(response.bodyBytes);
    if (!_looksLikeSvga(bytes)) {
      throw StateError('Response is not a valid SVGA file: $normalized');
    }

    await SVGACache.shared.putRawBytes(normalized, bytes);
    return SVGAParser.shared.decodeFromBuffer(bytes);
  }

  /// Prefetch without throwing — used by cover sheet / shop grids.
  static Future<void> prefetch(String url) async {
    try {
      final item = await decode(url);
      item.dispose();
    } catch (_) {}
  }

  /// Prefetch a bundled `.svga` used when CDN uploads are missing.
  static Future<void> prefetchAsset(String assetPath) async {
    final path = assetPath.trim();
    if (path.isEmpty) return;
    try {
      final item = await SVGAParser.shared.decodeFromAssets(path);
      item.dispose();
    } catch (_) {}
  }

  static bool _looksLikeSvga(Uint8List bytes) {
    if (bytes.length < 8) return false;

    // Reject HTML / JSON error pages that flutter_svga used to cache.
    final head = String.fromCharCodes(
      bytes.take(bytes.length < 64 ? bytes.length : 64),
    ).trimLeft().toLowerCase();
    if (head.startsWith('<!doctype') ||
        head.startsWith('<html') ||
        head.startsWith('<head') ||
        head.startsWith('{') ||
        head.startsWith('cannot get')) {
      return false;
    }

    // Standard SVGA containers are zlib-compressed (CMF = 0x78).
    return bytes[0] == 0x78;
  }
}
