import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/super_admin/home/controllers/super_admin_home_controller.dart';
import 'package:qobo_one_live/app/super_admin/models/super_admin_models.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_ui.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_ui_kit.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/safe_network_avatar.dart';
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
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage(kImgBG), fit: BoxFit.cover),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SuperAdminTabHeader(
              icon: Icons.mic_rounded,
              title: 'Host',
              subtitle: 'Track host activity across all agencies',
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
                  onRefresh: () =>
                      controller.loadTrackedHosts(showLoader: false),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                    itemCount: hosts.length,
                    separatorBuilder: (_, __) => Spacing.v12,
                    itemBuilder: (_, index) {
                      final host = hosts[index];
                      return SuperAdminGlassCard(
                        glow: SuperAdminUi.teal,
                        onTap: () => controller.openHostDetail(host),
                        child: Row(
                          children: [
                            SafeNetworkAvatar(
                              url: host.avatarUrl,
                              size: 48,
                              fallback: CircleAvatar(
                                radius: 24,
                                backgroundColor: kColorPrimary,
                                child: Text(
                                  host.name.isNotEmpty
                                      ? host.name.characters.first
                                      : 'H',
                                ),
                              ),
                            ),
                            Spacing.h12,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SemiBoldText(
                                    text: host.name,
                                    fontSize: TextStyles.k14FontSize,
                                    color: kColorWhite,
                                  ),
                                  Spacing.v2,
                                  AppText(
                                    text:
                                        'Agency ${host.agencyCode.isEmpty ? '—' : host.agencyCode} • ${host.status}',
                                    fontSize: TextStyles.k10FontSize,
                                    color: Colors.white70,
                                  ),
                                  Spacing.v8,
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _metricChip(
                                        Icons.diamond_rounded,
                                        host.diamonds.toStringAsFixed(0),
                                        SuperAdminUi.sky,
                                      ),
                                      _metricChip(
                                        Icons.monetization_on_rounded,
                                        host.coins.toStringAsFixed(0),
                                        SuperAdminUi.gold,
                                      ),
                                      _metricChip(
                                        Icons.timer_outlined,
                                        _formatSeconds(host.totalStreamSeconds),
                                        SuperAdminUi.mint,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: SuperAdminUi.gold.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      SuperAdminUi.gold.withValues(alpha: 0.4),
                                ),
                              ),
                              child: SemiBoldText(
                                text: host.totalCommissionEarned
                                    .toStringAsFixed(1),
                                fontSize: TextStyles.k12FontSize,
                                color: SuperAdminUi.gold,
                              ),
                            ),
                            Spacing.h6,
                            _manageButton(context, host),
                          ],
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricChip(IconData icon, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: accent),
          Spacing.h4,
          AppText(
            text: value,
            fontSize: TextStyles.k10FontSize,
            color: Colors.white70,
          ),
        ],
      ),
    );
  }

  Widget _filterChips() {
    return SizedBox(
      height: 44,
      child: Obx(() {
        final selected = controller.hostStatusFilter.value;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
            color: kColorWhite.withValues(alpha: 0.10),
            border: Border.all(color: kColorWhite.withValues(alpha: 0.16)),
          ),
          child: processing
              ? const Padding(
                  padding: EdgeInsets.all(7),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white70,
                  ),
                )
              : const Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: Colors.white70,
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
            border: Border.all(color: kColorWhite.withValues(alpha: 0.14)),
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
                color: kColorWhite,
              ),
              if (subtitle != null) ...[
                Spacing.v8,
                AppText(
                  text: subtitle,
                  fontSize: TextStyles.k12FontSize,
                  color: Colors.white60,
                ),
              ],
              Spacing.v12,
              TextField(
                controller: reasonController,
                style: const TextStyle(color: kColorWhite),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: Colors.white38),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: kColorWhite.withValues(alpha: 0.2),
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
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(
                            color: kColorWhite.withValues(alpha: 0.22),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const SemiBoldText(
                          text: 'Cancel',
                          fontSize: TextStyles.k12FontSize,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                  Spacing.h10,
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(true),
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
                          color: kColorWhite,
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
