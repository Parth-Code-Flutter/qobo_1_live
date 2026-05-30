import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

/// User repository contains API calls for social, backpack, tasks, and account utilities.
class UserRepo {
  UserRepo({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<Map<String, dynamic>?> getFollowList({
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: UserEndpoints.followList,
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
}
