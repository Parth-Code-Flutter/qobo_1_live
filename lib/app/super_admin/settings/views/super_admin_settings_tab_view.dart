import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/super_admin/bottom_nav/controllers/super_admin_bottom_nav_controller.dart';
import 'package:qobo_one_live/app/super_admin/home/controllers/super_admin_home_controller.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_ui.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_ui_kit.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Settings tab — profile summary + quick jumps + logout.
class SuperAdminSettingsTabView extends StatelessWidget {
  const SuperAdminSettingsTabView({super.key, required this.onLogoutPressed});

  final Future<void> Function() onLogoutPressed;

  @override
  Widget build(BuildContext context) {
    return SuperAdminPageScaffold(
      primary: SuperAdminUi.gold,
      secondary: SuperAdminUi.violet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SuperAdminTabHeader(
            title: 'Settings',
            subtitle: 'Account and session controls',
            accent: SuperAdminUi.gold,
          ),
          Expanded(
            child: ListView(
              padding: SuperAdminUi.pageInsets,
              children: [
                GetBuilder<UserSessionController>(
                  builder: (session) {
                    return SuperAdminGlassCard(
                      glow: SuperAdminUi.gold,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              FramedUserAvatar(
                                name: session.displayName,
                                imageUrl: session.displayPictureUrl,
                                frameUrl: session.profileFrameUrl,
                                frameSeed: session.userId,
                                size: 64,
                                fontSize: TextStyles.k16FontSize,
                              ),
                              Positioned(
                                right: -4,
                                bottom: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: SuperAdminUi.goldButtonGradient,
                                    boxShadow: [
                                      BoxShadow(
                                        color: SuperAdminUi.gold.withValues(
                                          alpha: 0.35,
                                        ),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.workspace_premium_rounded,
                                    size: 14,
                                    color: Color(0xFF1A1200),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Spacing.h12,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SemiBoldText(
                                  text: session.displayName,
                                  fontSize: TextStyles.k16FontSize,
                                  color: SuperAdminUi.textPrimary,
                                ),
                                Spacing.v4,
                                AppText(
                                  text: session.email.isNotEmpty
                                      ? session.email
                                      : session.phone,
                                  fontSize: TextStyles.k12FontSize,
                                  color: SuperAdminUi.textMuted,
                                ),
                                Spacing.v8,
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: SuperAdminUi.gold.withValues(
                                      alpha: 0.14,
                                    ),
                                    border: Border.all(
                                      color: SuperAdminUi.gold.withValues(
                                        alpha: 0.38,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.verified_rounded,
                                        size: 12,
                                        color: SuperAdminUi.gold,
                                      ),
                                      Spacing.h4,
                                      SemiBoldText(
                                        text: session.role.isEmpty
                                            ? 'super_admin'
                                            : session.role,
                                        fontSize: TextStyles.k10FontSize,
                                        color: SuperAdminUi.textPrimary,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Spacing.v(SuperAdminUi.sectionGap),
                _infoRow(
                  icon: Icons.refresh_rounded,
                  accent: SuperAdminUi.sky,
                  title: 'Refresh dashboard data',
                  subtitle: 'Reload agencies, hosts, and commissions',
                  onTap: () {
                    if (!Get.isRegistered<SuperAdminHomeController>()) {
                      return;
                    }
                    Get.find<SuperAdminHomeController>().loadDashboardStats(
                      showLoader: true,
                    );
                  },
                ),
                Spacing.v12,
                _infoRow(
                  icon: Icons.business_rounded,
                  accent: SuperAdminUi.pink,
                  title: 'Agencies',
                  subtitle: 'Jump to agency review',
                  onTap: () {
                    Get.find<SuperAdminBottomNavController>()
                        .onNavBarTabSelected(
                          SuperAdminBottomNavController.agencyTabIndex,
                        );
                  },
                ),
                Spacing.v12,
                _infoRow(
                  icon: Icons.mic_rounded,
                  accent: SuperAdminUi.teal,
                  title: 'Hosts',
                  subtitle: 'Jump to host tracking',
                  onTap: () {
                    Get.find<SuperAdminBottomNavController>()
                        .onNavBarTabSelected(
                          SuperAdminBottomNavController.hostTabIndex,
                        );
                  },
                ),
                Spacing.v24,
                appButton(
                  onPressed: () => onLogoutPressed(),
                  buttonText: 'Log out',
                  isGradient: true,
                  buttonHeight: 50,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color accent,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return SuperAdminGlassCard(
      glow: accent,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          SuperAdminUi.glowIcon(
            icon: icon,
            accent: accent,
            size: 40,
            iconSize: 20,
          ),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: title,
                  fontSize: TextStyles.k14FontSize,
                  color: SuperAdminUi.textPrimary,
                ),
                Spacing.v2,
                AppText(
                  text: subtitle,
                  fontSize: TextStyles.k12FontSize,
                  color: SuperAdminUi.textMuted,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: SuperAdminUi.textFaint,
            size: 20,
          ),
        ],
      ),
    );
  }
}
