import 'dart:io';

/// Request model for `PUT /api/user/update`.
///
/// All fields are optional as per API contract.
class UpdateProfileRequestModel {
  const UpdateProfileRequestModel({
    this.name,
    this.bio,
    this.gender,
    this.dob,
    this.country,
    this.password,
    this.displayPicture,
  });

  final String? name;
  final String? bio;
  final String? gender;
  final String? dob;
  final String? country;
  final String? password;
  final File? displayPicture;

  /// JSON payload for non-file update requests.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name?.trim(),
      'bio': bio?.trim(),
      'gender': gender?.trim(),
      'dob': dob?.trim(),
      'country': country?.trim(),
      'password': password?.trim(),
    };
    json.removeWhere((key, value) => value == null || (value is String && value.isEmpty));
    return json;
  }

  /// Multipart form fields when `displayPicture` is sent.
  Map<String, String> toFormFields() {
    return toJson().map((key, value) => MapEntry(key, value.toString()));
  }
}
