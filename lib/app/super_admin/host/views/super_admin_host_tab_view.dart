import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/super_admin/home/controllers/super_admin_home_controller.dart';
import 'package:qobo_one_live/app/super_admin/models/super_admin_models.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_ui.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_ui_kit.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Host tab — `GET /api/super-admin/hosts/track`.
class SuperAdminHostTabView extends GetView<SuperAdminHomeController> {
  const SuperAdminHostTabView({super.key});

  /// Empty string = no status filter (all hosts).
  static const _filters = <({String value, String label, IconData icon})>[
    (value: '', label: 'All', icon: Icons.grid_view_rounded),
    (value: 'active', label: 'Active', icon: Icons.verified_rounded),
    (
      value: 'suspended',
      label: 'Suspended',
      icon: Icons.pause_circle_filled_rounded,
    ),
    (value: 'inactive', label: 'Inactive', icon: Icons.person_off_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return SuperAdminPageScaffold(
      primary: SuperAdminUi.teal,
      secondary: SuperAdminUi.sky,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SuperAdminTabHeader(
            title: 'Host',
            subtitle: 'Track host activity across all agencies',
            accent: SuperAdminUi.teal,
          ),
          _filterChips(),
          Expanded(
            child: Obx(() {
              if (controller.isLoadingHosts.value &&
                  controller.trackedHosts.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: kColorPrimary),
                );
              }
              final hosts = controller.trackedHosts;
              if (hosts.isEmpty) {
                return RefreshIndicator(
                  color: kColorPrimary,
                  onRefresh: () =>
                      controller.loadTrackedHosts(showLoader: false),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      SuperAdminEmptyState(
                        icon: Icons.podcasts_rounded,
                        title: 'No host activity found',
                        subtitle: 'Pull down to refresh host tracking data',
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                color: kColorPrimary,
                onRefresh: () => controller.loadTrackedHosts(showLoader: false),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: SuperAdminUi.pageInsets,
                  itemCount: hosts.length,
                  separatorBuilder: (_, __) =>
                      Spacing.v(SuperAdminUi.sectionGap),
                  itemBuilder: (_, index) {
                    final host = hosts[index];
                    return _hostCard(context, host);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _hostCard(BuildContext context, SuperAdminTrackedHost host) {
    final glow = host.status.toLowerCase() == 'suspended'
        ? SuperAdminUi.warning
        : SuperAdminUi.teal;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: SuperAdminGlassCard(
        glow: glow,
        padding: const EdgeInsets.all(14),
        onTap: () => controller.openHostDetail(host),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SuperAdminAvatarRing(
                  url: host.avatarUrl,
                  fallbackLetter: host.name,
                  size: 74,
                  accent: glow,
                ),
                Spacing.h12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BoldText(
                        text: host.name,
                        fontSize: TextStyles.k16FontSize,
                        color: SuperAdminUi.textPrimary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Spacing.v4,
                      AppText(
                        text:
                            'Agency ${host.agencyCode.isEmpty ? '—' : host.agencyCode}',
                        fontSize: TextStyles.k12FontSize,
                        color: SuperAdminUi.textSecondary,
                      ),
                      Spacing.v8,
                      SuperAdminStatusPill(status: host.status),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            SuperAdminUi.gold.withValues(alpha: 0.35),
                            SuperAdminUi.gold.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: SuperAdminUi.gold.withValues(alpha: 0.45),
                        ),
                      ),
                      child: SemiBoldText(
                        text: host.totalCommissionEarned.toStringAsFixed(1),
                        fontSize: TextStyles.k12FontSize,
                        color: SuperAdminUi.gold,
                      ),
                    ),
                    Spacing.v8,
                    _manageButton(context, host),
                  ],
                ),
              ],
            ),
            Spacing.v12,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SuperAdminMetricChip(
                  icon: Icons.diamond_rounded,
                  label: host.diamonds.toStringAsFixed(0),
                  accent: SuperAdminUi.sky,
                ),
                SuperAdminMetricChip(
                  coinIcon: true,
                  label: host.coins.toStringAsFixed(0),
                  accent: SuperAdminUi.gold,
                ),
                SuperAdminMetricChip(
                  icon: Icons.timer_outlined,
                  label: _formatSeconds(host.totalStreamSeconds),
                  accent: SuperAdminUi.mint,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChips() {
    return SizedBox(
      height: 48,
      child: Obx(() {
        final selected = controller.hostStatusFilter.value;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: SuperAdminUi.pagePad),
          itemCount: _filters.length,
          separatorBuilder: (_, __) => Spacing.h8,
          itemBuilder: (_, index) {
            final filter = _filters[index];
            return SuperAdminFilterPill(
              label: filter.label,
              icon: filter.icon,
              isSelected: selected == filter.value,
              onTap: () => controller.changeHostFilter(filter.value),
            );
          },
        );
      }),
    );
  }

  Widget _manageButton(BuildContext context, SuperAdminTrackedHost host) {
    return Obx(() {
      final processing = controller.processingHostId.value == host.id;
      return InkWell(
        onTap: processing ? null : () => _openManageSheet(context, host),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: SuperAdminUi.textPrimary.withValues(alpha: 0.10),
            border: Border.all(
              color: SuperAdminUi.textPrimary.withValues(alpha: 0.16),
            ),
          ),
          child: processing
              ? const Padding(
                  padding: EdgeInsets.all(7),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: SuperAdminUi.textSecondary,
                  ),
                )
              : const Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: SuperAdminUi.textSecondary,
                ),
        ),
      );
    });
  }

  void _openManageSheet(BuildContext context, SuperAdminTrackedHost host) {
    final status = host.status.toLowerCase();
    Get.bottomSheet(
      SuperAdminSheetScaffold(
        title: host.name,
        subtitle:
            'Agency ${host.agencyCode.isEmpty ? '—' : host.agencyCode} • ${host.status}',
        children: [
          if (status != 'active')
            SuperAdminSheetAction(
              icon: Icons.play_circle_fill_rounded,
              color: SuperAdminUi.mint,
              label: 'Activate host',
              onTap: () {
                Get.back();
                controller.setHostStatus(host, 'active');
              },
            ),
          if (status != 'suspended')
            SuperAdminSheetAction(
              icon: Icons.pause_circle_filled_rounded,
              color: SuperAdminUi.warning,
              label: 'Suspend host',
              onTap: () async {
                Get.back();
                final reason = await _askReason(
                  context,
                  title: 'Suspend host?',
                  hint: 'Reason (optional)',
                  confirmLabel: 'Suspend',
                );
                if (reason == null) return;
                await controller.setHostStatus(
                  host,
                  'suspended',
                  reason: reason,
                );
              },
            ),
          if (status != 'inactive')
            SuperAdminSheetAction(
              icon: Icons.delete_forever_rounded,
              color: SuperAdminUi.danger,
              label: 'Delete host',
              onTap: () async {
                Get.back();
                final reason = await _askReason(
                  context,
                  title: 'Delete host?',
                  subtitle:
                      'The host is marked inactive and can no longer stream.',
                  hint: 'Reason (optional)',
                  confirmLabel: 'Delete',
                );
                if (reason == null) return;
                await controller.setHostStatus(
                  host,
                  'inactive',
                  reason: reason,
                );
              },
            ),
        ],
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  Future<String?> _askReason(
    BuildContext context, {
    required String title,
    String? subtitle,
    required String hint,
    required String confirmLabel,
  }) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            color: SuperAdminUi.sheet.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: SuperAdminUi.textPrimary.withValues(alpha: 0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: SuperAdminUi.violet.withValues(alpha: 0.22),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SemiBoldText(
                text: title,
                fontSize: TextStyles.k16FontSize,
                color: SuperAdminUi.textPrimary,
              ),
              if (subtitle != null) ...[
                Spacing.v8,
                AppText(
                  text: subtitle,
                  fontSize: TextStyles.k12FontSize,
                  color: SuperAdminUi.textMuted,
                ),
              ],
              Spacing.v12,
              TextField(
                controller: reasonController,
                style: const TextStyle(color: SuperAdminUi.textPrimary),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: SuperAdminUi.textFaint),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: SuperAdminUi.textPrimary.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: SuperAdminUi.violet),
                  ),
                ),
                maxLines: 3,
              ),
              Spacing.v16,
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: SuperAdminUi.textSecondary,
                          side: BorderSide(
                            color: SuperAdminUi.textPrimary.withValues(
                              alpha: 0.22,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const SemiBoldText(
                          text: 'Cancel',
                          fontSize: TextStyles.k12FontSize,
                          color: SuperAdminUi.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  Spacing.h10,
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SuperAdminUi.danger,
                          foregroundColor: kColorWhite,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: SemiBoldText(
                          text: confirmLabel,
                          fontSize: TextStyles.k12FontSize,
                          color: SuperAdminUi.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    final reason = reasonController.text.trim();
    reasonController.dispose();
    return confirmed == true ? reason : null;
  }

  String _formatSeconds(double seconds) {
    if (seconds <= 0) return '0h';
    final hours = seconds / 3600;
    if (hours >= 1) return '${hours.toStringAsFixed(1)}h';
    final minutes = seconds / 60;
    return '${minutes.toStringAsFixed(0)}m';
  }
}
