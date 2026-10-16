import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qobo_one_live/utils/svga_network_loader.dart';

/// Small cached still for gift grids; full SVGA playback is reserved for celebrations.
///
/// The gift list stores full SVGA animations (often several MB). This saves
/// one embedded picture without retaining an animation player for each tile.
class GiftIconPreviewStore {
  GiftIconPreviewStore._();

  static final _listeners = <String, int>{};
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
    _listeners.clear();
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
    _listeners[url] = (_listeners[url] ?? 0) + 1;
    if (_noPreview.contains(url)) return Future.value(null);
    final known = _paths[url];
    if (known != null) return Future.value(known);
    final waiter = _waiters.putIfAbsent(url, () => Completer<String?>());
    _enqueue(url, high: true);
    unawaited(_pump());
    return waiter.future;
  }

  /// Drop queued work when a tile scrolls away. An active download may finish
  /// and remain cached, but never starts playback or updates a disposed tile.
  static void release(String url) {
    final count = (_listeners[url] ?? 0) - 1;
    if (count > 0) {
      _listeners[url] = count;
      return;
    }
    _listeners.remove(url);
    final removed = _high.remove(url) || _low.remove(url);
    if (removed) {
      _queued.remove(url);
      final waiter = _waiters.remove(url);
      if (waiter != null && !waiter.isCompleted) waiter.complete(null);
    }
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

      // Store a small decoded thumbnail, not a potentially huge embedded image.
      final codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: 192,
      );
      Uint8List thumbnail;
      try {
        final frame = await codec.getNextFrame();
        try {
          final png = await frame.image.toByteData(
            format: ui.ImageByteFormat.png,
          );
          if (png == null) return null;
          thumbnail = png.buffer.asUint8List(
            png.offsetInBytes,
            png.lengthInBytes,
          );
        } finally {
          frame.image.dispose();
        }
      } finally {
        codec.dispose();
      }
      await file.parent.create(recursive: true);
      await file.writeAsBytes(thumbnail, flush: true);
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
