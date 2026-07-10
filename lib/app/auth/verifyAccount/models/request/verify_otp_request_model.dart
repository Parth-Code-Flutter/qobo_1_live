/// Request body for `POST /api/auth/verify-otp`.
class VerifyOtpRequestModel {
  const VerifyOtpRequestModel({
    required this.phone,
    required this.email,
    required this.otp,
  });

  final String phone;
  final String email;
  final String otp;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'phone': phone,
    'email': email,
    'otp': otp,
  };
}
