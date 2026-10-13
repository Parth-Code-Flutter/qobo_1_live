import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/services/chat/inbox_unread.dart';

void main() {
  test('a positive unread count is kept', () {
    expect(
      inboxUnreadCount(
        json: {'unreadCount': 3, 'lastMessage': 'Hii'},
        myUserId: 'me',
      ),
      3,
    );
  });

  test('a message from the other person is unread even when the count is 0', () {
    expect(
      inboxUnreadCount(
        json: {
          'unreadCount': 0,
          'lastMessage': 'Hii',
          'lastMessageSenderId': 'mic-king',
        },
        myUserId: 'me',
      ),
      1,
    );
  });

  test('my own last message is not marked unread', () {
    expect(
      inboxUnreadCount(
        json: {
          'unreadCount': 0,
          'lastMessage': 'Hii',
          'lastMessageSenderId': 'me',
        },
        myUserId: 'me',
      ),
      0,
    );
  });

  test('an empty thread is not marked unread', () {
    expect(
      inboxUnreadCount(
        json: {
          'unreadCount': 0,
          'lastMessage': '',
          'lastMessageSenderId': 'mic-king',
        },
        myUserId: 'me',
      ),
      0,
    );
  });

  test('a read flag stays clear', () {
    expect(
      inboxUnreadCount(
        json: {
          'unreadCount': 0,
          'isRead': true,
          'lastMessage': 'Hii',
          'lastMessageSenderId': 'mic-king',
        },
        myUserId: 'me',
      ),
      0,
    );
  });
}
