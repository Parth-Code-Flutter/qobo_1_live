class ApiConstants {
  ApiConstants._();

  static const String appVersionLabel = '1.0.0+1';

  /// Backend base URL for API calls.
  static const String baseUrl = 'https://my-backend-api-960q.onrender.com';
}

/// Central place for auth related API endpoints.
class AuthEndpoints {
  AuthEndpoints._();

  /// POST /api/auth/login
  static const String login = '/api/auth/login';

  /// POST /api/auth/login-phone
  static const String loginPhone = '/api/auth/login-phone';

  /// POST /api/auth/forgot-password
  static const String forgotPassword = '/api/auth/forgot-password';

  /// POST /api/auth/reset-password
  static const String resetPassword = '/api/auth/reset-password';

  /// POST /api/auth/verify-otp
  static const String verifyOtp = '/api/auth/verify-otp';

  /// POST /api/auth/social
  static const String socialLogin = '/api/auth/social';

  /// POST /api/auth/firebase-login
  static const String firebaseLogin = '/api/auth/firebase-login';

  /// PUT /api/user/update
  static const String updateProfile = '/api/user/update';

  /// GET /api/user/profile
  static const String getProfile = '/api/user/profile';

  /// POST /api/user/poster-upload
  static const String posterUpload = '/api/user/poster-upload';

  /// GET /api/user/search
  static const String searchUsers = '/api/user/search';

  /// POST /api/user/follow-unfollow
  static const String followUnfollow = '/api/user/follow-unfollow';
}

/// Central place for room related API endpoints.
class RoomEndpoints {
  RoomEndpoints._();

  /// POST /api/room/create
  static const String create = '/api/room/create';

  /// GET /api/room/list
  static const String listActiveRooms = '/api/room/list';

  /// POST /api/room/join
  static const String joinRoom = '/api/room/join';

  /// POST /api/room/mic-action
  static const String micAction = '/api/room/mic-action';

  /// POST /api/room/security-sos
  static const String securitySos = '/api/room/security-sos';
}

/// Central place for agency related API endpoints.
class AgencyEndpoints {
  AgencyEndpoints._();

  /// POST /api/agency/host-onboarding
  static const String hostOnboarding = '/api/agency/host-onboarding';

  /// GET /api/agency/host-verify-status
  static const String hostVerifyStatus = '/api/agency/host-verify-status';

  /// POST /api/agency/register
  static const String registerAgency = '/api/agency/register';

  /// GET /api/agency/generate-link
  static const String generateLink = '/api/agency/generate-link';

  /// GET /api/agency/host-list
  static const String hostList = '/api/agency/host-list';

  /// GET /api/agency/revenue
  static const String revenue = '/api/agency/revenue';
}

/// Central place for economy related API endpoints.
class EconomyEndpoints {
  EconomyEndpoints._();

  /// GET /api/economy/wallet
  static const String wallet = '/api/economy/wallet';

  /// POST /api/economy/recharge
  static const String recharge = '/api/economy/recharge';

  /// GET /api/economy/history
  static const String history = '/api/economy/history';

  /// GET /api/economy/gift-list
  static const String giftList = '/api/economy/gift-list';

  /// POST /api/economy/send-gift
  static const String sendGift = '/api/economy/send-gift';
}

/// Central place for PK and Dating related API endpoints.
class PkEndpoints {
  PkEndpoints._();

  /// GET /api/pk/search
  static const String searchOpponents = '/api/pk/search';

  /// POST /api/pk/send-request
  static const String sendRequest = '/api/pk/send-request';

  /// POST /api/pk/dating-onboarding
  static const String datingOnboarding = '/api/pk/dating-onboarding';

  /// GET /api/pk/dating-list
  static const String datingList = '/api/pk/dating-list';
}
