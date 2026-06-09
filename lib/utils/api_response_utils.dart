import 'dart:convert';

import 'package:qobo_one_live/constants/status_code_constants.dart';
import 'package:http/http.dart' as http;

/// Centralized API success validation.
///
/// Backend convention:
/// - HTTP statusCode: 200 or 201
/// - JSON body `statusCode`: 1 (legacy) or 201 (canonical)
class ApiResponseUtils {
  /// Try to decode a response body as JSON map.
  static Map<String, dynamic>? tryDecodeMap(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Extract `statusCode` from a decoded JSON map.
  static int? tryGetBodyStatusCode(Map<String, dynamic>? jsonMap) {
    final raw = jsonMap?['statusCode'];
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  /// Extract `message` from a decoded JSON map.
  static String? tryGetMessage(Map<String, dynamic>? jsonMap) {
    final msg = jsonMap?['message'];
    return msg is String ? msg : null;
  }

  /// True when HTTP is 2xx and body.statusCode is 1 or 201.
  static bool isApiSuccessResponse(http.Response response) {
    if (!StatusCodeConstants.isHttpSuccess(response.statusCode)) return false;
    final jsonMap = tryDecodeMap(response.body);
    final bodyStatusCode = tryGetBodyStatusCode(jsonMap);
    return StatusCodeConstants.isApiSuccess(bodyStatusCode);
  }

  /// True when decoded body uses legacy or canonical success code.
  static bool isBodySuccess(Map<String, dynamic>? jsonMap) {
    return StatusCodeConstants.isApiSuccess(tryGetBodyStatusCode(jsonMap));
  }
}
