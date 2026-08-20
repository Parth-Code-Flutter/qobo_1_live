import 'package:qobo_one_live/repo/economy/economy_api_utils.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

/// Parsed result from `POST /api/economy/calling/charge` or billing nested
/// inside `POST /api/call/direct/end`.
class CallingChargeResult {
  const CallingChargeResult({
    this.totalCoinsDeducted = 0,
    this.hostEarnedDiamonds = 0,
    this.platformCommission = 0,
    this.durationSeconds = 0,
  });

  final int totalCoinsDeducted;
  final int hostEarnedDiamonds;
  final int platformCommission;
  final int durationSeconds;

  bool get hasBilling =>
      totalCoinsDeducted > 0 ||
      hostEarnedDiamonds > 0 ||
      platformCommission > 0;
}

/// Reads charge fields from economy/call API envelopes (camelCase + snake_case).
abstract final class CallingChargeParser {
  CallingChargeParser._();

  static CallingChargeResult? fromResponse(Map<String, dynamic>? response) {
    if (!ApiResponseUtils.isBodySuccess(response)) return null;
    final data = response?['data'];
    if (data is! Map) return null;
    return fromMap(Map<String, dynamic>.from(data));
  }

  static CallingChargeResult? fromMap(Map<String, dynamic> map) {
    final billing = _billingMap(map);
    if (billing == null) return null;

    final deducted = _readInt(billing, const [
      'totalCoinsDeducted',
      'total_coins_deducted',
      'coinsDeducted',
      'coins_deducted',
      'chargedCoins',
      'charged_coins',
      'callerDebited',
      'caller_debited',
    ]);
    final hostEarned = _readInt(billing, const [
      'hostEarnedDiamonds',
      'host_earned_diamonds',
      'hostEarnedCoins',
      'host_earned_coins',
      'calleeEarned',
      'callee_earned',
      'calleeEarnedDiamonds',
      'callee_earned_diamonds',
    ]);
    final commission = _readInt(billing, const [
      'platformCommission',
      'platform_commission',
      'companyCommission',
      'company_commission',
      'agencyEarnedCoins',
      'agency_earned_coins',
    ]);
    final duration = _readInt(billing, const [
      'durationSeconds',
      'duration_seconds',
      'billableSeconds',
      'billable_seconds',
    ]);

    if (deducted <= 0 && hostEarned <= 0 && commission <= 0 && duration <= 0) {
      return null;
    }

    return CallingChargeResult(
      totalCoinsDeducted: deducted,
      hostEarnedDiamonds: hostEarned,
      platformCommission: commission,
      durationSeconds: duration,
    );
  }

  static Map<String, dynamic>? _billingMap(Map<String, dynamic> map) {
    final nestedKeys = const [
      'billing',
      'charge',
      'chargeResult',
      'charge_result',
      'callingCharge',
      'calling_charge',
    ];
    for (final key in nestedKeys) {
      final nested = map[key];
      if (nested is Map) {
        return Map<String, dynamic>.from(nested);
      }
    }
    return map;
  }

  static int _readInt(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (!map.containsKey(key)) continue;
      return parseWalletAmount(map[key]);
    }
    return 0;
  }
}
