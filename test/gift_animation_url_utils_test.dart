import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/utils/live_room_profile_utils.dart';
import 'package:qobo_one_live/utils/ui_utils/gift_media_utils.dart';
import 'package:qobo_one_live/utils/ui_utils/gift_sound_player.dart';

void main() {
  group('GiftMediaUtils', () {
    test('mapGiftFromApi keeps animation and sound urls', () {
      final gift = GiftMediaUtils.mapGiftFromApi({
        'id': 'g1',
        'name': 'Fireworks',
        'price': 100,
        'animationUrl': 'https://cdn.example.com/a.svga',
        'soundUrl': 'https://cdn.example.com/a.mp3',
      });
      expect(gift['id'], 'g1');
      expect(gift['animationUrl'], 'https://cdn.example.com/a.svga');
      expect(gift['soundUrl'], 'https://cdn.example.com/a.mp3');
    });

    test('buildChatLabel embeds media markers for peers', () {
      final label = GiftMediaUtils.buildChatLabel(
        giftName: 'Fireworks',
        giftIcon: '🎆',
        animationUrl: 'https://cdn.example.com/a.svga',
        soundUrl: 'https://cdn.example.com/a.mp3',
      );
      expect(label, startsWith('🎁 sent Fireworks'));
      expect(parseGiftAnimUrl(label), 'https://cdn.example.com/a.svga');
      expect(parseGiftSoundUrl(label), 'https://cdn.example.com/a.mp3');
      expect(stripGiftAnimMarker(label), isNot(contains('giftAnim')));
    });

    test('isGiftChatMessage detects gift payloads', () {
      expect(GiftMediaUtils.isGiftChatMessage('🎁 sent Rose'), isTrue);
      expect(GiftMediaUtils.isGiftChatMessage('hello'), isFalse);
    });
  });

  group('gift sound url resolution', () {
    test('resolvePlayableUrl accepts https urls', () {
      expect(
        GiftSoundPlayer.resolvePlayableUrl('https://cdn.example.com/gift.mp3'),
        'https://cdn.example.com/gift.mp3',
      );
    });

    test('resolvePlayableUrl normalizes relative api paths', () {
      final resolved = GiftSoundPlayer.resolvePlayableUrl('/uploads/gift.mp3');
      expect(resolved, isNotNull);
      expect(resolved!.startsWith('https://'), isTrue);
      expect(resolved.endsWith('/uploads/gift.mp3'), isTrue);
    });

    test('resolvePlayableUrl returns null for empty values', () {
      expect(GiftSoundPlayer.resolvePlayableUrl(null), isNull);
      expect(GiftSoundPlayer.resolvePlayableUrl(''), isNull);
    });
  });

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
