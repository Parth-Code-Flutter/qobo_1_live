import 'dart:io';

/// Request model for `PUT /api/user/update` (multipart/form-data).
///
/// All fields are optional per API contract.
class UpdateProfileRequestModel {
  const UpdateProfileRequestModel({
    this.name,
    this.gender,
    this.dob,
    this.displayPicture,
    this.relationshipStatus,
    this.languages,
    this.interests,
    this.currentLocation,
  });

  final String? name;
  final String? gender;
  /// `YYYY-MM-DD`
  final String? dob;
  final File? displayPicture;
  final String? relationshipStatus;
  /// CSV or JSON array string — we send CSV (e.g. `English, Hindi`).
  final String? languages;
  final String? interests;
  final String? currentLocation;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name?.trim(),
      'gender': gender?.trim(),
      'dob': dob?.trim(),
      'relationshipStatus': relationshipStatus?.trim(),
      'languages': languages?.trim(),
      'interests': interests?.trim(),
      'currentLocation': currentLocation?.trim(),
    };
    json.removeWhere(
      (key, value) => value == null || (value is String && value.isEmpty),
    );
    return json;
  }

  /// Multipart text fields (file sent separately as `displayPicture`).
  Map<String, String> toFormFields() {
    return toJson().map((key, value) => MapEntry(key, value.toString()));
  }

  bool get hasFile => displayPicture != null;

  bool get hasAnyField => toFormFields().isNotEmpty || hasFile;
}
