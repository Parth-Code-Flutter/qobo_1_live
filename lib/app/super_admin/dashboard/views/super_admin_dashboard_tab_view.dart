import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/super_admin/home/controllers/super_admin_home_controller.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_glass_card.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_ui_kit.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Dashboard tab — `GET /api/super-admin/dashboard` + generate-link.
class SuperAdminDashboardTabView extends GetView<SuperAdminHomeController> {
  const SuperAdminDashboardTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage(kImgBG), fit: BoxFit.cover),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(),
            Expanded(
              child: Obx(() {
                if (controller.isLoadingStats.value &&
                    controller.stats.value == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: kColorPrimary),
                  );
                }
                return RefreshIndicator(
                  color: kColorPrimary,
                  onRefresh: () =>
                      controller.loadDashboardStats(showLoader: false),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                    children: [
                      if (controller.error.value.isNotEmpty) ...[
                        SuperAdminGlassCard(
                          child: AppText(
                            text: controller.error.value,
                            fontSize: TextStyles.k12FontSize,
                            color: const Color(0xFFFF8A80),
                          ),
                        ),
                        Spacing.v12,
                      ],
                      _statsGrid(),
                      Spacing.v16,
                      _inviteCard(),
                      Spacing.v16,
                      _commissionsCard(),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return const SuperAdminTabHeader(
      icon: Icons.dashboard_rounded,
      title: 'Dashboard',
      subtitle: 'Agencies, hosts, and commissions at a glance',
    );
  }

  Widget _statsGrid() {
    return Obx(() {
      final stats = controller.stats.value;
      // (label, value, icon, accent color) per stat tile.
      final items = [
        (
          'Agencies',
          stats?.totalAgencies ?? 0,
          Icons.business_rounded,
          const Color(0xFF9C6BFF),
        ),
        (
          'Active Hosts',
          stats?.activeHosts ?? 0,
          Icons.video_camera_front_rounded,
          const Color(0xFF4ADE80),
        ),
        (
          'Pending Agencies',
          stats?.pendingAgencies ?? 0,
          Icons.pending_actions_rounded,
          const Color(0xFFFFD166),
        ),
        (
          'Pending Hosts',
          stats?.pendingHosts ?? 0,
          Icons.person_add_alt_rounded,
          const Color(0xFF62C6FF),
        ),
      ];
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          mainAxisExtent: 92,
        ),
        itemBuilder: (_, index) {
          final item = items[index];
          final accent = item.$4;
          return SuperAdminGlassCard(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.18),
                    border: Border.all(color: accent.withValues(alpha: 0.4)),
                  ),
                  child: Icon(item.$3, color: accent, size: 20),
                ),
                Spacing.h10,
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BoldText(
                        text: '${item.$2}',
                        fontSize: TextStyles.k20FontSize,
                        color: kColorWhite,
                      ),
                      AppText(
                        text: item.$1,
                        fontSize: TextStyles.k10FontSize,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _inviteCard() {
    return SuperAdminGlassCard(
      child: Row(
        children: [
          const Icon(Icons.link_rounded, color: Color(0xFFFFD166), size: 30),
          Spacing.h12,
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: 'Invite Agency',
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite,
                ),
                AppText(
                  text: 'Generate link and share on WhatsApp',
                  fontSize: TextStyles.k10FontSize,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: controller.generateAgencyLink,
            child: const SemiBoldText(
              text: 'Generate',
              fontSize: TextStyles.k12FontSize,
              color: Color(0xFFFFD166),
            ),
          ),
        ],
      ),
    );
  }

  Widget _commissionsCard() {
    return Obx(() {
      final total = controller.stats.value?.totalCommissions ?? 0;
      return SuperAdminGlassCard(
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFFFD166).withValues(alpha: 0.2),
              child: const Icon(
                Icons.payments_rounded,
                color: Color(0xFFFFD166),
              ),
            ),
            Spacing.h12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText(
                    text: 'Total Commissions',
                    fontSize: TextStyles.k12FontSize,
                    color: Colors.white70,
                  ),
                  Spacing.v4,
                  SemiBoldText(
                    text: total.toStringAsFixed(2),
                    fontSize: TextStyles.k18FontSize,
                    color: kColorWhite,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
