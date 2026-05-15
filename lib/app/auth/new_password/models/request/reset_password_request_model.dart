/// Request body for `POST /api/auth/reset-password`.
class ResetPasswordRequestModel {
  const ResetPasswordRequestModel({
    required this.phone,
    required this.otp,
    required this.password,
  });

  final String phone;
  final String otp;
  final String password;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'phone': phone,
        'otp': otp,
        'password': password,
      };
}
