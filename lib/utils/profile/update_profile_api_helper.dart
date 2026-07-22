import 'dart:io';

import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/update_profile/models/request/update_profile_request_model.dart';
import 'package:qobo_one_live/app/user_flow/update_profile/models/response/update_profile_response_model.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';

/// Builds `PUT /api/user/update` payloads shared by auth + basic profile screens.
class UpdateProfileApiHelper {
  const UpdateProfileApiHelper._();

  static UpdateProfileRequestModel buildRequest({
    String? name,
    String? email,
    String? genderLabel,
    DateTime? dob,
    File? displayPicture,
    String? poster,
    String? relationshipStatus,
    String? languages,
    String? interests,
    String? currentLocation,
    String? country,
    String? countryId,
    String? state,
    String? stateId,
    String? city,
    double? coinsPerSecond,
  }) {
    return UpdateProfileRequestModel(
      name: _nonEmpty(name),
      email: _nonEmpty(email),
      gender: genderForApi(genderLabel ?? ''),
      dob: dob != null ? formatDobForApi(dob) : null,
      displayPicture: displayPicture,
      poster: _nonEmpty(poster),
      relationshipStatus: _nonEmpty(relationshipStatus),
      languages: _nonEmpty(languages),
      interests: _nonEmpty(interests),
      currentLocation: _nonEmpty(currentLocation),
      country: _nonEmpty(country),
      countryId: _nonEmpty(countryId),
      state: _nonEmpty(state),
      stateId: _nonEmpty(stateId),
      city: _nonEmpty(city),
      coinsPerSecond: coinsPerSecond,
    );
  }

  /// API expects `YYYY-MM-DD`.
  static String formatDobForApi(DateTime dob) {
    final month = dob.month.toString().padLeft(2, '0');
    final day = dob.day.toString().padLeft(2, '0');
    return '${dob.year}-$month-$day';
  }

  /// Maps UI chip label to API values: Male, Female, Other.
  static String? genderForApi(String uiLabel) {
    final s = uiLabel.trim().toLowerCase();
    if (s.isEmpty) return null;
    if (s == 'male' || s == 'm') return 'Male';
    if (s == 'female' || s == 'f') return 'Female';
    if (s == 'other') return 'Other';
    final t = uiLabel.trim();
    return t[0].toUpperCase() + t.substring(1).toLowerCase();
  }

  static String? _nonEmpty(String? value) {
    final v = value?.trim() ?? '';
    return v.isEmpty ? null : v;
  }

  static Future<void> persistUserToSession(UpdateProfileResponseModel response) async {
    final user = response.data;
    if (user == null) return;
    final session = Get.isRegistered<UserSessionController>()
        ? Get.find<UserSessionController>()
        : Get.put(UserSessionController(), permanent: true);
    await session.saveProfile(user.toProfileMap());
  }
}
