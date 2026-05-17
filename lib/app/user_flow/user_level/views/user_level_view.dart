import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/user_level_controller.dart';

class UserLevelView extends GetView<UserLevelController> {
  const UserLevelView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorBackground,
      appBar: const CommonAppBarWidget(
        title: 'User Level',
        useMaterialAppBar: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLevelCard(),
            Spacing.v24,
            const SemiBoldText(
              text: 'Level Privileges',
              fontSize: TextStyles.k18FontSize,
              color: kColorText,
            ),
            Spacing.v16,
            _buildPerksList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCard() {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: kColorWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: kColorBlack.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kColorPrimary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_rounded,
                color: kColorPrimary,
                size: 48,
              ),
            ),
            Spacing.v16,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const SemiBoldText(
                  text: 'Lv.',
                  fontSize: TextStyles.k18FontSize,
                  color: kColorText,
                ),
                Spacing.h4,
                BoldText(
                  text: '${controller.currentLevel.value}',
                  fontSize: TextStyles.k32FontSize,
                  color: kColorPrimary,
                ),
              ],
            ),
            Spacing.v8,
            AppText(
              text: 'You are ${controller.nextLevelExp.value - controller.currentExp.value} EXP away from Level ${controller.currentLevel.value + 1}',
              fontSize: TextStyles.k14FontSize,
              color: kColorHint,
              align: TextAlign.center,
            ),
            Spacing.v24,
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: controller.progress,
                minHeight: 12,
                backgroundColor: kColorBackground,
                valueColor: const AlwaysStoppedAnimation<Color>(kColorPrimary),
              ),
            ),
            Spacing.v8,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText(
                  text: '${controller.currentExp.value} EXP',
                  fontSize: TextStyles.k12FontSize,
                  color: kColorHint,
                ),
                AppText(
                  text: '${controller.nextLevelExp.value} EXP',
                  fontSize: TextStyles.k12FontSize,
                  color: kColorHint,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPerksList() {
    return Obx(() {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.perks.length,
        separatorBuilder: (_, __) => Spacing.v12,
        itemBuilder: (context, index) {
          final perk = controller.perks[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kColorWhite,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kColorPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.card_giftcard_rounded,
                    color: kColorPrimary,
                    size: 20,
                  ),
                ),
                Spacing.h16,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SemiBoldText(
                        text: perk['title'] ?? '',
                        fontSize: TextStyles.k14FontSize,
                        color: kColorText,
                      ),
                      Spacing.v4,
                      AppText(
                        text: perk['subtitle'] ?? '',
                        fontSize: TextStyles.k12FontSize,
                        color: kColorHint,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}
