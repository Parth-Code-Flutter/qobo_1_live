/// Response envelope for `POST /api/auth/reset-password`.
class ResetPasswordResponseModel {
  const ResetPasswordResponseModel({
    required this.statusCode,
    required this.message,
  });

  /// Application-level status from JSON (same convention as `verify-otp`).
  final int statusCode;
  final String message;

  factory ResetPasswordResponseModel.fromJson(Map<String, dynamic> json) {
    return ResetPasswordResponseModel(
      statusCode: (json['statusCode'] as num?)?.toInt() ?? 0,
      message: (json['message'] as String?) ?? '',
    );
  }
}
