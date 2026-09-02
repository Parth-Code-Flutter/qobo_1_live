/// Request model for `POST /api/auth/login-phone`.
class LoginWithOtpRequestModel {
  const LoginWithOtpRequestModel({
    required this.phone,
    required this.countryCode,
    required this.email,
    this.fcmToken,
    this.deviceId,
    this.platform,
  });

  final String phone;
  final String countryCode;
  final String email;
  final String? fcmToken;
  final String? deviceId;
  final String? platform;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'phone': phone,
    'country_code': countryCode,
    'email': email,
    if (fcmToken?.trim().isNotEmpty == true) 'fcm_token': fcmToken!.trim(),
    if (deviceId?.trim().isNotEmpty == true) ...{
      'deviceId': deviceId!.trim(),
      'device_id': deviceId!.trim(),
    },
    if (platform?.trim().isNotEmpty == true) 'platform': platform!.trim(),
  };
}
