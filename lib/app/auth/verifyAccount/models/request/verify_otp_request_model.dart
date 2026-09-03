/// Request body for `POST /api/auth/verify-otp`.
class VerifyOtpRequestModel {
  const VerifyOtpRequestModel({
    required this.phone,
    required this.email,
    required this.otp,
    this.fcmToken,
    this.referralCode,
    this.deviceId,
    this.platform,
    this.forceLogin = false,
  });

  final String phone;
  final String email;
  final String otp;
  final String? fcmToken;
  final String? referralCode;
  final String? deviceId;
  final String? platform;
  final bool forceLogin;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'phone': phone,
    'email': email,
    'otp': otp,
    if (fcmToken?.trim().isNotEmpty == true) 'fcm_token': fcmToken!.trim(),
    if (deviceId?.trim().isNotEmpty == true) ...{
      'deviceId': deviceId!.trim(),
      'device_id': deviceId!.trim(),
    },
    if (platform?.trim().isNotEmpty == true) 'platform': platform!.trim(),
    if (referralCode?.trim().isNotEmpty == true)
      'referralCode': referralCode!.trim().toUpperCase(),
    if (forceLogin) 'forceLogin': true,
  };
}
