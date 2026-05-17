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
import '../app/splash/splash/views/splash_view.dart';

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
  ];
}
