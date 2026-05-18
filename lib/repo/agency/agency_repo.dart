import 'dart:io';

import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';
import 'package:dio/dio.dart';

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
}
