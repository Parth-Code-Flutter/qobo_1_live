import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/super_admin/agency/views/super_admin_agency_tab_view.dart';
import 'package:qobo_one_live/app/super_admin/bottom_nav/controllers/super_admin_bottom_nav_controller.dart';
import 'package:qobo_one_live/app/super_admin/dashboard/views/super_admin_dashboard_tab_view.dart';
import 'package:qobo_one_live/app/super_admin/home/controllers/super_admin_home_controller.dart';
import 'package:qobo_one_live/app/super_admin/host/views/super_admin_host_tab_view.dart';
import 'package:qobo_one_live/app/super_admin/settings/views/super_admin_settings_tab_view.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_ui.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/admin_agency_chrome.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';

/// Super Admin bottom nav shell — same bar chrome as main [BottomNavView].
class SuperAdminBottomNavView extends GetView<SuperAdminBottomNavController> {
  const SuperAdminBottomNavView({super.key});

  @override
  Widget build(BuildContext context) {
    // Opened from host Profile via Get.toNamed — system/back pops to Profile.
    return PopScope(
      canPop: true,
      child: Scaffold(
        // Transparent so each tab’s bare [kImgBG] shows through (Messages-style).
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: Obx(() {
          switch (controller.selectedIndex.value) {
            case SuperAdminBottomNavController.dashboardTabIndex:
              return const SuperAdminDashboardTabView();
            case SuperAdminBottomNavController.agencyTabIndex:
              return const SuperAdminAgencyTabView();
            case SuperAdminBottomNavController.hostTabIndex:
              return const SuperAdminHostTabView();
            case SuperAdminBottomNavController.settingsTabIndex:
              return SuperAdminSettingsTabView(
                onLogoutPressed: controller.onLogoutPressed,
              );
            default:
              return Spacing.shrink;
          }
        }),
        // Create actions: + on Agency / Host tabs (same vibe as Go Live FAB).
        floatingActionButton: Obx(() {
          final index = controller.selectedIndex.value;
          final isAgencyTab =
              index == SuperAdminBottomNavController.agencyTabIndex;
          final isHostTab = index == SuperAdminBottomNavController.hostTabIndex;
          if (!isAgencyTab && !isHostTab) return const SizedBox.shrink();

          final home = Get.find<SuperAdminHomeController>();
          final accent = isAgencyTab ? SuperAdminUi.pink : SuperAdminUi.teal;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: isAgencyTab
                      ? home.openCreateAgency
                      : home.openCreateHost,
                  child: Ink(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent,
                          Color.lerp(accent, kColorWhite, 0.28)!,
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      size: 30,
                      color: kColorWhite,
                      semanticLabel:
                          isAgencyTab ? 'Create agency' : 'Create host',
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        bottomNavigationBar: Obx(
          () => AdminBottomNavBar(
            items: controller.items,
            selectedIndex: controller.selectedIndex.value,
            onSelected: controller.onNavBarTabSelected,
          ),
        ),
      ),
    );
  }
}
