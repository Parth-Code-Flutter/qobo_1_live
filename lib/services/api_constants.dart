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

  /// POST /api/auth/send-email-otp
  static const String sendEmailOtp = '/api/auth/send-email-otp';

  /// POST /api/auth/verify-email-otp
  static const String verifyEmailOtp = '/api/auth/verify-email-otp';

  /// POST /api/auth/login-phone
  static const String loginPhone = '/api/auth/login-phone';

  /// POST /api/auth/forgot-password
  static const String forgotPassword = '/api/auth/forgot-password';

  /// POST /api/auth/reset-password
  static const String resetPassword = '/api/auth/reset-password';

  /// POST /api/auth/verify-otp
  static const String verifyOtp = '/api/auth/verify-otp';

  /// GET /api/auth/countries — public country list
  static const String countries = '/api/auth/countries';

  /// GET /api/auth/states?countryId= — public state list
  static const String states = '/api/auth/states';

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

  /// POST /api/rooms
  static const String create = '/api/rooms';

  /// Legacy route kept as fallback.
  static const String createLegacy = '/api/room/create';

  /// POST /api/live-streaming/create — host starts Zego live stream
  static const String createLiveStreaming = '/api/live-streaming/create';

  /// POST /api/live-streaming/end — host ends a Zego live stream
  static const String endLiveStreaming = '/api/live-streaming/end';

  /// GET /api/live-streaming/verify-access — wallet/agency gate for Go Live
  static const String verifyLiveStreamingAccess =
      '/api/live-streaming/verify-access';

  /// GET /api/room/list
  static const String listActiveRooms = '/api/room/list';

  /// POST /api/room/join
  static const String joinRoom = '/api/room/join';

  /// POST /api/room/leave
  static const String leaveRoom = '/api/room/leave';

  /// POST /api/room/end
  static const String endRoom = '/api/room/end';

  /// POST /api/room/mic-action
  static const String micAction = '/api/room/mic-action';

  /// GET /api/room/seats
  static const String seats = '/api/room/seats';

  /// POST /api/room/admin-action
  static const String adminAction = '/api/room/admin-action';

  /// GET /api/room/invite-candidates
  static const String inviteCandidates = '/api/room/invite-candidates';

  /// POST /api/room/invite
  static const String invite = '/api/room/invite';

  /// POST /api/room/invite/respond
  static const String inviteRespond = '/api/room/invite/respond';

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

  /// GET /api/economy/package-list
  static const String packageList = '/api/economy/package-list';

  /// Legacy admin route kept as fallback.
  static const String packageListLegacy = '/api/admin/package-list';

  /// GET /api/economy/history
  static const String history = '/api/economy/history';

  /// GET /api/economy/gift-list
  static const String giftList = '/api/economy/gift-list';

  /// POST /api/economy/send-gift
  static const String sendGift = '/api/economy/send-gift';

  /// Legacy transaction route kept as fallback.
  static const String sendGiftTransactionsLegacy =
      '/api/transactions/send-gift';

  /// Legacy route kept as fallback.
  static const String sendGiftLegacy = '/api/send-gift';

  /// POST /api/withdraw/request
  static const String withdrawRequest = '/api/withdraw/request';

  /// Legacy route kept as fallback.
  static const String withdraw = '/api/withdraw';

  /// GET /api/withdraw/config
  static const String withdrawConfig = '/api/withdraw/config';

  /// GET /api/withdraw/history
  static const String withdrawHistory = '/api/withdraw/history';

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

/// Central place for avatar frame storefront API endpoints.
class FrameEndpoints {
  FrameEndpoints._();

  /// GET /api/frame/shop
  static const String shop = '/api/frame/shop';

  /// POST /api/frame/buy
  static const String buy = '/api/frame/buy';

  /// GET /api/frame/my-backpack
  static const String myBackpack = '/api/frame/my-backpack';

  /// POST /api/frame/equip
  static const String equip = '/api/frame/equip';
}

/// Central place for profile background storefront API endpoints.
class BackgroundEndpoints {
  BackgroundEndpoints._();

  /// GET /api/background/shop
  static const String shop = '/api/background/shop';

  /// POST /api/background/buy
  static const String buy = '/api/background/buy';

  /// GET /api/background/my-backpack
  static const String myBackpack = '/api/background/my-backpack';

  /// POST /api/background/equip
  static const String equip = '/api/background/equip';
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

/// Central place for paid calling related API endpoints.
class CallingEndpoints {
  CallingEndpoints._();

  /// POST /api/economy/calling/charge
  static const String charge = '/api/economy/calling/charge';

  /// Legacy route kept as fallback.
  static const String chargeLegacy = '/api/calling/charge';
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

  /// POST /api/chat/firebase-token — Firebase custom token for Firestore
  static const String firebaseToken = '/api/chat/firebase-token';

  /// POST /api/chat/report — report abusive message
  static const String report = '/api/chat/report';

  /// POST /api/chat/send — send text message (backend must implement)
  static const String send = '/api/chat/send';

  /// POST /api/chat/delete — remove thread from inbox (for me)
  static const String deleteChat = '/api/chat/delete';

  /// POST /api/chat/clear — clear message history (for me)
  static const String clearChat = '/api/chat/clear';

  /// POST /api/chat/block — block user from chat + optional delete
  static const String blockFromChat = '/api/chat/block';

  /// POST /api/chat/read — mark thread read
  static const String markRead = '/api/chat/read';

  /// POST /api/chat/mute — mute / unmute thread
  static const String mute = '/api/chat/mute';

  /// POST /api/chat/archive — archive / unarchive thread
  static const String archive = '/api/chat/archive';

  /// GET /api/chat/can-message — pre-check before opening chat
  static const String canMessage = '/api/chat/can-message';
}

/// Central place for user, social, and backpack related API endpoints.
class UserEndpoints {
  UserEndpoints._();

  /// GET /api/user/follow-list
  static const String followList = '/api/user/follow-list';

  /// GET /api/user/discover — New Match feed (Messages tab)
  static const String discover = '/api/user/discover';

  /// GET /api/discover — Explore tab user grid (country filter + favourites)
  static const String exploreDiscover = '/api/discover';

  /// POST /api/user/favourite — mark user as favourite
  static const String favourite = '/api/user/favourite';

  /// POST /api/user/unfavourite — remove user from favourites
  static const String unfavourite = '/api/user/unfavourite';

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

  /// POST /api/user/points/redeem
  static const String redeemPoints = '/api/user/points/redeem';

  /// GET /api/user/achievements
  static const String achievements = '/api/user/achievements';

  /// POST /api/user/achievements/claim
  static const String claimAchievement = '/api/user/achievements/claim';

  /// GET /api/user/visitors
  static const String visitors = '/api/user/visitors';

  /// GET /api/user/level
  static const String level = '/api/user/level';

  /// GET /api/user/settings
  static const String settings = '/api/user/settings';

  /// DELETE /api/user/delete
  static const String delete = '/api/user/delete';

  /// POST /api/user/fcm-token — register device for chat push
  static const String fcmToken = '/api/user/fcm-token';

  /// POST /api/user/super-admin-request
  static const String superAdminRequest = '/api/user/super-admin-request';

  /// GET /api/users/super-admin-status
  static const String superAdminStatus = '/api/users/super-admin-status';
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

  /// GET /api/family/my
  static const String my = '/api/family/my';

  /// POST /api/family/leave
  static const String leave = '/api/family/leave';
}

/// Central place for activity and event related API endpoints.
class ActivityEndpoints {
  ActivityEndpoints._();

  /// GET /api/activity/list
  static const String list = '/api/activity/list';

  /// POST /api/activity/join
  static const String join = '/api/activity/join';
}

/// Central place for support related API endpoints.
class SupportEndpoints {
  SupportEndpoints._();

  /// POST /api/support/ticket
  static const String ticket = '/api/support/ticket';

  /// GET /api/support/tickets
  static const String tickets = '/api/support/tickets';

  /// GET /api/support/faqs
  static const String faqs = '/api/support/faqs';

  /// POST /api/support/chat/send
  static const String chatSend = '/api/support/chat/send';
}
