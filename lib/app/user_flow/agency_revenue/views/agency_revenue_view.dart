import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/agency_revenue_controller.dart';

class AgencyRevenueView extends GetView<AgencyRevenueController> {
  const AgencyRevenueView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorWhite,
      appBar: CommonAppBarWidget(
        title: 'Agency Revenue',
        useMaterialAppBar: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMonthSelector(),
            Spacing.v16,
            _buildBalanceCard(context),
            Spacing.v16,
            Obx(() => _statsRow()),
            Spacing.v24,
            _sectionTitle('Revenue History'),
            Spacing.v12,
            _buildHistoryList(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              appButton(
                onPressed: () => controller.requestPayout(context),
                buttonText: 'Request Payout',
              ),
              Spacing.v12,
              TextButton(
                onPressed: () => Get.toNamed(Routes.AGENCY_OWNER),
                child: const SemiBoldText(
                  text: 'Back to Dashboard',
                  fontSize: TextStyles.k14FontSize,
                  color: kColorPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SemiBoldText(
          text: 'Select Month',
          fontSize: TextStyles.k14FontSize,
          color: kColorText,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? kColorPrimary : kColorBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? kColorPrimary
                              : kColorHint.withValues(alpha: 0.25),
                        ),
                      ),
                      child: SemiBoldText(
                        text: month,
                        fontSize: TextStyles.k12FontSize,
                        color: selected ? kColorWhite : kColorHint,
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

  Widget _statsRow() {
    return Row(
      children: [
        Expanded(
          child: _miniStatCard(
            'Pending',
            controller.pendingCommissionCount.value,
          ),
        ),
        Spacing.h10,
        Expanded(
          child: _miniStatCard('Hosts', controller.hostsCount.value),
        ),
      ],
    );
  }

  Widget _miniStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kColorBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kColorHint.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            text: label,
            fontSize: TextStyles.k12FontSize,
            color: kColorHint,
          ),
          Spacing.v4,
          SemiBoldText(
            text: value,
            fontSize: TextStyles.k18FontSize,
            color: kColorText,
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kColorPrimary, Colors.pinkAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kColorPrimary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const AppText(
            text: 'Available for Payout (Diamonds)',
            fontSize: TextStyles.k14FontSize,
            color: kColorWhite,
            align: TextAlign.center,
          ),
          Spacing.v8,
          Obx(() => BoldText(
            text: controller.availableForPayout.value,
            fontSize: 36,
            color: kColorWhite,
          )),
          Spacing.v24,
          Container(
            height: 1,
            color: kColorWhite.withValues(alpha: 0.2),
          ),
          Spacing.v16,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText(
                text: 'Total Revenue Generated',
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite,
              ),
              Obx(() => SemiBoldText(
                text: controller.totalRevenue.value,
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return SemiBoldText(
      text: title,
      fontSize: TextStyles.k18FontSize,
      color: kColorText,
    );
  }

  Widget _buildHistoryList() {
    return Obx(() {
      if (controller.historyList.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: AppText(
              text: 'No revenue history yet.',
              fontSize: TextStyles.k14FontSize,
              color: kColorHint,
            ),
          ),
        );
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.historyList.length,
        separatorBuilder: (_, __) => const Divider(color: kColorHint, height: 24),
        itemBuilder: (context, index) {
          final item = controller.historyList[index];
          return Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_downward_rounded, color: Colors.green),
              ),
              Spacing.h16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemiBoldText(
                      text: 'Payout',
                      fontSize: TextStyles.k16FontSize,
                      color: kColorText,
                    ),
                    Spacing.v4,
                    AppText(
                      text: item.date,
                      fontSize: TextStyles.k12FontSize,
                      color: kColorHint,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SemiBoldText(
                    text: item.amount,
                    fontSize: TextStyles.k16FontSize,
                    color: Colors.green,
                  ),
                  Spacing.v4,
                  AppText(
                    text: item.status,
                    fontSize: TextStyles.k12FontSize,
                    color: kColorPrimary,
                  ),
                ],
              ),
            ],
          );
        },
      );
    });
  }
}
