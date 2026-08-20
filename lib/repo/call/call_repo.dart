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

  /// `POST /api/call/direct/start` — triggers backend FCM ring to callee.
  Future<Map<String, dynamic>?> startDirectCall({
    required String calleeUserId,
    required String callType, // voice | video
    required String clientCallId,
    String? roomId,
    String? historyDocId,
    bool isShowLoader = false,
  }) async {
    final body = <String, dynamic>{
      'calleeUserId': calleeUserId.trim(),
      'callType': callType.trim().toLowerCase(),
      'clientCallId': clientCallId.trim(),
    };
    if (roomId != null && roomId.trim().isNotEmpty) {
      body['roomId'] = roomId.trim();
    }
    if (historyDocId != null && historyDocId.trim().isNotEmpty) {
      body['historyDocId'] = historyDocId.trim();
    }

    final response = await _apiService.postRequest(
      endPoint: CallModuleEndpoints.directStart,
      requestModel: body,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `POST /api/call/direct/respond` — callee accepts or rejects a ring.
  Future<Map<String, dynamic>?> respondDirectCall({
    required String callId,
    required String action, // accept | reject
    String? roomId,
    bool isShowLoader = false,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: CallModuleEndpoints.directRespond,
      requestModel: <String, dynamic>{
        'callId': callId.trim(),
        'action': action.trim().toLowerCase(),
        if (roomId != null && roomId.trim().isNotEmpty) 'roomId': roomId.trim(),
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `POST /api/call/direct/end`
  Future<Map<String, dynamic>?> endDirectCall({
    required String callId,
    required String reason, // completed | missed | rejected | cancelled
    bool isShowLoader = false,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: CallModuleEndpoints.directEnd,
      requestModel: <String, dynamic>{
        'callId': callId.trim(),
        'reason': reason.trim().toLowerCase(),
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }
}
