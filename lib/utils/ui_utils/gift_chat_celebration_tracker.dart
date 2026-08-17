import 'package:qobo_one_live/utils/ui_utils/gift_media_utils.dart';

/// One gift chat line that may trigger a peer celebration.
typedef GiftChatEvent = ({String key, String senderId, String message});

/// Shared peer-gift celebration logic for audio/video rooms, live streams, and calls.
///
/// Protocol (same everywhere):
/// 1. Sender celebrates locally after `POST /api/economy/send-gift` succeeds.
/// 2. Sender broadcasts a Zego in-room chat line with `[[giftAnim:]]` / `[[giftSound:]]`.
/// 3. Peers receive that line and call [onGiftMessages] → play the same SVGA/sound.
///
/// Bootstrap skips history so joining mid-room does not replay old gifts.
class GiftChatCelebrationTracker {
  final Set<String> _seenKeys = <String>{};
  bool _bootstrapDone = false;
  String? _lastCelebratedKey;

  /// Handles a full gift-message snapshot from the Zego in-room message bus.
  void onGiftMessages({
    required Iterable<GiftChatEvent> events,
    required String myUserId,
    void Function(GiftChatEvent event)? onPeerGift,
    List<Map<String, String>> giftCatalog = const [],
  }) {
    final gifts = events.toList(growable: false);

    // First snapshot after join: remember existing gifts, do not animate them.
    if (!_bootstrapDone) {
      for (final event in gifts) {
        _seenKeys.add(event.key);
      }
      _bootstrapDone = true;
      return;
    }
    if (gifts.isEmpty) return;

    GiftChatEvent? lastPeer;
    var queued = false;
    for (var i = 0; i < gifts.length; i++) {
      final event = gifts[i];
      if (!_seenKeys.add(event.key)) continue;
      if (event.key == _lastCelebratedKey) continue;

      // Sender already celebrated on API success — skip self duplicates.
      final isMine =
          event.senderId.isNotEmpty && event.senderId == myUserId;
      if (isMine) continue;

      lastPeer = event;
      GiftMediaUtils.showCelebrationFromChatLabel(
        event.message,
        enqueueIfBusy: queued,
        giftCatalog: giftCatalog,
      );
      queued = true;
      onPeerGift?.call(event);
    }
    if (lastPeer != null) _lastCelebratedKey = lastPeer.key;
  }

  /// Clears state when leaving a room/call so the next session bootstraps cleanly.
  void reset() {
    _seenKeys.clear();
    _bootstrapDone = false;
    _lastCelebratedKey = null;
  }
}
