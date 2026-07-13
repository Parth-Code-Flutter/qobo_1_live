/// Request body for `POST /api/auth/verify-otp`.
class VerifyOtpRequestModel {
  const VerifyOtpRequestModel({
    required this.phone,
    required this.email,
    required this.otp,
    this.fcmToken,
  });

  final String phone;
  final String email;
  final String otp;
  final String? fcmToken;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'phone': phone,
    'email': email,
    'otp': otp,
    if (fcmToken?.trim().isNotEmpty == true) 'fcm_token': fcmToken!.trim(),
  };
}
