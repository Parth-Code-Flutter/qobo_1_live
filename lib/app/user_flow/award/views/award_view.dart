import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/award_controller.dart';

class AwardView extends GetView<AwardController> {
  const AwardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorBackground,
      appBar: const CommonAppBarWidget(
        title: 'Medals & Awards',
        useMaterialAppBar: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(kColorPrimary),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              _buildSummaryHeader(),
              Spacing.v16,
              _buildAwardsList(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSummaryHeader() {
    final unlockedCount = controller.awards.where((a) => a['isUnlocked'] == true).length;
    final totalCount = controller.awards.length;
    final totalPoints = controller.awards
        .where((a) => a['isUnlocked'] == true)
        .fold<int>(0, (sum, item) => sum + (item['points'] as int));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kColorPrimary, Color(0xFF9F3B8F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: kColorPrimary.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  text: 'Achievement Medals',
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite.withOpacity(0.8),
                ),
                Spacing.v6,
                BoldText(
                  text: '$unlockedCount / $totalCount Unlocked',
                  fontSize: 22,
                  color: kColorWhite,
                ),
                Spacing.v12,
                AppText(
                  text: 'Accumulated Points: $totalPoints Pts',
                  fontSize: TextStyles.k12FontSize,
                  color: kColorWhite.withOpacity(0.9),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kColorWhite.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFFFD700), // Gold
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAwardsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: controller.awards.length,
      separatorBuilder: (_, __) => Spacing.v12,
      itemBuilder: (context, index) {
        final award = controller.awards[index];
        final bool isUnlocked = award['isUnlocked'] ?? false;
        final int level = award['level'] ?? 1;
        final double progress = award['progress'] ?? 0.0;
        final String progressText = award['progressText'] ?? '';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kColorWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kColorBlack.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Medal Icon
              _buildMedalBadge(award, isUnlocked, level),
              Spacing.h16,
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SemiBoldText(
                            text: award['title'],
                            fontSize: TextStyles.k16FontSize,
                            color: kColorText,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: AppText(
                            text: '+${award['points']} Pts',
                            fontSize: 10,
                            color: Colors.orange,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    Spacing.v4,
                    AppText(
                      text: award['desc'],
                      fontSize: TextStyles.k12FontSize,
                      color: kColorHint,
                    ),
                    Spacing.v12,
                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: kColorBackground,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isUnlocked ? kColorPrimary : Colors.grey.shade400,
                        ),
                      ),
                    ),
                    Spacing.v6,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText(
                          text: award['type'],
                          fontSize: 10,
                          color: kColorPrimary.withOpacity(0.7),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        AppText(
                          text: progressText,
                          fontSize: TextStyles.k12FontSize,
                          color: kColorHint,
                        ),
                      ],
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

  Widget _buildMedalBadge(Map<String, dynamic> award, bool isUnlocked, int level) {
    IconData getIcon(String name) {
      switch (name) {
        case 'star_rounded':
          return Icons.star_rounded;
        case 'card_giftcard_rounded':
          return Icons.card_giftcard_rounded;
        case 'visibility_rounded':
          return Icons.visibility_rounded;
        case 'shield_rounded':
          return Icons.shield_rounded;
        case 'people_rounded':
          return Icons.people_rounded;
        default:
          return Icons.emoji_events_rounded;
      }
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isUnlocked ? kColorPrimary.withOpacity(0.12) : Colors.grey.shade100,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isUnlocked ? kColorPrimary.withOpacity(0.3) : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Icon(
                getIcon(award['icon']),
                color: isUnlocked ? kColorPrimary : Colors.grey.shade400,
                size: 28,
              ),
            ),
            if (isUnlocked)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: kColorWhite,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
        Spacing.v6,
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isUnlocked ? kColorPrimary : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: AppText(
            text: 'Lv.$level',
            fontSize: 9,
            color: isUnlocked ? kColorWhite : Colors.grey.shade600,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
