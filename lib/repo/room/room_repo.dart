import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

/// Room repository contains API calls for room management (create, join, etc).
class RoomRepo {
  RoomRepo({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  /// Calls `POST /api/room/create` to create a live room.
  ///
  /// Returns decoded JSON map on success, otherwise `null`.
  Future<Map<String, dynamic>?> createRoom({
    required String name,
    required String type, // 'AUDIO' or 'VIDEO'
    required String country,
    required int maxSeats,
    bool isPrivate = false,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: RoomEndpoints.create,
      requestModel: <String, dynamic>{
        'name': name,
        'type': type,
        'country': country,
        'maxSeats': maxSeats,
        'isPrivate': isPrivate,
      },
      isShowLoader: isShowLoader,
      isLoginCall: false, // assuming user is already logged in
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }
}
