import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/services/chat/chat_firebase_service.dart';
import 'package:qobo_one_live/services/chat/inbox_unread.dart';

void main() {
  // Anonymized documents captured from two real test-account exchanges.
  final fixtures =
      jsonDecode(
            File('test/fixtures/chat_unread_receipts.json').readAsStringSync(),
          )
          as List;
  for (var i = 0; i < fixtures.length; i++) {
    test(
      'live receipt fixture $i counts correctly, including after restart',
      () {
        final fixture = fixtures[i] as Map;
        final rows = (fixture['messages'] as List).map((raw) {
          final row = Map<String, dynamic>.from(raw as Map);
          return {
            ...row,
            'activityAt': ChatFirebaseService.messageActivityAt(row),
          };
        }).toList();
        for (var restart = 0; restart < 2; restart++) {
          expect(
            countUnreadMessages(
              messages: rows,
              myUserId: fixture['myUserId'] as String,
            ),
            i.isEven ? 3 : 0,
          );
        }
      },
    );
  }
  test('delivered is unread; another user reading does not clear my count', () {
    expect(
      countUnreadMessages(
        messages: [
          {
            'id': 'a',
            'senderId': 'peer',
            'status': {
              'me': {'deliveredAt': 'now'},
              'other': {'readAt': 'now'},
            },
          },
          {'id': 'b', 'senderId': 'me'},
        ],
        myUserId: 'me',
      ),
      1,
    );
  });
  test('duplicate delivery of the same client id is counted once', () {
    expect(
      countUnreadMessages(
        messages: [
          {'id': 'one', 'clientMessageId': 'same', 'senderId': 'peer'},
          {'id': 'two', 'clientMessageId': 'same', 'senderId': 'peer'},
          {'id': 'three', 'clientMessageId': '', 'senderId': 'peer'},
        ],
        myUserId: 'me',
      ),
      2,
    );
  });
  test('stable ids distinguish identical messages within one second', () {
    final at = DateTime.utc(2026);
    expect(
      incomingMessageKey(preview: 'Hi', activityAt: at, messageId: 'a'),
      isNot(incomingMessageKey(preview: 'Hi', activityAt: at, messageId: 'b')),
    );
  });
}
