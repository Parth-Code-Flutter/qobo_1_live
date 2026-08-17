/// Shared helpers for economy / wallet API responses.
bool isEconomyApiSuccess(Map<String, dynamic>? response) {
  if (response == null) return false;
  if (response['success'] == true) return true;
  final code = response['statusCode'];
  if (code is int) return code == 1 || code == 200 || code == 201;
  return code?.toString() == '1' ||
      code?.toString() == '200' ||
      code?.toString() == '201';
}

int parseWalletAmount(dynamic value) {
  if (value is num) return value.round();
  return int.tryParse(value?.toString().replaceAll(',', '') ?? '') ?? 0;
}

double parseWalletAmountDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString().replaceAll(',', '') ?? '') ?? 0;
}

/// Earning rule: **1,000 coins/diamonds = $1.00 USD**.
const double kCoinsPerDollar = 1000;

/// Converts coins or diamonds into USD using the platform rate.
double coinsToDollars(num coinsOrDiamonds) =>
    coinsOrDiamonds.toDouble() / kCoinsPerDollar;

/// Prefers API `dollars` / `earnedDollars` when present; otherwise derives
/// from diamonds (then coins) at [kCoinsPerDollar].
double resolveEarnedDollars({
  required Map data,
  int? diamondsFallback,
  int? coinsFallback,
}) {
  final nested = data['wallet'];
  final wallet = nested is Map ? nested : const <dynamic, dynamic>{};
  final fromApi = parseWalletAmountDouble(
    data['dollars'] ??
        data['earnedDollars'] ??
        data['earned_dollars'] ??
        wallet['dollars'] ??
        wallet['earnedDollars'] ??
        wallet['earned_dollars'],
  );
  if (fromApi > 0) return fromApi;

  final diamonds = diamondsFallback ??
      parseWalletAmount(
        data['diamonds'] ??
            data['diamond'] ??
            data['diamondBalance'] ??
            wallet['diamonds'],
      );
  if (diamonds > 0) return coinsToDollars(diamonds);

  final coins = coinsFallback ??
      parseWalletAmount(
        data['coins'] ?? data['coin'] ?? data['balance'] ?? wallet['coins'],
      );
  if (coins > 0) return coinsToDollars(coins);
  return 0;
}

/// Formats USD with 2 decimals, e.g. `$10.00`.
String formatUsd(num dollars) {
  final value = dollars.toDouble();
  final fixed = value.toStringAsFixed(2);
  return '\$$fixed';
}

/// Whole-dollar label from coins/diamonds; `$0` below 1,000 (= $1).
///
/// Session UIs should use this instead of [formatUsd] + [coinsToDollars] so
/// partial amounts (e.g. 9 coins) never show as `$0.01`.
String formatWholeUsdFromCoins(num coinsOrDiamonds) {
  final coins = coinsOrDiamonds.toDouble();
  if (coins < kCoinsPerDollar) return '\$0';
  final dollars = (coins / kCoinsPerDollar).floor();
  return '\$$dollars';
}

String formatLedgerAmount(num value) {
  final abs = value.abs().round();
  final formatted = abs.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  return formatted;
}
