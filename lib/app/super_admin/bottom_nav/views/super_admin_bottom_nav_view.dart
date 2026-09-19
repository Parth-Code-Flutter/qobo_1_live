import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/super_admin/agency/views/super_admin_agency_tab_view.dart';
import 'package:qobo_one_live/app/super_admin/bottom_nav/controllers/super_admin_bottom_nav_controller.dart';
import 'package:qobo_one_live/app/super_admin/dashboard/views/super_admin_dashboard_tab_view.dart';
import 'package:qobo_one_live/app/super_admin/host/views/super_admin_host_tab_view.dart';
import 'package:qobo_one_live/app/super_admin/settings/views/super_admin_settings_tab_view.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/admin_agency_chrome.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';

/// Super Admin bottom nav shell — shared [CommonAppBarWidget] + tab body.
class SuperAdminBottomNavView extends GetView<SuperAdminBottomNavController> {
  const SuperAdminBottomNavView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Obx(() {
        final meta = controller.appBarMeta;
        return Scaffold(
          backgroundColor: kColorLavenderBg,
          extendBody: true,
          appBar: CommonAppBarWidget(
            title: meta.$1,
            subtitle: meta.$2,
            toolbarHeight: 56,
            showBackButton: Navigator.of(context).canPop(),
          ),
          body: switch (controller.selectedIndex.value) {
            SuperAdminBottomNavController.dashboardTabIndex =>
              const SuperAdminDashboardTabView(),
            SuperAdminBottomNavController.agencyTabIndex =>
              const SuperAdminAgencyTabView(),
            SuperAdminBottomNavController.hostTabIndex =>
              const SuperAdminHostTabView(),
            SuperAdminBottomNavController.settingsTabIndex =>
              SuperAdminSettingsTabView(
                onLogoutPressed: controller.onLogoutPressed,
              ),
            _ => Spacing.shrink,
          },
          bottomNavigationBar: AdminBottomNavBar(
            items: controller.items,
            selectedIndex: controller.selectedIndex.value,
            onSelected: controller.onNavBarTabSelected,
          ),
        );
      }),
    );
  }
}
