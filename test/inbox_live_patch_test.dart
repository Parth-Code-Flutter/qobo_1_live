import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/services/chat/inbox_live_patch.dart';

void main() {
  final older = DateTime.utc(2026, 10, 12, 4, 0, 0);
  final newer = older.add(const Duration(seconds: 30));

  InboxLiveUpdate? resolve({
    DateTime? currentAt,
    String currentPreview = 'Hello',
    DateTime? messageAt,
    String preview = 'See you',
    bool fromMe = false,
    bool chatOpen = false,
    bool alreadyCounted = false,
    int shownUnread = 0,
  }) {
    return InboxLiveUpdate.resolve(
      currentActivityAt: currentAt,
      currentPreview: currentPreview,
      messageAt: messageAt ?? newer,
      preview: preview,
      messageType: 'text',
      shownUnread: shownUnread,
      fromMe: fromMe,
      chatOpen: chatOpen,
      alreadyCounted: alreadyCounted,
    );
  }

  test('a newer incoming message replaces the row and adds one unread', () {
    final update = resolve(currentAt: older);

    expect(update, isNotNull);
    expect(update!.preview, 'See you');
    expect(update.unreadCount, 1);
    expect(update.activityAt, newer);
  });

  test('an older message does not replace the row', () {
    expect(
      resolve(currentAt: newer, messageAt: older, preview: 'Old'),
      isNull,
    );
  });

  test('the same text a few hundred milliseconds later is not a new message', () {
    expect(
      resolve(
        currentAt: older,
        currentPreview: 'Hello',
        messageAt: older.add(const Duration(milliseconds: 400)),
        preview: 'Hello',
      ),
      isNull,
    );
  });

  test('my own message updates the row without a new unread badge', () {
    final update = resolve(currentAt: older, fromMe: true, shownUnread: 2);

    expect(update, isNotNull);
    expect(update!.unreadCount, 2);
  });

  test('an open chat clears the unread badge', () {
    final update = resolve(currentAt: older, chatOpen: true, shownUnread: 4);

    expect(update, isNotNull);
    expect(update!.unreadCount, 0);
  });

  test('the same message is not counted twice', () {
    final update = resolve(
      currentAt: older,
      alreadyCounted: true,
      shownUnread: 1,
    );

    expect(update, isNotNull);
    expect(update!.unreadCount, 1);
  });

  test('an empty preview is ignored', () {
    expect(resolve(currentAt: older, preview: '   '), isNull);
  });
}
