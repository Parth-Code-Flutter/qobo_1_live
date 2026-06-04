import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/agency_owner_dashboard/models/agency_revenue_demo.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/agency_revenue_controller.dart';

class AgencyRevenueView extends GetView<AgencyRevenueController> {
  const AgencyRevenueView({super.key});

  @override
  Widget build(BuildContext context) {
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildMonthSelector(),
                      Spacing.v16,
                      _buildBalanceCard(),
                      Spacing.v16,
                      Obx(() => _breakdownGrid()),
                      Spacing.v16,
                      Obx(() => _statsRow()),
                      Spacing.v20,
                      _sectionTitle('Revenue history'),
                      Spacing.v12,
                      _buildHistoryList(),
                    ],
                  ),
                ),
              ),
              _bottomActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kColorWhite, size: 18),
          ),
          const Expanded(
            child: Center(
              child: SemiBoldText(
                text: 'Agency Revenue',
                fontSize: TextStyles.k18FontSize,
                color: kColorWhite,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SemiBoldText(
          text: 'Select month',
          fontSize: TextStyles.k14FontSize,
          color: kColorWhite,
        ),
        Spacing.v10,
        Obx(
          () => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AgencyRevenueController.monthOptions.map((month) {
                final selected = controller.selectedMonth.value == month;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => controller.selectMonth(month),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? kColorPrimary : kColorWhite.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? kColorPrimary : kColorWhite.withValues(alpha: 0.24),
                        ),
                      ),
                      child: SemiBoldText(
                        text: month,
                        fontSize: TextStyles.k12FontSize,
                        color: kColorWhite,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kColorPrimary, Color(0xFFE91E8C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kColorPrimary.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const AppText(
            text: '${AgencyRevenueDemo.agencyName} · Available payout',
            fontSize: TextStyles.k12FontSize,
            color: Colors.white70,
            align: TextAlign.center,
          ),
          Spacing.v8,
          Obx(
            () => BoldText(
              text: '${controller.availableForPayout.value} coins',
              fontSize: 32,
              color: kColorWhite,
            ),
          ),
          Spacing.v16,
          Container(height: 1, color: Colors.white24),
          Spacing.v12,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText(
                text: 'Total agency earnings',
                fontSize: TextStyles.k12FontSize,
                color: Colors.white70,
              ),
              Obx(
                () => SemiBoldText(
                  text: '${controller.totalRevenue.value} coins',
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite,
                ),
              ),
            ],
          ),
          Spacing.v6,
          AppText(
            text:
                'Owner ${AgencyRevenueDemo.ownerName} · ${AgencyRevenueDemo.ownerCoinsPerSecond} coins/sec',
            fontSize: TextStyles.k10FontSize,
            color: Colors.white60,
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _breakdownGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _miniStat('Company (50%)', controller.companyShare.value)),
            Spacing.h8,
            Expanded(child: _miniStat('Hosts (50%)', controller.hostShare.value)),
          ],
        ),
        Spacing.v8,
        Row(
          children: [
            Expanded(child: _miniStat('Owner commission', controller.ownerCommission.value)),
            Spacing.h8,
            Expanded(child: _miniStat('Gifts volume', controller.giftsVolume.value)),
          ],
        ),
      ],
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        Expanded(child: _miniStat('Pending items', controller.pendingCommissionCount.value)),
        Spacing.h8,
        Expanded(child: _miniStat('Active hosts', controller.hostsCount.value)),
      ],
    );
  }

  Widget _miniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            text: label,
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite.withValues(alpha: 0.6),
          ),
          Spacing.v4,
          SemiBoldText(
            text: value,
            fontSize: TextStyles.k14FontSize,
            color: kColorWhite,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return SemiBoldText(
      text: title,
      fontSize: TextStyles.k16FontSize,
      color: kColorWhite,
    );
  }

  Widget _buildHistoryList() {
    return Obx(() {
      if (controller.historyList.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: AppText(
            text: 'No revenue entries for this month (demo: select June).',
            fontSize: TextStyles.k14FontSize,
            color: kColorWhite.withValues(alpha: 0.65),
            align: TextAlign.center,
          ),
        );
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.historyList.length,
        separatorBuilder: (_, __) => Spacing.v10,
        itemBuilder: (context, index) {
          final item = controller.historyList[index];
          return _historyTile(item);
        },
      );
    });
  }

  Widget _historyTile(RevenueHistoryModel item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _iconColor(item.type).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(_iconFor(item.type), color: _iconColor(item.type), size: 20),
          ),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: item.title,
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite,
                ),
                Spacing.v4,
                AppText(
                  text: item.subtitle,
                  fontSize: TextStyles.k12FontSize,
                  color: kColorWhite.withValues(alpha: 0.65),
                ),
                Spacing.v2,
                AppText(
                  text: item.date,
                  fontSize: TextStyles.k10FontSize,
                  color: kColorWhite.withValues(alpha: 0.45),
                ),
              ],
            ),
          ),
          SemiBoldText(
            text: item.amount,
            fontSize: TextStyles.k14FontSize,
            color: Colors.greenAccent,
          ),
        ],
      ),
    );
  }

  Widget _bottomActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          appButton(
            onPressed: () => controller.requestPayout(context),
            buttonText: 'Request Payout',
          ),
          Spacing.v8,
          TextButton(
            onPressed: controller.openDashboard,
            child: const SemiBoldText(
              text: 'Back to Dashboard',
              fontSize: TextStyles.k14FontSize,
              color: kColorWhite,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(AgencyRevenueLineType type) {
    switch (type) {
      case AgencyRevenueLineType.call:
        return Icons.call_rounded;
      case AgencyRevenueLineType.gift:
        return Icons.card_giftcard_rounded;
      case AgencyRevenueLineType.owner:
        return Icons.person_rounded;
      case AgencyRevenueLineType.payout:
        return Icons.payments_rounded;
    }
  }

  Color _iconColor(AgencyRevenueLineType type) {
    switch (type) {
      case AgencyRevenueLineType.call:
        return Colors.blueAccent;
      case AgencyRevenueLineType.gift:
        return const Color(0xFFFF6B9D);
      case AgencyRevenueLineType.owner:
        return Colors.amber;
      case AgencyRevenueLineType.payout:
        return Colors.greenAccent;
    }
  }
}
