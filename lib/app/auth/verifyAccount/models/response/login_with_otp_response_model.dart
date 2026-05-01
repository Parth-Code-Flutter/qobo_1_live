/// Response model for `POST /api/auth/login-phone`.
class LoginWithOtpResponseModel {
  const LoginWithOtpResponseModel({
    required this.statusCode,
    required this.message,
    required this.data,
  });

  final int statusCode;
  final String message;
  final LoginWithOtpData? data;

  factory LoginWithOtpResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginWithOtpResponseModel(
      statusCode: (json['statusCode'] as num?)?.toInt() ?? 0,
      message: (json['message'] as String?) ?? '',
      data: json['data'] == null
          ? null
          : LoginWithOtpData.fromJson(
              json['data'] as Map<String, dynamic>,
            ),
    );
  }
}

class LoginWithOtpData {
  const LoginWithOtpData({
    required this.message,
    this.smsResult,
  });

  final String message;
  final SmsResult? smsResult;

  factory LoginWithOtpData.fromJson(Map<String, dynamic> json) {
    return LoginWithOtpData(
      message: (json['message'] as String?) ?? '',
      smsResult: json['smsResult'] == null
          ? null
          : SmsResult.fromJson(json['smsResult'] as Map<String, dynamic>),
    );
  }
}

class SmsResult {
  const SmsResult({
    required this.returnValue,
    required this.requestId,
  });

  final bool returnValue;
  final String requestId;

  factory SmsResult.fromJson(Map<String, dynamic> json) {
    // API uses key `return`, which is a reserved word in Dart.
    final dynamic rawReturn = json['return'];
    return SmsResult(
      returnValue: rawReturn is bool ? rawReturn : rawReturn == 1,
      requestId: (json['request_id'] as String?) ?? '',
    );
  }
}
