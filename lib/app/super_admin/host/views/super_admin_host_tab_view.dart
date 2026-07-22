import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/super_admin/home/controllers/super_admin_home_controller.dart';
import 'package:qobo_one_live/app/super_admin/models/super_admin_models.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_glass_card.dart';
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
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => controller.openHostDetail(host),
                          borderRadius: BorderRadius.circular(18),
                          child: SuperAdminGlassCard(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      Spacing.v6,
                                      AppText(
                                        text:
                                            '💎 ${host.diamonds.toStringAsFixed(0)}  ·  🪙 ${host.coins.toStringAsFixed(0)}  ·  ⏱ ${_formatSeconds(host.totalStreamSeconds)}',
                                        fontSize: TextStyles.k10FontSize,
                                        color: Colors.white70,
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
                                    color: const Color(
                                      0xFFFFD166,
                                    ).withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFFFD166,
                                      ).withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: SemiBoldText(
                                    text: host.totalCommissionEarned
                                        .toStringAsFixed(1),
                                    fontSize: TextStyles.k12FontSize,
                                    color: const Color(0xFFFFD166),
                                  ),
                                ),
                                Spacing.h6,
                                _manageButton(context, host),
                              ],
                            ),
                          ),
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
            final isSelected = selected == filter.value;
            return GestureDetector(
              onTap: () => controller.changeHostFilter(filter.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: isSelected
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            kColorLiveFilterChipGradientStart,
                            kColorLiveFilterChipGradientMid,
                            kColorLiveFilterChipGradientEnd,
                          ],
                        )
                      : null,
                  color: isSelected
                      ? null
                      : kColorWhite.withValues(alpha: 0.10),
                  border: Border.all(
                    color: isSelected
                        ? kColorLiveFilterChipBorder
                        : kColorWhite.withValues(alpha: 0.14),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      filter.icon,
                      size: 15,
                      color: isSelected ? kColorWhite : Colors.white60,
                    ),
                    Spacing.h6,
                    SemiBoldText(
                      text: filter.label,
                      fontSize: TextStyles.k12FontSize,
                      color: isSelected ? kColorWhite : Colors.white70,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  /// Edit / delete entry point on each host card.
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

  /// Status actions from `POST /api/super-admin/hosts/:hostId/status`.
  /// `inactive` is the backend's closest equivalent to deleting a host.
  void _openManageSheet(BuildContext context, SuperAdminTrackedHost host) {
    final status = host.status.toLowerCase();
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1B4B),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Spacing.v12,
            SemiBoldText(
              text: host.name,
              fontSize: TextStyles.k16FontSize,
              color: kColorWhite,
            ),
            AppText(
              text:
                  'Agency ${host.agencyCode.isEmpty ? '—' : host.agencyCode}'
                  ' • ${host.status}',
              fontSize: TextStyles.k12FontSize,
              color: Colors.white60,
            ),
            Spacing.v12,
            if (status != 'active')
              _sheetAction(
                icon: Icons.play_circle_fill_rounded,
                color: const Color(0xFF4ADE80),
                label: 'Activate host',
                onTap: () {
                  Get.back();
                  controller.setHostStatus(host, 'active');
                },
              ),
            if (status != 'suspended')
              _sheetAction(
                icon: Icons.pause_circle_filled_rounded,
                color: const Color(0xFFFFB74D),
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
              _sheetAction(
                icon: Icons.delete_forever_rounded,
                color: const Color(0xFFFF8A80),
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
      ),
      backgroundColor: Colors.transparent,
    );
  }

  Widget _sheetAction({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: kColorWhite.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color),
                Spacing.h10,
                SemiBoldText(
                  text: label,
                  fontSize: TextStyles.k12FontSize,
                  color: kColorWhite,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Returns null when cancelled; empty string means confirmed w/o reason.
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
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kColorWhite,
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (subtitle != null) ...[
              Text(subtitle, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: reasonController,
              decoration: InputDecoration(hintText: hint),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
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
