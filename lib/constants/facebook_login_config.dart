/// Demo vs production behavior for Facebook Login (same pattern as Google).
///
/// Replace placeholders in `android/app/src/main/res/values/strings.xml`:
/// `facebook_app_id`, `facebook_client_token` (Meta Developer App dashboard).
abstract final class FacebookLoginConfig {
  FacebookLoginConfig._();

  /// When `false` (default), only runs the Facebook login UI and shows a toast.
  /// When implementing `/api/auth/social` for Facebook, set compile-time flag
  /// FACEBOOK_SUBMIT_TO_BACKEND to true (see project README or CI scripts).
  static const bool submitFacebookLoginToBackend = bool.fromEnvironment(
    'FACEBOOK_SUBMIT_TO_BACKEND',
    defaultValue: false,
  );
}
