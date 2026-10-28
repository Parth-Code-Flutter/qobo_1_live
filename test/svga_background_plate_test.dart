import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/utils/svga_background_plate.dart';

void main() {
  test('largest embedded bitmap is the background, not the frame ring', () {
    final ring = _png(width: 161, height: 161);
    final background = _png(width: 750, height: 1666);
    final packed = Uint8List.fromList(<int>[...ring, ...background]);
    final compressed = Uint8List.fromList(zlib.encode(packed));

    final plate = largestEmbeddedBitmap(compressed);

    expect(plate, isNotNull);
    expect(plate!.length, background.length);
    expect(_pngSize(plate), (750, 1666));
  });
}

Uint8List _png({required int width, required int height}) {
  final bytes = BytesBuilder();
  bytes.add(const <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  bytes.add(_u32(13));
  bytes.add('IHDR'.codeUnits);
  bytes.add(_u32(width));
  bytes.add(_u32(height));
  bytes.add(const <int>[8, 2, 0, 0, 0]);
  bytes.add(_u32(0));
  bytes.add(_u32(0));
  bytes.add('IEND'.codeUnits);
  bytes.add(_u32(0));
  return bytes.toBytes();
}

(int, int) _pngSize(Uint8List bytes) {
  final width = (bytes[16] << 24) |
      (bytes[17] << 16) |
      (bytes[18] << 8) |
      bytes[19];
  final height = (bytes[20] << 24) |
      (bytes[21] << 16) |
      (bytes[22] << 8) |
      bytes[23];
  return (width, height);
}

List<int> _u32(int value) {
  return <int>[
    (value >> 24) & 0xFF,
    (value >> 16) & 0xFF,
    (value >> 8) & 0xFF,
    value & 0xFF,
  ];
}
