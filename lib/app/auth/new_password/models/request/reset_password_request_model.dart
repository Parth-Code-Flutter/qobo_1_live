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
    // Current backend documentation uses code/newPassword. Keep otp/password
    // aliases while older deployments finish migrating.
    'code': otp,
    'otp': otp,
    'newPassword': password,
    'password': password,
  };
}
