/// Platform gift-share rule for rooms and live streams.
///
/// 1. Sender pays the catalog gift price once.
/// 2. Platform keeps a fixed **20%**.
/// 3. Remaining **80%** goes to recipients (sender is never included):
///    - individual gift → one receiver
///    - share-to-all → split equally among everyone else
abstract final class GiftShareEconomics {
  GiftShareEconomics._();

  static const int platformFeePercent = 20;

  /// Coins left after the 20% platform fee (e.g. 500 → 400).
  static int netAfterCommission(int coinsSpent) {
    if (coinsSpent <= 0) return 0;
    return (coinsSpent * (100 - platformFeePercent)) ~/ 100;
  }

  /// Equal share of the net pool. Integer leftover stays with the platform.
  static int shareEach({
    required int coinsSpent,
    required int recipientCount,
  }) {
    if (coinsSpent <= 0 || recipientCount <= 0) return 0;
    return netAfterCommission(coinsSpent) ~/ recipientCount;
  }

  /// Credit shown/applied on a device after a successful send.
  ///
  /// Ignores API `amount_each` when it is the full catalog price (pre-fee),
  /// so old backends still follow this rule on mobile.
  static int creditAmount({
    required int coinsSpent,
    required bool isRoomShare,
    required int recipientCount,
    int? apiAmountEach,
  }) {
    if (apiAmountEach != null && apiAmountEach > 0) {
      if (coinsSpent <= 0 || apiAmountEach < coinsSpent) {
        return apiAmountEach;
      }
    }
    if (isRoomShare) {
      return shareEach(
        coinsSpent: coinsSpent,
        recipientCount: recipientCount > 0 ? recipientCount : 1,
      );
    }
    return netAfterCommission(coinsSpent);
  }
}
