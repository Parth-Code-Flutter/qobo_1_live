import 'dart:math';

import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

/// Mobile API wrapper for emoji catalog and direct room emoji sends.
class EmojiRepo {
  EmojiRepo({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<Map<String, dynamic>?> getEmojiCatalog({
    String? category,
    int? packVersion,
    bool isShowLoader = false,
  }) async {
    final query = <String, String>{
      if (category?.trim().isNotEmpty == true) 'category': category!.trim(),
      if (packVersion != null && packVersion > 0)
        'packVersion': packVersion.toString(),
    };

    var response = await _apiService.getRequest(
      endPoint: EmojiEndpoints.list,
      queryParams: query,
      isShowLoader: isShowLoader,
    );

    if (response?.statusCode == 404) {
      response = await _apiService.getRequest(
        endPoint: EmojiEndpoints.publicList,
        queryParams: query,
        isShowLoader: isShowLoader,
      );
    }

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> sendRoomEmoji({
    required String roomId,
    required String emojiId,
    required String sessionType,
    String? receiverId,
    int packVersion = 1,
    String? clientEventId,
    bool isShowLoader = true,
  }) async {
    final resolvedClientEventId = clientEventId?.trim().isNotEmpty == true
        ? clientEventId!.trim()
        : _newClientReqId();
    final body = <String, dynamic>{
      'roomId': roomId,
      'room_id': roomId,
      'emojiId': emojiId,
      'emoji_id': emojiId,
      'packVersion': packVersion,
      'pack_version': packVersion,
      'sessionType': sessionType,
      'session_type': sessionType,
      'clientEventId': resolvedClientEventId,
      'client_event_id': resolvedClientEventId,
    };
    final targetUserId = receiverId?.trim() ?? '';
    if (targetUserId.isNotEmpty) {
      body.addAll({
        'receiverId': targetUserId,
        'receiver_id': targetUserId,
        'targetUserId': targetUserId,
        'target_user_id': targetUserId,
      });
    }

    final response = await _apiService.postRequest(
      endPoint: EmojiEndpoints.sendRoom,
      requestModel: body,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> sendLiveStreamingEmoji({
    required String liveStreamingId,
    required String emojiId,
    String? receiverId,
    int packVersion = 1,
    String? clientEventId,
    bool isShowLoader = true,
  }) async {
    final resolvedClientEventId = clientEventId?.trim().isNotEmpty == true
        ? clientEventId!.trim()
        : _newClientReqId();
    final body = <String, dynamic>{
      'liveStreamingId': liveStreamingId,
      'live_streaming_id': liveStreamingId,
      'emojiId': emojiId,
      'emoji_id': emojiId,
      'packVersion': packVersion,
      'pack_version': packVersion,
      'clientEventId': resolvedClientEventId,
      'client_event_id': resolvedClientEventId,
    };
    final targetUserId = receiverId?.trim() ?? '';
    if (targetUserId.isNotEmpty) {
      body.addAll({
        'receiverId': targetUserId,
        'receiver_id': targetUserId,
        'targetUserId': targetUserId,
        'target_user_id': targetUserId,
      });
    }

    final response = await _apiService.postRequest(
      endPoint: EmojiEndpoints.sendLiveStreaming,
      requestModel: body,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> sendEmoji({
    required String emojiId,
    required String receiverId,
    required String roomId,
    required String type,
    String? clientReqId,
    bool isShowLoader = true,
  }) async {
    final resolvedClientReqId = clientReqId?.trim().isNotEmpty == true
        ? clientReqId!.trim()
        : _newClientReqId();
    final body = <String, dynamic>{
      'emojiId': emojiId,
      'emoji_id': emojiId,
      'receiverId': receiverId,
      'receiver_id': receiverId,
      'roomId': roomId,
      'room_id': roomId,
      'type': type,
      'clientReqId': resolvedClientReqId,
      'client_req_id': resolvedClientReqId,
    };

    var response = await _apiService.postRequest(
      endPoint: EmojiEndpoints.send,
      requestModel: body,
      isShowLoader: isShowLoader,
    );

    if (response?.statusCode == 404) {
      response = await _apiService.postRequest(
        endPoint: EmojiEndpoints.sendV1,
        requestModel: body,
        isShowLoader: isShowLoader,
      );
    }

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  String _newClientReqId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final randomPart = Random().nextInt(1 << 32).toRadixString(16);
    return 'emoji_${timestamp}_$randomPart';
  }
}
