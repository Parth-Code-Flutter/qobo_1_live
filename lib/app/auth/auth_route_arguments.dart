/// Keys for [Get.arguments] on auth-related routes (single source of truth).
abstract final class AuthVerifyAccountArgs {
  AuthVerifyAccountArgs._();

  static const String isFromLoginWithOtp = 'isFromLoginWithOtp';
  static const String isComeFromForgotPassword = 'isComeFromForgotPassword';
}

abstract final class AuthNewPasswordArgs {
  AuthNewPasswordArgs._();

  /// 10-digit local number (same value sent to `forgot-password` / `verify-otp`).
  static const String phone = 'phone';

  /// OTP digits the user entered on the verify screen (used only by `reset-password`).
  static const String otp = 'otp';
}
