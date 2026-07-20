import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

/// API wrapper for the mobile Super Admin dashboard.
///
/// These calls only consume the backend role APIs; admin approval logic remains
/// on the server/admin panel.
class SuperAdminRepo {
  SuperAdminRepo({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<Map<String, dynamic>?> getDashboard({bool isShowLoader = true}) async {
    final response = await _apiService.getRequest(
      endPoint: SuperAdminEndpoints.dashboard,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> getAgencies({
    String status = 'pending',
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint:
          '${SuperAdminEndpoints.agencies}?${Uri(queryParameters: {'status': status.trim().isEmpty ? 'all' : status.trim()}).query}',
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> processAgency({
    required String agencyId,
    required String status,
    String? feedback,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: SuperAdminEndpoints.processAgency,
      requestModel: <String, dynamic>{
        'agency_id': agencyId.trim(),
        'status': status.trim(),
        if (feedback != null && feedback.trim().isNotEmpty)
          'feedback': feedback.trim(),
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> getTrackedHosts({
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: SuperAdminEndpoints.hostsTrack,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> generateAgencyLink({
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: SuperAdminEndpoints.generateAgencyLink,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }
}
