import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/super_admin/home/controllers/super_admin_home_controller.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_fresh_nav_bar.dart';
import 'package:qobo_one_live/repo/auth/auth_repo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/chat/chat_session_service.dart';
import 'package:qobo_one_live/services/firebase/fcm_token_sync_service.dart';
import 'package:qobo_one_live/services/realtime/user_realtime_socket_service.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/local_storage/controllers/local_storage_controller.dart';

/// Super Admin shell — mirrors user [BottomNavController] patterns.
class SuperAdminBottomNavController extends GetxController {
  final AuthRepo _authRepo = AuthRepo();

  final UserSessionController _userSession =
      Get.isRegistered<UserSessionController>()
      ? Get.find<UserSessionController>()
      : Get.put(UserSessionController(), permanent: true);

  final selectedIndex = dashboardTabIndex.obs;

  static const int dashboardTabIndex = 0;
  static const int agencyTabIndex = 1;
  static const int hostTabIndex = 2;
  static const int settingsTabIndex = 3;

  /// Figma `nav-bar-fresh-4tab` accents — cyan / magenta / green / orange.
  final freshNavItems = const <SuperAdminFreshNavItem>[
    SuperAdminFreshNavItem(
      label: 'Dashboard',
      accent: Color(0xFF00E8FF),
      kind: SuperAdminFreshNavIconKind.dashboard,
    ),
    SuperAdminFreshNavItem(
      label: 'Agency',
      accent: Color(0xFFFF2D9B),
      kind: SuperAdminFreshNavIconKind.agency,
    ),
    SuperAdminFreshNavItem(
      label: 'Host',
      accent: Color(0xFF3DFF6E),
      kind: SuperAdminFreshNavIconKind.host,
    ),
    SuperAdminFreshNavItem(
      label: 'Settings',
      accent: Color(0xFFFF9F1A),
      kind: SuperAdminFreshNavIconKind.settings,
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    _userSession.loadFromStorage();
  }

  /// Compact titles for the shared [CommonAppBarWidget] on the shell.
  (String title, String subtitle) get appBarMeta {
    switch (selectedIndex.value) {
      case agencyTabIndex:
        return ('Agency', 'Review applications');
      case hostTabIndex:
        return ('Hosts', 'Track activity');
      case settingsTabIndex:
        return ('Settings', 'Account & session');
      case dashboardTabIndex:
      default:
        return ('Dashboard', 'Agencies · hosts · commissions');
    }
  }

  void onNavBarTabSelected(int index) {
    selectedIndex.value = index;
    if (!Get.isRegistered<SuperAdminHomeController>()) return;
    final home = Get.find<SuperAdminHomeController>();

    // Lazy-load tab APIs when the user opens that module.
    if (index == dashboardTabIndex) {
      home.loadDashboardStats(showLoader: false);
    } else if (index == agencyTabIndex) {
      home.loadAgencies(showLoader: false);
    } else if (index == hostTabIndex) {
      home.loadTrackedHosts(showLoader: false);
    }
  }

  Future<void> onLogoutPressed() async {
    final storage = LocalStorage.shared;
    await _authRepo.logout(isShowLoader: false);
    if (Get.isRegistered<ChatSessionService>()) {
      await Get.find<ChatSessionService>().signOut();
    }
    await UserRealtimeSocketService.ensureDisconnected();
    if (Get.isRegistered<FcmTokenSyncService>()) {
      Get.find<FcmTokenSyncService>().clearCachedToken();
    }
    await _userSession.clearSession();
    await storage.clearAllData();
    Get.offAllNamed(Routes.AUTH_LOGIN);
  }
}
