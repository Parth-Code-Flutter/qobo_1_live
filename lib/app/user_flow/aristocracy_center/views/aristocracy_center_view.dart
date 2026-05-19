import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/aristocracy_center_controller.dart';

class AristocracyCenterView extends GetView<AristocracyCenterController> {
  const AristocracyCenterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorAppBackground,
      appBar: const CommonAppBarWidget(
        title: 'Aristocracy Center',
        useMaterialAppBar: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBalanceAndActiveRankHeader(),
          Spacing.v12,
          _buildRankSelector(),
          Expanded(child: _buildDetailsPanel()),
        ],
      ),
      bottomNavigationBar: _buildPurchaseBar(),
    );
  }

  Widget _buildBalanceAndActiveRankHeader() {
    return Container(
      color: kColorWhite,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.monetization_on, color: Colors.amber, size: 24),
              Spacing.h8,
              Obx(() => SemiBoldText(
                    text: '${controller.coinsBalance.value} Coins',
                    fontSize: TextStyles.k14FontSize,
                    color: kColorText,
                  )),
            ],
          ),
          Obx(() {
            final activeRank = controller.activeRankName.value;
            if (activeRank != null) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8A48)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium_outlined, color: kColorWhite, size: 14),
                    Spacing.h4,
                    BoldText(
                      text: activeRank,
                      fontSize: 10,
                      color: kColorWhite,
                    ),
                  ],
                ),
              );
            }
            return const AppText(
              text: 'No Active Rank',
              fontSize: TextStyles.k12FontSize,
              color: kColorHint,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRankSelector() {
    return SizedBox(
      height: 110,
      child: Obx(() {
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: controller.ranks.length,
          itemBuilder: (context, index) {
            final rank = controller.ranks[index];
            final isSelected = controller.selectedRankIndex.value == index;
            final gradients = rank['gradient'] as List<int>;
            final isActive = controller.activeRankName.value == rank['name'];

            return GestureDetector(
              onTap: () => controller.selectRank(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 12),
                width: 96,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradients.map((hex) => Color(hex)).toList(),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.amber : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: Color(gradients[0]).withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          index >= 2 ? Icons.military_tech_rounded : Icons.shield_rounded,
                          color: kColorWhite,
                          size: 32,
                        ),
                        Spacing.v6,
                        BoldText(
                          text: rank['name'],
                          fontSize: TextStyles.k14FontSize,
                          color: kColorWhite,
                        ),
                      ],
                    ),
                    if (isActive)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: kColorWhite, size: 10),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildDetailsPanel() {
    return Obx(() {
      final rank = controller.ranks[controller.selectedRankIndex.value];
      final privileges = rank['privileges'] as List<String>;
      final gradients = rank['gradient'] as List<int>;

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kColorWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: kColorBlack.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.stars_rounded, color: Color(gradients[0]), size: 24),
                Spacing.h10,
                BoldText(
                  text: '${rank['name']} Privileges',
                  fontSize: TextStyles.k16FontSize,
                  color: kColorText,
                ),
              ],
            ),
            Spacing.v16,
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: privileges.length,
                separatorBuilder: (_, __) => Spacing.v12,
                itemBuilder: (context, index) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Color(gradients[0]),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Spacing.h12,
                      Expanded(
                        child: AppText(
                          text: privileges[index],
                          fontSize: TextStyles.k14FontSize,
                          color: kColorTextGrey,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPurchaseBar() {
    return Obx(() {
      final rank = controller.ranks[controller.selectedRankIndex.value];
      final gradients = rank['gradient'] as List<int>;
      final isAlreadyActive = controller.activeRankName.value == rank['name'];

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: kColorWhite,
          boxShadow: [
            BoxShadow(
              color: kColorBlack.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText(
                      text: 'Subscription Fee',
                      fontSize: 10,
                      color: kColorHint,
                    ),
                    Spacing.v2,
                    SemiBoldText(
                      text: rank['price'],
                      fontSize: TextStyles.k14FontSize,
                      color: Color(gradients[0]),
                    ),
                  ],
                ),
              ),
              Spacing.h16,
              SizedBox(
                height: 44,
                width: 140,
                child: appButton(
                  onPressed: isAlreadyActive ? () {} : () => controller.purchaseNobleRank(rank['name']),
                  buttonText: isAlreadyActive ? 'Active' : 'Subscribe',
                  isGradient: !isAlreadyActive,
                  gradientColors: isAlreadyActive ? null : gradients.map((hex) => Color(hex)).toList(),
                  buttonColor: isAlreadyActive ? const Color(0xFFF3F3F3) : null,
                  textColor: isAlreadyActive ? kColorHint : kColorWhite,
                  borderRadius: 22,
                  textStyle: TextStyles.kSemiBoldPoppins(
                    fontSize: TextStyles.k14FontSize,
                    colors: isAlreadyActive ? kColorHint : kColorWhite,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
