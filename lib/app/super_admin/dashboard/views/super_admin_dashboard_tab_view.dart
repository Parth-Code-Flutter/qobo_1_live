import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/super_admin/bottom_nav/controllers/super_admin_bottom_nav_controller.dart';
import 'package:qobo_one_live/app/super_admin/home/controllers/super_admin_home_controller.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_ui.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_ui_kit.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

/// Dashboard tab — `GET /api/super-admin/dashboard` + generate-link.
class SuperAdminDashboardTabView extends GetView<SuperAdminHomeController> {
  const SuperAdminDashboardTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return SuperAdminPageScaffold(
      primary: SuperAdminUi.violet,
      secondary: SuperAdminUi.sky,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SuperAdminTabHeader(
            icon: Icons.dashboard_rounded,
            title: 'Dashboard',
            subtitle: 'Agencies, hosts, and commissions at a glance',
            accent: SuperAdminUi.violet,
          ),
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
                  padding: SuperAdminUi.pageInsets,
                  children: [
                    if (controller.error.value.isNotEmpty) ...[
                      SuperAdminGlassCard(
                        glow: SuperAdminUi.danger,
                        child: AppText(
                          text: controller.error.value,
                          fontSize: TextStyles.k12FontSize,
                          color: SuperAdminUi.danger,
                        ),
                      ),
                      Spacing.v(SuperAdminUi.sectionGap),
                    ],
                    _statsGrid(),
                    Spacing.v(SuperAdminUi.sectionGap),
                    _inviteCard(),
                    Spacing.v(SuperAdminUi.sectionGap),
                    _commissionsCard(),
                    Spacing.v(SuperAdminUi.sectionGap),
                    _topAgenciesCard(),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _jumpToAgency({String? filter}) {
    if (filter != null) {
      controller.changeAgencyFilter(filter);
    }
    Get.find<SuperAdminBottomNavController>().onNavBarTabSelected(
      SuperAdminBottomNavController.agencyTabIndex,
    );
  }

  void _jumpToHost({String? filter}) {
    if (filter != null) {
      controller.changeHostFilter(filter);
    }
    Get.find<SuperAdminBottomNavController>().onNavBarTabSelected(
      SuperAdminBottomNavController.hostTabIndex,
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
          SuperAdminUi.violet,
          () => _jumpToAgency(filter: 'all'),
        ),
        (
          'Active Hosts',
          stats?.activeHosts ?? 0,
          Icons.video_camera_front_rounded,
          SuperAdminUi.mint,
          () => _jumpToHost(filter: 'active'),
        ),
        (
          'Pending',
          stats?.pendingAgencies ?? 0,
          Icons.pending_actions_rounded,
          SuperAdminUi.gold,
          () => _jumpToAgency(filter: 'pending'),
        ),
        (
          'Live Now',
          stats?.liveHostsNow ?? 0,
          Icons.sensors_rounded,
          SuperAdminUi.rose,
          () => _jumpToHost(),
        ),
      ];

      // Two fixed rows avoid GridView shrink-wrap leaving a tall empty gap.
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _statTile(items[0], delayMs: 0)),
              Spacing.h12,
              Expanded(child: _statTile(items[1], delayMs: 40)),
            ],
          ),
          Spacing.v12,
          Row(
            children: [
              Expanded(child: _statTile(items[2], delayMs: 80)),
              Spacing.h12,
              Expanded(child: _statTile(items[3], delayMs: 120)),
            ],
          ),
        ],
      );
    });
  }

  Widget _statTile(
    (String, int, IconData, Color, VoidCallback) item, {
    required int delayMs,
  }) {
    final accent = item.$4;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1),
      duration: Duration(milliseconds: 420 + delayMs),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: SuperAdminGlassCard(
        glow: accent,
        onTap: item.$5,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            SuperAdminUi.glowIcon(
              icon: item.$3,
              accent: accent,
              size: 40,
              iconSize: 18,
            ),
            Spacing.h12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BoldText(
                    text: '${item.$2}',
                    fontSize: TextStyles.k22FontSize,
                    color: SuperAdminUi.textPrimary,
                  ),
                  Spacing.v2,
                  AppText(
                    text: item.$1,
                    fontSize: TextStyles.k10FontSize,
                    color: SuperAdminUi.textMuted,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inviteCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SuperAdminGlassCard(
          glow: SuperAdminUi.gold,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SuperAdminUi.glowIcon(
                icon: Icons.link_rounded,
                accent: SuperAdminUi.gold,
                size: 44,
                iconSize: 22,
              ),
              Spacing.h12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SemiBoldText(
                      text: 'Invite Agency',
                      fontSize: TextStyles.k14FontSize,
                      color: SuperAdminUi.textPrimary,
                    ),
                    Spacing.v4,
                    const AppText(
                      text: 'Create a link and share anywhere',
                      fontSize: TextStyles.k12FontSize,
                      color: SuperAdminUi.textMuted,
                    ),
                  ],
                ),
              ),
              Spacing.h10,
              Obx(() {
                final busy = controller.isGeneratingAgencyLink.value;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: busy ? null : controller.generateAgencyLink,
                    borderRadius: BorderRadius.circular(14),
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: SuperAdminUi.goldButtonGradient,
                        boxShadow: [
                          BoxShadow(
                            color: SuperAdminUi.gold.withValues(alpha: 0.28),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
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
        ),
        Obx(() {
          final link = controller.generatedAgencyLink.value;
          if (link.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SuperAdminGlassCard(
              glow: SuperAdminUi.sky,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: link));
                final ctx = Get.context;
                if (ctx != null) {
                  AppToast.showSuccess(ctx, 'Link copied.');
                }
              },
              child: Row(
                children: [
                  Icon(
                    Icons.content_copy_rounded,
                    size: 16,
                    color: SuperAdminUi.sky,
                  ),
                  Spacing.h8,
                  Expanded(
                    child: AppText(
                      text: link,
                      fontSize: TextStyles.k10FontSize,
                      color: SuperAdminUi.textSecondary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SemiBoldText(
                    text: 'Copy',
                    fontSize: TextStyles.k10FontSize,
                    color: SuperAdminUi.sky,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _commissionsCard() {
    return Obx(() {
      final stats = controller.stats.value;
      final total = stats?.totalCommissions ?? 0;
      final month = stats?.commissionsThisMonth ?? 0;
      return SuperAdminGlassCard(
        glow: SuperAdminUi.gold,
        child: Row(
          children: [
            SuperAdminUi.glowIcon(
              icon: Icons.payments_rounded,
              accent: SuperAdminUi.gold,
              size: 46,
              iconSize: 22,
            ),
            Spacing.h12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText(
                    text: 'Total Commissions',
                    fontSize: TextStyles.k12FontSize,
                    color: SuperAdminUi.textMuted,
                  ),
                  Spacing.v4,
                  SemiBoldText(
                    text: total.toStringAsFixed(2),
                    fontSize: TextStyles.k22FontSize,
                    color: SuperAdminUi.textPrimary,
                  ),
                  Spacing.v4,
                  AppText(
                    text: 'This month · ${month.toStringAsFixed(2)}',
                    fontSize: TextStyles.k12FontSize,
                    color: SuperAdminUi.textMuted,
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
        glow: SuperAdminUi.violet,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SuperAdminUi.glowIcon(
                  icon: Icons.emoji_events_rounded,
                  accent: SuperAdminUi.violet,
                  size: 30,
                  iconSize: 16,
                ),
                Spacing.h10,
                const SemiBoldText(
                  text: 'Top agencies',
                  fontSize: TextStyles.k14FontSize,
                  color: SuperAdminUi.textPrimary,
                ),
              ],
            ),
            Spacing.v16,
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
                final canOpen = agency.id.isNotEmpty;
                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: canOpen
                          ? () => controller.openAgencyById(agency.id)
                          : null,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: SuperAdminUi.panel.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: SuperAdminUi.textPrimary.withValues(
                              alpha: 0.06,
                            ),
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
                                color: SuperAdminUi.gold.withValues(alpha: 0.14),
                              ),
                              child: SemiBoldText(
                                text: '${index + 1}',
                                fontSize: TextStyles.k12FontSize,
                                color: SuperAdminUi.gold,
                              ),
                            ),
                            Spacing.h12,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SemiBoldText(
                                    text: agency.name,
                                    fontSize: TextStyles.k12FontSize,
                                    color: SuperAdminUi.textPrimary,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Spacing.v2,
                                  AppText(
                                    text: agency.code,
                                    fontSize: TextStyles.k10FontSize,
                                    color: SuperAdminUi.textMuted,
                                  ),
                                ],
                              ),
                            ),
                            SemiBoldText(
                              text: agency.totalCommissionEarned
                                  .toStringAsFixed(1),
                              fontSize: TextStyles.k12FontSize,
                              color: SuperAdminUi.gold,
                            ),
                            if (canOpen) ...[
                              Spacing.h4,
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: SuperAdminUi.textFaint,
                                size: 18,
                              ),
                            ],
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
    });
  }
}
