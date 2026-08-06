import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_shell_background.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/services/agency_session_controller.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/agency_access_controller.dart';

class AgencyAccessView extends GetView<AgencyAccessController> {
  const AgencyAccessView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppShellBackground(
        child: SafeArea(
          child: Column(
            children: [
              _topBar(),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  child: ColoredBox(
                    color: kColorWhite,
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        20,
                        22,
                        20,
                        28 + MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _header(),
                          Spacing.v20,
                          _modeSwitcher(),
                          Spacing.v20,
                          Obx(
                            () => AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child:
                                  controller.mode.value == AgencyAccessMode.host
                                  ? _hostPanel(context)
                                  : _ownerPanel(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 14, 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Get.back<void>(),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: kColorWhite,
                size: 20,
              ),
            ),
          ),
          const SemiBoldText(
            text: 'Agency Access',
            fontSize: TextStyles.k18FontSize,
            color: kColorWhite,
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BoldText(
          text: 'Choose your agency flow',
          fontSize: TextStyles.k22FontSize,
          color: kColorText,
        ),
        Spacing.v6,
        const AppText(
          text:
              'Hosts can apply or check approval status. Agency owners register once, then manage recruit links, hosts, and revenue from the dashboard.',
          fontSize: 13,
          color: kColorHint,
        ),
      ],
    );
  }

  Widget _modeSwitcher() {
    return Obx(() {
      final selected = controller.mode.value;
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: kColorAvatarFallbackBg.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kColorHint.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _modeButton(
                label: 'Host',
                icon: Icons.video_call_rounded,
                selected: selected == AgencyAccessMode.host,
                onTap: () => controller.selectMode(AgencyAccessMode.host),
              ),
            ),
            Expanded(
              child: _modeButton(
                label: 'Agency Owner',
                icon: Icons.business_center_rounded,
                selected: selected == AgencyAccessMode.owner,
                onTap: () => controller.selectMode(AgencyAccessMode.owner),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _modeButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? kColorPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: kColorPrimary.withValues(alpha: 0.24),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? kColorWhite : kColorHint),
            Spacing.h6,
            Flexible(
              child: SemiBoldText(
                text: label,
                fontSize: 13,
                color: selected ? kColorWhite : kColorHint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hostPanel(BuildContext context) {
    return Column(
      key: const ValueKey('host-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _infoCard(
          icon: Icons.verified_user_rounded,
          title: 'Host application',
          subtitle:
              'Submit your real photo, agency code, contact details, and content category for review.',
          color: kColorProfileActionPinkStart,
        ),
        Spacing.v16,
        appButton(
          onPressed: controller.openHostApplication,
          buttonText: 'Apply as Agency Host',
          buttonIcon: const Icon(
            Icons.mic_external_on_rounded,
            color: kColorWhite,
            size: 20,
          ),
          borderRadius: 16,
        ),
        Spacing.v12,
        _outlineAction(
          icon: Icons.manage_search_rounded,
          label: 'Check Application Status',
          onTap: controller.openHostStatus,
        ),
        Spacing.v20,
        _stepList(const [
          'Apply with host details',
          'Agency/admin reviews the profile',
          'Approved hosts can start streaming',
        ]),
      ],
    );
  }

  Widget _ownerPanel(BuildContext context) {
    final session = Get.find<AgencySessionController>();

    return Obx(
      () {
        final approved = session.hasApprovedAgency;
        final pending = session.isApplicationPending;
        final rejected = session.isApplicationRejected;

        return Column(
          key: ValueKey(
            'owner-panel-${session.applicationState.value.name}-$approved',
          ),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (controller.isRefreshingOwnerState.value)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(
                  color: kColorPrimary,
                  backgroundColor: kColorAvatarFallbackBg,
                ),
              ),
            _infoCard(
              icon: approved
                  ? Icons.admin_panel_settings_rounded
                  : pending
                  ? Icons.hourglass_top_rounded
                  : Icons.add_business_rounded,
              title: approved
                  ? 'Agency approved'
                  : pending
                  ? 'Application under review'
                  : rejected
                  ? 'Application not approved'
                  : 'Apply to become an agency',
              subtitle: approved
                  ? 'Your agency is active. Open the dashboard to manage recruit links, hosts, and revenue.'
                  : pending
                  ? 'Super admin is reviewing "${session.appliedAgencyName.value}". You will get dashboard access after approval.'
                  : rejected
                  ? session.applicationReason.value.isNotEmpty
                        ? session.applicationReason.value
                        : 'You can submit a new application or check status again.'
                  : 'Submit agency details for super admin approval. Dashboard unlocks only after approval.',
              color: approved
                  ? kColorPrimary
                  : pending
                  ? Colors.orange
                  : rejected
                  ? Colors.redAccent
                  : Colors.deepOrange,
            ),
            if (pending && session.applicationId.value.isNotEmpty) ...[
              Spacing.v12,
              _applicationIdChip(session.applicationId.value),
            ],
            Spacing.v16,
            if (approved) ...[
              appButton(
                onPressed: controller.openOwnerDashboard,
                buttonText: 'Open Agency Dashboard',
                buttonIcon: const Icon(
                  Icons.dashboard_rounded,
                  color: kColorWhite,
                  size: 20,
                ),
                borderRadius: 16,
              ),
            ] else ...[
              appButton(
                onPressed: controller.openOwnerApply,
                buttonText: rejected
                    ? 'Submit New Application'
                    : 'Apply to Become Agency',
                buttonIcon: const Icon(
                  Icons.add_business_rounded,
                  color: kColorWhite,
                  size: 20,
                ),
                borderRadius: 16,
              ),
              Spacing.v12,
              _outlineAction(
                icon: Icons.manage_search_rounded,
                label: 'Check Application Status',
                onTap: controller.openOwnerStatus,
              ),
              if (pending) ...[
                Spacing.v12,
                _outlineAction(
                  icon: Icons.dashboard_outlined,
                  label: 'Refresh Approval Status',
                  onTap: controller.openOwnerStatus,
                ),
              ],
            ],
            Spacing.v20,
            _stepList(
              approved
                  ? const [
                      'Agency approved by super admin',
                      'Share recruit code/link with hosts',
                      'Review hosts and revenue in the dashboard',
                    ]
                  : const [
                      'Apply with agency name, owner details, and logo',
                      'Super admin reviews your application',
                      'After approval, open the agency owner dashboard',
                    ],
            ),
          ],
        );
      },
    );
  }

  Widget _applicationIdChip(String applicationId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: kColorPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kColorPrimary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.confirmation_number_outlined,
              color: kColorPrimary, size: 18),
          Spacing.h8,
          Expanded(
            child: SemiBoldText(
              text: 'Application ID: $applicationId',
              fontSize: TextStyles.k12FontSize,
              color: kColorText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(text: title, fontSize: 15, color: kColorText),
                Spacing.v4,
                AppText(
                  text: subtitle,
                  fontSize: TextStyles.k12FontSize,
                  color: kColorHint,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _outlineAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: kColorWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kColorPrimary.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: kColorPrimary, size: 20),
            Spacing.h8,
            SemiBoldText(
              text: label,
              fontSize: TextStyles.k14FontSize,
              color: kColorPrimary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepList(List<String> steps) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kColorAvatarFallbackBg.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SemiBoldText(
            text: 'Flow Preview',
            fontSize: TextStyles.k14FontSize,
            color: kColorText,
          ),
          Spacing.v12,
          for (var i = 0; i < steps.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: kColorPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: SemiBoldText(
                    text: '${i + 1}',
                    fontSize: TextStyles.k10FontSize,
                    color: kColorWhite,
                  ),
                ),
                Spacing.h10,
                Expanded(
                  child: AppText(
                    text: steps[i],
                    fontSize: 13,
                    color: kColorText,
                  ),
                ),
              ],
            ),
            if (i != steps.length - 1) Spacing.v10,
          ],
        ],
      ),
    );
  }

}
