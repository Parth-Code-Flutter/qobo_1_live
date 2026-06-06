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

  /// POST /api/auth/register
  static const String register = '/api/auth/register';

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

  /// POST /api/live-streaming/create — host starts Zego live stream
  static const String createLiveStreaming = '/api/live-streaming/create';

  /// GET /api/room/list
  static const String listActiveRooms = '/api/room/list';

  /// POST /api/room/join
  static const String joinRoom = '/api/room/join';

  /// POST /api/room/mic-action
  static const String micAction = '/api/room/mic-action';

  /// POST /api/room/security-sos
  static const String securitySos = '/api/room/security-sos';

  /// GET /api/room/share
  static const String shareRoom = '/api/room/share';

  /// GET /api/room/translate
  static const String translateText = '/api/room/translate';

  /// GET /api/room/video-swiper
  static const String videoSwiper = '/api/room/video-swiper';

  /// GET /api/room/agora-token
  static const String agoraToken = '/api/room/agora-token';

  /// GET /api/room/zego-token
  static const String zegoToken = '/api/room/zego-token';

  /// POST /api/room/kick
  static const String kick = '/api/room/kick';

  /// GET /api/room/watch-history
  static const String watchHistory = '/api/room/watch-history';

  /// POST /api/room/watch-history/record
  static const String recordWatchHistory = '/api/room/watch-history/record';
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

  /// GET /api/agency/dashboard
  static const String dashboard = '/api/agency/dashboard';

  /// GET /api/agency/generate-link
  static const String generateLink = '/api/agency/generate-link';

  /// GET /api/agency/host-applications
  static const String hostApplications = '/api/agency/host-applications';

  /// GET /api/agency/host-list
  static const String hostList = '/api/agency/host-list';

  /// GET /api/agency/revenue
  static const String revenue = '/api/agency/revenue';

  /// POST /api/agency/payout
  static const String payout = '/api/agency/payout';
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

  /// POST /api/economy/seller/transfer
  static const String sellerTransfer = '/api/economy/seller/transfer';

  /// GET /api/economy/vip-packages
  static const String vipPackages = '/api/economy/vip-packages';

  /// POST /api/economy/buy-vip
  static const String buyVip = '/api/economy/buy-vip';

  /// GET /api/economy/mall
  static const String mallList = '/api/economy/mall';

  /// POST /api/economy/mall/buy
  static const String mallBuy = '/api/economy/mall/buy';

  /// GET /api/economy/aristocracy/packages
  static const String aristocracyPackages = '/api/economy/aristocracy/packages';

  /// POST /api/economy/aristocracy/buy
  static const String buyAristocracy = '/api/economy/aristocracy/buy';

  /// GET /api/economy/seller/dashboard
  static const String sellerDashboard = '/api/economy/seller/dashboard';
}

/// Central place for PK and Call related API endpoints.
class PkEndpoints {
  PkEndpoints._();

  /// GET /api/pk/search
  static const String searchOpponents = '/api/pk/search';

  /// POST /api/pk/send-request
  static const String sendRequest = '/api/pk/send-request';

  /// POST /api/pk/accept-reject
  static const String acceptReject = '/api/pk/accept-reject';

  /// GET /api/pk/status
  static const String status = '/api/pk/status';

  /// POST /api/pk/dating-onboarding
  static const String callOnboarding = '/api/pk/dating-onboarding';

  /// GET /api/pk/dating-list
  static const String callList = '/api/pk/dating-list';

  /// POST /api/pk/dating-action
  static const String datingAction = '/api/pk/dating-action';
}

/// Central place for chat related API endpoints.
class ChatEndpoints {
  ChatEndpoints._();

  /// GET /api/chat/list
  static const String list = '/api/chat/list';

  /// GET /api/chat/detail
  static const String detail = '/api/chat/detail';

  /// POST /api/chat/room — bootstrap chat room (Firebase)
  static const String createRoom = '/api/chat/room';
}

/// Central place for user, social, and backpack related API endpoints.
class UserEndpoints {
  UserEndpoints._();

  /// GET /api/user/follow-list
  static const String followList = '/api/user/follow-list';

  /// GET /api/user/discover — New Match feed
  static const String discover = '/api/user/discover';

  /// GET /api/user/public/:id — public profile card
  static const String publicProfile = '/api/user/public';

  /// GET /api/user/patti-style/:user_id
  static const String pattiStyle = '/api/user/patti-style';

  /// POST /api/user/block
  static const String block = '/api/user/block';

  /// POST /api/user/unblock
  static const String unblock = '/api/user/unblock';

  /// GET /api/user/block-list
  static const String blockList = '/api/user/block-list';

  /// GET /api/user/backpack
  static const String backpack = '/api/user/backpack';

  /// POST /api/user/backpack/equip
  static const String equipBackpack = '/api/user/backpack/equip';

  /// GET /api/user/tasks
  static const String tasks = '/api/user/tasks';

  /// POST /api/user/tasks/claim
  static const String claimTask = '/api/user/tasks/claim';

  /// GET /api/user/achievements
  static const String achievements = '/api/user/achievements';

  /// GET /api/user/visitors
  static const String visitors = '/api/user/visitors';

  /// DELETE /api/user/delete
  static const String delete = '/api/user/delete';
}

/// Central place for family related API endpoints.
class FamilyEndpoints {
  FamilyEndpoints._();

  /// POST /api/family/create
  static const String create = '/api/family/create';

  /// GET /api/family/list
  static const String list = '/api/family/list';

  /// POST /api/family/join
  static const String join = '/api/family/join';

  /// GET /api/family/detail/:id
  static const String detail = '/api/family/detail';
}

/// Central place for activity and event related API endpoints.
class ActivityEndpoints {
  ActivityEndpoints._();

  /// GET /api/activity/list
  static const String list = '/api/activity/list';
}

/// Central place for support related API endpoints.
class SupportEndpoints {
  SupportEndpoints._();

  /// POST /api/support/ticket
  static const String ticket = '/api/support/ticket';

  /// GET /api/support/tickets
  static const String tickets = '/api/support/tickets';
}
