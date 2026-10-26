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
    if (role == ApplicationRole.host) return _hostStatus(query);
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
        'agency_code': code.trim(),
        'agencyCode': code.trim(),
        'name': name.trim(),
        'hostName': name.trim(),
        'phone': digits,
        'whatsapp': digits,
        if (description.trim().isNotEmpty) 'description': description.trim(),
        if (description.trim().isNotEmpty) 'bio': description.trim(),
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

  /// Host status uses the bearer token. Phone, email, or application id
  /// are optional. An empty query still lets Google sign-in auto-heal.
  Future<Map<String, dynamic>?> _hostStatus(String query) async {
    final value = query.trim();
    final params = <String, String>{};
    if (value.contains('@')) {
      params['email'] = value;
    } else if (RegExp(r'^\d{6,15}$').hasMatch(value)) {
      params['phone'] = value;
    } else if (value.isNotEmpty) {
      params['application_id'] = value;
    }
    final queryText = params.isEmpty
        ? ''
        : '?${Uri(queryParameters: params).query}';
    final response = await _api.getRequest(
      endPoint: '/api/agency/host-verify-status$queryText',
      isShowLoader: false,
    );
    if (response == null) return null;
    final parsed = _normalize(response.statusCode, response.body);
    final data = parsed?['data'];
    final found = data is Map && data['status'] != null;
    if (found || !params.containsKey('phone')) return parsed;

    // Older host applications are still stored on the phone lookup.
    final legacy = await _api.getRequest(
      endPoint:
          '/api/agency/application-status?${Uri(queryParameters: {'phone': value}).query}',
      isShowLoader: false,
    );
    return legacy == null
        ? parsed
        : _normalize(legacy.statusCode, legacy.body);
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
