import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:qobo_one_live/utils/svga_network_loader.dart';

/// Saves each emoji GIF (or image) once, so panels and seat reactions
/// open from disk instead of downloading again.
class EmojiFileStore {
  EmojiFileStore._();

  static final _paths = <String, String>{};
  static final _waiters = <String, Completer<String?>>{};
  static final _high = Queue<String>();
  static final _low = Queue<String>();
  static final _queued = <String>{};
  static var _workers = 0;
  static Directory? _dir;

  /// Tiles on screen. These are saved before the background list.
  static Future<String?> ensure(String url) {
    final key = cacheKey(url);
    if (!key.startsWith('http://') && !key.startsWith('https://')) {
      return Future.value(null);
    }
    final known = _paths[key];
    if (known != null) return Future.value(known);
    final waiter = _waiters.putIfAbsent(key, () => Completer<String?>());
    _enqueue(key, high: true);
    unawaited(_pump());
    return waiter.future;
  }

  /// Background pass after the emoji list is saved.
  static void warm(Iterable<String> urls) {
    for (final url in urls) {
      final key = cacheKey(url);
      if (!key.startsWith('http://') && !key.startsWith('https://')) continue;
      if (_paths.containsKey(key)) continue;
      _enqueue(key, high: false);
    }
    unawaited(_pump());
  }

  /// Seat reactions append `emoji_playback` so a GIF can replay.
  /// The file on disk is the same GIF, so that query is ignored here.
  static String cacheKey(String url) {
    final raw = url.trim();
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme) return raw;
    if (!uri.queryParameters.containsKey('emoji_playback')) return raw;
    final params = Map<String, String>.from(uri.queryParameters)
      ..remove('emoji_playback');
    final cleaned = uri.replace(queryParameters: params).toString();
    return cleaned.endsWith('?')
        ? cleaned.substring(0, cleaned.length - 1)
        : cleaned;
  }

  static void _enqueue(String url, {required bool high}) {
    if (_paths.containsKey(url)) return;
    if (_queued.contains(url)) {
      if (high && _low.remove(url)) _high.addFirst(url);
      return;
    }
    _queued.add(url);
    if (high) {
      _high.addFirst(url);
    } else {
      _low.add(url);
    }
  }

  static Future<void> _pump() async {
    while (_workers < 2 && (_high.isNotEmpty || _low.isNotEmpty)) {
      _workers++;
      unawaited(_worker());
    }
  }

  static Future<void> _worker() async {
    try {
      while (_high.isNotEmpty || _low.isNotEmpty) {
        final url = _high.isNotEmpty ? _high.removeFirst() : _low.removeFirst();
        final path = await _build(url);
        if (path != null) {
          _paths[url] = path;
        } else {
          _queued.remove(url);
        }
        final waiter = _waiters.remove(url);
        if (waiter != null && !waiter.isCompleted) waiter.complete(path);
      }
    } finally {
      _workers--;
      if (_high.isNotEmpty || _low.isNotEmpty) unawaited(_pump());
    }
  }

  static Future<String?> _build(String url) async {
    try {
      final file = await _fileFor(url);
      if (await file.exists() && await file.length() > 32) return file.path;

      final bytes = await SvgaNetworkLoader.downloadBytes(url);
      if (bytes == null || bytes.isEmpty) return null;

      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  static Future<File> _fileFor(String url) async {
    final dir = _dir ??= Directory(
      '${(await getApplicationSupportDirectory()).path}/emoji_files',
    );
    return File('${dir.path}/${stableDiskKey(url)}${_extension(url)}');
  }

  static String _extension(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
    if (path.endsWith('.gif')) return '.gif';
    if (path.endsWith('.png')) return '.png';
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return '.jpg';
    if (path.endsWith('.webp')) return '.webp';
    if (path.endsWith('.svg')) return '.svg';
    return '.img';
  }
}
