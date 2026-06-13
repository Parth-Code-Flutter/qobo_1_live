import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

/// Repository for paid 1:1 call billing.
class CallingRepo {
  CallingRepo({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  /// Calls `POST /api/calling/charge` after a caller completes a paid call.
  Future<Map<String, dynamic>?> chargeCall({
    required String hostId,
    required int durationSeconds,
    bool isShowLoader = false,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: CallingEndpoints.charge,
      requestModel: <String, dynamic>{
        'host_id': hostId,
        'duration_seconds': durationSeconds,
      },
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }
}
