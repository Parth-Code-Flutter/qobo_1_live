/// Razorpay Checkout keys.
///
/// Replace [keyId] with the live/test Key ID from the Razorpay dashboard
/// (or pass `--dart-define=RAZORPAY_KEY_ID=rzp_...` at build time).
/// Never put the Key Secret in the mobile app — order creation / signature
/// verification stay on the backend when that contract ships.
abstract final class RazorpayConfig {
  RazorpayConfig._();

  /// Public Key ID shown in Razorpay Dashboard → API Keys.
  /// Placeholder until the client provides real test/live values.
  static const String keyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: 'rzp_test_REPLACE_WITH_CLIENT_KEY',
  );

  static const String companyName = String.fromEnvironment(
    'RAZORPAY_COMPANY_NAME',
    defaultValue: 'Qobo One Live',
  );

  /// When true, checkout opens even with the placeholder key (useful for UI
  /// wiring). Set false in production builds if key is still a placeholder.
  static const bool allowPlaceholderCheckout = bool.fromEnvironment(
    'RAZORPAY_ALLOW_PLACEHOLDER',
    defaultValue: true,
  );

  static bool get isPlaceholderKey =>
      keyId.contains('REPLACE') || keyId.trim().isEmpty;
}
