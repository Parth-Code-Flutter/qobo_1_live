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

  static const _gold = Color(0xFFFFD166);
  static const _violet = Color(0xFF9C6BFF);
  static const _mint = Color(0xFF4ADE80);
  static const _rose = Color(0xFFFF6B8A);

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
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    children: [
                      if (controller.error.value.isNotEmpty) ...[
                        SuperAdminGlassCard(
                          child: AppText(
                            text: controller.error.value,
                            fontSize: TextStyles.k12FontSize,
                            color: const Color(0xFFFF8A80),
                          ),
                        ),
                        Spacing.v10,
                      ],
                      _statsGrid(),
                      Spacing.v12,
                      _inviteCard(),
                      Spacing.v12,
                      _commissionsCard(),
                      Spacing.v12,
                      _topAgenciesCard(),
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
      final items = [
        (
          'Agencies',
          stats?.totalAgencies ?? 0,
          Icons.business_rounded,
          _violet,
        ),
        (
          'Active Hosts',
          stats?.activeHosts ?? 0,
          Icons.video_camera_front_rounded,
          _mint,
        ),
        (
          'Pending',
          stats?.pendingAgencies ?? 0,
          Icons.pending_actions_rounded,
          _gold,
        ),
        (
          'Live Now',
          stats?.liveHostsNow ?? 0,
          Icons.sensors_rounded,
          _rose,
        ),
      ];

      // Two fixed rows avoid GridView shrink-wrap leaving a tall empty gap.
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _statTile(items[0])),
              Spacing.h10,
              Expanded(child: _statTile(items[1])),
            ],
          ),
          Spacing.v10,
          Row(
            children: [
              Expanded(child: _statTile(items[2])),
              Spacing.h10,
              Expanded(child: _statTile(items[3])),
            ],
          ),
        ],
      );
    });
  }

  Widget _statTile(
    (String, int, IconData, Color) item,
  ) {
    final accent = item.$4;
    return SuperAdminGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.45),
                  accent.withValues(alpha: 0.12),
                ],
              ),
              border: Border.all(color: accent.withValues(alpha: 0.55)),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(item.$3, color: accent, size: 18),
          ),
          Spacing.h10,
          Expanded(
            child: Column(
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inviteCard() {
    return SuperAdminGlassCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _gold.withValues(alpha: 0.35),
                  _gold.withValues(alpha: 0.08),
                ],
              ),
              border: Border.all(color: _gold.withValues(alpha: 0.45)),
            ),
            child: const Icon(Icons.link_rounded, color: _gold, size: 22),
          ),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SemiBoldText(
                  text: 'Invite Agency',
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite,
                ),
                Spacing.v2,
                const AppText(
                  text: 'Create a link and share anywhere',
                  fontSize: TextStyles.k10FontSize,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
          Spacing.h8,
          Obx(() {
            final busy = controller.isGeneratingAgencyLink.value;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: busy ? null : controller.generateAgencyLink,
                borderRadius: BorderRadius.circular(22),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFE08A), Color(0xFFFFD166)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _gold.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF1A1200),
                            ),
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.ios_share_rounded,
                                size: 15,
                                color: Color(0xFF1A1200),
                              ),
                              SizedBox(width: 6),
                              SemiBoldText(
                                text: 'Generate',
                                fontSize: TextStyles.k12FontSize,
                                color: Color(0xFF1A1200),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _commissionsCard() {
    return Obx(() {
      final stats = controller.stats.value;
      final total = stats?.totalCommissions ?? 0;
      final month = stats?.commissionsThisMonth ?? 0;
      return SuperAdminGlassCard(
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    _gold.withValues(alpha: 0.4),
                    _gold.withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(color: _gold.withValues(alpha: 0.45)),
              ),
              child: const Icon(Icons.payments_rounded, color: _gold, size: 22),
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
                    fontSize: TextStyles.k20FontSize,
                    color: kColorWhite,
                  ),
                  Spacing.v2,
                  AppText(
                    text: 'This month · ${month.toStringAsFixed(2)}',
                    fontSize: TextStyles.k10FontSize,
                    color: Colors.white60,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _topAgenciesCard() {
    return Obx(() {
      final top = controller.stats.value?.topAgencies ?? const [];
      return SuperAdminGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: _violet.withValues(alpha: 0.2),
                    border: Border.all(color: _violet.withValues(alpha: 0.4)),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: _violet,
                    size: 16,
                  ),
                ),
                Spacing.h8,
                const SemiBoldText(
                  text: 'Top agencies',
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite,
                ),
              ],
            ),
            Spacing.v12,
            if (top.isEmpty)
              const SuperAdminEmptyState(
                icon: Icons.apartment_rounded,
                title: 'No top agencies yet',
                subtitle: 'Agency rankings will appear once commissions start.',
              )
            else
              ...top.asMap().entries.map((entry) {
                final index = entry.key;
                final agency = entry.value;
                final isLast = index == top.length - 1;
                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: kColorWhite.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: kColorWhite.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _gold.withValues(alpha: 0.15),
                          ),
                          child: SemiBoldText(
                            text: '${index + 1}',
                            fontSize: TextStyles.k12FontSize,
                            color: _gold,
                          ),
                        ),
                        Spacing.h10,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SemiBoldText(
                                text: agency.name,
                                fontSize: TextStyles.k12FontSize,
                                color: kColorWhite,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              AppText(
                                text: agency.code,
                                fontSize: TextStyles.k10FontSize,
                                color: Colors.white60,
                              ),
                            ],
                          ),
                        ),
                        SemiBoldText(
                          text: agency.totalCommissionEarned.toStringAsFixed(1),
                          fontSize: TextStyles.k12FontSize,
                          color: _gold,
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      );
    });
  }
}
