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

    // Background / frame uploads often arrive as `http://` while the app and
    // ATS/cleartext rules expect HTTPS for the same Render host.
    if (raw.startsWith('http://')) {
      final uri = Uri.tryParse(raw);
      final apiHost = Uri.tryParse(ApiConstants.baseUrl)?.host;
      if (uri != null &&
          apiHost != null &&
          apiHost.isNotEmpty &&
          uri.host == apiHost) {
        return raw.replaceFirst('http://', 'https://');
      }
    }

    if (raw.startsWith('http')) return raw;
    return '${ApiConstants.baseUrl}/$raw';
  }
}
