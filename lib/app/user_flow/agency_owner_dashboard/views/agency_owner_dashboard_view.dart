import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/agency_owner_dashboard/models/agency_revenue_demo.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/services/agency_session_controller.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/agency_owner_dashboard_controller.dart';

/// Local palette for agency dashboard glass UI.
abstract final class _DashUi {
  static const radiusLg = 24.0;
  static const radiusMd = 18.0;
  static const radiusSm = 14.0;

  static const glassFill = Color(0x14FFFFFF);
  static const glassBorder = Color(0x28FFFFFF);
  static const glassHighlight = Color(0x40FFFFFF);

  static const accentPink = Color(0xFFFF5CAB);
  static const accentViolet = Color(0xFF9B5CFF);
  static const accentCyan = Color(0xFF4FD1C5);
  static const accentGold = Color(0xFFFFD166);

  static const textMuted = Color(0xB3FFFFFF);
  static const textSoft = Color(0x8FFFFFFF);
}

class AgencyOwnerDashboardView extends GetView<AgencyOwnerDashboardController> {
  const AgencyOwnerDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0618),
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(kImgBG),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -40,
            child: _glowOrb(_DashUi.accentViolet.withValues(alpha: 0.35), 180),
          ),
          Positioned(
            top: 120,
            left: -60,
            child: _glowOrb(_DashUi.accentPink.withValues(alpha: 0.28), 140),
          ),
          Positioned(
            bottom: 80,
            right: -20,
            child: _glowOrb(_DashUi.accentCyan.withValues(alpha: 0.18), 120),
          ),
          SafeArea(
            child: Column(
              children: [
                _header(),
                Expanded(
                  child: Obx(() => _dashboardBody()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color, blurRadius: 80, spreadRadius: 20),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_DashUi.radiusSm),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: _DashUi.glassFill,
              borderRadius: BorderRadius.circular(_DashUi.radiusSm),
              border: Border.all(color: _DashUi.glassBorder),
            ),
            child: Row(
              children: [
                _iconButton(Icons.arrow_back_ios_new_rounded, Get.back),
                const Expanded(
                  child: Column(
                    children: [
                      SemiBoldText(
                        text: 'Agency Dashboard',
                        fontSize: TextStyles.k16FontSize,
                        color: kColorWhite,
                      ),
                      AppText(
                        text: 'Revenue & hosts overview',
                        fontSize: TextStyles.k10FontSize,
                        color: _DashUi.textSoft,
                      ),
                    ],
                  ),
                ),
                _iconButton(Icons.insights_rounded, controller.openRevenue),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(icon, color: kColorWhite, size: 18),
        ),
      ),
    );
  }

  Widget _dashboardBody() {
    final session = Get.find<AgencySessionController>();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (controller.isDemoPreview) ...[
            _demoChip(),
            Spacing.v16,
          ],
          _agencyHeroCard(session),
          Spacing.v20,
          _featuredEarningsCard(),
          Spacing.v12,
          _secondaryMetricsRow(),
          Spacing.v20,
          _sectionLabel('Revenue breakdown', Icons.pie_chart_outline_rounded),
          Spacing.v10,
          _revenueSplitCard(),
          Spacing.v16,
          _sampleCallCard(),
          Spacing.v20,
          _sectionHeader(
            title: 'Top hosts',
            action: 'View all',
            onAction: controller.openHostList,
          ),
          Spacing.v12,
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: controller.hosts.length,
              separatorBuilder: (_, __) => Spacing.h12,
              itemBuilder: (_, i) => _hostSlideCard(controller.hosts[i]),
            ),
          ),
          Spacing.v20,
          _sectionLabel('Quick actions', Icons.bolt_rounded),
          Spacing.v12,
          _quickActionsGrid(),
          if (controller.isDemoPreview) ...[
            Spacing.v20,
            _registerOutlineButton(),
          ],
          Spacing.v8,
        ],
      ),
    );
  }

  Widget _demoChip() {
    return _glass(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      radius: _DashUi.radiusSm,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _DashUi.accentGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: _DashUi.accentGold,
              size: 16,
            ),
          ),
          Spacing.h10,
          const Expanded(
            child: AppText(
              text: 'Client preview · Fun Call revenue model',
              fontSize: TextStyles.k12FontSize,
              color: _DashUi.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _agencyHeroCard(AgencySessionController session) {
    return _glass(
      radius: _DashUi.radiusLg,
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _DashUi.accentPink.withValues(alpha: 0.45),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [_DashUi.accentPink, _DashUi.accentViolet],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _DashUi.accentPink.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: kColorWhite,
                        size: 26,
                      ),
                    ),
                    Spacing.h12,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SemiBoldText(
                            text: controller.displayAgencyName,
                            fontSize: TextStyles.k22FontSize,
                            color: kColorWhite,
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
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, {IconData? icon, Color accent = _DashUi.accentViolet}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: accent),
            const SizedBox(width: 6),
          ],
          AppText(
            text: text,
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite.withValues(alpha: 0.92),
          ),
        ],
      ),
    );
  }

  Widget _featuredEarningsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_DashUi.radiusLg),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6B2D8E),
            Color(0xFF3D1F6E),
            Color(0xFF1E1038),
          ],
        ),
        border: Border.all(color: _DashUi.glassHighlight),
        boxShadow: [
          BoxShadow(
            color: _DashUi.accentViolet.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: 'Total agency earnings',
                  fontSize: TextStyles.k12FontSize,
                  color: _DashUi.textMuted,
                ),
                Spacing.v6,
                SemiBoldText(
                  text: _formatCoins(controller.totalAgencyEarnings),
                  fontSize: 32,
                  color: kColorWhite,
                ),
                Spacing.v4,
                AppText(
                  text: 'coins this month',
                  fontSize: TextStyles.k12FontSize,
                  color: _DashUi.textSoft,
                ),
              ],
            ),
          ),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _DashUi.accentCyan.withValues(alpha: 0.5), width: 2),
              gradient: RadialGradient(
                colors: [
                  _DashUi.accentCyan.withValues(alpha: 0.25),
                  Colors.transparent,
                ],
              ),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: _DashUi.accentCyan,
              size: 32,
            ),
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
            gradient: const [_DashUi.accentPink, Color(0xFFE91E63)],
          ),
        ),
        Spacing.h10,
        Expanded(
          child: _miniMetric(
            label: 'Active hosts',
            value: '${AgencyRevenueDemo.activeHosts}',
            icon: Icons.groups_rounded,
            gradient: const [_DashUi.accentViolet, Color(0xFF5C6BC0)],
          ),
        ),
      ],
    );
  }

  Widget _miniMetric({
    required String label,
    required String value,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return _glass(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(colors: gradient),
            ),
            child: Icon(icon, color: kColorWhite, size: 20),
          ),
          Spacing.h10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: value,
                  fontSize: TextStyles.k18FontSize,
                  color: kColorWhite,
                ),
                AppText(
                  text: label,
                  fontSize: TextStyles.k10FontSize,
                  color: _DashUi.textMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _revenueSplitCard() {
    final total = controller.companyShare +
        controller.hostCallShare +
        controller.ownerCommission +
        controller.totalGifts;

    return _glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            text: '50% company · 50% host · owner rate applied',
            fontSize: TextStyles.k12FontSize,
            color: _DashUi.textSoft,
          ),
          Spacing.v16,
          _splitBar(
            'Company share',
            controller.companyShare,
            total,
            _DashUi.accentCyan,
          ),
          Spacing.v12,
          _splitBar(
            'Hosts (calls)',
            controller.hostCallShare,
            total,
            Colors.greenAccent,
          ),
          Spacing.v12,
          _splitBar(
            'Owner commission',
            controller.ownerCommission,
            total,
            _DashUi.accentGold,
          ),
          Spacing.v12,
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
                color: kColorWhite.withValues(alpha: 0.9),
              ),
            ),
            SemiBoldText(
              text: _formatCoins(value),
              fontSize: TextStyles.k14FontSize,
              color: kColorWhite,
            ),
          ],
        ),
        Spacing.v8,
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _sampleCallCard() {
    final call = controller.sampleCall;
    return _glass(
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
                  color: kColorWhite.withValues(alpha: 0.4),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const AppText(
                            text: 'LIVE CALL',
                            fontSize: TextStyles.k10FontSize,
                            color: Colors.redAccent,
                          ),
                        ],
                      ),
                    ),
                    Spacing.v4,
                    AppText(
                      text: '${call.durationMinutes} min',
                      fontSize: TextStyles.k12FontSize,
                      color: _DashUi.textMuted,
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
            color: kColorWhite,
          ),
          Spacing.v4,
          AppText(
            text:
                '${call.coinsPerSecond} coins/sec · ${call.durationSeconds}s · gifts +${_formatCoins(call.giftsDuringCall)}',
            fontSize: TextStyles.k12FontSize,
            color: _DashUi.textMuted,
          ),
          Spacing.v12,
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _DashUi.glassBorder),
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
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.5)],
        ),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.3), width: 2),
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
                color: _DashUi.textMuted,
              ),
              AppText(
                text: formula,
                fontSize: TextStyles.k10FontSize,
                color: _DashUi.textSoft,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Divider(height: 1, color: kColorWhite.withValues(alpha: 0.1)),
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
              color: kColorWhite.withValues(alpha: 0.85),
            ),
          ),
          SemiBoldText(
            text: _formatCoins(coins),
            fontSize: TextStyles.k14FontSize,
            color: kColorWhite,
          ),
        ],
      ),
    );
  }

  Widget _hostSlideCard(AgencyHostRevenueDemo host) {
    return GestureDetector(
      onTap: controller.openHostList,
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_DashUi.radiusMd),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kColorWhite.withValues(alpha: 0.14),
              kColorWhite.withValues(alpha: 0.06),
            ],
          ),
          border: Border.all(color: _DashUi.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _callAvatar(host.name, _DashUi.accentViolet),
                Spacing.h10,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SemiBoldText(
                        text: host.name,
                        fontSize: TextStyles.k16FontSize,
                        color: kColorWhite,
                      ),
                      AppText(
                        text: '${host.coinsPerSecond} coins/sec',
                        fontSize: TextStyles.k12FontSize,
                        color: _DashUi.textMuted,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const AppText(
                    text: 'Active',
                    fontSize: TextStyles.k10FontSize,
                    color: Colors.greenAccent,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                _hostMetricChip(Icons.payments_rounded, _formatCoins(host.totalEarnings)),
                Spacing.h6,
                _hostMetricChip(Icons.card_giftcard_rounded, _formatCoins(host.totalGifts)),
              ],
            ),
            Spacing.v6,
            AppText(
              text: 'Calls ${_formatCoins(host.totalCallingSpend)} · ${host.callingMinutes}m · ${host.lastViewer}',
              fontSize: TextStyles.k10FontSize,
              color: _DashUi.textSoft,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _hostMetricChip(IconData icon, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: _DashUi.accentGold),
            const SizedBox(width: 4),
            Flexible(
              child: SemiBoldText(
                text: value,
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite,
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
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_DashUi.radiusMd),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(_DashUi.radiusMd),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              Spacing.v8,
              SemiBoldText(
                text: label,
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _registerOutlineButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: controller.openRegisterAgency,
        borderRadius: BorderRadius.circular(_DashUi.radiusMd),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_DashUi.radiusMd),
            border: Border.all(color: _DashUi.glassHighlight, width: 1.2),
            color: _DashUi.glassFill,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_business_rounded, color: kColorWhite, size: 20),
              Spacing.h8,
              const SemiBoldText(
                text: 'Register your agency',
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _DashUi.accentViolet),
        Spacing.h6,
        SemiBoldText(
          text: title.toUpperCase(),
          fontSize: TextStyles.k12FontSize,
          color: _DashUi.textMuted,
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
          color: kColorWhite,
        ),
        const Spacer(),
        GestureDetector(
          onTap: onAction,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _DashUi.accentPink.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _DashUi.accentPink.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  text: action,
                  fontSize: TextStyles.k12FontSize,
                  color: _DashUi.accentPink,
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: _DashUi.accentPink,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _glass({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    double radius = _DashUi.radiusMd,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: _DashUi.glassFill,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: _DashUi.glassBorder),
          ),
          child: child,
        ),
      ),
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
