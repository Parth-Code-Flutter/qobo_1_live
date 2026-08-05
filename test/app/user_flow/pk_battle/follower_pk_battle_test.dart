import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/models/follower_pk_battle.dart';

void main() {
  group('FollowerPkBattle', () {
    test('parses the backend active battle contract', () {
      final battle = FollowerPkBattle.fromMap({
        'battle_id': 'battle-1',
        'mode': 'audio_follower_pk',
        'room_id': 'room-1',
        'status': 'active',
        'duration_seconds': 300,
        'remaining_seconds': 184,
        'challenger_score': 1500,
        'opponent_score': 1000,
        'challenger': {
          'user_id': 'rahul-id',
          'name': 'Rahul',
          'avatar': 'rahul.png',
        },
        'opponent': {
          'user_id': 'sumit-id',
          'name': 'Sumit',
          'avatar': 'sumit.png',
        },
      });

      expect(battle.battleId, 'battle-1');
      expect(battle.isActive, isTrue);
      expect(battle.secondsRemaining(), 184);
      expect(battle.challenger.name, 'Rahul');
      expect(battle.opponent?.name, 'Sumit');
      expect(battle.challengerScore, 1500);
      expect(battle.opponentScore, 1000);
    });

    test('unwraps active-for-me battle payloads', () {
      final battle = FollowerPkBattle.fromMap({
        'battle': {
          'battle_id': 'battle-2',
          'room_id': 'room-2',
          'status': 'duration_pending',
          'challenger': {'user_id': 'one', 'name': 'One'},
          'opponent': {'user_id': 'two', 'name': 'Two'},
        },
      });

      expect(battle.battleId, 'battle-2');
      expect(battle.isDurationPending, isTrue);
      expect(battle.opponent?.userId, 'two');
    });
  });
}
