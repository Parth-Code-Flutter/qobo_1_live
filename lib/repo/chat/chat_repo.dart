import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

/// Chat repository — REST calls for inbox, history, room bootstrap, Firebase token, reports.
class ChatRepo {
  ChatRepo({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  /// `GET /api/chat/list` — inbox threads.
  Future<Map<String, dynamic>?> getInbox({bool isShowLoader = true}) async {
    final response = await _apiService.getRequest(
      endPoint: ChatEndpoints.list,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `GET /api/chat/detail` — paginated history with partner.
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

  /// `POST /api/chat/room` — create or return existing 1:1 room.
  Future<Map<String, dynamic>?> createRoom({
    required String targetId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: ChatEndpoints.createRoom,
      requestModel: <String, dynamic>{
        'type': 'direct',
        'target_id': targetId,
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `POST /api/chat/firebase-token` — custom token for Firestore access.
  Future<Map<String, dynamic>?> getFirebaseToken({
    bool isShowLoader = false,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: ChatEndpoints.firebaseToken,
      requestModel: <String, dynamic>{},
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `POST /api/chat/report` — report abusive message.
  Future<Map<String, dynamic>?> reportMessage({
    required String roomId,
    required String messageId,
    required String reason,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: ChatEndpoints.report,
      requestModel: <String, dynamic>{
        'roomId': roomId,
        'messageId': messageId,
        'reason': reason,
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `POST /api/chat/send` — persist a message to the partner thread.
  Future<Map<String, dynamic>?> sendMessage({
    required String targetId,
    required String content,
    String type = 'text',
    String? roomId,
    bool isShowLoader = false,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: ChatEndpoints.send,
      requestModel: <String, dynamic>{
        'target_id': targetId,
        'content': content,
        'type': type,
        if (roomId != null && roomId.isNotEmpty) 'room_id': roomId,
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `POST /api/user/fcm-token` — register device push token.
  Future<Map<String, dynamic>?> registerFcmToken({
    required String token,
    required String platform,
    bool isShowLoader = false,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: UserEndpoints.fcmToken,
      requestModel: <String, dynamic>{
        'token': token,
        'platform': platform,
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `POST /api/chat/delete` — remove conversation from inbox (for me).
  Future<Map<String, dynamic>?> deleteChat({
    required String targetId,
    String? roomId,
    bool isShowLoader = false,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: ChatEndpoints.deleteChat,
      requestModel: <String, dynamic>{
        'target_id': targetId,
        if (roomId != null && roomId.isNotEmpty) 'room_id': roomId,
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `POST /api/chat/block` — block user and optionally delete chat.
  Future<Map<String, dynamic>?> blockUserFromChat({
    required String targetId,
    String? roomId,
    bool deleteChat = true,
    bool isShowLoader = false,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: ChatEndpoints.blockFromChat,
      requestModel: <String, dynamic>{
        'target_id': targetId,
        if (roomId != null && roomId.isNotEmpty) 'room_id': roomId,
        'delete_chat': deleteChat,
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `POST /api/chat/read` — reset unread count for a thread.
  Future<Map<String, dynamic>?> markThreadRead({
    required String targetId,
    String? roomId,
    bool isShowLoader = false,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: ChatEndpoints.markRead,
      requestModel: <String, dynamic>{
        'target_id': targetId,
        if (roomId != null && roomId.isNotEmpty) 'room_id': roomId,
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `POST /api/chat/mute` — mute or unmute a thread.
  Future<Map<String, dynamic>?> setThreadMuted({
    required String roomId,
    required bool muted,
    bool isShowLoader = false,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: ChatEndpoints.mute,
      requestModel: <String, dynamic>{
        'room_id': roomId,
        'muted': muted,
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `GET /api/chat/can-message` — check if chat is allowed.
  Future<Map<String, dynamic>?> canMessage({
    required String targetId,
    bool isShowLoader = false,
  }) async {
    final response = await _apiService.getRequest(
      endPoint:
          '${ChatEndpoints.canMessage}?target_id=${Uri.encodeComponent(targetId)}',
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }
}
