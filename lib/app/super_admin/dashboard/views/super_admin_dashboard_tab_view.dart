import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/super_admin/bottom_nav/controllers/super_admin_bottom_nav_controller.dart';
import 'package:qobo_one_live/app/super_admin/home/controllers/super_admin_home_controller.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_ui.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_ui_kit.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/admin_agency_chrome.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

/// Dashboard tab — solid Profile-style colors (no frosted blur widgets).
class SuperAdminDashboardTabView extends GetView<SuperAdminHomeController> {
  const SuperAdminDashboardTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return SuperAdminPageScaffold(
      primary: SuperAdminUi.violet,
      secondary: SuperAdminUi.pink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SuperAdminTabHeader(
            icon: Icons.dashboard_customize_rounded,
            title: 'Dashboard',
            subtitle: 'Agencies, hosts, and commissions at a glance',
            accent: SuperAdminUi.sky,
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
      final items = <_StatSpec>[
        _StatSpec(
          label: 'Agencies',
          value: stats?.totalAgencies ?? 0,
          icon: Icons.apartment_rounded,
          accent: const Color(0xFF7C4DFF),
          accentEnd: const Color(0xFFB388FF),
          onTap: () => _jumpToAgency(filter: 'all'),
        ),
        _StatSpec(
          label: 'Active Hosts',
          value: stats?.activeHosts ?? 0,
          icon: Icons.videocam_rounded,
          accent: const Color(0xFF00C853),
          accentEnd: const Color(0xFF69F0AE),
          onTap: () => _jumpToHost(filter: 'active'),
        ),
        _StatSpec(
          label: 'Pending',
          value: stats?.pendingAgencies ?? 0,
          icon: Icons.hourglass_top_rounded,
          accent: const Color(0xFFFF9100),
          accentEnd: const Color(0xFFFFD180),
          onTap: () => _jumpToAgency(filter: 'pending'),
        ),
        _StatSpec(
          label: 'Live Now',
          value: stats?.liveHostsNow ?? 0,
          icon: Icons.sensors_rounded,
          accent: const Color(0xFFFF1744),
          accentEnd: const Color(0xFFFF8A80),
          onTap: () => _jumpToHost(),
        ),
      ];

      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _StatTile(spec: items[0])),
              Spacing.h12,
              Expanded(child: _StatTile(spec: items[1])),
            ],
          ),
          Spacing.v12,
          Row(
            children: [
              Expanded(child: _StatTile(spec: items[2])),
              Spacing.h12,
              Expanded(child: _StatTile(spec: items[3])),
            ],
          ),
        ],
      );
    });
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
              AdminAgencyUi.glowIcon(
                icon: Icons.add_link_rounded,
                accent: const Color(0xFFFFB300),
                accentEnd: const Color(0xFFFFE082),
                size: 48,
                iconSize: 24,
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
              Spacing.h8,
              Obx(() {
                final busy = controller.isGeneratingAgencyLink.value;
                return AdminGoldCtaButton(
                  label: 'Generate',
                  icon: Icons.ios_share_rounded,
                  busy: busy,
                  onTap: controller.generateAgencyLink,
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
                  AdminAgencyUi.glowIcon(
                    icon: Icons.content_copy_rounded,
                    accent: const Color(0xFF2979FF),
                    accentEnd: const Color(0xFF82B1FF),
                    size: 36,
                    iconSize: 16,
                  ),
                  Spacing.h10,
                  Expanded(
                    child: AppText(
                      text: link,
                      fontSize: TextStyles.k10FontSize,
                      color: SuperAdminUi.textSecondary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2979FF), Color(0xFF7C4DFF)],
                      ),
                    ),
                    child: const SemiBoldText(
                      text: 'Copy',
                      fontSize: TextStyles.k10FontSize,
                      color: kColorWhite,
                    ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AdminAgencyUi.glowIcon(
                  icon: Icons.payments_rounded,
                  accent: const Color(0xFFFF9100),
                  accentEnd: const Color(0xFFFFD54F),
                  size: 48,
                  iconSize: 24,
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
                        fontSize: TextStyles.k26FontSize,
                        color: SuperAdminUi.textPrimary,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C853), Color(0xFF69F0AE)],
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.trending_up_rounded,
                        size: 14,
                        color: kColorWhite,
                      ),
                      SizedBox(width: 4),
                      SemiBoldText(
                        text: 'Live',
                        fontSize: TextStyles.k10FontSize,
                        color: kColorWhite,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Spacing.v12,
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFF3D1F5C),
                border: Border.all(color: const Color(0xFFFF5CAB), width: 1.2),
              ),
              child: Row(
                children: [
                  AdminAgencyUi.glowIcon(
                    icon: Icons.calendar_month_rounded,
                    accent: const Color(0xFFFF5CAB),
                    accentEnd: const Color(0xFFFF8AD8),
                    size: 28,
                    iconSize: 14,
                  ),
                  Spacing.h8,
                  Expanded(
                    child: AppText(
                      text: 'This month · ${month.toStringAsFixed(2)}',
                      fontSize: TextStyles.k12FontSize,
                      color: SuperAdminUi.textSecondary,
                    ),
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
                AdminAgencyUi.glowIcon(
                  icon: Icons.emoji_events_rounded,
                  accent: const Color(0xFFFFB300),
                  accentEnd: const Color(0xFFFFE082),
                  size: 36,
                  iconSize: 18,
                ),
                Spacing.h10,
                const Expanded(
                  child: SemiBoldText(
                    text: 'Top agencies',
                    fontSize: TextStyles.k14FontSize,
                    color: SuperAdminUi.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C4DFF), Color(0xFFB388FF)],
                    ),
                  ),
                  child: SemiBoldText(
                    text: '${top.length}',
                    fontSize: TextStyles.k10FontSize,
                    color: kColorWhite,
                  ),
                ),
              ],
            ),
            Spacing.v16,
            if (top.isEmpty)
              const SuperAdminEmptyState(
                icon: Icons.apartment_rounded,
                title: 'No top agencies yet',
                subtitle:
                    'Agency rankings will appear once commissions start.',
              )
            else
              ...top.asMap().entries.map((entry) {
                final index = entry.key;
                final agency = entry.value;
                final isLast = index == top.length - 1;
                final canOpen = agency.id.isNotEmpty;
                final rankColors = index == 0
                    ? const [Color(0xFFFFB300), Color(0xFFFFE082)]
                    : index == 1
                        ? const [Color(0xFF2979FF), Color(0xFF82B1FF)]
                        : index == 2
                            ? const [Color(0xFFFF5CAB), Color(0xFFFF8AD8)]
                            : const [Color(0xFF7C4DFF), Color(0xFFB388FF)];
                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: canOpen
                          ? () => controller.openAgencyById(agency.id)
                          : null,
                      borderRadius: BorderRadius.circular(14),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: const Color(0xFF3D1F5C),
                          border: Border.all(
                            color: rankColors.first,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: rankColors),
                              ),
                              child: SemiBoldText(
                                text: '${index + 1}',
                                fontSize: TextStyles.k12FontSize,
                                color: const Color(0xFF1A1200),
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
                              color: rankColors.first,
                            ),
                            if (canOpen) ...[
                              Spacing.h4,
                              Icon(
                                Icons.chevron_right_rounded,
                                color: rankColors.first,
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

class _StatSpec {
  const _StatSpec({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.accentEnd,
    required this.onTap,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color accent;
  final Color accentEnd;
  final VoidCallback onTap;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.spec});

  final _StatSpec spec;

  @override
  Widget build(BuildContext context) {
    return SuperAdminGlassCard(
      glow: spec.accent,
      onTap: spec.onTap,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AdminAgencyUi.glowIcon(
                icon: spec.icon,
                accent: spec.accent,
                accentEnd: spec.accentEnd,
                size: 44,
                iconSize: 22,
              ),
              const Spacer(),
              Icon(
                Icons.arrow_outward_rounded,
                size: 16,
                color: spec.accent,
              ),
            ],
          ),
          Spacing.v12,
          BoldText(
            text: '${spec.value}',
            fontSize: TextStyles.k22FontSize,
            color: SuperAdminUi.textPrimary,
          ),
          Spacing.v4,
          AppText(
            text: spec.label,
            fontSize: TextStyles.k10FontSize,
            color: SuperAdminUi.textMuted,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
