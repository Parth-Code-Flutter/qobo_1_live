import 'package:get/get.dart';

import '../app/auth/login/bindings/auth_login_binding.dart';
import '../app/auth/login/views/auth_login_view.dart';
import '../app/auth/signUp/bindings/auth_sign_up_binding.dart';
import '../app/auth/signUp/views/auth_sign_up_view.dart';
import '../app/auth/verifyAccount/bindings/auth_verify_account_binding.dart';
import '../app/auth/verifyAccount/views/auth_verify_account_view.dart';
import '../app/auth/new_password/bindings/new_password_binding.dart';
import '../app/auth/new_password/views/new_password_view.dart';
import '../app/bottom_nav/bindings/bottom_nav_binding.dart';
import '../app/bottom_nav/views/bottom_nav_view.dart';
import '../app/splash/splash/bindings/splash_binding.dart';
import '../app/user_flow/update_profile/bindings/update_profile_binding.dart';
import '../app/user_flow/update_profile/views/update_profile_view.dart';
import '../app/user_flow/leader_board/bindings/leader_board_binding.dart';
import '../app/user_flow/leader_board/views/leader_board_view.dart';
import '../app/user_flow/user_basic_profile/bindings/user_basic_profile_binding.dart';
import '../app/user_flow/user_basic_profile/views/user_basic_profile_view.dart';
import '../app/user_flow/agency_host_onboarding/bindings/agency_host_onboarding_binding.dart';
import '../app/user_flow/agency_host_onboarding/views/agency_host_onboarding_view.dart';
import '../app/user_flow/agency_host_status/bindings/agency_host_status_binding.dart';
import '../app/user_flow/agency_host_status/views/agency_host_status_view.dart';
import '../app/user_flow/agency_owner_register/bindings/agency_owner_register_binding.dart';
import '../app/user_flow/agency_owner_register/views/agency_owner_register_view.dart';
import '../app/user_flow/agency_recruit_link/bindings/agency_recruit_link_binding.dart';
import '../app/user_flow/agency_recruit_link/views/agency_recruit_link_view.dart';
import '../app/user_flow/agency_host_list/bindings/agency_host_list_binding.dart';
import '../app/user_flow/agency_host_list/views/agency_host_list_view.dart';
import '../app/user_flow/agency_revenue/bindings/agency_revenue_binding.dart';
import '../app/user_flow/agency_revenue/views/agency_revenue_view.dart';
import '../app/user_flow/live_action/bindings/live_action_binding.dart';
import '../app/user_flow/live_action/views/live_action_view.dart';
import '../app/user_flow/live_room_create/bindings/live_room_create_binding.dart';
import '../app/user_flow/live_room_create/views/live_room_create_view.dart';
import '../app/user_flow/live_broadcast/bindings/live_broadcast_binding.dart';
import '../app/user_flow/live_broadcast/views/live_broadcast_view.dart';
import '../app/user_flow/messages/chat_detail/bindings/chat_detail_binding.dart';
import '../app/user_flow/messages/chat_detail/views/chat_detail_view.dart';
import '../app/user_flow/follow_list/bindings/follow_list_binding.dart';
import '../app/user_flow/follow_list/views/follow_list_view.dart';
import '../app/user_flow/settings/bindings/settings_binding.dart';
import '../app/user_flow/settings/views/settings_view.dart';
import '../app/user_flow/block_list/bindings/block_list_binding.dart';
import '../app/user_flow/block_list/views/block_list_view.dart';
import '../app/user_flow/user_level/bindings/user_level_binding.dart';
import '../app/user_flow/user_level/views/user_level_view.dart';
import '../app/user_flow/backpack/bindings/backpack_binding.dart';
import '../app/user_flow/backpack/views/backpack_view.dart';
import '../app/user_flow/mall/bindings/mall_binding.dart';
import '../app/user_flow/mall/views/mall_view.dart';
import '../app/user_flow/svip/bindings/svip_binding.dart';
import '../app/user_flow/svip/views/svip_view.dart';
import '../app/user_flow/family/bindings/family_binding.dart';
import '../app/user_flow/family/views/family_view.dart';
import '../app/user_flow/visitors/bindings/visitors_binding.dart';
import '../app/user_flow/visitors/views/visitors_view.dart';
import '../app/user_flow/aristocracy_center/bindings/aristocracy_center_binding.dart';
import '../app/user_flow/aristocracy_center/views/aristocracy_center_view.dart';
import '../app/user_flow/activity/bindings/activity_binding.dart';
import '../app/user_flow/activity/views/activity_view.dart';
import '../app/user_flow/point_center/bindings/point_center_binding.dart';
import '../app/user_flow/point_center/views/point_center_view.dart';
import '../app/splash/splash/views/splash_view.dart';
import '../app/user_flow/award/bindings/award_binding.dart';
import '../app/user_flow/award/views/award_view.dart';
import '../app/user_flow/broadcast_watched/bindings/broadcast_watched_binding.dart';
import '../app/user_flow/broadcast_watched/views/broadcast_watched_view.dart';
import '../app/user_flow/transaction_history/bindings/transaction_history_binding.dart';
import '../app/user_flow/transaction_history/views/transaction_history_view.dart';
import '../app/user_flow/vip_store/bindings/vip_store_binding.dart';
import '../app/user_flow/vip_store/views/vip_store_view.dart';
import '../app/user_flow/entrance_patti/bindings/entrance_patti_binding.dart';
import '../app/user_flow/entrance_patti/views/entrance_patti_view.dart';
import '../app/user_flow/live_moderation/bindings/live_moderation_binding.dart';
import '../app/user_flow/live_moderation/views/live_moderation_view.dart';
import '../app/user_flow/customer_service/bindings/customer_service_binding.dart';
import '../app/user_flow/customer_service/views/customer_service_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final routes = <GetPage<dynamic>>[
    GetPage(
      name: _Paths.SPLASH,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: _Paths.AUTH_LOGIN,
      page: () => const AuthLoginView(),
      binding: AuthLoginBinding(),
    ),
    GetPage(
      name: _Paths.AUTH_SIGN_UP,
      page: () => const AuthSignUpView(),
      binding: AuthSignUpBinding(),
    ),
    GetPage(
      name: _Paths.AUTH_VERIFY_ACCOUNT,
      page: () => const AuthVerifyAccountView(),
      binding: AuthVerifyAccountBinding(),
    ),
    GetPage(
      name: _Paths.AUTH_NEW_PASSWORD,
      page: () => const NewPasswordView(),
      binding: NewPasswordBinding(),
    ),
    GetPage(
      name: _Paths.BOTTOM_NAV,
      page: () => const BottomNavView(),
      binding: BottomNavBinding(),
    ),
    GetPage(
      name: _Paths.UPDATE_PROFILE,
      page: () => const UpdateProfileView(),
      binding: UpdateProfileBinding(),
    ),
    GetPage(
      name: _Paths.USER_BASIC_PROFILE,
      page: () => const UserBasicProfileView(),
      binding: UserBasicProfileBinding(),
    ),
    GetPage(
      name: _Paths.LEADER_BOARD,
      page: () => const LeaderBoardView(),
      binding: LeaderBoardBinding(),
    ),
    GetPage(
      name: _Paths.AGENCY_HOST_ONBOARDING,
      page: () => const AgencyHostOnboardingView(),
      binding: AgencyHostOnboardingBinding(),
    ),
    GetPage(
      name: _Paths.AGENCY_HOST_STATUS,
      page: () => const AgencyHostStatusView(),
      binding: AgencyHostStatusBinding(),
    ),
    GetPage(
      name: _Paths.AGENCY_OWNER_REGISTER,
      page: () => const AgencyOwnerRegisterView(),
      binding: AgencyOwnerRegisterBinding(),
    ),
    GetPage(
      name: _Paths.AGENCY_RECRUIT_LINK,
      page: () => const AgencyRecruitLinkView(),
      binding: AgencyRecruitLinkBinding(),
    ),
    GetPage(
      name: _Paths.AGENCY_HOST_LIST,
      page: () => const AgencyHostListView(),
      binding: AgencyHostListBinding(),
    ),
    GetPage(
      name: _Paths.AGENCY_REVENUE,
      page: () => const AgencyRevenueView(),
      binding: AgencyRevenueBinding(),
    ),
    GetPage(
      name: _Paths.LIVE_ACTION,
      page: () => const LiveActionView(),
      binding: LiveActionBinding(),
    ),
    GetPage(
      name: _Paths.LIVE_ROOM_CREATE,
      page: () => const LiveRoomCreateView(),
      binding: LiveRoomCreateBinding(),
    ),
    GetPage(
      name: _Paths.LIVE_BROADCAST,
      page: () => const LiveBroadcastView(),
      binding: LiveBroadcastBinding(),
    ),
    GetPage(
      name: _Paths.CHAT_DETAIL,
      page: () => const ChatDetailView(),
      binding: ChatDetailBinding(),
    ),
    GetPage(
      name: _Paths.FOLLOW_LIST,
      page: () => const FollowListView(),
      binding: FollowListBinding(),
    ),
    GetPage(
      name: _Paths.SETTINGS,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: _Paths.BLOCK_LIST,
      page: () => const BlockListView(),
      binding: BlockListBinding(),
    ),
    GetPage(
      name: _Paths.USER_LEVEL,
      page: () => const UserLevelView(),
      binding: UserLevelBinding(),
    ),
    GetPage(
      name: _Paths.BACKPACK,
      page: () => const BackpackView(),
      binding: BackpackBinding(),
    ),
    GetPage(
      name: _Paths.MALL,
      page: () => const MallView(),
      binding: MallBinding(),
    ),
    GetPage(
      name: _Paths.SVIP,
      page: () => const SvipView(),
      binding: SvipBinding(),
    ),
    GetPage(
      name: _Paths.FAMILY,
      page: () => const FamilyView(),
      binding: FamilyBinding(),
    ),
    GetPage(
      name: _Paths.VISITORS,
      page: () => const VisitorsView(),
      binding: VisitorsBinding(),
    ),
    GetPage(
      name: _Paths.ARISTOCRACY_CENTER,
      page: () => const AristocracyCenterView(),
      binding: AristocracyCenterBinding(),
    ),
    GetPage(
      name: _Paths.ACTIVITY,
      page: () => const ActivityView(),
      binding: ActivityBinding(),
    ),
    GetPage(
      name: _Paths.POINT_CENTER,
      page: () => const PointCenterView(),
      binding: PointCenterBinding(),
    ),
    GetPage(
      name: _Paths.AWARD,
      page: () => const AwardView(),
      binding: AwardBinding(),
    ),
    GetPage(
      name: _Paths.BROADCAST_WATCHED,
      page: () => const BroadcastWatchedView(),
      binding: BroadcastWatchedBinding(),
    ),
    GetPage(
      name: _Paths.TRANSACTION_HISTORY,
      page: () => const TransactionHistoryView(),
      binding: TransactionHistoryBinding(),
    ),
    GetPage(
      name: _Paths.VIP_STORE,
      page: () => const VipStoreView(),
      binding: VipStoreBinding(),
    ),
    GetPage(
      name: _Paths.ENTRANCE_PATTI,
      page: () => const EntrancePattiView(),
      binding: EntrancePattiBinding(),
    ),
    GetPage(
      name: _Paths.LIVE_MODERATION,
      page: () => const LiveModerationView(),
      binding: LiveModerationBinding(),
    ),
    GetPage(
      name: _Paths.CUSTOMER_SERVICE,
      page: () => const CustomerServiceView(),
      binding: CustomerServiceBinding(),
    ),
  ];
}
