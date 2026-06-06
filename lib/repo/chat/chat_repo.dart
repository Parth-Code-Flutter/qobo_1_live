import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

/// Chat repository contains API calls for private message inbox and history.
class ChatRepo {
  ChatRepo({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<Map<String, dynamic>?> getInbox({bool isShowLoader = true}) async {
    final response = await _apiService.getRequest(
      endPoint: ChatEndpoints.list,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> getConversation({
    required String targetId,
    int page = 1,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint:
          '${ChatEndpoints.detail}?target_id=${Uri.encodeComponent(targetId)}&page=$page',
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `POST /api/chat/room` — create/bootstrap chat room before messaging.
  Future<Map<String, dynamic>?> createRoom({
    required String targetId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: ChatEndpoints.createRoom,
      requestModel: <String, dynamic>{'target_id': targetId},
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }
}
