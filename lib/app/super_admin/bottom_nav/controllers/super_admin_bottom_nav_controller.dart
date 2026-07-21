import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/super_admin/home/controllers/super_admin_home_controller.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/chat/chat_session_service.dart';
import 'package:qobo_one_live/services/firebase/fcm_token_sync_service.dart';
import 'package:qobo_one_live/services/realtime/user_realtime_socket_service.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/local_storage/controllers/local_storage_controller.dart';

/// Super Admin shell — mirrors user [BottomNavController] patterns.
class SuperAdminBottomNavController extends GetxController {
  final UserSessionController _userSession =
      Get.isRegistered<UserSessionController>()
      ? Get.find<UserSessionController>()
      : Get.put(UserSessionController(), permanent: true);

  final selectedIndex = dashboardTabIndex.obs;

  static const int dashboardTabIndex = 0;
  static const int agencyTabIndex = 1;
  static const int hostTabIndex = 2;
  static const int settingsTabIndex = 3;

  /// Four modules — each tab gets a distinct accent for colorful icons.
  final items = const <({String label, IconData icon, Color accent})>[
    (
      label: 'Dashboard',
      icon: Icons.dashboard_rounded,
      accent: Color(0xFF7C9CFF),
    ),
    (label: 'Agency', icon: Icons.business_rounded, accent: Color(0xFFFF8AD8)),
    (label: 'Host', icon: Icons.mic_rounded, accent: Color(0xFF5CE1B0)),
    (
      label: 'Settings',
      icon: Icons.settings_rounded,
      accent: Color(0xFFFFD166),
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    _userSession.loadFromStorage();
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
