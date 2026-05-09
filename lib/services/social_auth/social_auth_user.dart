/// Normalized user profile returned by any social OAuth provider (Google, Facebook, …).
///
/// Maps cleanly onto `POST /api/auth/social` body fields.
class SocialAuthUser {
  const SocialAuthUser({
    required this.providerId,
    required this.socialId,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.phone,
  });

  /// Backend `authType`, e.g. `"google"`.
  final String providerId;

  /// Stable provider user id (maps to `socialId` in API).
  final String socialId;

  final String email;

  /// Fallback to `"User"` in request model if empty.
  final String displayName;

  final String? photoUrl;

  /// Optional; omitted or empty when not collected during OAuth.
  final String? phone;
}
