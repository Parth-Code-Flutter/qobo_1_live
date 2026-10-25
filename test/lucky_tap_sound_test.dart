import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/services/gifts/lucky_tap_sound.dart';

void main() {
  test('seven gifts have stable distinct bundled WAV sounds', () {
    final paths = <String>{};
    for (var i = 0; i < 7; i++) {
      final name = String.fromCharCode(65 + i);
      final path = LuckyTapSound.assetFor(name, 6 - i);
      paths.add(path);
      final bytes = File(path).readAsBytesSync();
      expect(String.fromCharCodes(bytes.take(4)), 'RIFF');
      expect(bytes.length, greaterThan(100));
    }
    expect(paths.length, 7);
  });
}
