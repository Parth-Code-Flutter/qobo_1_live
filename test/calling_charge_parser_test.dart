import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/repo/calling/calling_charge_utils.dart';

void main() {
  group('CallingChargeParser', () {
    test('parses direct charge response (10s @ 2 coins/sec)', () {
      final result = CallingChargeParser.fromResponse(<String, dynamic>{
        'statusCode': 1,
        'data': <String, dynamic>{
          'totalCoinsDeducted': 20,
          'hostEarnedDiamonds': 10,
          'platformCommission': 10,
          'durationSeconds': 10,
        },
      });

      expect(result, isNotNull);
      expect(result!.totalCoinsDeducted, 20);
      expect(result.hostEarnedDiamonds, 10);
      expect(result.platformCommission, 10);
      expect(result.durationSeconds, 10);
    });

    test('parses nested billing on direct/end response', () {
      final result = CallingChargeParser.fromResponse(<String, dynamic>{
        'statusCode': 1,
        'data': <String, dynamic>{
          'callId': 'vc_123',
          'billing': <String, dynamic>{
            'total_coins_deducted': 2,
            'host_earned_diamonds': 1,
            'company_commission': 1,
            'duration_seconds': 1,
          },
        },
      });

      expect(result, isNotNull);
      expect(result!.totalCoinsDeducted, 2);
      expect(result.hostEarnedDiamonds, 1);
      expect(result.platformCommission, 1);
      expect(result.durationSeconds, 1);
    });

    test('returns null when no billing fields present', () {
      final result = CallingChargeParser.fromResponse(<String, dynamic>{
        'statusCode': 1,
        'data': <String, dynamic>{'callId': 'vc_123', 'status': 'ended'},
      });

      expect(result, isNull);
    });
  });
}
