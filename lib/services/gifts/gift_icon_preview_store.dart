import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qobo_one_live/utils/svga_network_loader.dart';

/// Small picture for each gift, shown only until the clip starts playing.
///
/// The gift list stores full SVGA animations (often several MB). This saves
/// one embedded picture so a tile is not blank while that file is decoded.
class GiftIconPreviewStore {
  GiftIconPreviewStore._();

  static final _paths = <String, String>{};
  static final _noPreview = <String>{};
  static final _waiters = <String, Completer<String?>>{};
  static final _high = Queue<String>();
  static final _low = Queue<String>();
  static final _queued = <String>{};
  static var _workers = 0;
  static Directory? _dir;

  @visibleForTesting
  static void debugReset() {
    _paths.clear();
    _noPreview.clear();
    _waiters.clear();
    _high.clear();
    _low.clear();
    _queued.clear();
    _workers = 0;
    _dir = null;
  }

  /// Tiles that are on screen. These are built before the background list.
  static Future<String?> ensure(String url) {
    if (_noPreview.contains(url)) return Future.value(null);
    final known = _paths[url];
    if (known != null) return Future.value(known);
    final waiter = _waiters.putIfAbsent(url, () => Completer<String?>());
    _enqueue(url, high: true);
    unawaited(_pump());
    return waiter.future;
  }

  /// Background pass after the gift list is saved.
  static void warm(Iterable<String> urls) {
    for (final url in urls) {
      final value = url.trim();
      if (!value.startsWith('http://') && !value.startsWith('https://')) {
        continue;
      }
      if (_paths.containsKey(value) || _noPreview.contains(value)) continue;
      _enqueue(value, high: false);
    }
    unawaited(_pump());
  }

  static void _enqueue(String url, {required bool high}) {
    if (_paths.containsKey(url) || _noPreview.contains(url)) return;
    if (_queued.contains(url)) {
      // Still waiting in the background line — show this tile first.
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

      final Uint8List imageBytes;
      if (bytes.length > 2 && bytes[0] == 0x78) {
        final extracted = await compute(extractSvgaPreviewBytes, bytes);
        if (extracted == null || extracted.isEmpty) {
          // File arrived, but it has no embedded picture. Remember that so
          // the tile does not download the whole animation again.
          _noPreview.add(url);
          return null;
        }
        imageBytes = extracted;
      } else {
        imageBytes = bytes;
      }

      await file.parent.create(recursive: true);
      await file.writeAsBytes(imageBytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  static Future<File> _fileFor(String url) async {
    final dir = _dir ??= Directory(
      '${(await getApplicationSupportDirectory()).path}/gift_icon_previews',
    );
    return File('${dir.path}/${stableDiskKey(url)}.bin');
  }
}

/// Pulls the largest embedded picture out of an SVGA without starting playback.
Uint8List? extractSvgaPreviewBytes(Uint8List svgaBytes) {
  try {
    final inflated = ZLibCodec().decode(svgaBytes);
    final movie = MovieEntity.fromBuffer(inflated);
    Uint8List? best;
    for (final value in movie.images.values) {
      final data = Uint8List.fromList(value);
      if (data.length >= 3 && String.fromCharCodes(data.take(3)) == 'ID3') {
        continue;
      }
      if (best == null || data.length > best.length) best = data;
    }
    return best;
  } catch (_) {
    return null;
  }
}
