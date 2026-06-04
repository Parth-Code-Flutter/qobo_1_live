import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/services/agency_session_controller.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/agency_owner_dashboard_controller.dart';

class AgencyOwnerDashboardView extends GetView<AgencyOwnerDashboardController> {
  const AgencyOwnerDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<AgencySessionController>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage(kImgBG), fit: BoxFit.cover),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _header(),
              Expanded(
                child: Obx(
                  () => session.hasAgency.value
                      ? _dashboardBody(context)
                      : _noAgencyBody(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: Get.back,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: kColorWhite,
                size: 16,
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: SemiBoldText(
                text: 'Agency Dashboard',
                fontSize: 18,
                color: kColorWhite,
              ),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _noAgencyBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _glassCard(
            child: Column(
              children: [
                Icon(
                  Icons.storefront_rounded,
                  size: 56,
                  color: kColorWhite.withValues(alpha: 0.9),
                ),
                Spacing.v16,
                const SemiBoldText(
                  text: 'No agency registered yet',
                  fontSize: TextStyles.k18FontSize,
                  color: kColorWhite,
                  align: TextAlign.center,
                ),
                Spacing.v8,
                AppText(
                  text:
                      'Register your agency with your logged-in account. After approval you can recruit hosts and track revenue.',
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite.withValues(alpha: 0.75),
                  align: TextAlign.center,
                ),
              ],
            ),
          ),
          Spacing.v24,
          _primaryButton(
            label: 'Register New Agency',
            icon: Icons.add_business_rounded,
            onTap: controller.openRegisterAgency,
          ),
        ],
      ),
    );
  }

  Widget _dashboardBody(BuildContext context) {
    final session = Get.find<AgencySessionController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(() => _agencyHeroCard(session)),
          Spacing.v20,
          const SemiBoldText(
            text: 'Manage',
            fontSize: TextStyles.k16FontSize,
            color: kColorWhite,
          ),
          Spacing.v12,
          _actionTile(
            icon: Icons.link_rounded,
            title: 'Recruit Hosts',
            subtitle: 'Share agency code and invite link',
            onTap: controller.openRecruitLink,
          ),
          Spacing.v10,
          _actionTile(
            icon: Icons.groups_rounded,
            title: 'My Hosts',
            subtitle: 'View approved hosts under your agency',
            onTap: controller.openHostList,
          ),
          Spacing.v10,
          _actionTile(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Agency Revenue',
            subtitle: 'Commissions, payout balance, and history',
            onTap: controller.openRevenue,
          ),
          Spacing.v20,
          _stepList(const [
            'Share recruit link with new hosts',
            'Hosts apply using your agency code',
            'Track earnings after gifts go live',
          ]),
        ],
      ),
    );
  }

  Widget _agencyHeroCard(AgencySessionController session) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: kColorPrimary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SemiBoldText(
            text: session.agencyName.value,
            fontSize: TextStyles.k20FontSize,
            color: kColorWhite,
          ),
          Spacing.v4,
          AppText(
            text: 'Code: ${session.agencyCode.value}',
            fontSize: TextStyles.k14FontSize,
            color: Colors.white70,
          ),
          Spacing.v16,
          Row(
            children: [
              _statPill('Commission', session.commissionPercentLabel),
              Spacing.h10,
              _statPill(
                'Status',
                session.status.value.isEmpty
                    ? 'active'
                    : session.status.value,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statPill(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              text: label,
              fontSize: TextStyles.k10FontSize,
              color: Colors.white60,
            ),
            Spacing.v2,
            SemiBoldText(
              text: value,
              fontSize: TextStyles.k14FontSize,
              color: kColorWhite,
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kColorWhite.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kColorWhite.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: kColorPrimary.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: kColorWhite, size: 22),
              ),
              Spacing.h12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemiBoldText(
                      text: title,
                      fontSize: TextStyles.k16FontSize,
                      color: kColorWhite,
                    ),
                    Spacing.v4,
                    AppText(
                      text: subtitle,
                      fontSize: TextStyles.k12FontSize,
                      color: kColorWhite.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: kColorWhite.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.12)),
      ),
      child: child,
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kColorProfileActionPinkStart, kColorProfileActionPinkEnd],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: kColorWhite, size: 22),
            Spacing.h8,
            SemiBoldText(
              text: label,
              fontSize: TextStyles.k16FontSize,
              color: kColorWhite,
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
        color: kColorWhite.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SemiBoldText(
            text: 'Owner checklist',
            fontSize: TextStyles.k14FontSize,
            color: kColorWhite,
          ),
          Spacing.v12,
          for (var i = 0; i < steps.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
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
                    color: kColorWhite.withValues(alpha: 0.85),
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
