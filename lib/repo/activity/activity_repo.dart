import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

/// Activity repository contains API calls for platform event banners.
class ActivityRepo {
  ActivityRepo({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<Map<String, dynamic>?> getActivities({
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: ActivityEndpoints.list,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> joinActivity({
    required String activityId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: ActivityEndpoints.join,
      requestModel: <String, dynamic>{
        'activity_id': activityId,
        'activityId': activityId,
        'id': activityId,
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }
}
