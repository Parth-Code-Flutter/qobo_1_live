import 'dart:io';

import 'package:qobo_one_live/repo/agency/agency_api_utils.dart';
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

  /// Calls `GET /api/agency/host-verify-status` with one lookup key.
  Future<Map<String, dynamic>?> hostVerifyStatus({
    String? applicationId,
    String? hostId,
    String? agencyId,
    String? phone,
    bool isShowLoader = true,
  }) async {
    final params = <String, String>{};
    final id = applicationId?.trim();
    final host = hostId?.trim();
    final agency = agencyId?.trim();
    final phoneValue = phone?.trim();

    if (id != null && id.isNotEmpty) {
      params['application_id'] = id;
    } else if (host != null && host.isNotEmpty) {
      params['host_id'] = host;
    } else if (agency != null && agency.isNotEmpty) {
      params['agency_id'] = agency;
    } else if (phoneValue != null && phoneValue.isNotEmpty) {
      params['phone'] = phoneValue;
    }

    var path = AgencyEndpoints.hostVerifyStatus;
    if (params.isNotEmpty) {
      path += '?${Uri(queryParameters: params).query}';
    }

    final response = await _apiService.getRequest(
      endPoint: path,
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `GET /api/agency/dashboard?month=YYYY-MM` — full owner dashboard payload.
  Future<Map<String, dynamic>?> getAgencyDashboard({
    String? month,
    bool isShowLoader = true,
  }) async {
    final monthParam = month?.trim().isNotEmpty == true
        ? month!.trim()
        : agencyCurrentMonthParam();
    var path = AgencyEndpoints.dashboard;
    path += '?month=${Uri.encodeComponent(monthParam)}';
    final response = await _apiService.getRequest(
      endPoint: path,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Confirms logged-in user has an agency (uses dashboard endpoint).
  Future<Map<String, dynamic>?> checkAgencyOwnerActive({
    String? month,
    bool isShowLoader = true,
  }) => getAgencyDashboard(month: month, isShowLoader: isShowLoader);

  /// `POST /api/agency/register` — register agency for logged-in user.
  Future<Map<String, dynamic>?> registerAgency({
    required String agencyName,
    String? ownerName,
    String? ownerWhatsapp,
    String? logoUrl,
    bool isShowLoader = true,
  }) async {
    final body = <String, dynamic>{
      'agency_name': agencyName.trim(),
      if (ownerName != null && ownerName.trim().isNotEmpty)
        'owner_name': ownerName.trim(),
      if (ownerWhatsapp != null && ownerWhatsapp.trim().isNotEmpty)
        'owner_whatsapp': ownerWhatsapp.trim(),
      if (logoUrl != null && logoUrl.trim().isNotEmpty)
        'logo_url': logoUrl.trim(),
    };
    final response = await _apiService.postRequest(
      endPoint: AgencyEndpoints.registerAgency,
      requestModel: body,
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
    String? month,
    bool isShowLoader = true,
  }) async {
    final monthParam = month?.trim().isNotEmpty == true
        ? month!.trim()
        : agencyCurrentMonthParam();
    final response = await _apiService.getRequest(
      endPoint:
          '${AgencyEndpoints.revenue}?month=${Uri.encodeComponent(monthParam)}',
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/agency/payout` to process agency commissions payout.
  Future<Map<String, dynamic>?> processPayout({
    int? amount,
    bool isShowLoader = true,
  }) async {
    final requestModel = <String, dynamic>{
      if (amount != null) 'amount': amount,
    };
    final response = await _apiService.postRequest(
      endPoint: AgencyEndpoints.payout,
      requestModel: requestModel,
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }
}
