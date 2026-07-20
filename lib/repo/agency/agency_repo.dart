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
    required String type,
    required String category,
    required String countryRegion,
    required String state,
    String? countryId,
    String? stateId,
    required String city,
    required String address,
    required File hostRealPhoto,
    required File docPhotoFront,
    required File docPhotoBack,
    String? dob,
    String? idNo,
    bool isShowLoader = true,
  }) async {
    final fields = <String, String>{
      'agency_code': agencyCode.trim(),
      'name': hostName.trim(),
      'phone': whatsapp.trim(),
      'gmail': gmail.trim(),
      'type': type.trim(),
      'category': category.trim(),
      'countryRegion': countryRegion.trim(),
      'state': state.trim(),
      'address': address.trim(),
      if (countryId != null && countryId.trim().isNotEmpty)
        'countryId': countryId.trim(),
      if (stateId != null && stateId.trim().isNotEmpty)
        'stateId': stateId.trim(),
      'city': city.trim(),
      'interests': category.trim(),
      if (dob != null && dob.trim().isNotEmpty) 'dob': dob.trim(),
      if (idNo != null && idNo.trim().isNotEmpty) 'id_no': idNo.trim(),
      // Compatibility aliases from API_Agency_Host_Mobile.md.
      'agencyCode': agencyCode.trim(),
      'hostName': hostName.trim(),
      'whatsapp': whatsapp.trim(),
      'hostType': type.trim(),
      'interest': category.trim(),
      'country_region': countryRegion.trim(),
      if (dob != null && dob.trim().isNotEmpty) 'birthday': dob.trim(),
      if (idNo != null && idNo.trim().isNotEmpty) 'hostIdNumber': idNo.trim(),
    };

    final response = await _apiService.multipartFormRequest(
      endPoint: AgencyEndpoints.hostOnboarding,
      fields: fields,
      namedFiles: {
        // Deployed backend accepts `host_real_photo` (alias for `real_photo`).
        'host_real_photo': hostRealPhoto,
        'doc_photo_front': docPhotoFront,
        'doc_photo_back': docPhotoBack,
      },
      method: 'POST',
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `GET /api/agency/host-verify-status` with one lookup key.
  Future<Map<String, dynamic>?> hostVerifyStatus({
    String? applicationId,
    String? phone,
    bool isShowLoader = true,
  }) async {
    final params = <String, String>{};
    final id = applicationId?.trim();
    final phoneValue = phone?.trim();

    if (id != null && id.isNotEmpty) {
      params['application_id'] = id;
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

  /// `POST /api/agency/register-public` — public agency invite registration.
  ///
  /// This is used when a Super Admin shares an agency onboarding link. It does
  /// not require the user to be logged in, but the backend still accepts the
  /// standard auth headers when present.
  Future<Map<String, dynamic>?> registerAgencyPublic({
    required String agencyName,
    required String ownerName,
    required String email,
    required String phone,
    required String countryCode,
    required String password,
    required String invitedBy,
    required String country,
    required String state,
    required String city,
    required String address,
    File? agencyLogo,
    required File docPhotoFront,
    required File docPhotoBack,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.multipartFormRequest(
      endPoint: AgencyEndpoints.registerAgencyPublic,
      fields: {
        'agency_name': agencyName.trim(),
        'owner_name': ownerName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'countryCode': countryCode.trim(),
        'password': password,
        'invitedBy': invitedBy.trim(),
        'country': country.trim(),
        'state': state.trim(),
        'city': city.trim(),
        'address': address.trim(),
      },
      namedFiles: {
        if (agencyLogo != null) 'agency_logo': agencyLogo,
        'doc_photo_front': docPhotoFront,
        'doc_photo_back': docPhotoBack,
      },
      method: 'POST',
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `GET /api/agency/generate-link?agency_id=...` to generate an invite link.
  Future<Map<String, dynamic>?> generateInviteLink({
    String? agencyId,
    bool isShowLoader = true,
  }) async {
    final id = agencyId?.trim();
    final endpoint = id != null && id.isNotEmpty
        ? '${AgencyEndpoints.generateLink}?agency_id=${Uri.encodeComponent(id)}'
        : AgencyEndpoints.generateLink;
    final response = await _apiService.getRequest(
      endPoint: endpoint,
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `GET /api/agency/host-list` — hosts under the logged-in agency.
  Future<Map<String, dynamic>?> getAgencyHostsList({
    String? agencyId,
    String status = 'all',
    bool isShowLoader = true,
  }) async {
    final params = <String, String>{'status': status.trim()};
    final id = agencyId?.trim();
    if (id != null && id.isNotEmpty) {
      params['agency_id'] = id;
    }
    final response = await _apiService.getRequest(
      endPoint:
          '${AgencyEndpoints.hostList}?${Uri(queryParameters: params).query}',
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `GET /api/agency/host-applications?status=pending`
  Future<Map<String, dynamic>?> getHostApplications({
    String status = 'pending',
    int page = 1,
    int limit = 20,
    bool isShowLoader = true,
  }) async {
    final params = <String, String>{
      'status': status.trim(),
      'page': '$page',
      'limit': '$limit',
    };
    final response = await _apiService.getRequest(
      endPoint:
          '${AgencyEndpoints.hostApplications}?${Uri(queryParameters: params).query}',
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `GET /api/agency/host-applications/{id}`
  Future<Map<String, dynamic>?> getHostApplicationDetail({
    required String applicationId,
    bool isShowLoader = true,
  }) async {
    final id = applicationId.trim();
    final response = await _apiService.getRequest(
      endPoint: '${AgencyEndpoints.hostApplications}/$id',
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `POST /api/agency/host-applications/{id}/approve`
  Future<Map<String, dynamic>?> approveHostApplication({
    required String applicationId,
    int? coinsPerSecond,
    String? note,
    bool isShowLoader = true,
  }) async {
    final body = <String, dynamic>{
      if (coinsPerSecond != null) 'coins_per_second': coinsPerSecond,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    };
    final response = await _apiService.postRequest(
      endPoint:
          '${AgencyEndpoints.hostApplications}/${applicationId.trim()}/approve',
      requestModel: body,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// `POST /api/agency/host-applications/{id}/reject`
  Future<Map<String, dynamic>?> rejectHostApplication({
    required String applicationId,
    required String reason,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint:
          '${AgencyEndpoints.hostApplications}/${applicationId.trim()}/reject',
      requestModel: {'reason': reason.trim()},
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
