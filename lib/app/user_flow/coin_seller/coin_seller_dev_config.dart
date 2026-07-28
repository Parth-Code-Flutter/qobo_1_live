/// Temporary flags while wiring the seller portal against live APIs.
///
/// Set [bypassAuthForFlowTest] to `false` before release builds.
abstract final class CoinSellerDevConfig {
  CoinSellerDevConfig._();

  /// When true, Sign in opens the dashboard even if login/dashboard APIs fail.
  static const bool bypassAuthForFlowTest = true;
}
