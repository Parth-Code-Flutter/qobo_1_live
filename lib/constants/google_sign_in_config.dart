/// Configuration for [GoogleSignIn.instance.initialize].
///
/// **Android (`google_sign_in` 7.x)** uses the Credential Manager API and requires a
/// **Web application** OAuth 2.0 client ID (not the Android client ID). Create it in
/// [Google Cloud Console](https://console.cloud.google.com/) → APIs & Services → Credentials.
///
/// Provide the ID in either of these ways (you only need one):
/// 1. **Build-time (recommended for CI / no secrets in repo)**
///    `flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com`
/// 2. **Android resources**
///    Set `default_web_client_id` in `android/app/src/main/res/values/strings.xml`
abstract final class GoogleSignInConfig {
  GoogleSignInConfig._();

  /// Web OAuth client ID; empty means “let Android read `default_web_client_id` from resources”.
  static const String serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  /// When `false` (default), tapping “Login with Google” only opens the **Google account picker**
  /// and shows a confirmation — **no** `/api/auth/social` call (for client demos / APK handoff).
  ///
  /// Enable server login later with:
  /// `flutter run --dart-define=GOOGLE_SUBMIT_TO_BACKEND=true`
  /// (and keep [serverClientId] / `strings.xml` configured).
  static const bool submitGoogleLoginToBackend = bool.fromEnvironment(
    'GOOGLE_SUBMIT_TO_BACKEND',
    defaultValue: false,
  );
}
