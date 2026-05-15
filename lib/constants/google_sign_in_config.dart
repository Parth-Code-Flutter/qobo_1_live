/// Google Sign-In OAuth IDs (Google Cloud / Firebase project **qobo1live-914ac**).
///
/// **Android** (`google_sign_in` 7.x): [webServerClientId] must be the **Web application**
/// OAuth client (client_type 3), never the Android client ID.
///
/// Register `com.qobo1live.live` + your debug SHA-1 in Firebase Console → Project settings
/// → Your apps → Android, or in GCP Credentials for the same project as [webServerClientId].
abstract final class GoogleSignInConfig {
  GoogleSignInConfig._();

  /// Web application OAuth client (client_type 3) — used as Android `serverClientId`.
  static const String webServerClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '152049582917-r07ktr1kgeq70ongu0gpatc4sj1gnd6d.apps.googleusercontent.com',
  );

  /// Legacy alias.
  static const String serverClientId = webServerClientId;

  /// iOS client ID (create an iOS OAuth client in the same GCP project if needed).
  static const String iosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue: webServerClientId,
  );

  static const String iosUrlScheme =
      'com.googleusercontent.apps.152049582917-r07ktr1kgeq70ongu0gpatc4sj1gnd6d';

  static const bool submitGoogleLoginToBackend = bool.fromEnvironment(
    'GOOGLE_SUBMIT_TO_BACKEND',
    defaultValue: true,
  );
}
