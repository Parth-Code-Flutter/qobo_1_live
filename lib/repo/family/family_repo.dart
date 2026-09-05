import 'dart:convert';
import 'dart:math';

import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

/// REST wrapper for the Family group-chat module.
///
/// Backend owns all paid and membership actions, then syncs Firestore. Mobile
/// uses these methods for writes and listens to Firestore for realtime chat.
class FamilyRepo {
  FamilyRepo({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<Map<String, dynamic>?> getFamilies({bool isShowLoader = true}) async {
    return getDiscoverGroups(isShowLoader: isShowLoader);
  }

  Future<Map<String, dynamic>?> getMyFamily({bool isShowLoader = true}) async {
    return getMyGroups(isShowLoader: isShowLoader);
  }

  Future<Map<String, dynamic>?> getMyGroups({
    int page = 1,
    int limit = 20,
    bool isShowLoader = true,
  }) async {
    var response = await _apiService.getRequest(
      endPoint: FamilyEndpoints.myGroups,
      queryParams: {'page': '$page', 'limit': '$limit'},
      isShowLoader: isShowLoader,
    );
    if (response?.statusCode == 404) {
      response = await _apiService.getRequest(
        endPoint: FamilyEndpoints.my,
        isShowLoader: isShowLoader,
      );
    }
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> getDiscoverGroups({
    int page = 1,
    int limit = 20,
    String search = '',
    bool isShowLoader = true,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (search.trim().isNotEmpty) 'search': search.trim(),
    };
    var response = await _apiService.getRequest(
      endPoint: FamilyEndpoints.discoverGroups,
      queryParams: query,
      isShowLoader: isShowLoader,
    );
    if (response?.statusCode == 404) {
      response = await _apiService.getRequest(
        endPoint: FamilyEndpoints.list,
        queryParams: query,
        isShowLoader: isShowLoader,
      );
    }
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> getFamilyDetail({
    required String familyId,
    bool isShowLoader = true,
  }) async {
    final id = familyId.trim();
    var response = await _apiService.getRequest(
      endPoint: FamilyEndpoints.groupDetail(id),
      isShowLoader: isShowLoader,
    );
    if (response?.statusCode == 404) {
      response = await _apiService.getRequest(
        endPoint: '${FamilyEndpoints.detail}/${Uri.encodeComponent(id)}',
        isShowLoader: isShowLoader,
      );
    }
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> getFamilyMembers({
    required String familyId,
    int page = 1,
    int limit = 50,
    String search = '',
    bool isShowLoader = true,
  }) async {
    final id = familyId.trim();
    final query = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (search.trim().isNotEmpty) 'search': search.trim(),
    };
    var response = await _apiService.getRequest(
      endPoint: FamilyEndpoints.groupMembers(id),
      queryParams: query,
      isShowLoader: isShowLoader,
    );
    if (response?.statusCode == 404) {
      response = await _apiService.getRequest(
        endPoint: '${FamilyEndpoints.members}/${Uri.encodeComponent(id)}',
        queryParams: query,
        isShowLoader: isShowLoader,
      );
    }
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> getFamilyTree({
    required String familyId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint:
          '${FamilyEndpoints.tree}/${Uri.encodeComponent(familyId.trim())}',
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> createFamily({
    required String name,
    required String description,
    int joiningCoins = 0,
    String? logo,
    List<String> initialMemberIds = const [],
    bool isShowLoader = true,
  }) async {
    final body = <String, dynamic>{
      'name': name.trim(),
      'description': description.trim(),
      'joiningCoins': max(0, joiningCoins),
      if ((logo ?? '').trim().isNotEmpty) 'logo': logo!.trim(),
      if (initialMemberIds.isNotEmpty) 'initialMemberIds': initialMemberIds,
    };
    var response = await _apiService.postRequest(
      endPoint: FamilyEndpoints.groups,
      requestModel: body,
      isShowLoader: isShowLoader,
    );
    if (response?.statusCode == 404) {
      response = await _apiService.postRequest(
        endPoint: FamilyEndpoints.create,
        requestModel: body,
        isShowLoader: isShowLoader,
      );
    }
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> joinFamily({
    required String familyId,
    String? clientTransactionId,
    bool isShowLoader = true,
  }) async {
    final id = familyId.trim();
    final body = <String, dynamic>{
      'family_id': id,
      'familyId': id,
      'id': id,
      'clientTransactionId': clientTransactionId ?? _newClientId('join'),
    };
    var response = await _apiService.postRequest(
      endPoint: FamilyEndpoints.groupJoin(id),
      requestModel: body,
      isShowLoader: isShowLoader,
    );
    if (response?.statusCode == 404) {
      response = await _apiService.postRequest(
        endPoint: FamilyEndpoints.join,
        requestModel: body,
        isShowLoader: isShowLoader,
      );
    }
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> leaveFamily({
    String? familyId,
    bool isShowLoader = true,
  }) async {
    final id = familyId?.trim() ?? '';
    var response = await _apiService.postRequest(
      endPoint: id.isEmpty
          ? FamilyEndpoints.leave
          : FamilyEndpoints.groupLeave(id),
      requestModel: id.isEmpty ? <String, dynamic>{} : {'groupId': id},
      isShowLoader: isShowLoader,
    );
    if (response?.statusCode == 404 && id.isNotEmpty) {
      response = await _apiService.postRequest(
        endPoint: FamilyEndpoints.leave,
        requestModel: {'groupId': id, 'familyId': id, 'family_id': id},
        isShowLoader: isShowLoader,
      );
    }
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> addMembers({
    required String familyId,
    required List<String> userIds,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: FamilyEndpoints.groupMembers(familyId.trim()),
      requestModel: {'userIds': userIds},
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Admin update group profile (name / description).
  /// Tries `PATCH /api/family/groups/:id`, then legacy `/api/family/update`.
  Future<Map<String, dynamic>?> updateFamily({
    required String familyId,
    String? name,
    String? description,
    bool isShowLoader = true,
  }) async {
    final id = familyId.trim();
    if (id.isEmpty) return null;
    final body = <String, dynamic>{
      'groupId': id,
      'familyId': id,
      'family_id': id,
      if (name != null) 'name': name.trim(),
      if (description != null) 'description': description.trim(),
    };
    var response = await _apiService.patchRequest(
      endPoint: FamilyEndpoints.groupUpdate(id),
      requestModel: body,
      isShowLoader: isShowLoader,
    );
    if (response?.statusCode == 404) {
      response = await _apiService.patchRequest(
        endPoint: FamilyEndpoints.update,
        requestModel: body,
        isShowLoader: isShowLoader,
      );
    }
    if (response?.statusCode == 404) {
      response = await _apiService.putRequest(
        endPoint: FamilyEndpoints.groupUpdate(id),
        requestModel: body,
        isShowLoader: isShowLoader,
      );
    }
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> removeMember({
    required String familyId,
    required String userId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.deleteRequest(
      endPoint: FamilyEndpoints.groupMember(familyId.trim(), userId.trim()),
      requestModel: jsonEncode(<String, dynamic>{}),
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> sendTextMessage({
    required String familyId,
    required String text,
    String? clientMessageId,
    bool isShowLoader = false,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: FamilyEndpoints.groupMessages(familyId.trim()),
      requestModel: {
        'text': text.trim(),
        'clientMessageId': clientMessageId ?? _newClientId('msg'),
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `GET /api/family/groups/:id/messages` — history fallback when Firestore
  /// listen is blocked or empty.
  Future<Map<String, dynamic>?> listMessages({
    required String familyId,
    int page = 1,
    int limit = 50,
    bool isShowLoader = false,
  }) async {
    final id = familyId.trim();
    if (id.isEmpty) return null;
    final path =
        '${FamilyEndpoints.groupMessages(id)}?page=$page&limit=$limit';
    final response = await _apiService.getRequest(
      endPoint: path,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> sendEmojiMessage({
    required String familyId,
    required String emojiId,
    String? clientMessageId,
    bool isShowLoader = false,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: FamilyEndpoints.groupEmojis(familyId.trim()),
      requestModel: {
        'emojiId': emojiId.trim(),
        'clientMessageId': clientMessageId ?? _newClientId('emoji'),
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> sendGroupGift({
    required String familyId,
    required String giftId,
    int quantity = 1,
    String? clientGiftId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: FamilyEndpoints.groupGifts(familyId.trim()),
      requestModel: {
        'giftId': giftId.trim(),
        'quantity': quantity,
        'clientGiftId': clientGiftId ?? _newClientId('gift'),
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> markRead({
    required String familyId,
    String? lastReadMessageId,
    bool isShowLoader = false,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: FamilyEndpoints.groupRead(familyId.trim()),
      requestModel: {
        if ((lastReadMessageId ?? '').trim().isNotEmpty)
          'lastReadMessageId': lastReadMessageId!.trim(),
        'lastReadAt': DateTime.now().toIso8601String(),
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> searchUsers({
    required String query,
    bool followersOnly = false,
    bool isShowLoader = false,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: followersOnly
          ? UserEndpoints.followList
          : AuthEndpoints.searchUsers,
      queryParams: {
        if (query.trim().isNotEmpty) 'search': query.trim(),
        if (query.trim().isNotEmpty) 'query': query.trim(),
        'page': '1',
        'limit': '30',
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  String _newClientId(String prefix) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final randomPart = Random().nextInt(1 << 32).toRadixString(16);
    return '${prefix}_${timestamp}_$randomPart';
  }
}
