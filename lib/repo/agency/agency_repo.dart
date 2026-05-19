import 'dart:io';

import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

/// Agency repository contains API calls for agency and host management.
class AgencyRepo {
  AgencyRepo({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  /// Calls `POST /api/agency/host-onboarding` to submit a host application.
  ///
  /// Uses multipart/form-data.
  Future<Map<String, dynamic>?> hostOnboarding({
    required String agencyCode,
    required String name,
    required String phone,
    required File hostRealPhoto,
    bool isShowLoader = true,
  }) async {
    final fields = <String, String>{
      'agency_code': agencyCode,
      'name': name,
      'phone': phone,
    };

    final response = await _apiService.multipartFormRequest(
      endPoint: AgencyEndpoints.hostOnboarding,
      fields: fields,
      files: [hostRealPhoto],
      fileFieldName: 'host_real_photo',
      method: 'POST',
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `GET /api/agency/host-verify-status?phone=...` to verify host onboarding status.
  Future<Map<String, dynamic>?> hostVerifyStatus({
    required String phone,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: '${AgencyEndpoints.hostVerifyStatus}?phone=${Uri.encodeComponent(phone)}',
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/agency/register` to register as an agency owner.
  Future<Map<String, dynamic>?> registerAgency({
    required String agencyName,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: AgencyEndpoints.registerAgency,
      requestModel: <String, dynamic>{
        'agency_name': agencyName,
      },
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `GET /api/agency/generate-link?agency_id=...` to generate an invite link.
  Future<Map<String, dynamic>?> generateInviteLink({
    required String agencyId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: '${AgencyEndpoints.generateLink}?agency_id=${Uri.encodeComponent(agencyId)}',
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `GET /api/agency/host-list?agency_id=...` to fetch hosts registered under an agency.
  Future<Map<String, dynamic>?> getAgencyHostsList({
    required String agencyId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: '${AgencyEndpoints.hostList}?agency_id=${Uri.encodeComponent(agencyId)}',
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `GET /api/agency/revenue` to retrieve agency revenue stats.
  Future<Map<String, dynamic>?> getAgencyRevenueStats({
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: AgencyEndpoints.revenue,
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }
}
