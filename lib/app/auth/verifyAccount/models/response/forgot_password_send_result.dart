import 'package:http/http.dart' as http;
import 'package:qobo_one_live/constants/status_code_constants.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

/// Result of `POST /api/auth/forgot-password` (OTP send).
class ForgotPasswordSendResult {
  const ForgotPasswordSendResult({
    required this.isSuccess,
    required this.message,
  });

  final bool isSuccess;
  final String message;

  /// Treats HTTP 200/201 as transport success. If JSON includes `statusCode`,
  /// it must be `1`, `200`, or `201` (matches login-phone / generic success).
  static ForgotPasswordSendResult? fromResponse(http.Response? response) {
    if (response == null) return null;

    final jsonMap = ApiResponseUtils.tryDecodeMap(response.body);
    final httpOk = StatusCodeConstants.isHttpSuccess(response.statusCode);
    final bodyCode = ApiResponseUtils.tryGetBodyStatusCode(jsonMap);
    final rawMessage = ApiResponseUtils.tryGetMessage(jsonMap)?.trim();

    var bodyOk = true;
    if (bodyCode != null) {
      bodyOk = bodyCode == 1 ||
          bodyCode == StatusCodeConstants.httpSuccess ||
          bodyCode == StatusCodeConstants.success;
    }

    final success = httpOk && bodyOk;
    final message = (rawMessage != null && rawMessage.isNotEmpty)
        ? rawMessage
        : (success ? 'OTP sent successfully.' : 'Something went wrong.');

    return ForgotPasswordSendResult(isSuccess: success, message: message);
  }
}
