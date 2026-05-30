import 'package:qobo_one_live/services/api_constants.dart';

/// Small helpers for media URLs returned by the API.
class ApiImageUtils {
  const ApiImageUtils._();

  static String? normalize(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty || raw == 'null') return null;

    if (raw.startsWith('http://localhost:5000')) {
      return raw.replaceFirst('http://localhost:5000', ApiConstants.baseUrl);
    }
    if (raw.startsWith('https://localhost:5000')) {
      return raw.replaceFirst('https://localhost:5000', ApiConstants.baseUrl);
    }
    if (raw.startsWith('/')) return '${ApiConstants.baseUrl}$raw';
    if (raw.startsWith('http')) return raw;
    return '${ApiConstants.baseUrl}/$raw';
  }
}
