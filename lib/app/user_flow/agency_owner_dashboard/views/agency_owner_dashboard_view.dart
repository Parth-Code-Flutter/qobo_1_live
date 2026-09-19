import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/icon_constants.dart';
import 'package:qobo_one_live/app/user_flow/agency_owner_dashboard/models/agency_revenue_demo.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/repo/agency/agency_api_utils.dart';
import 'package:qobo_one_live/repo/economy/economy_api_utils.dart';
import 'package:qobo_one_live/services/agency_session_controller.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/app_widgets/admin_agency_chrome.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/app_widgets/earnings_chart_card.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/agency_owner_dashboard_controller.dart';

/// Local palette for agency dashboard — light AppLightUi dating canvas.
abstract final class _DashUi {
  static const radiusLg = 20.0;
  static const radiusMd = 16.0;

  static const accentPink = AdminAgencyUi.pink;
  static const accentViolet = AdminAgencyUi.violet;
  static const accentCyan = AdminAgencyUi.cyan;
  static const accentGold = AdminAgencyUi.goldDeep;
  static const accentSky = AdminAgencyUi.sky;
  static const accentMint = AdminAgencyUi.mint;

  static const textMuted = AppLightUi.subtitle;
  static const textSoft = AppLightUi.muted;
  static const title = AppLightUi.title;
}

class AgencyOwnerDashboardView extends GetView<AgencyOwnerDashboardController> {
  const AgencyOwnerDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold is required so Text has a Material ancestor (avoids yellow underlines).
    final canPop = Get.key.currentState?.canPop() ?? false;
    return Scaffold(
      backgroundColor: kColorLavenderBg,
      appBar: CommonAppBarWidget(
        title: 'Agency Dashboard',
        subtitle: 'Revenue & hosts overview',
        showBackButton: canPop,
        actions: [
          IconButton(
            onPressed: controller.openRevenue,
            icon: const Icon(
              Icons.insights_rounded,
              color: kColorWhite,
              size: 22,
            ),
          ),
          _profileIconButton(),
          const SizedBox(width: 4),
        ],
      ),
      body: Obx(() => _dashboardBody()),
    );
  }

  /// App-bar profile avatar — opens account / tools sheet.
  Widget _profileIconButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openAccountMenu,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: GetBuilder<UserSessionController>(
            init: Get.isRegistered<UserSessionController>()
                ? Get.find<UserSessionController>()
                : Get.put(UserSessionController(), permanent: true),
            builder: (session) {
              return FramedUserAvatar(
                name: session.displayName.isNotEmpty
                    ? session.displayName
                    : controller.displayOwnerName,
                imageUrl: session.displayPictureUrl,
                frameUrl: session.profileFrameUrl,
                frameSeed: session.userId,
                size: 34,
                fontSize: TextStyles.k10FontSize,
              );
            },
          ),
        ),
      ),
    );
  }

  void _openAccountMenu() {
    Get.bottomSheet(
      _AgencyAccountMenuSheet(controller: controller),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _dashboardBody() {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator(color: AppLightUi.pink));
    }

    if (controller.isApplicationPending.value) {
      return _pendingApplicationBody();
    }

    if (!controller.hasDashboard) {
      return _loadErrorBody();
    }

    final session = Get.find<AgencySessionController>();

    return RefreshIndicator(
      color: kColorPrimary,
      onRefresh: () => controller.loadDashboard(showLoader: false),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _agencyHeroCard(session),
            Spacing.v20,
            _featuredEarningsCard(),
            Spacing.v12,
            _secondaryMetricsRow(),
            Spacing.v12,
            _hostRecruitmentBonusCard(),
            Spacing.v20,
            _agencyEarningsChart(),
            Spacing.v20,
            _sectionLabel(
              'Revenue breakdown',
              Icons.pie_chart_outline_rounded,
              accent: _DashUi.accentCyan,
            ),
            Spacing.v10,
            _revenueSplitCard(),
            if (controller.latestCall != null) ...[
              Spacing.v16,
              _latestCallCard(controller.latestCall!),
            ],
            Spacing.v20,
            if (controller.pendingHostApplicationsCount > 0) ...[
              _pendingHostsBanner(),
              Spacing.v16,
            ],
            _sectionHeader(
              title: 'Top hosts',
              action: controller.hosts.isNotEmpty ? 'View all' : '',
              onAction: controller.hosts.isNotEmpty
                  ? controller.openHostList
                  : () {},
            ),
            Spacing.v12,
            if (controller.hosts.isEmpty)
              _emptyHostsCard()
            else
              SizedBox(
                height: 172,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: controller.hosts.length,
                  separatorBuilder: (_, __) => Spacing.h12,
                  itemBuilder: (_, i) => _hostSlideCard(controller.hosts[i], i),
                ),
              ),
            Spacing.v20,
            _sectionLabel(
              'Quick actions',
              Icons.bolt_rounded,
              accent: _DashUi.accentGold,
            ),
            Spacing.v12,
            _quickActionsGrid(),
            Spacing.v8,
          ],
        ),
      ),
    );
  }

  Widget _loadErrorBody() {
    final message = controller.loadError.value.isNotEmpty
        ? controller.loadError.value
        : 'Unable to load agency dashboard.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: AdminSolidPanel(
          accent: _DashUi.accentSky,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          radius: _DashUi.radiusMd,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AdminAgencyUi.glowIcon(
                icon: Icons.cloud_off_rounded,
                accent: _DashUi.accentSky,
                size: 64,
                iconSize: 32,
              ),
              Spacing.v16,
              const SemiBoldText(
                text: 'Dashboard unavailable',
                fontSize: TextStyles.k18FontSize,
                color: AppLightUi.title,
                align: TextAlign.center,
              ),
              Spacing.v8,
              AppText(
                text: message,
                fontSize: TextStyles.k14FontSize,
                color: AppLightUi.body,
                align: TextAlign.center,
              ),
              Spacing.v20,
              AdminGoldCtaButton(
                label: 'Retry',
                icon: Icons.refresh_rounded,
                expanded: true,
                height: 48,
                onTap: controller.loadDashboard,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyHostsCard() {
    return AdminSolidPanel(
      accent: _DashUi.accentCyan,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      radius: _DashUi.radiusMd,
      child: Row(
        children: [
          AdminAgencyUi.glowIcon(
            icon: Icons.groups_rounded,
            accent: _DashUi.accentCyan,
            size: 44,
            iconSize: 22,
          ),
          Spacing.h12,
          const Expanded(
            child: AppText(
              text: 'No hosts yet. Share your recruit link to onboard hosts.',
              fontSize: TextStyles.k12FontSize,
              color: AppLightUi.body,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pendingApplicationBody() {
    final agencyName = controller.pendingAgencyName.value;
    final message = controller.pendingMessage.value;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: AdminSolidPanel(
          accent: _DashUi.accentGold,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          radius: _DashUi.radiusMd,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AdminAgencyUi.glowIcon(
                icon: Icons.hourglass_top_rounded,
                accent: _DashUi.accentGold,
                size: 72,
                iconSize: 36,
              ),
              Spacing.v20,
              const SemiBoldText(
                text: 'Application Pending',
                fontSize: TextStyles.k22FontSize,
                color: AppLightUi.title,
                align: TextAlign.center,
              ),
              Spacing.v10,
              AppText(
                text: agencyName.isNotEmpty
                    ? 'Your application for "$agencyName" is under super admin review.'
                    : 'Your agency application is under super admin review.',
                fontSize: TextStyles.k14FontSize,
                color: AppLightUi.body,
                align: TextAlign.center,
              ),
              if (message.isNotEmpty) ...[
                Spacing.v12,
                AppText(
                  text: message,
                  fontSize: TextStyles.k12FontSize,
                  color: AppLightUi.subtitle,
                  align: TextAlign.center,
                ),
              ],
              Spacing.v8,
              const AppText(
                text:
                    'Once approved, your full agency dashboard with hosts and revenue will appear here.',
                fontSize: TextStyles.k12FontSize,
                color: AppLightUi.subtitle,
                align: TextAlign.center,
              ),
              Spacing.v24,
              AdminGoldCtaButton(
                label: 'Refresh Status',
                icon: Icons.refresh_rounded,
                expanded: true,
                height: 48,
                onTap: controller.loadDashboard,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _agencyHeroCard(AgencySessionController session) {
    return AdminSolidPanel(
      accent: _DashUi.accentPink,
      radius: _DashUi.radiusLg,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AdminAgencyUi.glowIcon(
                icon: Icons.storefront_rounded,
                accent: _DashUi.accentPink,
                accentEnd: _DashUi.accentViolet,
                size: 52,
                iconSize: 26,
              ),
              Spacing.h12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemiBoldText(
                      text: controller.displayAgencyName,
                      fontSize: TextStyles.k22FontSize,
                      color: AppLightUi.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacing.v4,
                    _chip(
                      controller.displayAgencyCode,
                      icon: Icons.tag_rounded,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Spacing.v12,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(
                controller.displayOwnerName,
                icon: Icons.person_outline_rounded,
              ),
              if (controller.ownerCoinsPerSecond > 0)
                _chip(
                  '${controller.ownerCoinsPerSecond} coins/sec',
                  icon: Icons.speed_rounded,
                  accent: _DashUi.accentCyan,
                ),
              if (session.hasAgency.value)
                _chip(
                  session.commissionPercentLabel,
                  icon: Icons.percent_rounded,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(
    String text, {
    IconData? icon,
    Color accent = _DashUi.accentViolet,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: accent),
            const SizedBox(width: 6),
          ],
          SemiBoldText(
            text: text,
            fontSize: TextStyles.k12FontSize,
            color: AppLightUi.title,
          ),
        ],
      ),
    );
  }

  Widget _featuredEarningsCard() {
    return AdminSolidPanel(
      accent: _DashUi.accentGold,
      radius: _DashUi.radiusLg,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText(
                  text: 'Total agency earnings',
                  fontSize: TextStyles.k12FontSize,
                  color: AppLightUi.subtitle,
                ),
                Spacing.v6,
                SemiBoldText(
                  text: _formatCoins(controller.totalAgencyEarnings),
                  fontSize: TextStyles.k28FontSize,
                  color: AppLightUi.title,
                ),
                Spacing.v4,
                AppText(
                  text: controller.displayMonth.isNotEmpty
                      ? 'coins · ${controller.displayMonth}'
                      : 'coins this month',
                  fontSize: TextStyles.k12FontSize,
                  color: AppLightUi.body,
                ),
              ],
            ),
          ),
          AdminAgencyUi.glowIcon(
            icon: Icons.trending_up_rounded,
            accent: _DashUi.accentCyan,
            size: 64,
            iconSize: 28,
          ),
        ],
      ),
    );
  }

  Widget _secondaryMetricsRow() {
    return Row(
      children: [
        Expanded(
          child: _miniMetric(
            label: 'Payout ready',
            value: _formatCoins(controller.availableForPayout),
            icon: Icons.account_balance_wallet_outlined,
            accent: _DashUi.accentGold,
          ),
        ),
        Spacing.h10,
        Expanded(
          child: _miniMetric(
            label: 'Active hosts',
            value: '${controller.activeHostsCount}',
            icon: Icons.groups_rounded,
            accent: _DashUi.accentCyan,
          ),
        ),
      ],
    );
  }

  Widget _hostRecruitmentBonusCard() {
    return AdminSolidPanel(
      accent: _DashUi.accentMint,
      padding: const EdgeInsets.all(16),
      radius: _DashUi.radiusMd,
      child: Row(
        children: [
          AdminAgencyUi.glowIcon(
            icon: Icons.person_add_alt_1_rounded,
            accent: _DashUi.accentMint,
            accentEnd: _DashUi.accentGold,
            size: 48,
            iconSize: 24,
          ),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SemiBoldText(
                  text: 'Host recruitment bonus',
                  fontSize: TextStyles.k14FontSize,
                  color: AppLightUi.title,
                ),
                Spacing.v4,
                AppText(
                  text:
                      '${controller.activeHostsCount} active hosts × 10,000 coins',
                  fontSize: TextStyles.k10FontSize,
                  color: AppLightUi.subtitle,
                ),
              ],
            ),
          ),
          Spacing.h10,
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SemiBoldText(
                text: formatUsd(controller.hostRecruitmentEarningsDollars),
                fontSize: TextStyles.k18FontSize,
                color: _DashUi.accentGold,
              ),
              Spacing.v2,
              AppText(
                text:
                    '${_formatCoins(controller.hostRecruitmentEarningsCoins)} coins',
                fontSize: TextStyles.k10FontSize,
                color: AppLightUi.subtitle,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _agencyEarningsChart() {
    final total = controller.totalAgencyEarnings;
    final payout = controller.availableForPayout;
    final hostBonus = controller.hostRecruitmentEarningsCoins;
    final ownerCommission = controller.ownerCommission;
    return EarningsChartCard(
      title: 'Earnings graph',
      subtitle: 'Agency coins, payout, bonus, and commission',
      totalLabel: formatUsd(coinsToUsd(total + hostBonus)),
      icon: Icons.show_chart_rounded,
      points: [
        EarningsChartPoint(
          label: 'Agency',
          value: total,
          color: _DashUi.accentGold,
        ),
        EarningsChartPoint(
          label: 'Payout',
          value: payout,
          color: _DashUi.accentPink,
        ),
        EarningsChartPoint(
          label: 'Bonus',
          value: hostBonus,
          color: _DashUi.accentCyan,
        ),
        EarningsChartPoint(
          label: 'Commission',
          value: ownerCommission,
          color: const Color(0xFF2E9B6B),
        ),
      ],
    );
  }

  Widget _miniMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color accent,
  }) {
    return AdminSolidPanel(
      accent: accent,
      padding: const EdgeInsets.all(14),
      radius: _DashUi.radiusMd,
      child: Row(
        children: [
          AdminAgencyUi.glowIcon(
            icon: icon,
            accent: accent,
            size: 40,
            iconSize: 20,
          ),
          Spacing.h10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: value,
                  fontSize: TextStyles.k18FontSize,
                  color: AppLightUi.title,
                ),
                AppText(
                  text: label,
                  fontSize: TextStyles.k10FontSize,
                  color: AppLightUi.subtitle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _revenueSplitCard() {
    final total =
        controller.companyShare +
        controller.hostCallShare +
        controller.ownerCommission +
        controller.totalGifts;

    return AdminSolidPanel(
      accent: _DashUi.accentViolet,
      radius: _DashUi.radiusMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            text: '50% company · 50% host · owner rate applied',
            fontSize: TextStyles.k12FontSize,
            color: AppLightUi.subtitle,
          ),
          Spacing.v16,
          _splitBar(
            'Company share',
            controller.companyShare,
            total,
            _DashUi.accentCyan,
          ),
          Spacing.v16,
          _splitBar(
            'Hosts (calls)',
            controller.hostCallShare,
            total,
            const Color(0xFF2E9B6B),
          ),
          Spacing.v16,
          _splitBar(
            'Owner commission',
            controller.ownerCommission,
            total,
            _DashUi.accentGold,
          ),
          Spacing.v16,
          _splitBar(
            'Gifts volume',
            controller.totalGifts,
            total,
            _DashUi.accentPink,
          ),
        ],
      ),
    );
  }

  Widget _splitBar(String label, int value, int total, Color color) {
    final fraction = total > 0 ? (value / total).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SemiBoldText(
                text: label,
                fontSize: TextStyles.k14FontSize,
                color: AppLightUi.title,
              ),
            ),
            SemiBoldText(
              text: _formatCoins(value),
              fontSize: TextStyles.k14FontSize,
              color: AppLightUi.title,
            ),
          ],
        ),
        Spacing.v8,
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 4,
            backgroundColor: AppLightUi.borderStrong,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _latestCallCard(AgencyCallSample call) {
    return AdminSolidPanel(
      accent: _DashUi.accentPink,
      radius: _DashUi.radiusMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _callAvatar(call.hostName, _DashUi.accentPink),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: AppLightUi.muted,
                  size: 18,
                ),
              ),
              _callAvatar(call.viewerName, _DashUi.accentCyan),
              Spacing.h12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.28),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 6,
                            height: 6,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Color(0xFFE53935),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          SizedBox(width: 6),
                          AppText(
                            text: 'LIVE CALL',
                            fontSize: TextStyles.k10FontSize,
                            color: Color(0xFFE53935),
                          ),
                        ],
                      ),
                    ),
                    Spacing.v4,
                    AppText(
                      text: '${call.durationMinutes} min',
                      fontSize: TextStyles.k12FontSize,
                      color: AppLightUi.subtitle,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Spacing.v16,
          SemiBoldText(
            text: '${call.hostName} with ${call.viewerName}',
            fontSize: TextStyles.k16FontSize,
            color: AppLightUi.title,
          ),
          Spacing.v4,
          AppText(
            text:
                '${call.coinsPerSecond} coins/sec · ${call.durationSeconds}s · gifts +${_formatCoins(call.giftsDuringCall)}',
            fontSize: TextStyles.k12FontSize,
            color: AppLightUi.body,
          ),
          Spacing.v12,
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppLightUi.cardSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppLightUi.border),
            ),
            child: Column(
              children: [
                _calcHighlight(
                  'Gross earnings',
                  call.grossCoins,
                  '${call.durationSeconds} × ${call.coinsPerSecond}',
                ),
                _calcDivider(),
                _calcLine('Company (50%)', call.companyCoins),
                _calcLine('Host ${call.hostName} (50%)', call.hostCoins),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _callAvatar(String name, Color color) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.55)]),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: SemiBoldText(
        text: name.isNotEmpty ? name[0] : '?',
        fontSize: TextStyles.k16FontSize,
        color: kColorWhite,
      ),
    );
  }

  Widget _calcHighlight(String label, int coins, String formula) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                text: label,
                fontSize: TextStyles.k12FontSize,
                color: AppLightUi.body,
              ),
              AppText(
                text: formula,
                fontSize: TextStyles.k10FontSize,
                color: AppLightUi.subtitle,
              ),
            ],
          ),
        ),
        SemiBoldText(
          text: _formatCoins(coins),
          fontSize: TextStyles.k20FontSize,
          color: _DashUi.accentCyan,
        ),
      ],
    );
  }

  Widget _calcDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Divider(height: 1, color: AppLightUi.border),
    );
  }

  Widget _calcLine(String label, int coins) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: AppText(
              text: label,
              fontSize: TextStyles.k12FontSize,
              color: AppLightUi.body,
            ),
          ),
          SemiBoldText(
            text: _formatCoins(coins),
            fontSize: TextStyles.k14FontSize,
            color: AppLightUi.title,
          ),
        ],
      ),
    );
  }

  Widget _hostSlideCard(AgencyHostRevenueDemo host, int index) {
    final accents = [
      _DashUi.accentPink,
      _DashUi.accentViolet,
      _DashUi.accentCyan,
      _DashUi.accentGold,
      _DashUi.accentSky,
    ];
    final accent = accents[index % accents.length];
    return GestureDetector(
      onTap: controller.openHostList,
      child: AdminSolidPanel(
        accent: accent,
        radius: _DashUi.radiusMd,
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 228,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _callAvatar(host.name, accent),
                  Spacing.h10,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SemiBoldText(
                          text: host.name,
                          fontSize: TextStyles.k16FontSize,
                          color: AppLightUi.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Spacing.v2,
                        AppText(
                          text: '${host.coinsPerSecond} coins/sec',
                          fontSize: TextStyles.k12FontSize,
                          color: AppLightUi.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Spacing.h6,
                  _hostStatusBadge(host.status),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  _hostMetricChip(
                    Icons.payments_rounded,
                    _formatCoins(host.totalEarnings),
                  ),
                  Spacing.h6,
                  _hostMetricChip(kGiftIcon, _formatCoins(host.totalGifts)),
                ],
              ),
              Spacing.v6,
              AppText(
                text: _hostCallsLine(host),
                fontSize: TextStyles.k10FontSize,
                color: AppLightUi.muted,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _hostCallsLine(AgencyHostRevenueDemo host) {
    final viewer = host.lastViewer.trim();
    final viewerPart = viewer.isNotEmpty ? ' · $viewer' : '';
    return 'Calls ${_formatCoins(host.totalCallingSpend)} · ${host.callingMinutes}m$viewerPart';
  }

  Widget _hostStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    final normalized = status.trim().toLowerCase();

    if (isHostStatusActive(status)) {
      bgColor = const Color(0xFF2E9B6B).withValues(alpha: 0.12);
      textColor = const Color(0xFF1B7A52);
    } else if (isHostStatusPending(status)) {
      bgColor = _DashUi.accentGold.withValues(alpha: 0.14);
      textColor = const Color(0xFFB7791F);
    } else if (isHostStatusRejected(status)) {
      bgColor = Colors.red.withValues(alpha: 0.10);
      textColor = const Color(0xFFC62828);
    } else {
      bgColor = AppLightUi.border.withValues(alpha: 0.6);
      textColor = AppLightUi.subtitle;
    }

    final label = normalized.isEmpty
        ? '—'
        : normalized[0].toUpperCase() + normalized.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.22)),
      ),
      child: AppText(
        text: label,
        fontSize: TextStyles.k10FontSize,
        color: textColor,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _hostMetricChip(IconData icon, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: _DashUi.accentGold.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _DashUi.accentGold.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: _DashUi.accentGold),
            const SizedBox(width: 4),
            Flexible(
              child: SemiBoldText(
                text: value,
                fontSize: TextStyles.k12FontSize,
                color: AppLightUi.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionsGrid() {
    return Row(
      children: [
        Expanded(
          child: _actionCard(
            icon: Icons.link_rounded,
            label: 'Recruit',
            color: _DashUi.accentViolet,
            onTap: controller.openRecruitLink,
          ),
        ),
        Spacing.h10,
        Expanded(
          child: _actionCard(
            icon: Icons.groups_rounded,
            label: 'Hosts',
            color: _DashUi.accentCyan,
            onTap: controller.openHostList,
          ),
        ),
        Spacing.h10,
        Expanded(
          child: _actionCard(
            icon: Icons.wallet_rounded,
            label: 'Revenue',
            color: _DashUi.accentPink,
            onTap: controller.openRevenue,
          ),
        ),
      ],
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return AdminSolidPanel(
      accent: color,
      radius: _DashUi.radiusMd,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Column(
            children: [
              AdminAgencyUi.glowIcon(
                icon: icon,
                accent: color,
                size: 44,
                iconSize: 22,
              ),
              Spacing.v8,
              SemiBoldText(
                text: label,
                fontSize: TextStyles.k12FontSize,
                color: AppLightUi.title,
                align: TextAlign.center,
              ),
            ],
          ),
          if (badgeCount > 0)
            Positioned(
              right: -2,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _DashUi.accentGold,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SemiBoldText(
                  text: '$badgeCount',
                  fontSize: TextStyles.k10FontSize,
                  color: kColorWhite,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pendingHostsBanner() {
    final count = controller.pendingHostApplicationsCount;
    return AdminSolidPanel(
      accent: _DashUi.accentGold,
      radius: _DashUi.radiusMd,
      onTap: controller.openPendingHosts,
      child: Row(
        children: [
          AdminAgencyUi.glowIcon(
            icon: Icons.pending_actions_rounded,
            accent: AdminAgencyUi.goldDeep,
            accentEnd: AdminAgencyUi.gold,
            size: 44,
            iconSize: 22,
          ),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: '$count host${count == 1 ? '' : 's'} awaiting review',
                  fontSize: TextStyles.k14FontSize,
                  color: AppLightUi.title,
                ),
                Spacing.v2,
                const AppText(
                  text: 'Tap to review pending applications',
                  fontSize: TextStyles.k10FontSize,
                  color: AppLightUi.subtitle,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppLightUi.subtitle,
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title, IconData icon, {Color? accent}) {
    final color = accent ?? _DashUi.accentViolet;
    return Row(
      children: [
        AdminAgencyUi.glowIcon(
          icon: icon,
          accent: color,
          size: 28,
          iconSize: 14,
        ),
        Spacing.h8,
        SemiBoldText(
          text: title.toUpperCase(),
          fontSize: TextStyles.k12FontSize,
          color: _DashUi.title,
        ),
      ],
    );
  }

  Widget _sectionHeader({
    required String title,
    required String action,
    required VoidCallback onAction,
  }) {
    return Row(
      children: [
        SemiBoldText(
          text: title,
          fontSize: TextStyles.k18FontSize,
          color: _DashUi.title,
        ),
        if (action.isNotEmpty) ...[
          const Spacer(),
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _DashUi.accentPink.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _DashUi.accentPink.withValues(alpha: 0.35),
                ),
              ),
              child: SemiBoldText(
                text: action,
                fontSize: TextStyles.k12FontSize,
                color: _DashUi.accentPink,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatCoins(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

/// Account / tools sheet opened from the agency dashboard profile avatar.
class _AgencyAccountMenuSheet extends StatelessWidget {
  const _AgencyAccountMenuSheet({required this.controller});

  final AgencyOwnerDashboardController controller;

  @override
  Widget build(BuildContext context) {
    final session = Get.isRegistered<UserSessionController>()
        ? Get.find<UserSessionController>()
        : null;
    final name = session?.displayName.isNotEmpty == true
        ? session!.displayName
        : controller.displayOwnerName;
    final subtitle = session?.email.isNotEmpty == true
        ? session!.email
        : (session?.phone.isNotEmpty == true
              ? session!.phone
              : controller.displayAgencyCode);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          decoration: AppLightUi.cardDecoration(radius: _DashUi.radiusLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Spacing.v10,
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppLightUi.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                child: Row(
                  children: [
                    FramedUserAvatar(
                      name: name,
                      imageUrl: session?.displayPictureUrl,
                      frameUrl: session?.profileFrameUrl,
                      frameSeed: session?.userId,
                      size: 52,
                      fontSize: TextStyles.k14FontSize,
                    ),
                    Spacing.h12,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SemiBoldText(
                            text: name,
                            fontSize: TextStyles.k16FontSize,
                            color: AppLightUi.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Spacing.v4,
                          AppText(
                            text: subtitle,
                            fontSize: TextStyles.k12FontSize,
                            color: _DashUi.textMuted,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Spacing.v6,
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _DashUi.accentViolet.withValues(
                                alpha: 0.28,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: SemiBoldText(
                              text: session?.role.isNotEmpty == true
                                  ? session!.role
                                  : 'agency',
                              fontSize: TextStyles.k10FontSize,
                              color: AppLightUi.title,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppLightUi.border, height: 1),
              _menuTile(
                icon: Icons.manage_accounts_rounded,
                title: 'Edit profile',
                subtitle: 'Name, photo, and account details',
                onTap: () {
                  Get.back<void>();
                  controller.openEditProfile();
                },
              ),
              _menuTile(
                icon: Icons.link_rounded,
                title: 'Recruit hosts',
                subtitle: 'Share your agency invite link',
                onTap: () {
                  Get.back<void>();
                  controller.openRecruitLink();
                },
              ),
              _menuTile(
                icon: Icons.hub_rounded,
                title: 'Host network',
                subtitle: 'Active hosts under your agency',
                onTap: () {
                  Get.back<void>();
                  controller.openHostList();
                },
              ),
              _menuTile(
                icon: Icons.pending_actions_rounded,
                title: 'Pending applications',
                subtitle: 'Approve or reject host requests',
                onTap: () {
                  Get.back<void>();
                  controller.openPendingHosts();
                },
              ),
              _menuTile(
                icon: Icons.insights_rounded,
                title: 'Revenue details',
                subtitle: 'Earnings and payout overview',
                onTap: () {
                  Get.back<void>();
                  controller.openRevenue();
                },
              ),
              const Divider(color: AppLightUi.border, height: 1),
              Obx(() {
                final busy = controller.isLoggingOut.value;
                return _menuTile(
                  icon: Icons.logout_rounded,
                  title: busy ? 'Logging out…' : 'Log out',
                  subtitle: 'Sign out of this agency account',
                  destructive: true,
                  onTap: busy
                      ? null
                      : () async {
                          Get.back<void>();
                          await controller.logout();
                        },
                );
              }),
              Spacing.v8,
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool destructive = false,
  }) {
    final tileAccent = destructive
        ? const Color(0xFFFF6B8A)
        : _DashUi.accentViolet;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            children: [
              AdminAgencyUi.glowIcon(
                icon: icon,
                accent: tileAccent,
                size: 40,
                iconSize: 20,
              ),
              Spacing.h12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemiBoldText(
                      text: title,
                      fontSize: TextStyles.k14FontSize,
                      color: destructive ? tileAccent : AppLightUi.title,
                    ),
                    Spacing.v2,
                    AppText(
                      text: subtitle,
                      fontSize: TextStyles.k10FontSize,
                      color: _DashUi.textSoft,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppLightUi.muted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
