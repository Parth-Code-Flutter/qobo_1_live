import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/icon_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/app_widgets/dating_empty_hero.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/award_controller.dart';

class AwardView extends GetView<AwardController> {
  const AwardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorLavenderBg,
      appBar: const CommonAppBarWidget(
        title: 'Medals & Awards',
        subtitle: 'Unlock badges and earn bonus points',
        trailingIcon: Icons.military_tech_rounded,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.awards.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppLightUi.pink),
          );
        }

        if (controller.awards.isEmpty) {
          return _emptyState();
        }

        return RefreshIndicator(
          color: AppLightUi.pink,
          backgroundColor: AppLightUi.card,
          onRefresh: () async => controller.fetchAwards(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              _summaryHeader(),
              Spacing.v16,
              ...List.generate(controller.awards.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == controller.awards.length - 1 ? 0 : 12,
                  ),
                  child: _awardCard(controller.awards[index], index),
                );
              }),
            ],
          ),
        );
      }),
    );
  }

  Widget _summaryHeader() {
    final unlockedCount =
        controller.awards.where((a) => a['isUnlocked'] == true).length;
    final totalCount = controller.awards.length;
    final totalPoints = controller.awards
        .where((a) => a['isUnlocked'] == true)
        .fold<int>(0, (sum, item) => sum + _pointsOf(item));
    final ratio = totalCount == 0 ? 0.0 : unlockedCount / totalCount;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: AppLightUi.familyCtaGradient,
        boxShadow: [
          BoxShadow(
            color: AppLightUi.pink.withValues(alpha: 0.32),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
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
                  color: kColorWhite.withValues(alpha: 0.18),
                  border: Border.all(
                    color: kColorWhite.withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFFFE08A),
                  size: 28,
                ),
              ),
              Spacing.h12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      text: 'Achievement medals',
                      fontSize: TextStyles.k12FontSize,
                      color: kColorWhite.withValues(alpha: 0.88),
                    ),
                    Spacing.v4,
                    SemiBoldText(
                      text: '$unlockedCount / $totalCount unlocked',
                      fontSize: TextStyles.k20FontSize,
                      color: kColorWhite,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                decoration: BoxDecoration(
                  color: kColorWhite,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: SemiBoldText(
                  text: '$totalPoints pts',
                  fontSize: TextStyles.k12FontSize,
                  color: AppLightUi.title,
                ),
              ),
            ],
          ),
          Spacing.v16,
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: kColorWhite.withValues(alpha: 0.22),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFE08A)),
            ),
          ),
          Spacing.v8,
          AppText(
            text: totalCount == 0
                ? 'Complete challenges to earn medals.'
                : '${(ratio * 100).round()}% of medals collected',
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite.withValues(alpha: 0.90),
          ),
        ],
      ),
    );
  }

  Widget _awardCard(Map<String, dynamic> award, int index) {
    final isUnlocked = award['isUnlocked'] == true;
    final isClaimed = award['isClaimed'] == true;
    final level = award['level'] is int
        ? award['level'] as int
        : int.tryParse('${award['level']}') ?? 1;
    final progress = (award['progress'] is num)
        ? (award['progress'] as num).toDouble().clamp(0.0, 1.0)
        : 0.0;
    final progressText = award['progressText']?.toString().trim().isNotEmpty ==
            true
        ? award['progressText'].toString()
        : '${(progress * 100).round()}%';
    final type = award['type']?.toString().trim().isNotEmpty == true
        ? award['type'].toString()
        : 'Achievement';
    final canClaim = isUnlocked && !isClaimed;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppLightUi.cardDecoration(radius: 20),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _medalBadge(
                iconKey: award['icon']?.toString() ?? '',
                level: level,
                isUnlocked: isUnlocked,
              ),
              Spacing.h12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SemiBoldText(
                            text: award['title']?.toString() ?? 'Medal',
                            fontSize: TextStyles.k14FontSize,
                            color: AppLightUi.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Spacing.h8,
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            gradient: isUnlocked
                                ? AppLightUi.familyCtaGradient
                                : null,
                            color: isUnlocked ? null : AppLightUi.cardSoft,
                            borderRadius: BorderRadius.circular(999),
                            border: isUnlocked
                                ? null
                                : Border.all(color: AppLightUi.borderStrong),
                          ),
                          child: SemiBoldText(
                            text: '+${_pointsOf(award)} pts',
                            fontSize: TextStyles.k10FontSize,
                            color: isUnlocked ? kColorWhite : AppLightUi.title,
                          ),
                        ),
                      ],
                    ),
                    Spacing.v6,
                    AppText(
                      text: award['desc']?.toString() ?? '',
                      fontSize: TextStyles.k12FontSize,
                      color: AppLightUi.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacing.v10,
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppLightUi.violet.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppLightUi.violet.withValues(alpha: 0.28),
                            ),
                          ),
                          child: SemiBoldText(
                            text: type,
                            fontSize: TextStyles.k10FontSize,
                            color: AppLightUi.violet,
                          ),
                        ),
                        const Spacer(),
                        SemiBoldText(
                          text: isUnlocked ? 'Completed' : progressText,
                          fontSize: TextStyles.k12FontSize,
                          color: isUnlocked
                              ? const Color(0xFF1FA86A)
                              : AppLightUi.title,
                        ),
                      ],
                    ),
                    Spacing.v10,
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: isUnlocked ? 1 : progress,
                        minHeight: 8,
                        backgroundColor: AppLightUi.borderStrong,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isUnlocked
                              ? const Color(0xFF25D98F)
                              : AppLightUi.pink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (canClaim) ...[
            Spacing.v12,
            SizedBox(
              width: double.infinity,
              height: 42,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => controller.claimAwardRewards(index),
                  borderRadius: BorderRadius.circular(14),
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: AppLightUi.familyCtaGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppLightUi.pink.withValues(alpha: 0.28),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: SemiBoldText(
                        text: 'Claim reward',
                        fontSize: TextStyles.k12FontSize,
                        color: kColorWhite,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ] else if (isClaimed) ...[
            Spacing.v10,
            Container(
              width: double.infinity,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppLightUi.cardSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppLightUi.borderStrong),
              ),
              child: const SemiBoldText(
                text: 'Reward claimed',
                fontSize: TextStyles.k12FontSize,
                color: AppLightUi.body,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _medalBadge({
    required String iconKey,
    required int level,
    required bool isUnlocked,
  }) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isUnlocked ? AppLightUi.familyCtaGradient : null,
                color: isUnlocked ? null : AppLightUi.cardSoft,
                border: Border.all(
                  color: isUnlocked
                      ? AppLightUi.pink.withValues(alpha: 0.45)
                      : AppLightUi.borderStrong,
                  width: 1.6,
                ),
                boxShadow: isUnlocked
                    ? [
                        BoxShadow(
                          color: AppLightUi.pink.withValues(alpha: 0.28),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                _iconFor(iconKey),
                color: isUnlocked ? kColorWhite : AppLightUi.body,
                size: 28,
              ),
            ),
            if (isUnlocked)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D98F),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppLightUi.card, width: 2),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: kColorWhite,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
        Spacing.v8,
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isUnlocked
                ? AppLightUi.pink.withValues(alpha: 0.12)
                : AppLightUi.cardSoft,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isUnlocked
                  ? AppLightUi.pink.withValues(alpha: 0.30)
                  : AppLightUi.borderStrong,
            ),
          ),
          child: SemiBoldText(
            text: 'Lv.$level',
            fontSize: TextStyles.k10FontSize,
            color: isUnlocked ? AppLightUi.pink : AppLightUi.body,
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          decoration: AppLightUi.cardDecoration(radius: 28),
          child: Column(
            children: [
              const DatingEmptyHero(
                style: DatingEmptyHeroStyle.sparks,
                size: 148,
                accentColors: [AppLightUi.gold, AppLightUi.pink],
              ),
              Spacing.v16,
              const SemiBoldText(
                text: 'No medals yet',
                fontSize: TextStyles.k16FontSize,
                color: AppLightUi.title,
                align: TextAlign.center,
              ),
              Spacing.v8,
              const AppText(
                text: 'Keep streaming, gifting, and socializing to unlock awards.',
                fontSize: TextStyles.k12FontSize,
                color: AppLightUi.subtitle,
                align: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'star_rounded':
        return Icons.star_rounded;
      case 'card_giftcard_rounded':
      case 'redeem_rounded':
        return kGiftIcon;
      case 'visibility_rounded':
        return Icons.visibility_rounded;
      case 'shield_rounded':
        return Icons.shield_rounded;
      case 'people_rounded':
        return Icons.people_rounded;
      case 'live_tv_rounded':
      case 'sensors_rounded':
        return Icons.sensors_rounded;
      case 'favorite_rounded':
        return Icons.favorite_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }

  int _pointsOf(Map<String, dynamic> award) {
    final value = award['points'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
