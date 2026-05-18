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
        title: 'User Level & Badges',
        useMaterialAppBar: true,
      ),
      body: Column(
        children: [
          _buildSubTabBar(),
          Expanded(
            child: Obx(() {
              if (controller.selectedSubTab.value == 0) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildLevelCard(),
                      Spacing.v24,
                      const SemiBoldText(
                        text: 'Active Level Privileges',
                        fontSize: TextStyles.k14FontSize,
                        color: kColorText,
                      ),
                      Spacing.v12,
                      _buildPerksList(),
                    ],
                  ),
                );
              } else {
                return _buildIconsHistoryList();
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      height: 44,
      decoration: BoxDecoration(
        color: kColorWhite,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: kColorBlack.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() {
        return Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => controller.selectedSubTab.value = 0,
                child: Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: controller.selectedSubTab.value == 0
                        ? const LinearGradient(colors: [kColorPrimary, Color(0xFFC04B9F)])
                        : null,
                  ),
                  child: SemiBoldText(
                    text: 'My Perks',
                    fontSize: TextStyles.k13FontSize,
                    color: controller.selectedSubTab.value == 0 ? kColorWhite : kColorText.withOpacity(0.7),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => controller.selectedSubTab.value = 1,
                child: Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: controller.selectedSubTab.value == 1
                        ? const LinearGradient(colors: [kColorPrimary, Color(0xFFC04B9F)])
                        : null,
                  ),
                  child: SemiBoldText(
                    text: 'Badge Milestones',
                    fontSize: TextStyles.k13FontSize,
                    color: controller.selectedSubTab.value == 1 ? kColorWhite : kColorText.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildIconsHistoryList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: controller.levelMilestones.length,
      separatorBuilder: (_, __) => Spacing.v12,
      itemBuilder: (context, index) {
        final mile = controller.levelMilestones[index];
        final bool isUnlocked = mile['isUnlocked'] ?? false;
        final color = Color(mile['color'] as int);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kColorWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kColorBlack.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Badge Icon Display
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isUnlocked ? color.withOpacity(0.12) : Colors.grey.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isUnlocked ? color : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  mile['icon'] as IconData,
                  color: isUnlocked ? color : Colors.grey.shade400,
                  size: 28,
                ),
              ),
              Spacing.h16,
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: SemiBoldText(
                            text: mile['title'] ?? '',
                            fontSize: TextStyles.k14FontSize,
                            color: isUnlocked ? kColorText : Colors.grey.shade400,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Spacing.h8,
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isUnlocked ? Colors.green.withOpacity(0.1) : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: AppText(
                            text: isUnlocked ? 'Unlocked' : 'Lv. ${mile['level']}',
                            fontSize: 9,
                            color: isUnlocked ? Colors.green : Colors.grey.shade600,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    Spacing.v4,
                    AppText(
                      text: mile['desc'] ?? '',
                      fontSize: TextStyles.k12FontSize,
                      color: isUnlocked ? kColorHint : Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
