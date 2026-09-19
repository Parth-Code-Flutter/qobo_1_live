import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/super_admin/home/controllers/super_admin_home_controller.dart';
import 'package:qobo_one_live/app/super_admin/models/super_admin_models.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_ui.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_ui_kit.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/dating_empty_hero.dart';
import 'package:qobo_one_live/utils/app_widgets/rooms_empty_state.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Agency tab — `GET /api/super-admin/agencies` + process approve/reject.
class SuperAdminAgencyTabView extends GetView<SuperAdminHomeController> {
  const SuperAdminAgencyTabView({super.key});

  static const _filters = ['pending', 'approved', 'suspended', 'all'];

  static const _filterIcons = <String, IconData>{
    'pending': Icons.hourglass_top_rounded,
    'approved': Icons.verified_rounded,
    'suspended': Icons.pause_circle_filled_rounded,
    'all': Icons.grid_view_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return SuperAdminPageScaffold(
      primary: SuperAdminUi.pink,
      secondary: SuperAdminUi.violet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Spacing.v6,
          _filterChips(),
          Expanded(
            child: Obx(() {
              if (controller.isLoadingAgencies.value &&
                  controller.agencies.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: kColorPrimary),
                );
              }
              final agencies = controller.agencies;
              if (agencies.isEmpty) {
                return RefreshIndicator(
                  color: kColorPrimary,
                  onRefresh: () => controller.loadAgencies(showLoader: false),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: SuperAdminUi.pageInsets,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 24,
                          ),
                          child: const RoomsEmptyState(
                            title: 'No agencies found',
                            subtitle:
                                'Pull down to refresh or try another filter',
                            accentColors: [
                              SuperAdminUi.pink,
                              SuperAdminUi.violet,
                            ],
                            heroStyle: DatingEmptyHeroStyle.agency,
                            hint: 'Pull down to refresh',
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
              return RefreshIndicator(
                color: kColorPrimary,
                onRefresh: () => controller.loadAgencies(showLoader: false),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: SuperAdminUi.pageInsets,
                  itemCount: agencies.length,
                  separatorBuilder: (_, __) =>
                      Spacing.v(SuperAdminUi.sectionGap),
                  itemBuilder: (_, index) {
                    final agency = agencies[index];
                    final processing =
                        controller.processingAgencyId.value == agency.id;
                    return _agencyCard(context, agency, processing);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _filterChips() {
    return SizedBox(
      height: 36,
      child: Obx(() {
        final selected = controller.agencyStatusFilter.value;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: SuperAdminUi.pagePad),
          itemCount: _filters.length,
          separatorBuilder: (_, __) => Spacing.h8,
          itemBuilder: (_, index) {
            final filter = _filters[index];
            final label = filter[0].toUpperCase() + filter.substring(1);
            return SuperAdminFilterPill(
              label: label,
              icon: _filterIcons[filter] ?? Icons.circle,
              isSelected: selected == filter,
              onTap: () => controller.changeAgencyFilter(filter),
            );
          },
        );
      }),
    );
  }

  Widget _agencyCard(
    BuildContext context,
    SuperAdminAgencyItem agency,
    bool processing,
  ) {
    final glow = agency.isPending
        ? SuperAdminUi.gold
        : agency.isSuspended
        ? SuperAdminUi.warning
        : SuperAdminUi.pink;
    final filter = controller.agencyStatusFilter.value.toLowerCase();
    // Status is already clear from the filter chip — skip duplicate pill.
    final showStatusPill =
        filter == 'all' || filter != agency.status.toLowerCase();
    final commissionPct =
        (agency.commissionRate * 100).toStringAsFixed(0);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: SuperAdminGlassCard(
        glow: glow,
        padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
        onTap: () => controller.openAgencyDetail(agency),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SuperAdminAvatarRing(
                  url: agency.ownerAvatar,
                  fallbackLetter: agency.name.isNotEmpty
                      ? agency.name
                      : agency.ownerName,
                  size: 52,
                  accent: glow,
                ),
                Spacing.h10,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: BoldText(
                              text: agency.name,
                              fontSize: TextStyles.k14FontSize,
                              color: SuperAdminUi.textPrimary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (showStatusPill) ...[
                            Spacing.h6,
                            SuperAdminStatusPill(status: agency.status),
                          ],
                        ],
                      ),
                      Spacing.v4,
                      AppText(
                        text: agency.ownerName.isEmpty
                            ? (agency.code.isEmpty ? '—' : agency.code)
                            : agency.code.isEmpty
                            ? agency.ownerName
                            : '${agency.ownerName} · ${agency.code}',
                        fontSize: TextStyles.k10FontSize,
                        color: SuperAdminUi.textSecondary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Spacing.h4,
                _manageButton(context, agency, processing),
              ],
            ),
            Spacing.v10,
            _metricStrip(
              hosts: agency.hostCount,
              pending: agency.pendingHostsCount,
              commissionPct: commissionPct,
              showCommission: agency.commissionRate > 0,
            ),
            if (agency.isPending) ...[
              Spacing.v10,
              Row(
                children: [
                  Expanded(
                    child: SuperAdminActionButton(
                      label: 'Reject',
                      icon: Icons.close_rounded,
                      background: SuperAdminUi.danger.withValues(alpha: 0.12),
                      borderColor: SuperAdminUi.danger.withValues(alpha: 0.35),
                      foreground: SuperAdminUi.danger,
                      onTap: processing
                          ? null
                          : () => _confirmReject(context, agency),
                    ),
                  ),
                  Spacing.h8,
                  Expanded(
                    child: SuperAdminActionButton(
                      label: processing ? 'Wait...' : 'Approve',
                      icon: Icons.check_rounded,
                      background: SuperAdminUi.success,
                      foreground: kColorWhite,
                      onTap: processing
                          ? null
                          : () => controller.approveAgency(agency),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Equal-width metric strip — clearer than a wrap of tiny chips.
  Widget _metricStrip({
    required int hosts,
    required int pending,
    required String commissionPct,
    required bool showCommission,
  }) {
    final cells = <({IconData icon, String value, String label, Color accent})>[
      (
        icon: Icons.groups_rounded,
        value: '$hosts',
        label: 'Hosts',
        accent: SuperAdminUi.sky,
      ),
      (
        icon: Icons.hourglass_top_rounded,
        value: '$pending',
        label: 'Pending',
        accent: SuperAdminUi.gold,
      ),
      if (showCommission)
        (
          icon: Icons.percent_rounded,
          value: '$commissionPct%',
          label: 'Rate',
          accent: SuperAdminUi.mint,
        ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: SuperAdminUi.pink.withValues(alpha: 0.04),
        border: Border.all(color: SuperAdminUi.pink.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 28,
                color: SuperAdminUi.textPrimary.withValues(alpha: 0.08),
              ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(cells[i].icon, size: 14, color: cells[i].accent),
                  Spacing.v4,
                  BoldText(
                    text: cells[i].value,
                    fontSize: TextStyles.k12FontSize,
                    color: SuperAdminUi.textPrimary,
                  ),
                  Spacing.v2,
                  AppText(
                    text: cells[i].label,
                    fontSize: TextStyles.k8FontSize,
                    color: SuperAdminUi.textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _manageButton(
    BuildContext context,
    SuperAdminAgencyItem agency,
    bool processing,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: processing ? null : () => _openManageSheet(context, agency),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: SuperAdminUi.textPrimary.withValues(alpha: 0.06),
          ),
          child: const Icon(
            Icons.more_horiz_rounded,
            size: 20,
            color: SuperAdminUi.textSecondary,
          ),
        ),
      ),
    );
  }

  void _openManageSheet(BuildContext context, SuperAdminAgencyItem agency) {
    Get.bottomSheet(
      SuperAdminSheetScaffold(
        title: agency.name,
        subtitle:
            'Code ${agency.code.isEmpty ? '—' : agency.code} • ${agency.status}',
        children: [
          if (agency.isPending)
            SuperAdminSheetAction(
              icon: Icons.check_circle_rounded,
              color: SuperAdminUi.mint,
              label: 'Approve agency',
              onTap: () {
                Get.back();
                controller.approveAgency(agency);
              },
            ),
          if (agency.isSuspended)
            SuperAdminSheetAction(
              icon: Icons.play_circle_fill_rounded,
              color: SuperAdminUi.mint,
              label: 'Reactivate agency',
              onTap: () {
                Get.back();
                controller.activateAgency(agency);
              },
            ),
          if (agency.isApproved)
            SuperAdminSheetAction(
              icon: Icons.pause_circle_filled_rounded,
              color: SuperAdminUi.warning,
              label: 'Suspend agency',
              onTap: () async {
                Get.back();
                final reason = await _askReason(
                  context,
                  title: 'Suspend agency?',
                  hint: 'Reason (optional)',
                  confirmLabel: 'Suspend',
                );
                if (reason == null) return;
                await controller.suspendAgency(agency, reason);
              },
            ),
          SuperAdminSheetAction(
            icon: Icons.percent_rounded,
            color: SuperAdminUi.sky,
            label: 'Edit commission rate',
            onTap: () async {
              Get.back();
              final rate = await _askCommission(context, agency);
              if (rate == null) return;
              await controller.updateAgencyCommission(agency, rate);
            },
          ),
          SuperAdminSheetAction(
            icon: Icons.delete_forever_rounded,
            color: SuperAdminUi.danger,
            label: 'Delete agency',
            onTap: () async {
              Get.back();
              final reason = await _askReason(
                context,
                title: 'Delete agency?',
                subtitle:
                    'The agency is rejected and removed from active lists.',
                hint: 'Reason (optional)',
                confirmLabel: 'Delete',
              );
              if (reason == null) return;
              await controller.deleteAgency(agency, reason);
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
      builder: (dialogContext) => _SuperAdminGlassDialog(
        title: title,
        subtitle: subtitle,
        confirmLabel: confirmLabel,
        confirmColor: SuperAdminUi.danger,
        onCancel: () => Navigator.of(dialogContext).pop(false),
        onConfirm: () => Navigator.of(dialogContext).pop(true),
        child: TextField(
          controller: reasonController,
          style: const TextStyle(color: SuperAdminUi.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: SuperAdminUi.textFaint),
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
      ),
    );
    final reason = reasonController.text.trim();
    reasonController.dispose();
    return confirmed == true ? reason : null;
  }

  Future<double?> _askCommission(
    BuildContext context,
    SuperAdminAgencyItem agency,
  ) async {
    final rateController = TextEditingController(
      text: (agency.commissionRate * 100).toStringAsFixed(1),
    );
    final rate = await showDialog<double>(
      context: context,
      builder: (dialogContext) => _SuperAdminGlassDialog(
        title: 'Commission rate',
        confirmLabel: 'Save',
        confirmColor: SuperAdminUi.sky,
        onCancel: () => Navigator.of(dialogContext).pop(),
        onConfirm: () {
          final percent = double.tryParse(rateController.text.trim());
          if (percent == null || percent < 0 || percent > 100) return;
          Navigator.of(dialogContext).pop(percent / 100);
        },
        child: TextField(
          controller: rateController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: SuperAdminUi.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. 12.5',
            hintStyle: const TextStyle(color: SuperAdminUi.textFaint),
            suffixText: '%',
            suffixStyle: const TextStyle(color: SuperAdminUi.textSecondary),
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
        ),
      ),
    );
    rateController.dispose();
    return rate;
  }

  Future<void> _confirmReject(
    BuildContext context,
    SuperAdminAgencyItem agency,
  ) async {
    final feedbackController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _SuperAdminGlassDialog(
        title: 'Reject agency?',
        confirmLabel: 'Reject',
        confirmColor: SuperAdminUi.danger,
        onCancel: () => Navigator.of(dialogContext).pop(false),
        onConfirm: () => Navigator.of(dialogContext).pop(true),
        child: TextField(
          controller: feedbackController,
          style: const TextStyle(color: SuperAdminUi.textPrimary),
          decoration: InputDecoration(
            hintText: 'Optional feedback',
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
      ),
    );
    if (confirmed == true) {
      await controller.rejectAgency(agency, feedbackController.text.trim());
    }
    feedbackController.dispose();
  }
}

/// Dark glass confirm dialog matching Super Admin chrome.
class _SuperAdminGlassDialog extends StatelessWidget {
  const _SuperAdminGlassDialog({
    required this.title,
    this.subtitle,
    required this.child,
    required this.confirmLabel,
    required this.confirmColor,
    required this.onCancel,
    required this.onConfirm,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final String confirmLabel;
  final Color confirmColor;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              Spacing.v8,
              AppText(
                text: subtitle!,
                fontSize: TextStyles.k12FontSize,
                color: SuperAdminUi.textMuted,
              ),
            ],
            Spacing.v12,
            child,
            Spacing.v16,
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      onPressed: onCancel,
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
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor,
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
    );
  }
}
