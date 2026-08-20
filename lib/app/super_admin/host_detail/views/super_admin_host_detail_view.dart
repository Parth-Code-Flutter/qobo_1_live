import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/super_admin/host_detail/controllers/super_admin_host_detail_controller.dart';
import 'package:qobo_one_live/app/super_admin/models/super_admin_models.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_detail_chrome.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_ui.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_ui_kit.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Host detail screen — P0 `GET /api/super-admin/hosts/:hostId`.
class SuperAdminHostDetailView extends GetView<SuperAdminHostDetailController> {
  const SuperAdminHostDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return SuperAdminDetailBackdrop(
      primary: SuperAdminUi.teal,
      secondary: SuperAdminUi.sky,
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
                icon: Icons.mic_rounded,
                accent: SuperAdminUi.teal,
                size: 34,
                iconSize: 18,
              ),
              Spacing.h10,
              const SemiBoldText(
                text: 'Host Detail',
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
                  icon: Icons.mic_none_rounded,
                  title: 'Host not found',
                  subtitle: controller.error.value.isEmpty
                      ? 'Pull to retry'
                      : controller.error.value,
                ),
              ),
            );
          }
          return RefreshIndicator(
            color: kColorPrimary,
            onRefresh: () => controller.loadDetail(showLoader: false),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: SuperAdminUi.detailInsets,
              children: [
                _headerCard(detail),
                Spacing.v(SuperAdminUi.sectionGap),
                _profileCard(detail),
                Spacing.v(SuperAdminUi.sectionGap),
                _earningsCard(detail),
                Spacing.v(SuperAdminUi.sectionGap),
                _agencyCard(detail),
                Spacing.v(SuperAdminUi.sectionGap),
                _docsCard(detail),
                Spacing.v(SuperAdminUi.sectionGap),
                _actionsCard(context, detail),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _headerCard(SuperAdminHostDetail detail) {
    return SuperAdminGlassCard(
      blur: false,
      glow: SuperAdminUi.teal,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          SuperAdminAvatarRing(
            url: detail.displayPicture,
            fallbackLetter: detail.name,
            size: 88,
            accent: SuperAdminUi.teal,
            live: detail.recentActivity.isLiveNow,
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
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    SuperAdminStatusPill(status: detail.status),
                    if (detail.recentActivity.isLiveNow)
                      const SuperAdminStatusPill(status: 'LIVE'),
                  ],
                ),
                Spacing.v8,
                SuperAdminMetricChip(
                  icon: Icons.category_rounded,
                  label:
                      detail.category.isEmpty ? 'Host talent' : detail.category,
                  accent: SuperAdminUi.sky,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileCard(SuperAdminHostDetail detail) {
    final location = SuperAdminDetailFormat.location([
      detail.city,
      detail.state,
      detail.country,
    ]);
    final phone = SuperAdminDetailFormat.phone(
      detail.countryCode,
      detail.phone,
    );
    final dob = detail.dob.trim();
    final joined = detail.joinedAt.trim();
    final lastLive = detail.recentActivity.lastLiveAt.trim();
    return SuperAdminGlassCard(
      blur: false,
      glow: SuperAdminUi.sky,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SuperAdminCleanSectionHeader(
            icon: Icons.badge_rounded,
            title: 'Profile',
            accent: SuperAdminUi.sky,
          ),
          Spacing.v8,
          SuperAdminCleanInfoRow(
            icon: Icons.mail_rounded,
            label: 'Email',
            value: detail.email,
            accent: SuperAdminUi.pink,
          ),
          SuperAdminCleanInfoRow(
            icon: Icons.phone_rounded,
            label: 'Phone',
            value: phone,
            accent: SuperAdminUi.mint,
          ),
          SuperAdminCleanInfoRow(
            icon: Icons.wc_rounded,
            label: 'Gender',
            value: detail.gender,
            accent: SuperAdminUi.violet,
          ),
          SuperAdminCleanInfoRow(
            icon: Icons.cake_rounded,
            label: 'DOB',
            value: dob.isEmpty ? '' : SuperAdminDetailFormat.date(dob),
            accent: SuperAdminUi.gold,
          ),
          SuperAdminCleanInfoRow(
            icon: Icons.location_on_rounded,
            label: 'Location',
            value: location,
            accent: SuperAdminUi.sky,
          ),
          SuperAdminCleanInfoRow(
            icon: Icons.home_rounded,
            label: 'Address',
            value: detail.address,
            accent: SuperAdminUi.warning,
          ),
          SuperAdminCleanInfoRow(
            icon: Icons.event_available_rounded,
            label: 'Joined',
            value: joined.isEmpty
                ? ''
                : SuperAdminDetailFormat.date(joined, withTime: true),
            accent: SuperAdminUi.teal,
          ),
          SuperAdminCleanInfoRow(
            icon: Icons.videocam_rounded,
            label: 'Sessions',
            value: '${detail.recentActivity.totalSessions}',
            accent: SuperAdminUi.rose,
            showDivider: lastLive.isNotEmpty,
          ),
          SuperAdminCleanInfoRow(
            icon: Icons.history_rounded,
            label: 'Last live',
            value: lastLive.isEmpty
                ? ''
                : SuperAdminDetailFormat.date(lastLive, withTime: true),
            accent: SuperAdminUi.gold,
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _earningsCard(SuperAdminHostDetail detail) {
    final e = detail.earnings;
    return SuperAdminGlassCard(
      blur: false,
      glow: SuperAdminUi.gold,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SuperAdminCleanSectionHeader(
            icon: Icons.payments_rounded,
            title: 'Earnings',
            accent: SuperAdminUi.gold,
          ),
          Spacing.v(14),
          Row(
            children: [
              Expanded(
                child: SuperAdminStatTile(
                  icon: Icons.diamond_rounded,
                  label: 'Diamonds',
                  value: e.diamonds.toStringAsFixed(0),
                  accent: SuperAdminUi.sky,
                ),
              ),
              Spacing.h10,
              Expanded(
                child: SuperAdminStatTile(
                  coinIcon: true,
                  label: 'Coins',
                  value: e.coins.toStringAsFixed(0),
                  accent: SuperAdminUi.gold,
                ),
              ),
            ],
          ),
          Spacing.v10,
          Row(
            children: [
              Expanded(
                child: SuperAdminStatTile(
                  icon: Icons.payments_rounded,
                  label: 'Commission',
                  value: e.totalCommissionEarned.toStringAsFixed(1),
                  accent: SuperAdminUi.pink,
                ),
              ),
              Spacing.h10,
              Expanded(
                child: SuperAdminStatTile(
                  icon: Icons.timer_outlined,
                  label: 'Stream time',
                  value: _formatSeconds(e.totalStreamSeconds),
                  accent: SuperAdminUi.mint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _agencyCard(SuperAdminHostDetail detail) {
    final agency = detail.agency;
    return SuperAdminGlassCard(
      blur: false,
      glow: SuperAdminUi.violet,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SuperAdminCleanSectionHeader(
            icon: Icons.business_rounded,
            title: 'Agency',
            accent: SuperAdminUi.violet,
          ),
          Spacing.v8,
          SuperAdminCleanInfoRow(
            icon: Icons.apartment_rounded,
            label: 'Name',
            value: agency.name,
            accent: SuperAdminUi.violet,
          ),
          SuperAdminCleanInfoRow(
            icon: Icons.qr_code_2_rounded,
            label: 'Code',
            value: agency.code,
            accent: SuperAdminUi.sky,
          ),
          SuperAdminCleanInfoRow(
            icon: Icons.flag_rounded,
            label: 'Status',
            value: agency.status,
            accent: SuperAdminUi.mint,
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _docsCard(SuperAdminHostDetail detail) {
    final idNo = detail.documents.idNo.trim();
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
          Spacing.v8,
          if (idNo.isNotEmpty)
            SuperAdminCleanInfoRow(
              icon: Icons.badge_rounded,
              label: 'ID No',
              value: idNo,
              accent: SuperAdminUi.sky,
              showDivider: false,
            ),
          if (idNo.isNotEmpty) Spacing.v8,
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

  Widget _actionsCard(BuildContext context, SuperAdminHostDetail detail) {
    return Obx(() {
      final busy = controller.isProcessing.value;
      final showSuspend = detail.isActive;
      final showReactivate =
          detail.isSuspended || detail.status.toLowerCase() == 'inactive';
      if (!showSuspend && !showReactivate) return const SizedBox.shrink();

      return SuperAdminGlassCard(
        blur: false,
        glow: SuperAdminUi.warning,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SuperAdminCleanSectionHeader(
              icon: Icons.shield_rounded,
              title: 'Moderation',
              accent: SuperAdminUi.warning,
            ),
            Spacing.v(14),
            if (showSuspend)
              SuperAdminActionButton(
                label: 'Suspend host',
                icon: Icons.pause_circle_filled_rounded,
                background: SuperAdminUi.warning.withValues(alpha: 0.18),
                borderColor: SuperAdminUi.warning.withValues(alpha: 0.45),
                foreground: SuperAdminUi.warning,
                onTap: busy
                    ? null
                    : () async {
                        final reason = await _askReason(context);
                        if (reason == null) return;
                        await controller.setStatus('suspended', reason: reason);
                      },
              ),
            if (showReactivate) ...[
              if (showSuspend) Spacing.v10,
              SuperAdminActionButton(
                label: 'Reactivate host',
                icon: Icons.play_circle_fill_rounded,
                background: SuperAdminUi.success,
                foreground: kColorWhite,
                onTap: busy ? null : () => controller.setStatus('active'),
              ),
            ],
          ],
        ),
      );
    });
  }

  Future<String?> _askReason(BuildContext context) async {
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
              const SemiBoldText(
                text: 'Suspend host?',
                fontSize: TextStyles.k16FontSize,
                color: SuperAdminUi.textPrimary,
              ),
              Spacing.v12,
              TextField(
                controller: textController,
                style: const TextStyle(color: SuperAdminUi.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Reason',
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
                          backgroundColor: SuperAdminUi.warning,
                          foregroundColor: kColorWhite,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const SemiBoldText(
                          text: 'Suspend',
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

  String _formatSeconds(double seconds) {
    if (seconds <= 0) return '0h';
    final hours = seconds / 3600;
    if (hours >= 1) return '${hours.toStringAsFixed(1)}h';
    return '${(seconds / 60).toStringAsFixed(0)}m';
  }
}
