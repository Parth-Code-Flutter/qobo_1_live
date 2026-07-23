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
      endPoint:
          '${PkEndpoints.searchOpponents}?room_id=${Uri.encodeComponent(roomId)}',
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/pk/send-request` to challenge a target room to a PK battle.
  Future<Map<String, dynamic>?> sendPkRequest({
    required String roomId,
    required String targetRoomId,
    int duration = 300,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: PkEndpoints.sendRequest,
      requestModel: <String, dynamic>{
        'room_id': roomId,
        'target_room_id': targetRoomId,
        'duration': duration,
      },
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/pk/accept-reject` to accept or reject a PK request.
  Future<Map<String, dynamic>?> acceptRejectPkRequest({
    required String roomId,
    required String requestId,
    required String action, // 'accept' or 'reject'
    int duration = 300,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: PkEndpoints.acceptReject,
      requestModel: <String, dynamic>{
        'room_id': roomId,
        'request_id': requestId,
        'action': action,
        'duration': duration,
      },
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/pk/cancel-request` to cancel an outgoing challenge.
  Future<Map<String, dynamic>?> cancelPkRequest({
    required String roomId,
    required String requestId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: PkEndpoints.cancelRequest,
      requestModel: <String, dynamic>{
        'room_id': roomId,
        'request_id': requestId,
      },
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/pk/end` to force-end an active battle.
  Future<Map<String, dynamic>?> endPkBattle({
    required String battleId,
    required String roomId,
    String reason = 'host_leave',
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: PkEndpoints.endBattle,
      requestModel: <String, dynamic>{
        'battle_id': battleId,
        'room_id': roomId,
        'reason': reason,
      },
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `GET /api/pk/status?battle_id=...`.
  Future<Map<String, dynamic>?> getPkStatus({
    required String battleId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint:
          '${PkEndpoints.status}?battle_id=${Uri.encodeComponent(battleId)}',
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `GET /api/pk/active?room_id=...` for pending request / active battle.
  Future<Map<String, dynamic>?> getActivePk({
    required String roomId,
    bool isShowLoader = false,
  }) async {
    final id = roomId.trim();
    if (id.isEmpty) return null;
    final response = await _apiService.getRequest(
      endPoint: '${PkEndpoints.active}?room_id=${Uri.encodeComponent(id)}',
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/pk/dating-onboarding` to save call preferences.
  Future<Map<String, dynamic>?> callOnboarding({
    required List<String> interests,
    String? preferredGender,
    int? minAge,
    int? maxAge,
    String? location,
    String? lookingFor,
    String? aboutMe,
    bool isShowLoader = true,
  }) async {
    // Keep payload aligned with backend profile fields.
    final payload = <String, dynamic>{
      'interests': interests,
      if (preferredGender != null && preferredGender.trim().isNotEmpty)
        'preferredGender': preferredGender,
      if (minAge != null) 'minAge': minAge,
      if (maxAge != null) 'maxAge': maxAge,
      if (location != null && location.trim().isNotEmpty)
        'location': location.trim(),
      if (lookingFor != null && lookingFor.trim().isNotEmpty)
        'lookingFor': lookingFor.trim(),
      // The DOCX lists `aboutMe`, but the deployed backend currently rejects
      // that field in Prisma. Keep the parameter for callers and omit it until
      // the backend migration lands.
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
  Future<Map<String, dynamic>?> getCallList({bool isShowLoader = true}) async {
    final response = await _apiService.getRequest(
      endPoint: PkEndpoints.callList,
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/pk/dating-action` for like/dislike/superlike swipes.
  Future<Map<String, dynamic>?> datingAction({
    required String targetId,
    required String type, // 'like', 'dislike', or 'superlike'
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: PkEndpoints.datingAction,
      requestModel: <String, dynamic>{'target_id': targetId, 'type': type},
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }
}
