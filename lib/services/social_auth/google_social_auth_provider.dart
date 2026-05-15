import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:qobo_one_live/constants/google_sign_in_config.dart';

import 'social_auth_provider.dart';
import 'social_auth_user.dart';

/// Google Sign-In via `google_sign_in` v7 (Credential Manager on Android).
class GoogleSocialAuthProvider implements SocialAuthProvider {
  GoogleSocialAuthProvider();

  static Future<void>? _initFuture;

  Future<void> _ensureInitialized() {
    _initFuture ??= _initializeOnce();
    return _initFuture!;
  }

  Future<void> _initializeOnce() async {
    final webId = GoogleSignInConfig.webServerClientId.trim();
    if (webId.isEmpty) {
      throw StateError(
        'Google Sign-In: missing Web OAuth client ID (GOOGLE_WEB_CLIENT_ID).',
      );
    }

    final isIos = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

    await GoogleSignIn.instance.initialize(
      clientId: isIos ? GoogleSignInConfig.iosClientId.trim() : null,
      serverClientId: webId,
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
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      throw StateError(_messageForGoogleException(e));
    } catch (e) {
      throw StateError('Google sign-in failed: $e');
    }
  }

  String _messageForGoogleException(GoogleSignInException e) {
    final detail = (e.description ?? e.toString()).trim();
    final lower = detail.toLowerCase();

    if (e.code == GoogleSignInExceptionCode.unknownError &&
        (detail.contains('28444') ||
            lower.contains('developer console') ||
            lower.contains('not set up correctly'))) {
      return 'Google Sign-In setup error (28444). In Firebase project qobo1live-914ac '
          '(or the same GCP project as your Web client): register Android app '
          'package com.qobo1live.live with SHA-1 '
          '01:EC:6E:88:2F:E0:EC:3A:22:08:2B:8A:D0:22:97:C8:0E:EA:B0:C6, '
          'then flutter clean, uninstall the app, and reinstall.';
    }

    if (e.code == GoogleSignInExceptionCode.clientConfigurationError) {
      return 'Google Sign-In is misconfigured. Use a Web application OAuth client ID '
          'for serverClientId (not the Android client ID). $detail';
    }

    return 'Google sign-in failed (${e.code}). $detail';
  }
}
