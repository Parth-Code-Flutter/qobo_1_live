import 'package:google_sign_in/google_sign_in.dart';

import 'package:qobo_one_live/constants/google_sign_in_config.dart';

import 'social_auth_provider.dart';
import 'social_auth_user.dart';

/// Google Sign-In backed implementation of [SocialAuthProvider].
///
/// Platform setup (do once per platform):
/// - **Android**: Add OAuth client in Google Cloud Console with your app’s SHA-1,
///   download/use configuration as described in `google_sign_in` README.
/// - **iOS**: Add URL scheme / client ID per `google_sign_in` iOS setup.
///
/// This class uses `google_sign_in` v7+: [GoogleSignIn.instance.initialize] must
/// complete before [authenticate].
///
/// On Android, initialization **must** resolve a non-empty Web client ID (`serverClientId`).
/// Pass [GoogleSignInConfig.serverClientId] via `--dart-define` or define
/// `default_web_client_id` in Android `strings.xml` — see [GoogleSignInConfig].
class GoogleSocialAuthProvider implements SocialAuthProvider {
  GoogleSocialAuthProvider();

  /// Shared init future so multiple calls await the same initialization.
  static Future<void>? _initFuture;

  Future<void> _ensureInitialized() {
    _initFuture ??= _initializeOnce();
    return _initFuture!;
  }

  /// Ensures Credential Manager has a `serverClientId` (avoids broken native fallback).
  Future<void> _initializeOnce() async {
    final fromDefine = GoogleSignInConfig.serverClientId.trim();
    await GoogleSignIn.instance.initialize(
      serverClientId: fromDefine.isEmpty ? null : fromDefine,
    );
  }

  @override
  Future<SocialAuthUser?> signIn() async {
    await _ensureInitialized();

    try {
      final GoogleSignInAccount account = await GoogleSignIn.instance
          .authenticate(scopeHint: const <String>['email', 'profile']);

      final email = account.email.trim();
      if (email.isEmpty) {
        throw StateError('Your Google account has no email address.');
      }

      final name = (account.displayName ?? '').trim();

      return SocialAuthUser(
        providerId: 'google',
        socialId: account.id,
        email: email,
        displayName: name.isNotEmpty ? name : email.split('@').first,
        photoUrl: account.photoUrl,
      );
    } on GoogleSignInException catch (e) {
      // User dismissed picker / flow cancelled — not an error for UX.
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      rethrow;
    }
  }
}
