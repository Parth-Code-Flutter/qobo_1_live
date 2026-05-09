import 'social_auth_user.dart';

/// Contract for native social sign-in flows.
///
/// Each provider (Google, Facebook, Apple, …) implements this so UI/controllers
/// stay provider-agnostic.
abstract class SocialAuthProvider {
  /// Opens the provider UI and returns a normalized user, or `null` if the user
  /// cancelled / dismissed the flow (no error toast in that case).
  Future<SocialAuthUser?> signIn();
}
