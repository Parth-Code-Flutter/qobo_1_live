import 'dart:io';

import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

/// Agency repository contains API calls for agency and host management.
class AgencyRepo {
  AgencyRepo({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  /// Calls `POST /api/agency/host-onboarding` to submit a host application.
  ///
  /// Uses multipart/form-data.
  Future<Map<String, dynamic>?> hostOnboarding({
    required String agencyCode,
    required String hostName,
    required String gmail,
    required String whatsapp,
    required String category,
    required File hostRealPhoto,
    String? birthday,
    String? hostIdNumber,
    bool isShowLoader = true,
  }) async {
    final fields = <String, String>{
      // Documented backend fields from Qobo1live_API_Documentation.docx.
      'agencyCode': agencyCode,
      'hostName': hostName,
      'gmail': gmail,
      'whatsapp': whatsapp,
      'category': category,
      // Compatibility aliases required by the currently deployed backend.
      'agency_code': agencyCode,
      'name': hostName,
      'phone': whatsapp,
      if (birthday != null && birthday.trim().isNotEmpty)
        'birthday': birthday.trim(),
      if (hostIdNumber != null && hostIdNumber.trim().isNotEmpty)
        'hostIdNumber': hostIdNumber.trim(),
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

  /// Calls `GET /api/agency/host-verify-status?application_id=...`
  /// or `?phone=...` to verify host onboarding status.
  Future<Map<String, dynamic>?> hostVerifyStatus({
    String? applicationId,
    String? phone,
    bool isShowLoader = true,
  }) async {
    final id = applicationId?.trim() ?? '';
    final phoneValue = phone?.trim() ?? '';
    final path = id.isNotEmpty
        ? '${AgencyEndpoints.hostVerifyStatus}?application_id=${Uri.encodeComponent(id)}'
        : '${AgencyEndpoints.hostVerifyStatus}?phone=${Uri.encodeComponent(phoneValue)}';

    final response = await _apiService.getRequest(
      endPoint: path,
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
      requestModel: <String, dynamic>{'agency_name': agencyName},
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
      endPoint:
          '${AgencyEndpoints.generateLink}?agency_id=${Uri.encodeComponent(agencyId)}',
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
      endPoint:
          '${AgencyEndpoints.hostList}?agency_id=${Uri.encodeComponent(agencyId)}',
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

  /// Calls `POST /api/agency/payout` to process agency commissions payout.
  Future<Map<String, dynamic>?> processPayout({
    Map<String, dynamic> requestModel = const <String, dynamic>{},
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: AgencyEndpoints.payout,
      requestModel: requestModel,
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }
}
