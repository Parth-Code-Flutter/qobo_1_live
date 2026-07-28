/// Temporary flags while wiring the user coins-seller APIs.
///
/// Keep [bypassAuthForFlowTest] `false` so apply / 403 / dashboard follow the
/// real backend contract from USER_COINS_SELLER_API.md.
abstract final class CoinSellerDevConfig {
  CoinSellerDevConfig._();

  /// When true, a failed dashboard still opens a placeholder approved view.
  static const bool bypassAuthForFlowTest = false;
}
