import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
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
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage(kImgBG), fit: BoxFit.cover),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const CommonAppBarWidget(
          title: 'Aristocracy Center',
          useMaterialAppBar: true,
          backgroundColor: Colors.transparent,
          titleColor: kColorWhite,
        ),
        body: Column(
          children: [
            Spacing.v12,
            _buildRankSelector(),
            Expanded(child: _buildDetailsPanel()),
          ],
        ),
        bottomNavigationBar: _buildPurchaseBar(),
      ),
    );
  }

  Widget _buildRankSelector() {
    return SizedBox(
      height: 120,
      child: Obx(() {
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: controller.ranks.length,
          itemBuilder: (context, index) {
            final rank = controller.ranks[index];
            final isSelected = controller.selectedRankIndex.value == index;
            final gradients = rank['gradient'] as List<int>;

            return GestureDetector(
              onTap: () => controller.selectRank(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 12),
                width: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradients.map((hex) => Color(hex)).toList(),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? kColorWhite : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: Color(gradients[0]).withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      index >= 2
                          ? Icons.military_tech_rounded
                          : Icons.shield_rounded,
                      color: kColorWhite,
                      size: 36,
                    ),
                    Spacing.v8,
                    BoldText(
                      text: rank['name'],
                      fontSize: TextStyles.k14FontSize,
                      color: kColorWhite,
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
        margin: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kColorWhite.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kColorWhite.withOpacity(0.12), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.stars_rounded, color: Color(gradients[0]), size: 28),
                Spacing.h10,
                BoldText(
                  text: '${rank['name']} Privileges',
                  fontSize: TextStyles.k18FontSize,
                  color: kColorWhite,
                ),
              ],
            ),
            Spacing.v16,
            Expanded(
              child: ListView.separated(
                itemCount: privileges.length,
                separatorBuilder: (_, __) => Spacing.v12,
                itemBuilder: (context, index) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 4),
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
                          color: kColorWhite.withOpacity(0.85),
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

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kColorWhite.withOpacity(0.06),
          border: Border.all(color: kColorWhite.withOpacity(0.08)),
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
                    AppText(
                      text: 'Subscription Fee',
                      fontSize: TextStyles.k12FontSize,
                      color: kColorWhite.withOpacity(0.6),
                    ),
                    Spacing.v4,
                    SemiBoldText(
                      text: rank['price'],
                      fontSize: TextStyles.k16FontSize,
                      color: kColorWhite,
                    ),
                  ],
                ),
              ),
              Spacing.h16,
              SizedBox(
                height: 48,
                width: 140,
                child: appButton(
                  onPressed: () => controller.purchaseNobleRank(rank['name']),
                  buttonText: 'Subscribe',
                  isGradient: true,
                  gradientColors: gradients.map((hex) => Color(hex)).toList(),

                  borderRadius: 24,
                  textStyle: TextStyles.kSemiBoldPoppins(
                    fontSize: TextStyles.k14FontSize,
                    colors: kColorWhite,
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
