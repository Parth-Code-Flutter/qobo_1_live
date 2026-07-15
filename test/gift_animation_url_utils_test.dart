import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/utils/live_room_profile_utils.dart';

void main() {
  group('gift animation chat markers', () {
    test('stripGiftAnimMarker hides embedded gift media urls', () {
      const raw =
          '🎁 sent tree_love gift_79\n'
          '[[giftAnim:https://cdn.example.com/a.svga]]\n'
          '[[giftSound:https://cdn.example.com/a.mp3]]';
      expect(stripGiftAnimMarker(raw), '🎁 sent tree_love gift_79');
    });

    test('parseGiftAnimUrl reads https animation url', () {
      const raw =
          '🎁 sent Fireworks\n[[giftAnim:https://cdn.example.com/clip]]';
      expect(parseGiftAnimUrl(raw), 'https://cdn.example.com/clip');
    });

    test('parseGiftAnimUrl returns null when marker missing', () {
      expect(parseGiftAnimUrl('🎁 sent Fireworks'), isNull);
    });

    test('parseGiftSoundUrl reads https sound url', () {
      const raw =
          '🎁 sent Fireworks\n[[giftSound:https://cdn.example.com/gift.mp3]]';
      expect(parseGiftSoundUrl(raw), 'https://cdn.example.com/gift.mp3');
    });

    test('parseGiftSoundUrl returns null when marker missing', () {
      expect(parseGiftSoundUrl('🎁 sent Fireworks'), isNull);
    });
  });
}
