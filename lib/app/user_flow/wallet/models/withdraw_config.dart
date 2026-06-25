/// Withdrawal rules and user eligibility from `GET /api/withdraw/config`.
class WithdrawConfig {
  const WithdrawConfig({
    required this.allowedTiers,
    required this.maxLimit,
    required this.isEligibleThisWeek,
    required this.userBalance,
    required this.currencySymbol,
  });

  final List<int> allowedTiers;
  final int maxLimit;
  final bool isEligibleThisWeek;
  final num userBalance;
  final String currencySymbol;

  factory WithdrawConfig.fromJson(Map<String, dynamic> json) {
    final tiersRaw = json['allowedTiers'] ?? json['allowed_tiers'];
    final tiers = <int>[];
    if (tiersRaw is List) {
      for (final tier in tiersRaw) {
        if (tier is num) {
          tiers.add(tier.round());
        } else {
          final parsed = int.tryParse(tier?.toString() ?? '');
          if (parsed != null) tiers.add(parsed);
        }
      }
    }

    final balanceRaw = json['userBalance'] ?? json['user_balance'];
    final maxRaw = json['maxLimit'] ?? json['max_limit'];

    return WithdrawConfig(
      allowedTiers: tiers,
      maxLimit: maxRaw is num
          ? maxRaw.round()
          : int.tryParse(maxRaw?.toString() ?? '') ?? 0,
      isEligibleThisWeek:
          json['isEligibleThisWeek'] == true ||
          json['is_eligible_this_week'] == true,
      userBalance: balanceRaw is num
          ? balanceRaw
          : num.tryParse(balanceRaw?.toString() ?? '') ?? 0,
      currencySymbol:
          json['currencySymbol']?.toString().trim().isNotEmpty == true
          ? json['currencySymbol'].toString()
          : (json['currency_symbol']?.toString().trim().isNotEmpty == true
                ? json['currency_symbol'].toString()
                : '\$'),
    );
  }
}
