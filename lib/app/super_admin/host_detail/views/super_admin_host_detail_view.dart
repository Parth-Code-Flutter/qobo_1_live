import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/super_admin/host_detail/controllers/super_admin_host_detail_controller.dart';
import 'package:qobo_one_live/app/super_admin/models/super_admin_models.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_glass_card.dart';
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
          iconTheme: const IconThemeData(color: kColorWhite),
          title: const SemiBoldText(
            text: 'Host Detail',
            fontSize: TextStyles.k16FontSize,
            color: kColorWhite,
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

  Widget _headerCard(SuperAdminHostDetail detail) {
    return SuperAdminGlassCard(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SemiBoldText(
            text: 'Profile',
            fontSize: TextStyles.k14FontSize,
            color: kColorWhite,
          ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SemiBoldText(
            text: 'Earnings',
            fontSize: TextStyles.k14FontSize,
            color: kColorWhite,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SemiBoldText(
            text: 'Agency',
            fontSize: TextStyles.k14FontSize,
            color: kColorWhite,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SemiBoldText(
            text: 'Documents',
            fontSize: TextStyles.k14FontSize,
            color: kColorWhite,
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
      return SuperAdminGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SemiBoldText(
              text: 'Moderation',
              fontSize: TextStyles.k14FontSize,
              color: kColorWhite,
            ),
            Spacing.v12,
            if (detail.isActive)
              _btn(
                label: 'Suspend host',
                color: const Color(0xFFFFB74D).withValues(alpha: 0.18),
                fg: const Color(0xFFFFB74D),
                onTap: busy
                    ? null
                    : () async {
                        final reason = await _askReason(context);
                        if (reason == null) return;
                        await controller.setStatus('suspended', reason: reason);
                      },
              ),
            if (detail.isSuspended || detail.status.toLowerCase() == 'inactive')
              _btn(
                label: 'Reactivate host',
                color: const Color(0xFF2E9E5B),
                fg: kColorWhite,
                onTap: busy ? null : () => controller.setStatus('active'),
              ),
          ],
        ),
      );
    });
  }

  Widget _btn({
    required String label,
    required Color color,
    required Color fg,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: SemiBoldText(
              text: label,
              fontSize: TextStyles.k12FontSize,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _askReason(BuildContext context) async {
    final textController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kColorWhite,
        title: const Text('Suspend host?'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(hintText: 'Reason'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Suspend'),
          ),
        ],
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
