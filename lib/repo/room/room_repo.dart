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

  /// Calls `GET /api/room/list` to fetch active live rooms.
  Future<Map<String, dynamic>?> listActiveRooms({
    required String type, // 'AUDIO' or 'VIDEO'
    String? country,
    bool isShowLoader = true,
  }) async {
    var path = '${RoomEndpoints.listActiveRooms}?type=$type';
    if (country != null && country.isNotEmpty) {
      path += '&country=${Uri.encodeComponent(country)}';
    }

    final response = await _apiService.getRequest(
      endPoint: path,
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/room/join` to join a room.
  Future<Map<String, dynamic>?> joinRoom({
    required String roomId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: RoomEndpoints.joinRoom,
      requestModel: <String, dynamic>{
        'room_id': roomId,
      },
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/room/mic-action` to change seat status.
  Future<Map<String, dynamic>?> micAction({
    required String roomId,
    required String action, // 'mute', 'unmute', 'lock', 'unlock'
    required int seatId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: RoomEndpoints.micAction,
      requestModel: <String, dynamic>{
        'room_id': roomId,
        'action': action,
        'seat_id': seatId,
      },
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/room/security-sos` to trigger a security SOS.
  Future<Map<String, dynamic>?> securitySos({
    required String roomId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: RoomEndpoints.securitySos,
      requestModel: <String, dynamic>{
        'room_id': roomId,
      },
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }
}
