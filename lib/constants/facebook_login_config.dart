/// Demo vs production behavior for Facebook Login (same pattern as Google).
///
/// Replace placeholders in `android/app/src/main/res/values/strings.xml`:
/// `facebook_app_id`, `facebook_client_token` (Meta Developer App dashboard).
abstract final class FacebookLoginConfig {
  FacebookLoginConfig._();

  /// Complete the backend session exchange by default, including release builds.
  /// Set FACEBOOK_SUBMIT_TO_BACKEND=false only for explicit SDK-only diagnostics.
  static const bool submitFacebookLoginToBackend = bool.fromEnvironment(
    'FACEBOOK_SUBMIT_TO_BACKEND',
    defaultValue: true,
  );
}
