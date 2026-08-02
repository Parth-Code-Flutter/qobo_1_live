import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/super_admin/agency_detail/controllers/super_admin_agency_detail_controller.dart';
import 'package:qobo_one_live/app/super_admin/models/super_admin_models.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_detail_chrome.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_ui.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_ui_kit.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Agency detail screen — P0 `GET /api/super-admin/agencies/:agencyId`.
class SuperAdminAgencyDetailView
    extends GetView<SuperAdminAgencyDetailController> {
  const SuperAdminAgencyDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return SuperAdminDetailBackdrop(
      primary: SuperAdminUi.pink,
      secondary: SuperAdminUi.violet,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: SuperAdminUi.textPrimary),
          title: Row(
            children: [
              SuperAdminUi.glowIcon(
                icon: Icons.business_rounded,
                accent: SuperAdminUi.pink,
                size: 34,
                iconSize: 18,
              ),
              Spacing.h10,
              const SemiBoldText(
                text: 'Agency Detail',
                fontSize: TextStyles.k16FontSize,
                color: SuperAdminUi.textPrimary,
              ),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value && controller.detail.value == null) {
            return const Center(
              child: CircularProgressIndicator(color: kColorPrimary),
            );
          }
          final detail = controller.detail.value;
          if (detail == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SuperAdminEmptyState(
                  icon: Icons.business_outlined,
                  title: 'Agency not found',
                  subtitle: controller.error.value.isEmpty
                      ? 'Pull to retry'
                      : controller.error.value,
                ),
              ),
            );
          }
          return RefreshIndicator(
            color: kColorPrimary,
            onRefresh: () => controller.loadAll(showLoader: false),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: SuperAdminUi.detailInsets,
              children: [
                _headerCard(detail),
                Spacing.v10,
                _openOwnerDashboardButton(),
                Spacing.v(SuperAdminUi.sectionGap),
                _ownerCard(detail),
                Spacing.v(SuperAdminUi.sectionGap),
                _statsCard(detail),
                Spacing.v(SuperAdminUi.sectionGap),
                _docsCard(detail),
                Spacing.v(SuperAdminUi.sectionGap),
                _actionsCard(context, detail),
                Spacing.v(SuperAdminUi.sectionGap),
                _hostsSection(),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _openOwnerDashboardButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: controller.openOwnerDashboard,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                SuperAdminUi.pink.withValues(alpha: 0.28),
                SuperAdminUi.violet.withValues(alpha: 0.22),
              ],
            ),
            border: Border.all(
              color: SuperAdminUi.pink.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.dashboard_customize_rounded, color: SuperAdminUi.pink),
              Spacing.h10,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SemiBoldText(
                      text: 'Open agency dashboard',
                      fontSize: TextStyles.k14FontSize,
                      color: SuperAdminUi.textPrimary,
                    ),
                    Spacing.v2,
                    AppText(
                      text:
                          'Owner metrics via /api/agency/dashboard?agency_id=',
                      fontSize: TextStyles.k10FontSize,
                      color: SuperAdminUi.textSecondary,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: SuperAdminUi.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCard(SuperAdminAgencyDetail detail) {
    final imageUrl = detail.logo.isNotEmpty
        ? detail.logo
        : detail.owner.displayPicture;
    return SuperAdminGlassCard(
      blur: false,
      glow: SuperAdminUi.pink,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          SuperAdminAvatarRing(
            url: imageUrl,
            fallbackLetter: detail.name,
            size: 88,
            accent: SuperAdminUi.pink,
          ),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BoldText(
                  text: detail.name,
                  fontSize: TextStyles.k18FontSize,
                  color: SuperAdminUi.textPrimary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Spacing.v8,
                SuperAdminStatusPill(status: detail.status),
                Spacing.v8,
                SuperAdminMetricChip(
                  icon: Icons.qr_code_2_rounded,
                  label: detail.code.isEmpty ? 'No code' : detail.code,
                  accent: SuperAdminUi.violet,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ownerCard(SuperAdminAgencyDetail detail) {
    final phone = SuperAdminDetailFormat.phone(
      detail.owner.countryCode,
      detail.owner.phone,
    );
    final hasFeedback = detail.feedback.trim().isNotEmpty;
    final hasInvited = detail.invitedBy.name.trim().isNotEmpty;
    return SuperAdminGlassCard(
      blur: false,
      glow: SuperAdminUi.sky,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SuperAdminCleanSectionHeader(
            icon: Icons.person_rounded,
            title: 'Owner & address',
            accent: SuperAdminUi.sky,
          ),
          Spacing.v8,
          SuperAdminCleanInfoRow(
            icon: Icons.badge_rounded,
            label: 'Owner',
            value: detail.owner.name,
            accent: SuperAdminUi.sky,
          ),
          SuperAdminCleanInfoRow(
            icon: Icons.mail_rounded,
            label: 'Email',
            value: detail.owner.email,
            accent: SuperAdminUi.pink,
          ),
          SuperAdminCleanInfoRow(
            icon: Icons.phone_rounded,
            label: 'Phone',
            value: phone,
            accent: SuperAdminUi.mint,
          ),
          SuperAdminCleanInfoRow(
            icon: Icons.location_on_rounded,
            label: 'Address',
            value: detail.address.line,
            accent: SuperAdminUi.gold,
          ),
          SuperAdminCleanInfoRow(
            icon: Icons.percent_rounded,
            label: 'Commission %',
            value: '${(detail.commissionRate * 100).toStringAsFixed(1)}%',
            accent: SuperAdminUi.violet,
            showDivider: hasFeedback || hasInvited,
          ),
          if (hasFeedback)
            SuperAdminCleanInfoRow(
              icon: Icons.chat_bubble_rounded,
              label: 'Feedback',
              value: detail.feedback,
              accent: SuperAdminUi.warning,
              showDivider: hasInvited,
            ),
          if (hasInvited)
            SuperAdminCleanInfoRow(
              icon: Icons.workspace_premium_rounded,
              label: 'Invited by',
              value: detail.invitedBy.name,
              accent: SuperAdminUi.gold,
              showDivider: false,
            ),
        ],
      ),
    );
  }

  Widget _statsCard(SuperAdminAgencyDetail detail) {
    final s = detail.stats;
    return SuperAdminGlassCard(
      blur: false,
      glow: SuperAdminUi.mint,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SuperAdminCleanSectionHeader(
            icon: Icons.insights_rounded,
            title: 'Stats',
            accent: SuperAdminUi.mint,
          ),
          Spacing.v(14),
          Row(
            children: [
              Expanded(
                child: SuperAdminStatTile(
                  icon: Icons.groups_rounded,
                  label: 'Hosts',
                  value: '${s.hostCount}',
                  accent: SuperAdminUi.sky,
                ),
              ),
              Spacing.h10,
              Expanded(
                child: SuperAdminStatTile(
                  icon: Icons.verified_rounded,
                  label: 'Active',
                  value: '${s.activeHostsCount}',
                  accent: SuperAdminUi.mint,
                ),
              ),
            ],
          ),
          Spacing.v10,
          Row(
            children: [
              Expanded(
                child: SuperAdminStatTile(
                  icon: Icons.hourglass_top_rounded,
                  label: 'Pending',
                  value: '${s.pendingHostsCount}',
                  accent: SuperAdminUi.gold,
                ),
              ),
              Spacing.h10,
              Expanded(
                child: SuperAdminStatTile(
                  icon: Icons.payments_rounded,
                  label: 'Commission',
                  value: s.totalCommissionEarned.toStringAsFixed(1),
                  accent: SuperAdminUi.pink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _docsCard(SuperAdminAgencyDetail detail) {
    return SuperAdminGlassCard(
      blur: false,
      glow: SuperAdminUi.pink,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SuperAdminCleanSectionHeader(
            icon: Icons.folder_rounded,
            title: 'Documents',
            accent: SuperAdminUi.pink,
          ),
          Spacing.v(14),
          Row(
            children: [
              SuperAdminDocThumb(
                label: 'Front',
                url: detail.documents.docPhotoFront,
              ),
              Spacing.h10,
              SuperAdminDocThumb(
                label: 'Back',
                url: detail.documents.docPhotoBack,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionsCard(BuildContext context, SuperAdminAgencyDetail detail) {
    return Obx(() {
      final busy = controller.isProcessing.value;
      final hasActions =
          detail.isPending || detail.isApproved || detail.isSuspended;
      if (!hasActions) return const SizedBox.shrink();

      return SuperAdminGlassCard(
        blur: false,
        glow: SuperAdminUi.gold,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SuperAdminCleanSectionHeader(
              icon: Icons.bolt_rounded,
              title: 'Actions',
              accent: SuperAdminUi.gold,
            ),
            Spacing.v(14),
            if (detail.isPending)
              Row(
                children: [
                  Expanded(
                    child: SuperAdminActionButton(
                      label: 'Reject',
                      icon: Icons.close_rounded,
                      background: SuperAdminUi.danger.withValues(alpha: 0.16),
                      borderColor: SuperAdminUi.danger.withValues(alpha: 0.4),
                      foreground: SuperAdminUi.danger,
                      onTap: busy
                          ? null
                          : () async {
                              final feedback = await _askText(
                                context,
                                title: 'Reject agency?',
                                hint: 'Optional feedback',
                              );
                              if (feedback == null) return;
                              await controller.reject(feedback);
                            },
                    ),
                  ),
                  Spacing.h10,
                  Expanded(
                    child: SuperAdminActionButton(
                      label: 'Approve',
                      icon: Icons.check_rounded,
                      background: SuperAdminUi.success,
                      foreground: kColorWhite,
                      onTap: busy ? null : controller.approve,
                    ),
                  ),
                ],
              ),
            if (detail.isApproved)
              Row(
                children: [
                  Expanded(
                    child: SuperAdminActionButton(
                      label: 'Suspend',
                      icon: Icons.pause_circle_filled_rounded,
                      background: SuperAdminUi.warning.withValues(alpha: 0.18),
                      borderColor: SuperAdminUi.warning.withValues(alpha: 0.45),
                      foreground: SuperAdminUi.warning,
                      onTap: busy
                          ? null
                          : () async {
                              final reason = await _askText(
                                context,
                                title: 'Suspend agency?',
                                hint: 'Reason',
                              );
                              if (reason == null) return;
                              await controller.suspend(reason);
                            },
                    ),
                  ),
                  Spacing.h10,
                  Expanded(
                    child: SuperAdminActionButton(
                      label: 'Edit %',
                      icon: Icons.percent_rounded,
                      background: SuperAdminUi.sky.withValues(alpha: 0.28),
                      borderColor: SuperAdminUi.sky.withValues(alpha: 0.45),
                      foreground: kColorWhite,
                      onTap: busy
                          ? null
                          : () async {
                              final rate = await _askCommission(
                                context,
                                detail.commissionRate,
                              );
                              if (rate == null) return;
                              await controller.updateCommission(rate);
                            },
                    ),
                  ),
                ],
              ),
            if (detail.isSuspended)
              SuperAdminActionButton(
                label: 'Reactivate',
                icon: Icons.play_circle_fill_rounded,
                background: SuperAdminUi.success,
                foreground: kColorWhite,
                onTap: busy ? null : controller.reactivate,
              ),
          ],
        ),
      );
    });
  }

  Widget _hostsSection() {
    return Obx(() {
      final items = controller.hosts;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SuperAdminCleanSectionHeader(
            icon: Icons.mic_rounded,
            title: 'Hosts in this agency',
            accent: SuperAdminUi.teal,
          ),
          Spacing.v12,
          if (controller.isLoadingHosts.value && items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: kColorPrimary),
              ),
            )
          else if (items.isEmpty)
            const SuperAdminEmptyState(
              icon: Icons.mic_none_rounded,
              title: 'No hosts yet',
              subtitle: 'Hosts under this agency will appear here',
            )
          else
            ...items.map((host) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SuperAdminGlassCard(
                  blur: false,
                  glow: SuperAdminUi.teal,
                  radius: 16,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  onTap: () => controller.openHostDetail(host),
                  child: Row(
                    children: [
                      SuperAdminAvatarRing(
                        url: host.avatarUrl,
                        fallbackLetter: host.name,
                        size: 46,
                        accent: SuperAdminUi.teal,
                      ),
                      Spacing.h10,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SemiBoldText(
                              text: host.name,
                              fontSize: TextStyles.k14FontSize,
                              color: SuperAdminUi.textPrimary,
                            ),
                            Spacing.v4,
                            SuperAdminStatusPill(status: host.status),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: SuperAdminUi.textMuted,
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      );
    });
  }

  Future<String?> _askText(
    BuildContext context, {
    required String title,
    required String hint,
  }) async {
    final textController = TextEditingController();
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
            border: Border.all(color: SuperAdminUi.textPrimary.withValues(alpha: 0.14)),
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
              Spacing.v12,
              TextField(
                controller: textController,
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
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: SuperAdminUi.textSecondary,
                          side: BorderSide(
                            color: SuperAdminUi.textPrimary.withValues(alpha: 0.22),
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
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SuperAdminUi.violet,
                          foregroundColor: kColorWhite,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const SemiBoldText(
                          text: 'Confirm',
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
    final value = textController.text.trim();
    textController.dispose();
    if (confirmed != true) return null;
    return value;
  }

  Future<double?> _askCommission(BuildContext context, double current) async {
    final textController = TextEditingController(
      text: (current * 100).toStringAsFixed(1),
    );
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
            border: Border.all(color: SuperAdminUi.textPrimary.withValues(alpha: 0.14)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SemiBoldText(
                text: 'Commission %',
                fontSize: TextStyles.k16FontSize,
                color: SuperAdminUi.textPrimary,
              ),
              Spacing.v12,
              TextField(
                controller: textController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: SuperAdminUi.textPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g. 10',
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
                          foregroundColor: SuperAdminUi.textSecondary,
                          side: BorderSide(
                            color: SuperAdminUi.textPrimary.withValues(alpha: 0.22),
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
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SuperAdminUi.sky,
                          foregroundColor: kColorWhite,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const SemiBoldText(
                          text: 'Save',
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
    final raw = double.tryParse(textController.text.trim());
    textController.dispose();
    if (confirmed != true || raw == null) return null;
    // Accept either 0.12 or 12 (percent).
    return raw > 1 ? raw / 100 : raw;
  }
}
