import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/services/gifts/lucky_gift_reward.dart';

void main() {
  test('winner notice reads a nested room broadcast', () {
    final notice = LuckyGiftRewardNotice.tryParse({
      'event': 'lucky_gift_reward',
      'data': {
        'transaction_id': 'tx-1',
        'channel_id': 'room-9',
        'sender': {'id': 'idc1057300', 'name': 'Niks'},
        'gift': {'name': 'Lucky Clover', 'isLucky': true},
        'luckyRewardCoins': 700,
        'luckyRewardBonus': 200,
        'combo': 5,
      },
    });

    expect(notice, isNotNull);
    expect(notice!.id, 'tx-1');
    expect(notice.winnerId, 'idc1057300');
    expect(notice.winnerName, 'Niks');
    expect(notice.giftName, 'Lucky Clover');
    expect(notice.total, 700);
    expect(notice.bonus, 200);
    expect(notice.combo, 5);
    expect(notice.roomId, 'room-9');
    expect(notice.chatLine, 'Niks won 700 coins on Lucky Clover');
  });

  test('a zero-coin payload is not a winner banner', () {
    expect(
      LuckyGiftRewardNotice.tryParse({
        'event': 'lucky_gift_reward',
        'luckyRewardCoins': 0,
        'sender': {'name': 'Niks'},
      }),
      isNull,
    );
  });

  test(
    'snake_case diamond balance is accepted and a replay is not announced',
    () {
      expect(
        readLuckyDiamondBalance({'user_coins': '1,200', 'userCoins': null}),
        1200,
      );
      expect(
        readLuckyDiamondBalance({
          'luckyReward': {'userCoins': 80},
        }),
        80,
      );
      expect(readLuckyDiamondBalance({'combo': 2}), isNull);
      expect(luckySendShouldBroadcast({'idempotent': false}), isTrue);
      expect(luckySendShouldBroadcast({'idempotent': true}), isFalse);
      expect(luckySendShouldBroadcast({'combo': 1}), isTrue);
    },
  );

  test('a lucky gift_sent is recognized so the clip is not played twice', () {
    expect(
      luckySocketPayloadIsLuckyGift({
        'gift': {'name': 'Clover', 'isLucky': true},
      }),
      isTrue,
    );
    expect(
      luckySocketPayloadIsLuckyGift({
        'data': {
          'type': 'lucky_gift',
          'gift': {'name': 'Clover'},
        },
      }),
      isTrue,
    );
    expect(
      luckySocketPayloadIsLuckyGift({
        'gift': {'name': 'Rose', 'isLucky': false},
      }),
      isFalse,
    );
  });
}
