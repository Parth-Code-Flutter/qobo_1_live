import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/icon_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/app_widgets/glossy_dating_card.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/user_level_controller.dart';

class UserLevelView extends GetView<UserLevelController> {
  const UserLevelView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppLightUi.bg,
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
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildLevelCard(),
                      Spacing.v24,
                      const SemiBoldText(
                        text: 'Active Level Privileges',
                        fontSize: TextStyles.k14FontSize,
                        color: AppLightUi.title,
                      ),
                      Spacing.v12,
                      _buildPerksList(),
                    ],
                  ),
                );
              }
              return _buildIconsHistoryList();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: GlossyDatingCard(
        radius: 24,
        padding: const EdgeInsets.all(4),
        child: Obx(() {
          return Row(
            children: [
              Expanded(
                child: _subTab(
                  label: 'My Perks',
                  selected: controller.selectedSubTab.value == 0,
                  onTap: () => controller.selectedSubTab.value = 0,
                ),
              ),
              Expanded(
                child: _subTab(
                  label: 'Badge Milestones',
                  selected: controller.selectedSubTab.value == 1,
                  onTap: () => controller.selectedSubTab.value = 1,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _subTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: selected ? AppLightUi.familyCtaGradient : null,
        ),
        child: SemiBoldText(
          text: label,
          fontSize: TextStyles.k12FontSize,
          color: selected ? kColorWhite : AppLightUi.subtitle,
        ),
      ),
    );
  }

  Widget _buildIconsHistoryList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: controller.levelMilestones.length,
      separatorBuilder: (_, __) => Spacing.v12,
      itemBuilder: (context, index) {
        final mile = controller.levelMilestones[index];
        final bool isUnlocked = mile['isUnlocked'] ?? false;
        final color = Color(mile['color'] as int);

        return GlossyDatingCard(
          radius: 18,
          padding: const EdgeInsets.all(14),
          emphasized: isUnlocked,
          borderGradient: isUnlocked
              ? LinearGradient(colors: [color, color.withValues(alpha: 0.55)])
              : null,
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? color.withValues(alpha: 0.14)
                      : AppLightUi.cardSoft,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isUnlocked
                        ? color.withValues(alpha: 0.55)
                        : AppLightUi.borderStrong,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  mile['icon'] as IconData,
                  color: isUnlocked ? color : AppLightUi.muted,
                  size: 28,
                ),
              ),
              Spacing.h16,
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
                            color: isUnlocked
                                ? AppLightUi.title
                                : AppLightUi.muted,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Spacing.h8,
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            gradient: isUnlocked
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF4ADE80),
                                      Color(0xFF22C55E),
                                    ],
                                  )
                                : null,
                            color: isUnlocked ? null : AppLightUi.cardSoft,
                            borderRadius: BorderRadius.circular(8),
                            border: isUnlocked
                                ? null
                                : Border.all(color: AppLightUi.border),
                          ),
                          child: AppText(
                            text: isUnlocked
                                ? 'Unlocked'
                                : 'Lv. ${mile['level']}',
                            fontSize: 9,
                            color: isUnlocked
                                ? kColorWhite
                                : AppLightUi.subtitle,
                          ),
                        ),
                      ],
                    ),
                    Spacing.v4,
                    AppText(
                      text: mile['desc'] ?? '',
                      fontSize: TextStyles.k12FontSize,
                      color: isUnlocked
                          ? AppLightUi.subtitle
                          : AppLightUi.muted,
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
      final remaining =
          controller.nextLevelExp.value - controller.currentExp.value;
      return GlossyDatingCard(
        radius: 22,
        padding: const EdgeInsets.all(22),
        emphasized: true,
        borderGradient: AppLightUi.familyCtaGradient,
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppLightUi.violet.withValues(alpha: 0.2),
                    AppLightUi.pink.withValues(alpha: 0.14),
                  ],
                ),
                border: Border.all(
                  color: AppLightUi.violet.withValues(alpha: 0.35),
                ),
              ),
              child: const Icon(
                Icons.star_rounded,
                color: AppLightUi.violet,
                size: 40,
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
                  color: AppLightUi.title,
                ),
                Spacing.h4,
                BoldText(
                  text: '${controller.currentLevel.value}',
                  fontSize: TextStyles.k32FontSize,
                  color: AppLightUi.pink,
                ),
              ],
            ),
            Spacing.v8,
            AppText(
              text: remaining > 0
                  ? 'You are $remaining EXP away from Level ${controller.currentLevel.value + 1}'
                  : 'Max level reached — keep shining!',
              fontSize: TextStyles.k14FontSize,
              color: AppLightUi.subtitle,
              align: TextAlign.center,
            ),
            Spacing.v20,
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  Container(
                    height: 12,
                    width: double.infinity,
                    color: AppLightUi.border,
                  ),
                  FractionallySizedBox(
                    widthFactor: controller.progress.clamp(0.0, 1.0),
                    child: Container(
                      height: 12,
                      decoration: const BoxDecoration(
                        gradient: AppLightUi.familyCtaGradient,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Spacing.v8,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText(
                  text: '${controller.currentExp.value} EXP',
                  fontSize: TextStyles.k12FontSize,
                  color: AppLightUi.subtitle,
                ),
                AppText(
                  text: '${controller.nextLevelExp.value} EXP',
                  fontSize: TextStyles.k12FontSize,
                  color: AppLightUi.subtitle,
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
          return GlossyDatingCard(
            radius: 16,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration:
                      AppLightUi.iconTileDecoration(AppLightUi.violet),
                  child: const Icon(
                    kGiftIcon,
                    color: AppLightUi.violet,
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
                        color: AppLightUi.title,
                      ),
                      Spacing.v4,
                      AppText(
                        text: perk['subtitle'] ?? '',
                        fontSize: TextStyles.k12FontSize,
                        color: AppLightUi.subtitle,
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
