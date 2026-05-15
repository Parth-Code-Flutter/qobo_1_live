import 'package:qobo_one_live/services/social_auth/social_auth_user.dart';

/// Request body for `POST /api/auth/social`.
///
/// See [API_ENDPOINTS_SUMMARY.md] for the contract.
class SocialLoginRequestModel {
  SocialLoginRequestModel({
    required this.name,
    required this.email,
    required this.socialId,
    required this.authType,
    this.phone,
    this.displayPicture,
  });

  factory SocialLoginRequestModel.fromSocialUser(SocialAuthUser user) {
    final name = user.displayName.trim().isNotEmpty
        ? user.displayName.trim()
        : 'User';
    return SocialLoginRequestModel(
      name: name,
      email: user.email.trim(),
      phone: user.phone?.trim(),
      socialId: user.socialId,
      authType: user.providerId,
      displayPicture: user.photoUrl?.trim(),
    );
  }

  final String name;
  final String email;
  final String socialId;
  final String authType;
  final String? phone;
  final String? displayPicture;

  /// `POST /api/auth/social` — optional keys omitted when empty.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'authType': authType,
      'socialId': socialId.trim(),
    };
    if (email.trim().isNotEmpty) map['email'] = email.trim();
    final p = phone?.trim();
    if (p != null && p.isNotEmpty) map['phone'] = p;
    final pic = displayPicture?.trim();
    if (pic != null && pic.isNotEmpty) map['displayPicture'] = pic;
    return map;
  }
}
