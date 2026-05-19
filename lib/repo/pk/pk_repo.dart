import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

/// PK repository contains API calls for PK Battles and Dating Onboarding / Matching.
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

  /// Calls `POST /api/pk/dating-onboarding` to save dating preferences.
  Future<Map<String, dynamic>?> datingOnboarding({
    required List<String> interests,
    required String lookingFor,
    required String aboutMe,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: PkEndpoints.datingOnboarding,
      requestModel: <String, dynamic>{
        'interests': interests,
        'lookingFor': lookingFor,
        'aboutMe': aboutMe,
      },
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `GET /api/pk/dating-list` to list available matching profiles.
  Future<Map<String, dynamic>?> getDatingList({
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: PkEndpoints.datingList,
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }
}
