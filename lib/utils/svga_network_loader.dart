import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/services/header_data.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';

/// Production SVGA loader for profile covers / VIP entrances.
///
/// - Tries https + http variants of API upload URLs
/// - Sends Bearer token for same-host uploads (some hosts gate `/uploads`)
/// - Rejects / purges HTML 404 bodies that poison flutter_svga's cache
/// - Persists successful downloads under app support so covers keep playing
///   after Render redeploys wipe ephemeral disk
/// - Never calls [SVGAParser.decodeFromURL] (it caches every HTTP body)
class SvgaNetworkLoader {
  const SvgaNetworkLoader._();

  static Directory? _diskCacheDir;

  /// Downloads + decodes [url], only caching successful SVGA payloads.
  static Future<MovieEntity> decode(String url) async {
    final candidates = _candidateUrls(url);
    Object? lastError;

    for (final candidate in candidates) {
      try {
        return await _decodeSingle(candidate);
      } catch (error) {
        lastError = error;
        if (kDebugMode) {
          debugPrint('SvgaNetworkLoader candidate failed ($candidate): $error');
        }
      }
    }

    throw lastError ?? StateError('SVGA decode failed for $url');
  }

  static List<String> _candidateUrls(String url) {
    final raw = url.trim();
    final normalized = ApiImageUtils.normalize(raw)?.trim() ?? raw;
    final out = <String>[];

    void add(String value) {
      final v = value.trim();
      if (v.isEmpty) return;
      if (!out.contains(v)) out.add(v);
    }

    add(normalized);
    add(raw);

    // Always try both schemes for the API host (ATS + cleartext setups differ).
    for (final base in [normalized, raw]) {
      if (base.startsWith('https://')) {
        add(base.replaceFirst('https://', 'http://'));
      } else if (base.startsWith('http://')) {
        add(base.replaceFirst('http://', 'https://'));
      }
    }
    return out;
  }

  static Future<MovieEntity> _decodeSingle(String sourceUrl) async {
    if (sourceUrl.isEmpty) {
      throw ArgumentError('SVGA url is empty');
    }
    if (!sourceUrl.startsWith('http://') &&
        !sourceUrl.startsWith('https://')) {
      throw ArgumentError('SVGA url must be http(s): $sourceUrl');
    }

    // 1) Durable app-support cache (survives flutter_svga temp cache clears).
    final diskBytes = await _readDiskCache(sourceUrl);
    if (diskBytes != null) {
      try {
        return await SVGAParser.shared.decodeFromBuffer(diskBytes);
      } catch (_) {
        await _removeDiskCache(sourceUrl);
      }
    }

    // 2) flutter_svga temp cache — only if bytes look like SVGA.
    final cached = await SVGACache.shared.getRawBytes(sourceUrl);
    if (cached != null) {
      if (!_looksLikeSvga(cached)) {
        await SVGACache.shared.remove(sourceUrl);
      } else {
        try {
          final item = await SVGAParser.shared.decodeFromBuffer(cached);
          await _writeDiskCache(sourceUrl, cached);
          return item;
        } catch (_) {
          await SVGACache.shared.remove(sourceUrl);
        }
      }
    }

    // 3) Network download (auth for API host). Never use decodeFromURL —
    // it stores 404 HTML into SVGACache and causes FormatException loops.
    final bytes = await _downloadBytes(sourceUrl);
    if (!_looksLikeSvga(bytes)) {
      await SVGACache.shared.remove(sourceUrl);
      throw StateError('SVGA response is not a valid file for $sourceUrl');
    }

    final item = await SVGAParser.shared.decodeFromBuffer(bytes);
    await SVGACache.shared.putRawBytes(sourceUrl, bytes);
    await _writeDiskCache(sourceUrl, bytes);
    return item;
  }

  static Future<Uint8List> _downloadBytes(String sourceUrl) async {
    final headers = <String, String>{
      'Accept': '*/*',
      'User-Agent': 'qobo_one_live/1.0 (Flutter)',
    };

    final apiHost = Uri.tryParse(ApiConstants.baseUrl)?.host;
    final uri = Uri.tryParse(sourceUrl);
    if (apiHost != null && uri != null && uri.host == apiHost) {
      try {
        final auth = await HeaderData().headers();
        final token = auth['Authorization'];
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = token;
        }
      } catch (_) {}
    }

    final response = await http
        .get(Uri.parse(sourceUrl), headers: headers)
        .timeout(const Duration(seconds: 60));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'SVGA download failed (${response.statusCode}) for $sourceUrl',
      );
    }
    return Uint8List.fromList(response.bodyBytes);
  }

  /// Prefetch without throwing — used by cover sheet / shop grids.
  static Future<void> prefetch(String url) async {
    try {
      final item = await decode(url);
      item.dispose();
    } catch (_) {}
  }

  static Future<void> prefetchAsset(String assetPath) async {
    final path = assetPath.trim();
    if (path.isEmpty) return;
    try {
      final item = await SVGAParser.shared.decodeFromAssets(path);
      item.dispose();
    } catch (_) {}
  }

  /// True only for zlib-compressed SVGA payloads (rejects HTML/JSON 404 bodies).
  static bool _looksLikeSvga(Uint8List bytes) {
    if (bytes.length < 8) return false;
    final head = String.fromCharCodes(
      bytes.take(bytes.length < 80 ? bytes.length : 80),
    ).trimLeft().toLowerCase();
    if (head.startsWith('<!doctype') ||
        head.startsWith('<html') ||
        head.startsWith('<head') ||
        head.startsWith('{') ||
        head.startsWith('cannot get') ||
        head.contains('<pre>cannot get')) {
      return false;
    }
    // Standard SVGA containers are zlib-compressed (CMF = 0x78).
    return bytes[0] == 0x78;
  }

  static Future<Directory> _ensureDiskCacheDir() async {
    final existing = _diskCacheDir;
    if (existing != null) return existing;
    final root = await getApplicationSupportDirectory();
    final dir = Directory('${root.path}/svga_durable_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _diskCacheDir = dir;
    return dir;
  }

  static String _cacheKey(String sourceUrl) {
    final digest = base64Url
        .encode(utf8.encode(sourceUrl))
        .replaceAll('=', '');
    // Keep filename length reasonable for mobile FS.
    return digest.length <= 80 ? digest : digest.substring(0, 80);
  }

  static Future<File> _cacheFile(String sourceUrl) async {
    final dir = await _ensureDiskCacheDir();
    return File('${dir.path}/${_cacheKey(sourceUrl)}.svga');
  }

  static Future<Uint8List?> _readDiskCache(String sourceUrl) async {
    try {
      final file = await _cacheFile(sourceUrl);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      if (!_looksLikeSvga(bytes)) {
        await file.delete();
        return null;
      }
      return bytes;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _writeDiskCache(String sourceUrl, Uint8List bytes) async {
    try {
      if (!_looksLikeSvga(bytes)) return;
      final file = await _cacheFile(sourceUrl);
      await file.writeAsBytes(bytes, flush: true);
    } catch (_) {}
  }

  static Future<void> _removeDiskCache(String sourceUrl) async {
    try {
      final file = await _cacheFile(sourceUrl);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
