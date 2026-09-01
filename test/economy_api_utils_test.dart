import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/repo/economy/economy_api_utils.dart';

void main() {
  group('coin USD conversion', () {
    test('converts recruitment coins into USD', () {
      expect(coinsToUsd(10000), 1);
      expect(coinsToUsd(100000), 10);
      expect(formatUsd(coinsToUsd(10000)), r'$1.00');
    });

    test('converts USD into recruitment coins', () {
      expect(usdToCoins(1), 10000);
      expect(usdToCoins(10), 100000);
    });

    test('formats coins with USD label', () {
      expect(formatCoinsWithUsd(10000), r'10,000 Coins ($1.00)');
      expect(formatCoinsWithUsd(100000), r'100,000 Coins ($10.00)');
    });
  });
}
