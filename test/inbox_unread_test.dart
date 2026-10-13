import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/services/chat/inbox_unread.dart';

void main() {
  test('the API count is kept before the chat has been opened', () {
    expect(
      unreadBadgeCount(
        reportedCount: 4,
        seenIncomingCount: 1,
        alreadyRead: false,
      ),
      4,
    );
  });

  test('after the chat is read, an old API total is ignored', () {
    expect(
      unreadBadgeCount(
        reportedCount: 4,
        seenIncomingCount: 2,
        alreadyRead: false,
        sinceRead: true,
      ),
      2,
    );
  });

  test('after the chat is read, no new messages means a clear badge', () {
    expect(
      unreadBadgeCount(
        reportedCount: 4,
        seenIncomingCount: 0,
        alreadyRead: false,
        sinceRead: true,
      ),
      0,
    );
  });

  test('two incoming messages count as two when the API count is missing', () {
    expect(
      unreadBadgeCount(
        reportedCount: 0,
        seenIncomingCount: 2,
        alreadyRead: false,
      ),
      2,
    );
  });

  test('an opened chat shows no unread count', () {
    expect(
      unreadBadgeCount(
        reportedCount: 3,
        seenIncomingCount: 3,
        alreadyRead: true,
      ),
      0,
    );
  });

  test('the same message fetched twice shares one key', () {
    final first = incomingMessageKey(
      preview: 'Hii',
      activityRaw: '2026-10-13T04:11:00.100Z',
    );
    final again = incomingMessageKey(
      preview: 'Hii',
      activityAt: DateTime.parse('2026-10-13T04:11:00.800Z'),
    );
    final next = incomingMessageKey(
      preview: 'Hello',
      activityRaw: '2026-10-13T04:11:05.000Z',
    );

    expect(first, again);
    expect(next, isNot(first));
  });

  test('a message from the other person is incoming', () {
    expect(
      inboxPayloadIsIncoming(
        json: {
          'lastMessage': 'Hii',
          'lastMessageSenderId': 'mic-king',
        },
        myUserId: 'me',
      ),
      isTrue,
    );
  });

  test('my own last message is not incoming', () {
    expect(
      inboxPayloadIsIncoming(
        json: {
          'lastMessage': 'Hii',
          'lastMessageSenderId': 'me',
        },
        myUserId: 'me',
      ),
      isFalse,
    );
  });

  test('reported unread reads the API field', () {
    expect(reportedInboxUnread({'unreadCount': 3}), 3);
    expect(reportedInboxUnread({'unread_count': '2'}), 2);
  });
}
