import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/repo/economy/economy_api_utils.dart';

void main() {
  test('gift send compares diamonds and ignores coins and myCoins', () {
    final data = {
      'coins': 703352,
      'myCoins': 703352,
      'diamonds': 2880,
    };

    expect(giftSpendDiamonds(data), 2880);
    expect(
      canAffordGift(diamonds: giftSpendDiamonds(data), giftPrice: 3600),
      isFalse,
    );
    expect(
      canAffordGift(diamonds: giftSpendDiamonds(data), giftPrice: 1200),
      isTrue,
    );
  });

  test('combo cost is price times count against diamonds', () {
    expect(
      canAffordGift(diamonds: 1000, giftPrice: 400, count: 3),
      isFalse,
    );
    expect(
      canAffordGift(diamonds: 1200, giftPrice: 400, count: 3),
      isTrue,
    );
  });

  test('falls back to diamond then diamondBalance', () {
    expect(giftSpendDiamonds({'diamond': 50}), 50);
    expect(giftSpendDiamonds({'diamondBalance': '80'}), 80);
    expect(giftSpendDiamonds({'coins': 999}), 0);
  });
}
