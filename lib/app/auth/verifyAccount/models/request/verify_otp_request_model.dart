/// Request body for `POST /api/auth/verify-otp`.
class VerifyOtpRequestModel {
  const VerifyOtpRequestModel({
    required this.phone,
    required this.otp,
  });

  final String phone;
  final String otp;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'phone': phone,
        'otp': otp,
      };
}
