import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

/// PK repository contains API calls for PK Battles and Call Onboarding / Matching.
class PkRepo {
  PkRepo({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  /// Calls `GET /api/pk/search?room_id=...` to search active PK opponents.
  Future<Map<String, dynamic>?> searchOpponents({
    required String roomId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: '${PkEndpoints.searchOpponents}?room_id=${Uri.encodeComponent(roomId)}',
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/pk/send-request` to challenge a target room to a PK battle.
  Future<Map<String, dynamic>?> sendPkRequest({
    required String targetRoomId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: PkEndpoints.sendRequest,
      requestModel: <String, dynamic>{
        'target_room_id': targetRoomId,
      },
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/pk/dating-onboarding` to save call preferences.
  Future<Map<String, dynamic>?> callOnboarding({
    required List<String> interests,
    required String preferredGender,
    required int minAge,
    required int maxAge,
    String? location,
    bool isShowLoader = true,
  }) async {
    // Keep payload aligned with backend profile fields.
    final payload = <String, dynamic>{
      'interests': interests,
      'preferredGender': preferredGender,
      'minAge': minAge,
      'maxAge': maxAge,
      if (location != null && location.trim().isNotEmpty)
        'location': location.trim(),
    };

    final response = await _apiService.postRequest(
      endPoint: PkEndpoints.callOnboarding,
      requestModel: payload,
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `GET /api/pk/dating-list` to list available matching profiles.
  Future<Map<String, dynamic>?> getCallList({
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: PkEndpoints.callList,
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }
}
