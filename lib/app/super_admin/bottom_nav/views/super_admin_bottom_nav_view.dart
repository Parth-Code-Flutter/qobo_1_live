import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/super_admin/agency/views/super_admin_agency_tab_view.dart';
import 'package:qobo_one_live/app/super_admin/bottom_nav/controllers/super_admin_bottom_nav_controller.dart';
import 'package:qobo_one_live/app/super_admin/dashboard/views/super_admin_dashboard_tab_view.dart';
import 'package:qobo_one_live/app/super_admin/host/views/super_admin_host_tab_view.dart';
import 'package:qobo_one_live/app/super_admin/settings/views/super_admin_settings_tab_view.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Super Admin bottom nav shell — same chrome as user [BottomNavView].
class SuperAdminBottomNavView extends GetView<SuperAdminBottomNavController> {
  const SuperAdminBottomNavView({super.key});

  static const double _iconSize = 18;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
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
                    children: List.generate(
                      controller.items.length,
                      (index) => Expanded(
                        child: _SuperAdminNavTab(
                          label: controller.items[index].label,
                          iconPath: controller.items[index].iconPath,
                          selectedIconPath:
                              controller.items[index].selectedIconPath,
                          selected: controller.selectedIndex.value == index,
                          iconSize: _iconSize,
                          onTap: () => controller.onNavBarTabSelected(index),
                        ),
                      ),
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
    required this.iconPath,
    required this.selectedIconPath,
    required this.selected,
    required this.iconSize,
    required this.onTap,
  });

  final String label;
  final String iconPath;
  final String selectedIconPath;
  final bool selected;
  final double iconSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayIconPath = selected ? selectedIconPath : iconPath;
    final color = selected ? kColorWhite : Colors.white.withValues(alpha: 0.42);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white.withValues(alpha: 0.08),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              displayIconPath,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            Spacing.v6,
            AppText(
              text: label,
              fontSize: TextStyles.k10FontSize,
              style: selected
                  ? TextStyles.kSemiBoldPoppins(
                      fontSize: TextStyles.k12FontSize,
                      colors: kColorWhite,
                    )
                  : TextStyles.kRegularPoppins(
                      fontSize: TextStyles.k10FontSize,
                      colors: Colors.white.withValues(alpha: 0.45),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
