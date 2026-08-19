import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/services/session/session_earnings_tracker.dart';
import 'package:qobo_one_live/utils/session_earnings_utils.dart';

void main() {
  group('SessionEarningsUtils host session ingest', () {
    test('prefers hostSessionCoins when sessionCoinsEarned is 0', () {
      final tracker = SessionEarningsTracker();
      SessionEarningsUtils.ingestApiEnvelope(tracker, {
        'statusCode': 1,
        'data': {
          'sessionCoinsEarned': 0,
          'hostSessionCoins': 1280,
          'giftCoinsEarned': 1280,
        },
      });
      expect(tracker.displayCoins, 1280);
    });

    test('reads nested sessionEarnings from join payload', () {
      final tracker = SessionEarningsTracker();
      SessionEarningsUtils.ingestRoomData(tracker, {
        'sessionCoinsEarned': 0,
        'sessionEarnings': {
          'sessionCoinsEarned': 1280,
          'hostSessionCoins': 1280,
        },
      });
      expect(tracker.displayCoins, 1280);
    });

    test('does not overwrite a known total with zero', () {
      final tracker = SessionEarningsTracker();
      tracker.setFromTotals(coins: 500, diamonds: 0);
      SessionEarningsUtils.ingestApiEnvelope(tracker, {
        'statusCode': 1,
        'data': {'sessionCoinsEarned': 0, 'hostSessionCoins': 0},
      });
      expect(tracker.displayCoins, 500);
    });

    test('copyHostSessionFields keeps join aliases on payload', () {
      final payload = <String, dynamic>{};
      SessionEarningsUtils.copyHostSessionFields(
        payload,
        data: {
          'sessionEarnings': {'hostSessionCoins': 1280},
          'host_session_coins': 1280,
        },
      );
      expect(payload['host_session_coins'], 1280);
      expect((payload['sessionEarnings'] as Map)['hostSessionCoins'], 1280);
    });
  });
}
