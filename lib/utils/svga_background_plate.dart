import 'dart:io';
import 'dart:typed_data';

/// Picks the background plate out of an SVGA file.
///
/// Profile-background uploads often pack a full-screen scene and a small
/// avatar-frame ring in the same file. The largest bitmap is the scene.
Uint8List? largestEmbeddedBitmap(Uint8List bytes) {
  if (bytes.length < 8) return null;
  final inflated = _inflate(bytes) ?? bytes;
  _BitmapHit? best;
  best = _keepLargest(best, _largestPng(inflated));
  best = _keepLargest(best, _largestJpeg(inflated));
  return best?.bytes;
}

Uint8List? _inflate(Uint8List bytes) {
  if (bytes[0] != 0x78) return null;
  try {
    return Uint8List.fromList(zlib.decode(bytes));
  } catch (_) {
    return null;
  }
}

_BitmapHit? _keepLargest(_BitmapHit? current, _BitmapHit? next) {
  if (next == null) return current;
  if (current == null || next.area > current.area) return next;
  return current;
}

_BitmapHit? _largestPng(Uint8List bytes) {
  const sig = <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
  _BitmapHit? best;
  var from = 0;
  while (from < bytes.length) {
    final start = _indexOf(bytes, sig, from);
    if (start < 0 || start + 24 > bytes.length) break;
    final width = _u32(bytes, start + 16);
    final height = _u32(bytes, start + 20);
    final end = _pngEnd(bytes, start);
    if (width > 0 && height > 0 && end > start) {
      final hit = _BitmapHit(
        area: width * height,
        bytes: Uint8List.fromList(bytes.sublist(start, end)),
      );
      best = _keepLargest(best, hit);
      from = end;
    } else {
      from = start + sig.length;
    }
  }
  return best;
}

int _pngEnd(Uint8List bytes, int start) {
  const iend = <int>[0x49, 0x45, 0x4E, 0x44];
  final at = _indexOf(bytes, iend, start + 8);
  if (at < 0) return -1;
  final end = at + 8;
  if (end > bytes.length) return -1;
  return end;
}

_BitmapHit? _largestJpeg(Uint8List bytes) {
  _BitmapHit? best;
  var from = 0;
  while (from + 4 < bytes.length) {
    final start = _indexOf(bytes, const [0xFF, 0xD8], from);
    if (start < 0) break;
    final size = _jpegSize(bytes, start);
    final end = _jpegEnd(bytes, start + 2);
    if (size != null && end > start) {
      best = _keepLargest(
        best,
        _BitmapHit(
          area: size.$1 * size.$2,
          bytes: Uint8List.fromList(bytes.sublist(start, end)),
        ),
      );
      from = end;
    } else {
      from = start + 2;
    }
  }
  return best;
}

(int, int)? _jpegSize(Uint8List bytes, int start) {
  var i = start + 2;
  while (i + 8 < bytes.length) {
    if (bytes[i] != 0xFF) {
      i++;
      continue;
    }
    final marker = bytes[i + 1];
    if (marker == 0xC0 || marker == 0xC2) {
      final height = _u16(bytes, i + 5);
      final width = _u16(bytes, i + 7);
      if (width <= 0 || height <= 0) return null;
      return (width, height);
    }
    if (marker == 0xD8 || marker == 0xD9 || marker == 0x01) {
      i += 2;
      continue;
    }
    if (i + 3 >= bytes.length) return null;
    final length = _u16(bytes, i + 2);
    if (length < 2) return null;
    i += 2 + length;
  }
  return null;
}

int _jpegEnd(Uint8List bytes, int from) {
  final at = _indexOf(bytes, const [0xFF, 0xD9], from);
  if (at < 0) return -1;
  return at + 2;
}

int _indexOf(Uint8List bytes, List<int> needle, int from) {
  if (needle.isEmpty || from < 0) return -1;
  final last = bytes.length - needle.length;
  for (var i = from; i <= last; i++) {
    var matched = true;
    for (var j = 0; j < needle.length; j++) {
      if (bytes[i + j] != needle[j]) {
        matched = false;
        break;
      }
    }
    if (matched) return i;
  }
  return -1;
}

int _u32(Uint8List bytes, int offset) {
  return (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
}

int _u16(Uint8List bytes, int offset) {
  return (bytes[offset] << 8) | bytes[offset + 1];
}

class _BitmapHit {
  const _BitmapHit({required this.area, required this.bytes});

  final int area;
  final Uint8List bytes;
}
