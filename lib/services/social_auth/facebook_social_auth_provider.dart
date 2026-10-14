import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import 'social_auth_provider.dart';
import 'social_auth_user.dart';

/// Facebook Login via [flutter_facebook_auth].
///
/// Requires Meta app id + client token in Android resources (see `strings.xml`).
/// Opens the native Facebook flow / account picker when Facebook app or browser is available.
class FacebookSocialAuthProvider implements SocialAuthProvider {
  FacebookSocialAuthProvider();

  @override
  Future<SocialAuthUser?> signIn() async {
    try {
      return await _signInWithFacebookSdk();
    } on MissingPluginException {
      throw Exception(
        'Facebook Login did not load. Usually the Meta SDK rejected '
        'android/app/src/main/res/values/strings.xml facebook_app_id '
        '(it must be your numeric App ID). '
        'Uninstall the app, fix strings.xml, then run flutter clean and flutter run. '
        'Search Logcat for: Error registering plugin flutter_facebook_auth',
      );
    }
  }

  Future<SocialAuthUser?> _signInWithFacebookSdk() async {
    final LoginResult result = await FacebookAuth.instance.login(
      permissions: const <String>['email', 'public_profile'],
      loginBehavior: LoginBehavior.nativeWithFallback,
    );

    // User closed the sheet — same as Google cancel (no error toast).
    if (result.status == LoginStatus.cancelled) return null;

    if (result.status != LoginStatus.success) {
      throw Exception(result.message ?? 'Facebook login failed');
    }

    final token = result.accessToken;
    if (token == null) {
      throw StateError(
        'Facebook login did not return an authentication token.',
      );
    }
    // Limited Login on iOS returns profile claims in the SDK token. That token
    // cannot be used for a Graph API /me request.
    final Map<String, dynamic> userData = token is LimitedToken
        ? {'id': token.userId, 'name': token.userName, 'email': token.userEmail}
        : await FacebookAuth.instance.getUserData(
            fields: 'id,name,email,picture.width(200)',
          );

    final id = userData['id'] as String?;
    if (id == null || id.trim().isEmpty) {
      throw StateError('Facebook profile did not return an account id.');
    }

    final trimmedId = id.trim();
    final rawEmail = (userData['email'] as String?)?.trim() ?? '';
    // Email is optional in the social-login request. Never invent an address
    // for an account that declined email permission or has no email.
    final email = rawEmail;

    final name = (userData['name'] as String?)?.trim();
    final displayName = (name != null && name.isNotEmpty)
        ? name
        : (email.isNotEmpty ? email.split('@').first : 'Facebook User');

    String? photoUrl;
    final picture = userData['picture'];
    if (picture is Map<String, dynamic>) {
      final data = picture['data'];
      if (data is Map<String, dynamic>) {
        final url = data['url'];
        if (url is String && url.isNotEmpty) photoUrl = url;
      }
    }

    return SocialAuthUser(
      providerId: 'facebook',
      socialId: trimmedId,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }
}
