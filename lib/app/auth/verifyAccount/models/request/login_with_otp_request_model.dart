/// Request model for `POST /api/auth/login-phone`.
class LoginWithOtpRequestModel {
  const LoginWithOtpRequestModel({
    required this.phone,
    required this.countryCode,
    required this.email,
  });

  final String phone;
  final String countryCode;
  final String email;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'phone': phone,
    'country_code': countryCode,
    'email': email,
  };
}
