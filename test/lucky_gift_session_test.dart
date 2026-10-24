import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/services/gifts/lucky_gift_session.dart';

class FakeLuckyRepo extends LuckyGiftRepo {
  final calls = <Map<String, dynamic>>[];
  bool fail = false;
  bool reject = false;
  bool duplicate = false;
  @override
  Future<Map<String, dynamic>?> catalog() async => {
    'statusCode': 1,
    'data': [
      {
        'id': 'heart',
        'name': 'Heart',
        'price': 100,
        'luckyThreshold': 5,
        'luckyRewardRate': 40,
        'iconUrl': '/heart.png',
      },
    ],
  };
  @override
  Future<Map<String, dynamic>?> send(
    Map<String, dynamic> body,
    String token,
  ) async {
    calls.add(Map.of(body));
    await Future<void>.delayed(Duration.zero);
    if (fail) return null;
    if (reject) return {'statusCode': 0, 'message': 'Insufficient coins'};
    final c = body['combo'] as int;
    if (duplicate)
      return {
        'statusCode': 1,
        'data': {'idempotent': true, 'combo': c},
      };
    return {
      'statusCode': 1,
      'data': {
        'combo': c,
        'userCoins': c == 5 ? 1200 : 1000 - c * 100,
        'luckyRewardTriggered': c == 5,
        'luckyRewardCoins': 700,
        'luckyRewardBonus': 200,
      },
    };
  }
}

Future<void> settle(LuckyGiftSession s) async {
  while (s.busy) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

void main() {
  test('serial taps advance combos and use server reward/balance', () async {
    final repo = FakeLuckyRepo();
    var successes = 0;
    final s = LuckyGiftSession(
      repo: repo,
      token: 'test',
      isOwner: () => true,
      onSuccess: (_, __, ___) => successes++,
    );
    await s.load();
    for (var i = 0; i < 5; i++) {
      s.tap(s.gifts.first, host: 'host', channel: 'room');
    }
    await settle(s);
    expect(repo.calls.map((c) => c['combo']), [1, 2, 3, 4, 5]);
    expect(repo.calls.map((c) => c['clientGiftId']).toSet().length, 5);
    expect(repo.calls.first['host_id'], 'host');
    expect(repo.calls.first['channel_id'], 'room');
    expect(s.balance, 1200);
    expect(successes, 5);
    expect(s.message, contains('700 Coins'));
    s.dispose();
  });
  test(
    'uncertain send retries same id and combo without dispatching queued sends',
    () async {
      final repo = FakeLuckyRepo()..fail = true;
      final s = LuckyGiftSession(
        repo: repo,
        token: 'test',
        isOwner: () => true,
        onSuccess: (_, __, ___) {},
      );
      await s.load();
      s.tap(s.gifts.first);
      s.tap(s.gifts.first);
      await settle(s);
      expect(s.needsRetry, true);
      expect(repo.calls.length, 1);
      repo.fail = false;
      await s.retry();
      expect(repo.calls[0], repo.calls[1]);
      expect(s.combos['heart'], 1);
      expect(repo.calls.first.containsKey('host_id'), false);
      s.dispose();
    },
  );
  test(
    'duplicate confirmation advances once without inventing wallet or reward',
    () async {
      final repo = FakeLuckyRepo()..fail = true;
      var successes = 0;
      final s = LuckyGiftSession(
        repo: repo,
        token: 'test',
        isOwner: () => true,
        onSuccess: (_, __, ___) => successes++,
      );
      await s.load();
      s.tap(s.gifts.first);
      await settle(s);
      repo.fail = false;
      repo.duplicate = true;
      await s.retry();
      expect(successes, 1);
      expect(s.balance, isNull);
      expect(s.message, contains('Previous send confirmed'));
      expect(repo.calls.first, repo.calls.last);
      s.dispose();
    },
  );
  test('account switch suppresses old response and further sends', () async {
    final repo = FakeLuckyRepo();
    var owner = true;
    var successes = 0;
    final s = LuckyGiftSession(
      repo: repo,
      token: 'test',
      isOwner: () => owner,
      onSuccess: (_, __, ___) => successes++,
    );
    await s.load();
    s.tap(s.gifts.first);
    owner = false;
    await settle(s);
    s.tap(s.gifts.first);
    expect(successes, 0);
    expect(repo.calls.length, 1);
    s.dispose();
  });
  test('rejected send never advances combo or runs success callback', () async {
    final repo = FakeLuckyRepo()..reject = true;
    var successes = 0;
    final s = LuckyGiftSession(
      repo: repo,
      token: 'test',
      isOwner: () => true,
      onSuccess: (_, __, ___) => successes++,
    );
    await s.load();
    s.tap(s.gifts.first);
    await settle(s);
    expect(successes, 0);
    expect(s.combos, isEmpty);
    expect(s.message, 'Insufficient coins');
    s.dispose();
  });
}
