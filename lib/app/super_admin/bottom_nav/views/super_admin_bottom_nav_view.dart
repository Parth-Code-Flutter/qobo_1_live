import 'dart:ui';

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
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Super Admin bottom nav shell — same chrome as user [BottomNavView],
/// with per-tab accent colors for icons.
class SuperAdminBottomNavView extends GetView<SuperAdminBottomNavController> {
  const SuperAdminBottomNavView({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    // Opened from host Profile via Get.toNamed — system/back pops to Profile.
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: kColorWhite,
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
        // Create actions: + on Agency tab registers a new agency,
        // + on Host tab submits a new host application.
        floatingActionButton: Obx(() {
          final index = controller.selectedIndex.value;
          final isAgencyTab =
              index == SuperAdminBottomNavController.agencyTabIndex;
          final isHostTab = index == SuperAdminBottomNavController.hostTabIndex;
          if (!isAgencyTab && !isHostTab) return const SizedBox.shrink();

          final home = Get.find<SuperAdminHomeController>();
          final accent =
              isAgencyTab ? SuperAdminUi.pink : SuperAdminUi.teal;
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
                      color: const Color(0xFF121644),
                      semanticLabel:
                          isAgencyTab ? 'Create agency' : 'Create host',
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        bottomNavigationBar: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF181A5A).withValues(alpha: 0.86),
                    const Color(0xFF121644).withValues(alpha: 0.93),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(26),
                  topRight: Radius.circular(26),
                ),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 0.7,
                  ),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: SizedBox(
                  height: 84,
                  child: Obx(
                    () => Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: List.generate(controller.items.length, (index) {
                        final item = controller.items[index];
                        return Expanded(
                          child: _SuperAdminNavTab(
                            label: item.label,
                            icon: item.icon,
                            accent: item.accent,
                            selected: controller.selectedIndex.value == index,
                            onTap: () => controller.onNavBarTabSelected(index),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuperAdminNavTab extends StatelessWidget {
  const _SuperAdminNavTab({
    required this.label,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? accent : accent.withValues(alpha: 0.45);
    final labelColor = selected ? accent : Colors.white.withValues(alpha: 0.42);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: accent.withValues(alpha: 0.12),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? accent.withValues(alpha: 0.18)
                    : Colors.transparent,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.35),
                          blurRadius: 12,
                          spreadRadius: 0.5,
                        ),
                      ]
                    : null,
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            Spacing.v4,
            AppText(
              text: label,
              fontSize: TextStyles.k10FontSize,
              style: selected
                  ? TextStyles.kSemiBoldPoppins(
                      fontSize: TextStyles.k10FontSize,
                      colors: labelColor,
                    )
                  : TextStyles.kRegularPoppins(
                      fontSize: TextStyles.k10FontSize,
                      colors: labelColor,
                    ),
            ),
            Spacing.v4,
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: selected ? 18 : 0,
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: accent,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.55),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
