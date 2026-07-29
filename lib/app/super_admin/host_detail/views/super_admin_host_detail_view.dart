import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/super_admin/host_detail/controllers/super_admin_host_detail_controller.dart';
import 'package:qobo_one_live/app/super_admin/models/super_admin_models.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_ui.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_ui_kit.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/safe_network_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Host detail screen — P0 `GET /api/super-admin/hosts/:hostId`.
class SuperAdminHostDetailView extends GetView<SuperAdminHostDetailController> {
  const SuperAdminHostDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage(kImgBG), fit: BoxFit.cover),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: kColorWhite),
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
                color: kColorWhite,
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _headerCard(detail),
                Spacing.v12,
                _profileCard(detail),
                Spacing.v12,
                _earningsCard(detail),
                Spacing.v12,
                _agencyCard(detail),
                Spacing.v12,
                _docsCard(detail),
                Spacing.v12,
                _actionsCard(context, detail),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon, Color accent) {
    return Row(
      children: [
        SuperAdminUi.glowIcon(
          icon: icon,
          accent: accent,
          size: 28,
          iconSize: 14,
        ),
        Spacing.h8,
        SemiBoldText(
          text: title,
          fontSize: TextStyles.k14FontSize,
          color: kColorWhite,
        ),
      ],
    );
  }

  Widget _headerCard(SuperAdminHostDetail detail) {
    return SuperAdminGlassCard(
      glow: SuperAdminUi.teal,
      child: Row(
        children: [
          SafeNetworkAvatar(
            url: detail.displayPicture,
            size: 56,
            fallback: CircleAvatar(
              radius: 28,
              backgroundColor: kColorPrimary,
              child: Text(
                detail.name.isNotEmpty ? detail.name.characters.first : 'H',
              ),
            ),
          ),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: detail.name,
                  fontSize: TextStyles.k16FontSize,
                  color: kColorWhite,
                ),
                Spacing.v4,
                AppText(
                  text: detail.category.isEmpty ? 'Host' : detail.category,
                  fontSize: TextStyles.k12FontSize,
                  color: Colors.white70,
                ),
                Spacing.v6,
                Row(
                  children: [
                    SuperAdminStatusPill(status: detail.status),
                    if (detail.recentActivity.isLiveNow) ...[
                      Spacing.h8,
                      const SuperAdminStatusPill(status: 'LIVE'),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileCard(SuperAdminHostDetail detail) {
    final location = [
      detail.city,
      detail.state,
      detail.country,
    ].where((e) => e.isNotEmpty).join(', ');
    return SuperAdminGlassCard(
      glow: SuperAdminUi.sky,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Profile', Icons.badge_rounded, SuperAdminUi.sky),
          Spacing.v12,
          SuperAdminInfoRow(label: 'Email', value: detail.email),
          SuperAdminInfoRow(
            label: 'Phone',
            value: [
              detail.countryCode,
              detail.phone,
            ].where((e) => e.isNotEmpty).join(' '),
          ),
          SuperAdminInfoRow(label: 'Gender', value: detail.gender),
          SuperAdminInfoRow(label: 'DOB', value: detail.dob),
          SuperAdminInfoRow(label: 'Location', value: location),
          SuperAdminInfoRow(label: 'Address', value: detail.address),
          SuperAdminInfoRow(label: 'Joined', value: detail.joinedAt),
          SuperAdminInfoRow(
            label: 'Sessions',
            value: '${detail.recentActivity.totalSessions}',
          ),
          SuperAdminInfoRow(
            label: 'Last live',
            value: detail.recentActivity.lastLiveAt,
          ),
        ],
      ),
    );
  }

  Widget _earningsCard(SuperAdminHostDetail detail) {
    final e = detail.earnings;
    return SuperAdminGlassCard(
      glow: SuperAdminUi.gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Earnings',
            Icons.payments_rounded,
            SuperAdminUi.gold,
          ),
          Spacing.v12,
          SuperAdminInfoRow(
            label: 'Diamonds',
            value: e.diamonds.toStringAsFixed(0),
          ),
          SuperAdminInfoRow(label: 'Coins', value: e.coins.toStringAsFixed(0)),
          SuperAdminInfoRow(
            label: 'Commission',
            value: e.totalCommissionEarned.toStringAsFixed(2),
          ),
          SuperAdminInfoRow(
            label: 'Stream time',
            value: _formatSeconds(e.totalStreamSeconds),
          ),
          SuperAdminInfoRow(
            label: 'Coins/sec',
            value: e.coinsPerSecond.toStringAsFixed(1),
          ),
        ],
      ),
    );
  }

  Widget _agencyCard(SuperAdminHostDetail detail) {
    final agency = detail.agency;
    return SuperAdminGlassCard(
      glow: SuperAdminUi.violet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Agency',
            Icons.business_rounded,
            SuperAdminUi.violet,
          ),
          Spacing.v12,
          SuperAdminInfoRow(label: 'Name', value: agency.name),
          SuperAdminInfoRow(label: 'Code', value: agency.code),
          SuperAdminInfoRow(label: 'Status', value: agency.status),
        ],
      ),
    );
  }

  Widget _docsCard(SuperAdminHostDetail detail) {
    return SuperAdminGlassCard(
      glow: SuperAdminUi.pink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Documents',
            Icons.folder_rounded,
            SuperAdminUi.pink,
          ),
          Spacing.v12,
          if (detail.documents.idNo.isNotEmpty)
            SuperAdminInfoRow(label: 'ID No', value: detail.documents.idNo),
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
        glow: SuperAdminUi.warning,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(
              'Moderation',
              Icons.shield_rounded,
              SuperAdminUi.warning,
            ),
            Spacing.v12,
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
            border: Border.all(color: kColorWhite.withValues(alpha: 0.14)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SemiBoldText(
                text: 'Suspend host?',
                fontSize: TextStyles.k16FontSize,
                color: kColorWhite,
              ),
              Spacing.v12,
              TextField(
                controller: textController,
                style: const TextStyle(color: kColorWhite),
                decoration: InputDecoration(
                  hintText: 'Reason',
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
