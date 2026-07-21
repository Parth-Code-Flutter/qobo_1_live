import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/super_admin/agency_detail/controllers/super_admin_agency_detail_controller.dart';
import 'package:qobo_one_live/app/super_admin/models/super_admin_models.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_glass_card.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_ui_kit.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/safe_network_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Agency detail screen — P0 `GET /api/super-admin/agencies/:agencyId`.
class SuperAdminAgencyDetailView
    extends GetView<SuperAdminAgencyDetailController> {
  const SuperAdminAgencyDetailView({super.key});

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
            text: 'Agency Detail',
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _headerCard(detail),
                Spacing.v12,
                _ownerCard(detail),
                Spacing.v12,
                _statsCard(detail),
                Spacing.v12,
                _docsCard(detail),
                Spacing.v12,
                _actionsCard(context, detail),
                Spacing.v16,
                _hostsSection(),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _headerCard(SuperAdminAgencyDetail detail) {
    return SuperAdminGlassCard(
      child: Row(
        children: [
          SafeNetworkAvatar(
            url: detail.logo.isNotEmpty
                ? detail.logo
                : detail.owner.displayPicture,
            size: 56,
            fallback: CircleAvatar(
              radius: 28,
              backgroundColor: kColorPrimary,
              child: Text(
                detail.name.isNotEmpty ? detail.name.characters.first : 'A',
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
                  text: 'Code ${detail.code}',
                  fontSize: TextStyles.k12FontSize,
                  color: Colors.white70,
                ),
                Spacing.v6,
                SuperAdminStatusPill(status: detail.status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ownerCard(SuperAdminAgencyDetail detail) {
    return SuperAdminGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SemiBoldText(
            text: 'Owner & address',
            fontSize: TextStyles.k14FontSize,
            color: kColorWhite,
          ),
          Spacing.v12,
          SuperAdminInfoRow(label: 'Owner', value: detail.owner.name),
          SuperAdminInfoRow(label: 'Email', value: detail.owner.email),
          SuperAdminInfoRow(
            label: 'Phone',
            value: [
              detail.owner.countryCode,
              detail.owner.phone,
            ].where((e) => e.isNotEmpty).join(' '),
          ),
          SuperAdminInfoRow(label: 'Address', value: detail.address.line),
          SuperAdminInfoRow(
            label: 'Commission',
            value: '${(detail.commissionRate * 100).toStringAsFixed(1)}%',
          ),
          if (detail.feedback.isNotEmpty)
            SuperAdminInfoRow(label: 'Feedback', value: detail.feedback),
          if (detail.invitedBy.name.isNotEmpty)
            SuperAdminInfoRow(
              label: 'Invited by',
              value: detail.invitedBy.name,
            ),
        ],
      ),
    );
  }

  Widget _statsCard(SuperAdminAgencyDetail detail) {
    final s = detail.stats;
    return SuperAdminGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SemiBoldText(
            text: 'Stats',
            fontSize: TextStyles.k14FontSize,
            color: kColorWhite,
          ),
          Spacing.v12,
          SuperAdminInfoRow(label: 'Hosts', value: '${s.hostCount}'),
          SuperAdminInfoRow(label: 'Active', value: '${s.activeHostsCount}'),
          SuperAdminInfoRow(label: 'Pending', value: '${s.pendingHostsCount}'),
          SuperAdminInfoRow(
            label: 'Commission',
            value: s.totalCommissionEarned.toStringAsFixed(2),
          ),
        ],
      ),
    );
  }

  Widget _docsCard(SuperAdminAgencyDetail detail) {
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
      return SuperAdminGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SemiBoldText(
              text: 'Actions',
              fontSize: TextStyles.k14FontSize,
              color: kColorWhite,
            ),
            Spacing.v12,
            if (detail.isPending)
              Row(
                children: [
                  Expanded(
                    child: _btn(
                      label: 'Reject',
                      color: const Color(0xFFFF8A80).withValues(alpha: 0.16),
                      fg: const Color(0xFFFF8A80),
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
                    child: _btn(
                      label: 'Approve',
                      color: const Color(0xFF2E9E5B),
                      fg: kColorWhite,
                      onTap: busy ? null : controller.approve,
                    ),
                  ),
                ],
              ),
            if (detail.isApproved) ...[
              Row(
                children: [
                  Expanded(
                    child: _btn(
                      label: 'Suspend',
                      color: const Color(0xFFFFB74D).withValues(alpha: 0.18),
                      fg: const Color(0xFFFFB74D),
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
                    child: _btn(
                      label: 'Edit %',
                      color: kColorPrimary.withValues(alpha: 0.35),
                      fg: kColorWhite,
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
            ],
            if (detail.isSuspended)
              _btn(
                label: 'Reactivate',
                color: const Color(0xFF2E9E5B),
                fg: kColorWhite,
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
          const SemiBoldText(
            text: 'Hosts in this agency',
            fontSize: TextStyles.k14FontSize,
            color: kColorWhite,
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
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => controller.openHostDetail(host),
                    borderRadius: BorderRadius.circular(18),
                    child: SuperAdminGlassCard(
                      child: Row(
                        children: [
                          SafeNetworkAvatar(
                            url: host.avatarUrl,
                            size: 42,
                            fallback: CircleAvatar(
                              radius: 21,
                              backgroundColor: kColorPrimary,
                              child: Text(
                                host.name.isNotEmpty
                                    ? host.name.characters.first
                                    : 'H',
                              ),
                            ),
                          ),
                          Spacing.h10,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SemiBoldText(
                                  text: host.name,
                                  fontSize: TextStyles.k14FontSize,
                                  color: kColorWhite,
                                ),
                                AppText(
                                  text: host.status,
                                  fontSize: TextStyles.k10FontSize,
                                  color: Colors.white70,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white54,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
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

  Future<String?> _askText(
    BuildContext context, {
    required String title,
    required String hint,
  }) async {
    final textController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kColorWhite,
        title: Text(title),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(hintText: hint),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirm'),
          ),
        ],
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
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kColorWhite,
        title: const Text('Commission %'),
        content: TextField(
          controller: textController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'e.g. 10'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final raw = double.tryParse(textController.text.trim());
    textController.dispose();
    if (confirmed != true || raw == null) return null;
    // Accept either 0.12 or 12 (percent).
    return raw > 1 ? raw / 100 : raw;
  }
}
