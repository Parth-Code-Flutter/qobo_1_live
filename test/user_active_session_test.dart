import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/social_user_card.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/user_active_session.dart';

void main() {
  group('UserActiveSession', () {
    test('parses nested activeSession from public profile', () {
      final card = SocialUserCard.fromJson({
        'id': 'idc1',
        'name': 'Agency Owner',
        'activeSession': {
          'isLive': true,
          'roomId': 'room-1',
          'roomType': 'AUDIO',
          'sessionType': 'audio_room',
          'title': 'Friday Audio Lounge',
          'viewerCount': 19,
        },
      });

      expect(card.isLiveNow, isTrue);
      expect(card.activeSession?.roomId, 'room-1');
      expect(card.activeSession?.joinButtonLabel, 'Join Audio Room');
      expect(card.activeSession?.resolvedSessionType, 'audio_room');
    });

    test('parses flat aliases when nested missing', () {
      final session = UserActiveSession.tryParse({
        'isLive': true,
        'room_id': 'live-9',
        'room_type': 'LIVE_STREAM',
        'session_type': 'live_stream',
      });

      expect(session?.isJoinable, isTrue);
      expect(session?.isLiveStream, isTrue);
      expect(session?.joinButtonLabel, 'Join Live Stream');
    });

    test('hides join when not live', () {
      final card = SocialUserCard.fromJson({
        'id': 'idc1',
        'name': 'Offline',
        'activeSession': {'isLive': false, 'roomId': null},
      });

      expect(card.isLiveNow, isFalse);
    });
  });
}
