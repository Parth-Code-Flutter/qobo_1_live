import 'dart:io';

import 'package:flutter/foundation.dart';
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
    String? title,
    required String type, // 'audio'/'video' or legacy 'AUDIO'/'VIDEO'
    required String country,
    required int maxSeats,
    String? category,
    String? coverImage,
    String? coverImageFilePath,
    bool isPrivate = false,
    bool isShowLoader = true,
  }) async {
    final roomTitle = (title == null || title.trim().isEmpty)
        ? name.trim()
        : title.trim();
    final trimmedCategory = category?.trim();
    final trimmedCoverImage = coverImage?.trim();
    final fields = <String, dynamic>{
      'title': roomTitle,
      'name': roomTitle,
      'roomName': roomTitle,
      'room_name': roomTitle,
      'type': type.trim().toLowerCase(),
      'country': country,
      'maxSeats': maxSeats,
      'seatConfig': maxSeats,
      'isPrivate': isPrivate,
      if (trimmedCategory != null && trimmedCategory.isNotEmpty)
        'category': trimmedCategory,
      if (trimmedCoverImage != null && trimmedCoverImage.isNotEmpty)
        'coverImage': trimmedCoverImage,
    };
    final coverFilePath = coverImageFilePath?.trim();
    final coverFile = coverFilePath == null || coverFilePath.isEmpty
        ? null
        : File(coverFilePath);

    if (coverFile != null && coverFile.existsSync()) {
      debugPrint('POST ${RoomEndpoints.create} multipart params: $fields');
      debugPrint(
        'POST ${RoomEndpoints.create} multipart files: {coverImage: ${coverFile.path}}',
      );
      final response = await _apiService.multipartFormRequest(
        endPoint: RoomEndpoints.create,
        fields: fields.map((key, value) => MapEntry(key, value.toString())),
        namedFiles: {'coverImage': coverFile},
        isShowLoader: isShowLoader,
      );

      if (response == null) return null;
      return ApiResponseUtils.tryDecodeMap(response.body);
    }

    debugPrint('POST ${RoomEndpoints.create} params: $fields');
    final response = await _apiService.postRequest(
      endPoint: RoomEndpoints.create,
      requestModel: fields,
      isShowLoader: isShowLoader,
      isLoginCall: false, // assuming user is already logged in
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/live-streaming/create` to register a host live stream.
  Future<Map<String, dynamic>?> createLiveStreaming({
    required String name,
    required String liveStreamingId,
    required bool onlyFollows,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: RoomEndpoints.createLiveStreaming,
      requestModel: <String, dynamic>{
        'name': name,
        'liveStreamingId': liveStreamingId,
        'onlyFollows': onlyFollows,
      },
      isShowLoader: isShowLoader,
      isLoginCall: false,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `GET /api/live-streaming/verify-access?userId=...`
  Future<Map<String, dynamic>?> verifyLiveStreamingAccess({
    required String userId,
    bool isShowLoader = false,
  }) async {
    final id = userId.trim();
    if (id.isEmpty) return null;
    final response = await _apiService.getRequest(
      endPoint:
          '${RoomEndpoints.verifyLiveStreamingAccess}?userId=${Uri.encodeComponent(id)}',
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `GET /api/room/list` to fetch active live rooms.
  Future<Map<String, dynamic>?> listActiveRooms({
    String? type, // 'audio'/'video' or legacy 'AUDIO'/'VIDEO'
    String? country,
    String? category,
    int page = 1,
    int limit = 20,
    bool isShowLoader = true,
  }) async {
    var path = RoomEndpoints.listActiveRooms;
    final params = <String, String>{};
    if (type != null && type.trim().isNotEmpty) {
      params['type'] = type.trim().toLowerCase();
    }
    if (country != null && country.isNotEmpty) {
      params['country'] = country;
    }
    if (category != null && category.trim().isNotEmpty) {
      params['category'] = category.trim();
    }
    params['page'] = page.toString();
    params['limit'] = limit.toString();
    if (params.isNotEmpty) {
      path += '?${Uri(queryParameters: params).query}';
    }

    final response = await _apiService.getRequest(
      endPoint: path,
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/room/leave` to leave a room.
  Future<Map<String, dynamic>?> leaveRoom({
    required String roomId,
    bool isShowLoader = false,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: RoomEndpoints.leaveRoom,
      requestModel: <String, dynamic>{'room_id': roomId},
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/room/end` to end a host room.
  Future<Map<String, dynamic>?> endRoom({
    required String roomId,
    bool isShowLoader = false,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: RoomEndpoints.endRoom,
      requestModel: <String, dynamic>{'room_id': roomId},
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
      requestModel: <String, dynamic>{'room_id': roomId},
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/room/mic-action` to change seat status.
  Future<Map<String, dynamic>?> micAction({
    String? roomId,
    required String action, // 'mute', 'unmute', 'lock', 'unlock'
    required int seatId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: RoomEndpoints.micAction,
      requestModel: <String, dynamic>{
        if (roomId != null && roomId.trim().isNotEmpty) 'room_id': roomId,
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
      requestModel: <String, dynamic>{'room_id': roomId},
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `GET /api/room/video-swiper` for discover video host cards.
  Future<Map<String, dynamic>?> getVideoSwiper({
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: RoomEndpoints.videoSwiper,
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `GET /api/room/agora-token?room_id=...`.
  Future<Map<String, dynamic>?> getAgoraToken({
    required String roomId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint:
          '${RoomEndpoints.agoraToken}?room_id=${Uri.encodeComponent(roomId)}',
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `GET /api/room/zego-token?room_id=...`.
  Future<Map<String, dynamic>?> getZegoToken({
    required String roomId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint:
          '${RoomEndpoints.zegoToken}?room_id=${Uri.encodeComponent(roomId)}',
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/room/kick`.
  Future<Map<String, dynamic>?> kickParticipant({
    required String roomId,
    required String targetUserId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: RoomEndpoints.kick,
      requestModel: <String, dynamic>{
        'room_id': roomId,
        'target_user_id': targetUserId,
      },
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `GET /api/room/watch-history`.
  Future<Map<String, dynamic>?> getWatchHistory({
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: RoomEndpoints.watchHistory,
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/room/watch-history/record`.
  Future<Map<String, dynamic>?> recordWatchHistory({
    required String roomId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: RoomEndpoints.recordWatchHistory,
      requestModel: <String, dynamic>{'room_id': roomId},
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `GET /api/room/share?room_id=...`.
  Future<Map<String, dynamic>?> getShareLink({
    required String roomId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint:
          '${RoomEndpoints.shareRoom}?room_id=${Uri.encodeComponent(roomId)}',
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `GET /api/room/translate?text=...&target_lang=...`.
  Future<Map<String, dynamic>?> translateText({
    required String text,
    required String targetLang,
    bool isShowLoader = true,
  }) async {
    final query = Uri(
      queryParameters: <String, String>{
        'text': text,
        'target_lang': targetLang,
      },
    ).query;
    final response = await _apiService.getRequest(
      endPoint: '${RoomEndpoints.translateText}?$query',
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }
}
