class ApiConstants {
  ApiConstants._();

  static const String appVersionLabel = '1.0.0+1';

  /// Backend base URL for API calls.
  static const String baseUrl = 'https://my-backend-api-960q.onrender.com';
}

/// Central place for auth related API endpoints.
class AuthEndpoints {
  AuthEndpoints._();

  /// POST /api/auth/login-phone
  static const String loginPhone = '/api/auth/login-phone';

  /// POST /api/auth/verify-otp
  static const String verifyOtp = '/api/auth/verify-otp';

  /// POST /api/auth/social
  static const String socialLogin = '/api/auth/social';

  /// POST /api/auth/firebase-login
  static const String firebaseLogin = '/api/auth/firebase-login';

  /// PUT /api/user/update
  static const String updateProfile = '/api/user/update';
}
