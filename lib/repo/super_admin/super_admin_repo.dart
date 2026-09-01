import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

/// API wrapper for Super Admin mobile endpoints
/// (`super_admin_mobile_api_handover_v1.md`).
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
    String search = '',
    int page = 1,
    int limit = 20,
    bool isShowLoader = true,
  }) async {
    final params = <String, String>{
      'status': status.trim().isEmpty ? 'all' : status.trim(),
      'page': '$page',
      'limit': '$limit',
      if (search.trim().isNotEmpty) 'search': search.trim(),
    };
    final response = await _apiService.getRequest(
      endPoint:
          '${SuperAdminEndpoints.agencies}?${Uri(queryParameters: params).query}',
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> getAgencyDetail({
    required String agencyId,
    bool isShowLoader = true,
  }) async {
    if (agencyId.trim().isEmpty) return null;
    final response = await _apiService.getRequest(
      endPoint: SuperAdminEndpoints.agencyDetail(agencyId),
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> getAgencyHosts({
    required String agencyId,
    String status = 'all',
    String search = '',
    int page = 1,
    int limit = 20,
    bool isShowLoader = true,
  }) async {
    if (agencyId.trim().isEmpty) return null;
    final params = <String, String>{
      'status': status.trim().isEmpty ? 'all' : status.trim(),
      'page': '$page',
      'limit': '$limit',
      if (search.trim().isNotEmpty) 'search': search.trim(),
    };
    final response = await _apiService.getRequest(
      endPoint:
          '${SuperAdminEndpoints.agencyHosts(agencyId)}?${Uri(queryParameters: params).query}',
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
    final body = <String, dynamic>{
      'agencyId': agencyId.trim(),
      'agency_id': agencyId.trim(),
      'status': status.trim(),
      if (feedback != null && feedback.trim().isNotEmpty)
        'feedback': feedback.trim(),
    };
    var response = await _apiService.postRequest(
      endPoint: SuperAdminEndpoints.processAgencyRequest,
      requestModel: body,
      isShowLoader: isShowLoader,
    );
    if (response == null || response.statusCode == 404) {
      response = await _apiService.postRequest(
        endPoint: SuperAdminEndpoints.processAgency,
        requestModel: body,
        isShowLoader: isShowLoader,
      );
    }
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> updateAgencyCommission({
    required String agencyId,
    required double commissionRate,
    bool isShowLoader = true,
  }) async {
    if (agencyId.trim().isEmpty) return null;
    final response = await _apiService.patchRequest(
      endPoint: SuperAdminEndpoints.agencyCommission(agencyId),
      requestModel: <String, dynamic>{'commissionRate': commissionRate},
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> getTrackedHosts({
    String status = '',
    String agencyCode = '',
    String search = '',
    int page = 1,
    int limit = 20,
    String sortBy = '',
    String sortOrder = 'desc',
    bool isShowLoader = true,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (status.trim().isNotEmpty) 'status': status.trim(),
      if (agencyCode.trim().isNotEmpty) 'agencyCode': agencyCode.trim(),
      if (search.trim().isNotEmpty) 'search': search.trim(),
      if (sortBy.trim().isNotEmpty) 'sortBy': sortBy.trim(),
      if (sortOrder.trim().isNotEmpty) 'sortOrder': sortOrder.trim(),
    };
    final response = await _apiService.getRequest(
      endPoint:
          '${SuperAdminEndpoints.hostsTrack}?${Uri(queryParameters: params).query}',
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> getHostDetail({
    required String hostId,
    bool isShowLoader = true,
  }) async {
    if (hostId.trim().isEmpty) return null;
    final response = await _apiService.getRequest(
      endPoint: SuperAdminEndpoints.hostDetail(hostId),
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> updateHostStatus({
    required String hostId,
    required String status,
    String? reason,
    bool isShowLoader = true,
  }) async {
    if (hostId.trim().isEmpty) return null;
    final response = await _apiService.postRequest(
      endPoint: SuperAdminEndpoints.hostStatus(hostId),
      requestModel: <String, dynamic>{
        'status': status.trim(),
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
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
