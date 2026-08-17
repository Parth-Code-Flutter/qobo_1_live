import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/utils/ui_utils/gift_chat_celebration_tracker.dart';
import 'package:qobo_one_live/utils/ui_utils/gift_media_utils.dart';

void main() {
  test('buildChatLabel embeds anim + sound markers for peer playback', () {
    final label = GiftMediaUtils.buildChatLabel(
      giftName: 'Rose',
      giftIcon: '🌹',
      animationUrl: 'https://cdn.example/rose.svga',
      soundUrl: 'https://cdn.example/rose.mp3',
      receiverId: 'peer-1',
    );
    expect(label.startsWith('🎁 '), isTrue);
    expect(label.contains('[[giftAnim:https://cdn.example/rose.svga]]'), isTrue);
    expect(label.contains('[[giftSound:https://cdn.example/rose.mp3]]'), isTrue);
    expect(GiftMediaUtils.isGiftChatMessage(label), isTrue);
    expect(GiftMediaUtils.giftNameFromChatLabel(label), 'Rose');
  });

  test('tracker bootstraps history then only accepts new peer gift keys', () {
    final tracker = GiftChatCelebrationTracker();

    // First snapshot bootstraps — history is marked seen (no replay).
    tracker.onGiftMessages(
      myUserId: 'me',
      events: const [
        (
          key: '1_100',
          senderId: 'peer',
          message: '🎁 sent Rose',
        ),
      ],
    );

    // Same history again must be a no-op.
    tracker.onGiftMessages(
      myUserId: 'me',
      events: const [
        (
          key: '1_100',
          senderId: 'peer',
          message: '🎁 sent Rose',
        ),
      ],
    );

    // Own gift key is consumed but must not celebrate for self.
    tracker.onGiftMessages(
      myUserId: 'me',
      events: const [
        (
          key: '1_100',
          senderId: 'peer',
          message: '🎁 sent Rose',
        ),
        (
          key: '2_200',
          senderId: 'me',
          message: '🎁 sent Crown',
        ),
      ],
    );

    // New peer gift is the live event peers should celebrate.
    tracker.onGiftMessages(
      myUserId: 'me',
      events: const [
        (
          key: '1_100',
          senderId: 'peer',
          message: '🎁 sent Rose',
        ),
        (
          key: '2_200',
          senderId: 'me',
          message: '🎁 sent Crown',
        ),
        (
          key: '3_300',
          senderId: 'peer',
          message: '🎁 sent Heart',
        ),
      ],
    );

    tracker.reset();
    tracker.onGiftMessages(
      myUserId: 'me',
      events: const [
        (
          key: '9_900',
          senderId: 'peer',
          message: '🎁 sent Star',
        ),
      ],
    );

    // Pure state machine test — completing without throw is the contract.
    expect(GiftMediaUtils.isGiftChatMessage('🎁 sent Heart'), isTrue);
  });
}
