import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

/// Call hub repository — history, user search, direct call start/end.
class CallRepo {
  CallRepo({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  /// `GET /api/call/history`
  Future<Map<String, dynamic>?> getHistory({
    String filter = 'all',
    String callType = 'all',
    int page = 1,
    int limit = 30,
    bool isShowLoader = false,
  }) async {
    final params = <String, String>{
      'filter': filter.trim().isEmpty ? 'all' : filter.trim().toLowerCase(),
      'call_type': callType.trim().isEmpty
          ? 'all'
          : callType.trim().toLowerCase(),
      'page': page.toString(),
      'limit': limit.toString(),
    };
    final path =
        '${CallModuleEndpoints.history}?${Uri(queryParameters: params).query}';
    final response = await _apiService.getRequest(
      endPoint: path,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `GET /api/call/users/search?q=`
  Future<Map<String, dynamic>?> searchUsers({
    required String query,
    int page = 1,
    int limit = 20,
    bool isShowLoader = false,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return null;
    final params = <String, String>{
      'q': q,
      'page': page.toString(),
      'limit': limit.toString(),
    };
    final path =
        '${CallModuleEndpoints.usersSearch}?${Uri(queryParameters: params).query}';
    final response = await _apiService.getRequest(
      endPoint: path,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `POST /api/call/start` — backend creates the active call session.
  Future<Map<String, dynamic>?> startDirectCall({
    required String calleeUserId,
    required String callType, // voice | video
    bool isShowLoader = false,
  }) async {
    final body = <String, dynamic>{
      'calleeUserId': calleeUserId.trim(),
      'callType': callType.trim().toLowerCase(),
    };

    final response = await _postWithLegacyFallback(
      endPoint: CallModuleEndpoints.directStart,
      legacyEndPoint: CallModuleEndpoints.legacyDirectStart,
      requestModel: body,
      isShowLoader: isShowLoader,
    );
    return response;
  }

  /// `POST /api/call/respond` — callee accepts or rejects an in-app ring.
  Future<Map<String, dynamic>?> respondDirectCall({
    required String callId,
    required String action, // accept | reject
    String? roomId,
    bool isShowLoader = false,
  }) async {
    return _postWithLegacyFallback(
      endPoint: CallModuleEndpoints.directRespond,
      legacyEndPoint: CallModuleEndpoints.legacyDirectRespond,
      requestModel: <String, dynamic>{
        'callId': callId.trim(),
        'call_id': callId.trim(),
        'action': action.trim().toLowerCase(),
        if (roomId != null && roomId.trim().isNotEmpty) ...{
          'roomId': roomId.trim(),
          'room_id': roomId.trim(),
        },
      },
      isShowLoader: isShowLoader,
    );
  }

  /// `POST /api/call/end`
  ///
  /// When [durationSeconds] > 0 the backend auto-runs calling charge (50/50
  /// split) — do not also call [CallingRepo.chargeCall] for the same session.
  Future<Map<String, dynamic>?> endDirectCall({
    required String callId,
    required String reason, // user_hangup | missed | rejected | cancelled
    int? durationSeconds,
    String? hostId,
    bool isShowLoader = false,
  }) async {
    final body = <String, dynamic>{
      'callId': callId.trim(),
      'call_id': callId.trim(),
      'reason': reason.trim().toLowerCase(),
    };
    if (durationSeconds != null && durationSeconds > 0) {
      body['durationSeconds'] = durationSeconds;
      body['duration_seconds'] = durationSeconds;
    }
    if (hostId != null && hostId.trim().isNotEmpty) {
      body['hostId'] = hostId.trim();
      body['host_id'] = hostId.trim();
    }

    final response = await _postWithLegacyFallback(
      endPoint: CallModuleEndpoints.directEnd,
      legacyEndPoint: CallModuleEndpoints.legacyDirectEnd,
      requestModel: body,
      isShowLoader: isShowLoader,
    );
    return response;
  }

  Future<Map<String, dynamic>?> _postWithLegacyFallback({
    required String endPoint,
    required String legacyEndPoint,
    required Map<String, dynamic> requestModel,
    required bool isShowLoader,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: endPoint,
      requestModel: requestModel,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;

    if (response.statusCode == 404) {
      final legacyResponse = await _apiService.postRequest(
        endPoint: legacyEndPoint,
        requestModel: requestModel,
        isShowLoader: false,
      );
      if (legacyResponse == null) return null;
      return ApiResponseUtils.tryDecodeMap(legacyResponse.body);
    }

    return ApiResponseUtils.tryDecodeMap(response.body);
  }
}
