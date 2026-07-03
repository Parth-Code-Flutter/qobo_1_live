import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

/// User repository contains API calls for social, backpack, tasks, and account utilities.
class UserRepo {
  UserRepo({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<Map<String, dynamic>?> getFollowList({
    String? userId,
    bool isShowLoader = true,
  }) async {
    final params = <String, String>{};
    final id = userId?.trim();
    if (id != null && id.isNotEmpty) {
      params['user_id'] = id;
    }
    final query = params.isEmpty
        ? ''
        : '?${Uri(queryParameters: params).query}';
    final response = await _apiService.getRequest(
      endPoint: '${UserEndpoints.followList}$query',
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `GET /api/user/discover` — paginated users for Messages New Match.
  Future<Map<String, dynamic>?> discoverUsers({
    int page = 1,
    int limit = 20,
    String? country,
    String? gender,
    bool excludeFollowing = false,
    bool isShowLoader = false,
  }) async {
    return _fetchDiscoverFeed(
      endPoint: UserEndpoints.discover,
      page: page,
      limit: limit,
      country: country,
      gender: gender,
      excludeFollowing: excludeFollowing,
      isShowLoader: isShowLoader,
    );
  }

  /// `GET /api/discover` — Explore tab grid (same params + `country` filter).
  Future<Map<String, dynamic>?> exploreDiscover({
    int page = 1,
    int limit = 20,
    String? country,
    String? gender,
    bool excludeFollowing = false,
    bool isShowLoader = false,
  }) async {
    return _fetchDiscoverFeed(
      endPoint: UserEndpoints.exploreDiscover,
      page: page,
      limit: limit,
      country: country,
      gender: gender,
      excludeFollowing: excludeFollowing,
      isShowLoader: isShowLoader,
    );
  }

  Future<Map<String, dynamic>?> _fetchDiscoverFeed({
    required String endPoint,
    int page = 1,
    int limit = 20,
    String? country,
    String? gender,
    bool excludeFollowing = false,
    bool isShowLoader = false,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
    };
    if (country != null && country.trim().isNotEmpty) {
      params['country'] = country.trim();
    }
    if (gender != null && gender.trim().isNotEmpty) {
      params['gender'] = gender.trim();
    }
    if (excludeFollowing) {
      params['exclude_following'] = 'true';
    }
    final response = await _apiService.getRequest(
      endPoint: '$endPoint?${Uri(queryParameters: params).query}',
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `POST /api/user/favourite`
  Future<Map<String, dynamic>?> favouriteUser({
    required String targetId,
    bool isShowLoader = false,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: UserEndpoints.favourite,
      requestModel: {'target_id': targetId.trim()},
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `POST /api/user/unfavourite`
  Future<Map<String, dynamic>?> unfavouriteUser({
    required String targetId,
    bool isShowLoader = false,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: UserEndpoints.unfavourite,
      requestModel: {'target_id': targetId.trim()},
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `GET /api/user/public/:id` — sanitized profile for match sheet.
  Future<Map<String, dynamic>?> getPublicProfile({
    required String userId,
    bool isShowLoader = false,
  }) async {
    final response = await _apiService.getRequest(
      endPoint:
          '${UserEndpoints.publicProfile}/${Uri.encodeComponent(userId)}',
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> getPattiStyle({
    required String userId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: '${UserEndpoints.pattiStyle}/${Uri.encodeComponent(userId)}',
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> blockUser({
    required String targetId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: UserEndpoints.block,
      requestModel: <String, dynamic>{'target_id': targetId},
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> unblockUser({
    required String targetId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: UserEndpoints.unblock,
      requestModel: <String, dynamic>{'target_id': targetId},
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> getBlockList({bool isShowLoader = true}) async {
    final response = await _apiService.getRequest(
      endPoint: UserEndpoints.blockList,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> getBackpack({bool isShowLoader = true}) async {
    final response = await _apiService.getRequest(
      endPoint: UserEndpoints.backpack,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> equipBackpackItem({
    required String itemId,
    required bool isEquipped,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: UserEndpoints.equipBackpack,
      requestModel: <String, dynamic>{
        'id': itemId,
        'itemId': itemId,
        'item_id': itemId,
        'backpack_item_id': itemId,
        'isEquipped': isEquipped,
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> getTasks({bool isShowLoader = true}) async {
    final response = await _apiService.getRequest(
      endPoint: UserEndpoints.tasks,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> claimTask({
    required String taskId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: UserEndpoints.claimTask,
      requestModel: <String, dynamic>{
        'id': taskId,
        'taskId': taskId,
        'task_id': taskId,
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> getAchievements({
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: UserEndpoints.achievements,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> getVisitors({bool isShowLoader = true}) async {
    final response = await _apiService.getRequest(
      endPoint: UserEndpoints.visitors,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> deleteAccount({
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.deleteRequest(
      endPoint: UserEndpoints.delete,
      requestModel: null,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `POST /api/users/super-admin-request` — logged-in user requests Super Admin review.
  Future<Map<String, dynamic>?> requestSuperAdmin({
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: UserEndpoints.superAdminRequest,
      requestModel: <String, dynamic>{},
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `GET /api/users/super-admin-status` — current logged-in user's request status.
  Future<Map<String, dynamic>?> getSuperAdminStatus({
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: UserEndpoints.superAdminStatus,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }
}
