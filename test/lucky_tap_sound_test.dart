import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/services/gifts/lucky_tap_sound.dart';

void main() {
  test('every lucky gift resolves to a bundled tune', () {
    final named = {
      'Golden Crown': 'magic_spell_02.mp3',
      'Royal Gift': 'magic_spell_02.mp3',
      'Golden Hookah': 'magical_whoosh.mp3',
      'Lucky Gift Blue Box': 'bonus_earned.mp3',
      'Lucky Chest': 'treasure_success.mp3',
    };
    for (final entry in named.entries) {
      final path = LuckyTapSound.assetFor(entry.key, 0);
      expect(path, endsWith(entry.value));
      expect(File(path).lengthSync(), greaterThan(1000));
    }
    final heard = <String>{};
    for (var i = 0; i < 7; i++) {
      final path = LuckyTapSound.assetFor(String.fromCharCode(65 + i), i);
      heard.add(path);
      expect(File(path).existsSync(), isTrue);
    }
    expect(heard.length, 4);
    expect(LuckyTapSound.assetFor('Mystery Gift', 2), endsWith('bonus_earned.mp3'));
    expect(LuckyTapSound.assetFor('Gift B', 9), endsWith('magic_spell_02.mp3'));
    expect(LuckyTapSound.assetFor('Gift C', 0), endsWith('magical_whoosh.mp3'));
  });
}
