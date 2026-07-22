import 'dart:io';

/// Request model for `PUT /api/user/update` (multipart/form-data).
///
/// All fields are optional per API contract.
class UpdateProfileRequestModel {
  const UpdateProfileRequestModel({
    this.name,
    this.email,
    this.gender,
    this.dob,
    this.displayPicture,
    this.poster,
    this.relationshipStatus,
    this.languages,
    this.interests,
    this.currentLocation,
    this.country,
    this.countryId,
    this.state,
    this.stateId,
    this.city,
    this.coinsPerSecond,
  });

  final String? name;
  final String? email;
  final String? gender;
  /// `YYYY-MM-DD`
  final String? dob;
  final File? displayPicture;
  /// Catalog / remote poster URL (ads banner selection).
  final String? poster;
  final String? relationshipStatus;
  /// CSV or JSON array string — we send CSV (e.g. `English, Hindi`).
  final String? languages;
  final String? interests;
  final String? currentLocation;
  final String? country;
  final String? countryId;
  final String? state;
  final String? stateId;
  final String? city;
  final double? coinsPerSecond;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name?.trim(),
      'email': email?.trim(),
      'gender': gender?.trim(),
      'dob': dob?.trim(),
      'poster': poster?.trim(),
      'posterUrl': poster?.trim(),
      'relationshipStatus': relationshipStatus?.trim(),
      'languages': languages?.trim(),
      'interests': interests?.trim(),
      'currentLocation': currentLocation?.trim(),
      'country': country?.trim(),
      'countryId': countryId?.trim(),
      'state': state?.trim(),
      'stateId': stateId?.trim(),
      'city': city?.trim(),
      if (coinsPerSecond != null) 'coinsPerSecond': coinsPerSecond,
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
