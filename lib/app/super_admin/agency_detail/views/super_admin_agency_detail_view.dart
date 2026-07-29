import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/super_admin/agency_detail/controllers/super_admin_agency_detail_controller.dart';
import 'package:qobo_one_live/app/super_admin/models/super_admin_models.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_ui.dart';
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
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: kColorWhite),
          title: Row(
            children: [
              SuperAdminUi.glowIcon(
                icon: Icons.business_rounded,
                accent: SuperAdminUi.violet,
                size: 34,
                iconSize: 18,
              ),
              Spacing.h10,
              const SemiBoldText(
                text: 'Agency Detail',
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

  Widget _headerCard(SuperAdminAgencyDetail detail) {
    return SuperAdminGlassCard(
      glow: SuperAdminUi.violet,
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
      glow: SuperAdminUi.sky,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Owner & address',
            Icons.person_rounded,
            SuperAdminUi.sky,
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
      glow: SuperAdminUi.mint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Stats', Icons.insights_rounded, SuperAdminUi.mint),
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
        glow: SuperAdminUi.gold,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(
              'Actions',
              Icons.bolt_rounded,
              SuperAdminUi.gold,
            ),
            Spacing.v12,
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
          _sectionTitle(
            'Hosts in this agency',
            Icons.mic_rounded,
            SuperAdminUi.teal,
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
                child: SuperAdminGlassCard(
                  glow: SuperAdminUi.teal,
                  onTap: () => controller.openHostDetail(host),
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
            border: Border.all(color: kColorWhite.withValues(alpha: 0.14)),
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
              Spacing.v12,
              TextField(
                controller: textController,
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
            border: Border.all(color: kColorWhite.withValues(alpha: 0.14)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SemiBoldText(
                text: 'Commission %',
                fontSize: TextStyles.k16FontSize,
                color: kColorWhite,
              ),
              Spacing.v12,
              TextField(
                controller: textController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: kColorWhite),
                decoration: InputDecoration(
                  hintText: 'e.g. 10',
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
    final raw = double.tryParse(textController.text.trim());
    textController.dispose();
    if (confirmed != true || raw == null) return null;
    // Accept either 0.12 or 12 (percent).
    return raw > 1 ? raw / 100 : raw;
  }
}
