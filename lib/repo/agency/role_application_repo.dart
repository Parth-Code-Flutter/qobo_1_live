import 'dart:io';
import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

enum ApplicationRole { superAdmin, agency, host }

/// September 2026 streamlined applications. Management APIs remain separate.
class RoleApplicationRepo {
  RoleApplicationRepo({ApiService? apiService})
    : _api = apiService ?? ApiService();
  final ApiService _api;

  static String endpoint(
    ApplicationRole role, {
    bool status = false,
  }) => switch (role) {
    ApplicationRole.superAdmin =>
      status ? '/api/user/super-admin-status' : '/api/user/super-admin-request',
    ApplicationRole.agency =>
      status ? '/api/agency/status' : '/api/agency/register-public',
    ApplicationRole.host =>
      status ? '/api/agency/application-status' : '/api/agency/host-onboarding',
  };

  Future<Map<String, dynamic>?> verifyCode(
    ApplicationRole role,
    String code,
  ) async {
    final endpoint = role == ApplicationRole.agency
        ? '/api/agency/verify-super-admin-code'
        : '/api/agency/verify-code';
    final response = await _api.getRequest(
      endPoint:
          '$endpoint?${Uri(queryParameters: {'code': code.trim()}).query}',
      isShowLoader: false,
    );
    return response == null
        ? null
        : _normalize(response.statusCode, response.body);
  }

  Future<Map<String, dynamic>?> status(
    ApplicationRole role,
    String query,
  ) async {
    final params = {
      role == ApplicationRole.agency ? 'query' : 'phone': query.trim(),
    };
    final response = await _api.getRequest(
      endPoint:
          '${endpoint(role, status: true)}?${Uri(queryParameters: params).query}',
      isShowLoader: false,
    );
    return response == null
        ? null
        : _normalize(response.statusCode, response.body);
  }

  Future<Map<String, dynamic>?> submit(
    ApplicationRole role, {
    required String code,
    required String name,
    required String phone,
    File? front,
    File? back,
    String agencyName = '',
    String description = '',
  }) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final fields = switch (role) {
      ApplicationRole.agency => <String, String>{
        'invitedBy': code.trim(),
        'name': agencyName.trim(),
        'ownerName': name.trim(),
        'phone': digits,
        if (description.trim().isNotEmpty) 'description': description.trim(),
      },
      ApplicationRole.host => <String, String>{
        'agencyCode': code.trim(),
        'whatsapp': digits,
        'hostName': name.trim(),
        if (description.trim().isNotEmpty) 'description': description.trim(),
      },
      ApplicationRole.superAdmin => <String, String>{
        'fullName': name.trim(),
        'phone': digits,
        if (description.trim().isNotEmpty) 'description': description.trim(),
      },
    };
    final response = await _api.multipartFormRequest(
      endPoint: endpoint(role),
      fields: fields,
      namedFiles: {
        if (front != null) 'doc_photo_front': front,
        if (back != null) 'doc_photo_back': back,
      },
      method: 'POST',
      isShowLoader: false,
    );
    return response == null
        ? null
        : _normalize(response.statusCode, response.body);
  }

  // The final guide uses bare objects; older deployments use statusCode/data.
  static Map<String, dynamic>? _normalize(int status, String body) {
    final decoded = ApiResponseUtils.tryDecodeMap(body);
    if (decoded == null) return null;
    if (status < 200 || status >= 300) {
      return {'statusCode': status, 'message': decoded['message']};
    }
    if (decoded.containsKey('statusCode')) return decoded;
    return {'statusCode': 1, 'data': decoded['data'] ?? decoded};
  }
}
