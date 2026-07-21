import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/social_user_card.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';

void main() {
  group('SocialUserCard social list parsing', () {
    test('parses paged items from friends/followers APIs', () {
      final users = SocialUserCard.listFromResponseData({
        'items': [
          {
            'id': 'friend-1',
            'name': 'Asha',
            'displayPicture': '/uploads/a.png',
            'country': 'India',
            'level': 3,
            'isFriend': true,
            'isFollowing': true,
            'isFollower': true,
          },
        ],
        'page': 1,
        'total': 1,
      });

      expect(users, hasLength(1));
      expect(users.first.id, 'friend-1');
      expect(users.first.isMutual, isTrue);
      expect(users.first.isFollowing, isTrue);
    });

    test('parses visitor rows that use userId instead of id', () {
      final users = SocialUserCard.listFromResponseData({
        'items': [
          {
            'id': 'visit-uuid-1',
            'userId': 'visitor-user-id',
            'name': 'Visitor',
            'isFollowing': false,
            'visitedAt': '2026-07-21T10:00:00.000Z',
          },
        ],
      });

      expect(users.first.id, 'visitor-user-id');
    });
  });

  group('UserSessionController social stats', () {
    late UserSessionController session;

    setUp(() {
      session = UserSessionController();
    });

    Future<void> hydrate(Map<String, dynamic> data) async {
      // In-memory profile is set before storage write; ignore MissingPluginException.
      try {
        await session.saveProfile(data);
      } catch (_) {}
    }

    test('prefers formatted counters from profile payload', () async {
      await hydrate({
        'id': 'u1',
        'name': 'Kirit',
        'formattedVisitors': '2K',
        'formattedFriends': '1K',
        'formattedFollowing': '1K',
        'formattedFollowers': '10.4K',
        'levelBadge': 'LV.5',
        'visitorsCount': 2045,
      });

      expect(session.formattedVisitors, '2K');
      expect(session.formattedFriends, '1K');
      expect(session.formattedFollowing, '1K');
      expect(session.formattedFollowers, '10.4K');
      expect(session.levelBadge, 'LV.5');
    });

    test('falls back to nested stats and compact counts', () async {
      await hydrate({
        'id': 'u2',
        'stats': {
          'visitors': 2045,
          'friends': 1024,
          'following': 50,
          'followers': 10400,
          'formattedFollowing': '50',
        },
        'level': 2,
      });

      expect(session.formattedVisitors, '2K');
      expect(session.formattedFriends, '1K');
      expect(session.formattedFollowing, '50');
      expect(session.formattedFollowers, '10.4K');
      expect(session.levelBadge, 'LV.2');
    });
  });
}
