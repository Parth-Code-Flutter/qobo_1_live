import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

/// Repository for paid 1:1 call / session billing.
class CallingRepo {
  CallingRepo({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  /// `POST /api/economy/calling/charge` — deducts caller coins for duration.
  ///
  /// **50/50 split:** caller pays `rate × duration` coins; callee earns 50%
  /// as diamonds; platform retains 50%. Prefer settling via
  /// [CallRepo.endDirectCall] when a server `callId` exists — backend runs
  /// charge automatically on end.
  Future<Map<String, dynamic>?> chargeCall({
    required String hostId,
    required int durationSeconds,
    bool isShowLoader = false,
  }) async {
    final body = <String, dynamic>{
      'hostId': hostId.trim(),
      'durationSeconds': durationSeconds,
      // Legacy snake_case fallbacks for older backends.
      'host_id': hostId.trim(),
      'duration_seconds': durationSeconds,
    };

    var response = await _apiService.postRequest(
      endPoint: CallingEndpoints.charge,
      requestModel: body,
      isShowLoader: isShowLoader,
    );

    if (response?.statusCode == 404) {
      response = await _apiService.postRequest(
        endPoint: CallingEndpoints.chargeV1,
        requestModel: body,
        isShowLoader: isShowLoader,
      );
    }

    if (response?.statusCode == 404) {
      response = await _apiService.postRequest(
        endPoint: CallingEndpoints.chargeLegacy,
        requestModel: body,
        isShowLoader: isShowLoader,
      );
    }

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }
}
