import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

/// Room repository contains API calls for room management (create, join, etc).
class RoomRepo {
  RoomRepo({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  /// Calls `POST /api/rooms` to create a live room.
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
    String? backgroundId,
    String? backgroundImage,
    bool isPrivate = false,
    bool joinApprovalRequired = false,
    bool isShowLoader = true,
  }) async {
    final roomTitle = (title == null || title.trim().isEmpty)
        ? name.trim()
        : title.trim();
    final trimmedCategory = category?.trim();
    final trimmedCoverImage = coverImage?.trim();
    final trimmedBackgroundId = backgroundId?.trim();
    final trimmedBackgroundImage = backgroundImage?.trim();
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
      'joinApprovalRequired': joinApprovalRequired,
      if (trimmedCategory != null && trimmedCategory.isNotEmpty)
        'category': trimmedCategory,
      if (trimmedCoverImage != null && trimmedCoverImage.isNotEmpty)
        'coverImage': trimmedCoverImage,
      if (trimmedBackgroundId != null && trimmedBackgroundId.isNotEmpty) ...{
        'backgroundId': trimmedBackgroundId,
        'background_id': trimmedBackgroundId,
      },
      if (trimmedBackgroundImage != null &&
          trimmedBackgroundImage.isNotEmpty) ...{
        'backgroundImage': trimmedBackgroundImage,
        'background_image': trimmedBackgroundImage,
      },
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
      var response = await _apiService.multipartFormRequest(
        endPoint: RoomEndpoints.create,
        fields: fields.map((key, value) => MapEntry(key, value.toString())),
        namedFiles: {'coverImage': coverFile},
        isShowLoader: isShowLoader,
      );

      if (response?.statusCode == 404) {
        response = await _apiService.multipartFormRequest(
          endPoint: RoomEndpoints.createLegacy,
          fields: fields.map((key, value) => MapEntry(key, value.toString())),
          namedFiles: {'coverImage': coverFile},
          isShowLoader: isShowLoader,
        );
      }

      if (response == null) return null;
      return ApiResponseUtils.tryDecodeMap(response.body);
    }

    debugPrint('POST ${RoomEndpoints.create} params: $fields');
    var response = await _apiService.postRequest(
      endPoint: RoomEndpoints.create,
      requestModel: fields,
      isShowLoader: isShowLoader,
      isLoginCall: false, // assuming user is already logged in
    );

    if (response?.statusCode == 404) {
      response = await _apiService.postRequest(
        endPoint: RoomEndpoints.createLegacy,
        requestModel: fields,
        isShowLoader: isShowLoader,
        isLoginCall: false,
      );
    }

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/live-streaming/create` to register a host live stream.
  Future<Map<String, dynamic>?> createLiveStreaming({
    required String name,
    required String liveStreamingId,
    required bool onlyFollows,
    bool joinApprovalRequired = false,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: RoomEndpoints.createLiveStreaming,
      requestModel: <String, dynamic>{
        'name': name,
        'liveStreamingId': liveStreamingId,
        'onlyFollows': onlyFollows,
        'joinApprovalRequired': joinApprovalRequired,
      },
      isShowLoader: isShowLoader,
      isLoginCall: false,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/live-streaming/end` to close a host live stream.
  Future<Map<String, dynamic>?> endLiveStreaming({
    required String liveStreamingId,
    bool isShowLoader = true,
  }) async {
    final id = liveStreamingId.trim();
    if (id.isEmpty) return null;

    final response = await _apiService.postRequest(
      endPoint: RoomEndpoints.endLiveStreaming,
      requestModel: <String, dynamic>{
        'liveStreamingId': id,
        'live_streaming_id': id,
        'liveId': id,
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
  ///
  /// Pass [invitationId] when joining from a direct `room_invite` push so the
  /// backend can grant private-room access without a password.
  /// Pass [joinRequestId] after host approval when `joinApprovalRequired` is on.
  Future<Map<String, dynamic>?> joinRoom({
    required String roomId,
    String? password,
    String? invitationId,
    String? joinRequestId,
    String? sessionType,
    bool isShowLoader = true,
  }) async {
    final trimmedPassword = password?.trim();
    final trimmedInvitationId = invitationId?.trim();
    final trimmedJoinRequestId = joinRequestId?.trim();
    final trimmedSessionType = sessionType?.trim();
    final body = <String, dynamic>{
      'roomId': roomId,
      'room_id': roomId,
      if (trimmedPassword != null && trimmedPassword.isNotEmpty)
        'password': trimmedPassword,
      if (trimmedInvitationId != null && trimmedInvitationId.isNotEmpty)
        'invitation_id': trimmedInvitationId,
      if (trimmedJoinRequestId != null && trimmedJoinRequestId.isNotEmpty)
        'join_request_id': trimmedJoinRequestId,
      if (trimmedSessionType != null && trimmedSessionType.isNotEmpty)
        'session_type': trimmedSessionType,
    };
    final response = await _apiService.postRequest(
      endPoint: RoomEndpoints.joinRoom,
      requestModel: body,
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `POST /api/room/join-request` — ask host for admission.
  Future<Map<String, dynamic>?> createJoinRequest({
    required String roomId,
    required String sessionType,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: RoomEndpoints.joinRequest,
      requestModel: <String, dynamic>{
        'room_id': roomId,
        'roomId': roomId,
        'session_type': sessionType.trim(),
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `POST /api/room/join-request/respond` — host approve/reject.
  Future<Map<String, dynamic>?> respondToJoinRequest({
    required String roomId,
    required String requestId,
    required String action,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: RoomEndpoints.joinRequestRespond,
      requestModel: <String, dynamic>{
        'room_id': roomId,
        'roomId': roomId,
        'request_id': requestId,
        'requestId': requestId,
        'action': action.trim().toLowerCase(),
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `POST /api/room/join-request/cancel` — viewer cancels pending request.
  Future<Map<String, dynamic>?> cancelJoinRequest({
    required String roomId,
    required String requestId,
    bool isShowLoader = false,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: RoomEndpoints.joinRequestCancel,
      requestModel: <String, dynamic>{
        'room_id': roomId,
        'roomId': roomId,
        'request_id': requestId,
        'requestId': requestId,
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `GET /api/room/join-request/status?request_id=`
  Future<Map<String, dynamic>?> getJoinRequestStatus({
    required String requestId,
    bool isShowLoader = false,
  }) async {
    final id = requestId.trim();
    if (id.isEmpty) return null;
    final response = await _apiService.getRequest(
      endPoint:
          '${RoomEndpoints.joinRequestStatus}?request_id=${Uri.encodeComponent(id)}',
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `GET /api/room/join-requests?room_id=&status=pending`
  Future<Map<String, dynamic>?> listJoinRequests({
    required String roomId,
    String status = 'pending',
    bool isShowLoader = false,
  }) async {
    final id = roomId.trim();
    if (id.isEmpty) return null;
    final params = <String, String>{
      'room_id': id,
      if (status.trim().isNotEmpty) 'status': status.trim(),
    };
    final response = await _apiService.getRequest(
      endPoint: '${RoomEndpoints.joinRequests}?${Uri(queryParameters: params).query}',
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `POST /api/room/settings` — toggle mid-session flags.
  Future<Map<String, dynamic>?> updateRoomSettings({
    required String roomId,
    bool? joinApprovalRequired,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: RoomEndpoints.roomSettings,
      requestModel: <String, dynamic>{
        'room_id': roomId,
        'roomId': roomId,
        if (joinApprovalRequired != null)
          'joinApprovalRequired': joinApprovalRequired,
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/room/mic-action` to change seat status.
  Future<Map<String, dynamic>?> micAction({
    String? roomId,
    String? targetUserId,
    required String action,
    required int seatId,
    bool isShowLoader = true,
  }) async {
    final trimmedRoomId = roomId?.trim() ?? '';
    final trimmedTargetUserId = targetUserId?.trim();
    final response = await _apiService.postRequest(
      endPoint: RoomEndpoints.micAction,
      requestModel: <String, dynamic>{
        if (trimmedRoomId.isNotEmpty) ...{
          'room_id': trimmedRoomId,
          'roomId': trimmedRoomId,
        },
        if (trimmedTargetUserId != null && trimmedTargetUserId.isNotEmpty) ...{
          'target_user_id': trimmedTargetUserId,
          'targetUserId': trimmedTargetUserId,
        },
        'action': action,
        'seat_id': seatId,
        'seatId': seatId,
      },
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `GET /api/room/seats?room_id=...` (also sends `roomId` for new backends).
  Future<Map<String, dynamic>?> getRoomSeats({
    required String roomId,
    bool isShowLoader = false,
  }) async {
    final id = roomId.trim();
    final params = <String, String>{
      'room_id': id,
      'roomId': id,
    };
    final response = await _apiService.getRequest(
      endPoint: '${RoomEndpoints.seats}?${Uri(queryParameters: params).query}',
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `POST /api/room/seat-request` — floor user asks host for a mic seat.
  Future<Map<String, dynamic>?> createSeatRequest({
    required String roomId,
    required int seatId,
    bool isShowLoader = true,
  }) async {
    final id = roomId.trim();
    if (id.isEmpty || seatId <= 0) return null;
    final response = await _apiService.postRequest(
      endPoint: RoomEndpoints.seatRequest,
      requestModel: <String, dynamic>{
        'roomId': id,
        'room_id': id,
        'seatId': seatId,
        'seat_id': seatId,
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `POST /api/room/seat-request/respond` — host approve/reject.
  Future<Map<String, dynamic>?> respondToSeatRequest({
    required String roomId,
    required String requestId,
    required String action,
    bool isShowLoader = true,
  }) async {
    final id = roomId.trim();
    final reqId = requestId.trim();
    if (id.isEmpty || reqId.isEmpty) return null;
    final response = await _apiService.postRequest(
      endPoint: RoomEndpoints.seatRequestRespond,
      requestModel: <String, dynamic>{
        'roomId': id,
        'room_id': id,
        'requestId': reqId,
        'request_id': reqId,
        'action': action.trim().toLowerCase(),
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `POST /api/room/seat-request/cancel`
  Future<Map<String, dynamic>?> cancelSeatRequest({
    required String roomId,
    required String requestId,
    bool isShowLoader = false,
  }) async {
    final id = roomId.trim();
    final reqId = requestId.trim();
    if (id.isEmpty || reqId.isEmpty) return null;
    final response = await _apiService.postRequest(
      endPoint: RoomEndpoints.seatRequestCancel,
      requestModel: <String, dynamic>{
        'roomId': id,
        'room_id': id,
        'requestId': reqId,
        'request_id': reqId,
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `GET /api/room/seat-requests?roomId=`
  Future<Map<String, dynamic>?> listSeatRequests({
    required String roomId,
    bool isShowLoader = false,
  }) async {
    final id = roomId.trim();
    if (id.isEmpty) return null;
    final params = <String, String>{'roomId': id, 'room_id': id};
    final response = await _apiService.getRequest(
      endPoint:
          '${RoomEndpoints.seatRequests}?${Uri(queryParameters: params).query}',
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `GET /api/room/session-earnings?room_id=&session_type=`.
  Future<Map<String, dynamic>?> getSessionEarnings({
    required String roomId,
    required String sessionType,
    bool isShowLoader = false,
  }) async {
    final trimmedRoomId = roomId.trim();
    final trimmedType = sessionType.trim();
    if (trimmedRoomId.isEmpty || trimmedType.isEmpty) return null;

    final query =
        'room_id=${Uri.encodeComponent(trimmedRoomId)}'
        '&session_type=${Uri.encodeComponent(trimmedType)}';
    final response = await _apiService.getRequest(
      endPoint: '${RoomEndpoints.sessionEarnings}?$query',
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/room/admin-action`.
  Future<Map<String, dynamic>?> adminAction({
    required String roomId,
    required String targetUserId,
    required String action,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: RoomEndpoints.adminAction,
      requestModel: <String, dynamic>{
        'room_id': roomId,
        'target_user_id': targetUserId,
        'action': action,
      },
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `GET /api/room/invite-candidates?room_id=...`.
  Future<Map<String, dynamic>?> getInviteCandidates({
    required String roomId,
    int page = 1,
    int limit = 20,
    String? search,
    bool isShowLoader = false,
  }) async {
    final params = <String, String>{
      'room_id': roomId,
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };
    final response = await _apiService.getRequest(
      endPoint:
          '${RoomEndpoints.inviteCandidates}?${Uri(queryParameters: params).query}',
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/room/invite`.
  Future<Map<String, dynamic>?> inviteUserToSeat({
    required String roomId,
    required String targetUserId,
    required int seatId,
    String? message,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: RoomEndpoints.invite,
      requestModel: <String, dynamic>{
        'room_id': roomId,
        'target_user_id': targetUserId,
        'seat_id': seatId,
        if (message != null && message.trim().isNotEmpty)
          'message': message.trim(),
      },
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/room/invite/respond` for in-room seat invites.
  Future<Map<String, dynamic>?> respondToSeatInvite({
    required String roomId,
    required int seatId,
    required String action,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: RoomEndpoints.inviteRespond,
      requestModel: <String, dynamic>{
        'room_id': roomId,
        'seat_id': seatId,
        'action': action,
      },
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/room/invite/respond` for push-notification invitations.
  ///
  /// Backend contract: `{ invitation_id, action: "reject" | "accept" }`.
  Future<Map<String, dynamic>?> respondToRoomInvite({
    required String invitationId,
    required String action,
    String? roomId,
    bool isShowLoader = true,
  }) async {
    final trimmedInvite = invitationId.trim();
    if (trimmedInvite.isEmpty) return null;

    final trimmedRoomId = roomId?.trim();
    final response = await _apiService.postRequest(
      endPoint: RoomEndpoints.inviteRespond,
      requestModel: <String, dynamic>{
        'invitation_id': trimmedInvite,
        'action': action.trim().toLowerCase(),
        if (trimmedRoomId != null && trimmedRoomId.isNotEmpty)
          'room_id': trimmedRoomId,
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
    final id = roomId.trim();
    final target = targetUserId.trim();
    if (id.isEmpty || target.isEmpty) return null;
    final response = await _apiService.postRequest(
      endPoint: RoomEndpoints.kick,
      requestModel: <String, dynamic>{
        'room_id': id,
        'roomId': id,
        'target_user_id': target,
        'targetUserId': target,
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

  /// `GET /api/room/backgrounds` — active catalog themes for hosts.
  Future<Map<String, dynamic>?> getRoomBackgrounds({
    bool isShowLoader = false,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: RoomEndpoints.backgrounds,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `POST /api/room/change-background` — host applies a catalog theme (or URL).
  Future<Map<String, dynamic>?> changeRoomBackground({
    required String roomId,
    String? backgroundId,
    String? backgroundImage,
    bool isShowLoader = true,
  }) async {
    final id = roomId.trim();
    if (id.isEmpty) return null;
    final bgId = backgroundId?.trim();
    final image = backgroundImage?.trim();
    final response = await _apiService.postRequest(
      endPoint: RoomEndpoints.changeBackground,
      requestModel: <String, dynamic>{
        'room_id': id,
        'roomId': id,
        if (bgId != null && bgId.isNotEmpty) 'background_id': bgId,
        if (bgId != null && bgId.isNotEmpty) 'backgroundId': bgId,
        if (image != null && image.isNotEmpty) 'image': image,
        if (image != null && image.isNotEmpty) 'backgroundImage': image,
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }
}
