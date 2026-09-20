import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/app_widgets/dating_empty_hero.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/activity_controller.dart';

class ActivityView extends GetView<ActivityController> {
  const ActivityView({super.key});

  static const _activeGreen = Color(0xFF1B8A5A);
  static const _soonAmber = Color(0xFFC27803);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorLavenderBg,
      appBar: const CommonAppBarWidget(
        title: 'Hot Activities',
        subtitle: 'Events, leagues & prize pools',
        trailingIcon: Icons.local_fire_department_rounded,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.activities.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppLightUi.pink),
          );
        }

        if (controller.activities.isEmpty) {
          return _emptyState();
        }

        return RefreshIndicator(
          color: AppLightUi.pink,
          backgroundColor: AppLightUi.card,
          onRefresh: controller.fetchActivities,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            itemCount: controller.activities.length,
            separatorBuilder: (_, __) => Spacing.v16,
            itemBuilder: (context, index) {
              return _activityCard(controller.activities[index], index);
            },
          ),
        );
      }),
    );
  }

  Widget _activityCard(Map<String, dynamic> act, int index) {
    final gradients = (act['gradient'] as List?)?.cast<int>() ??
        const [0xFFFF5C9A, 0xFFB14DFF];
    final start = Color(gradients[0]);
    final end = Color(gradients.length > 1 ? gradients[1] : gradients[0]);
    final isSoon = act['status'] == 'Starting Soon';
    final isJoined = act['isJoined'] == true;
    final statusColor = isSoon ? _soonAmber : _activeGreen;

    return Container(
      decoration: AppLightUi.cardDecoration(radius: 22),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Accent hero strip — keeps color energy without washing the CTA
          Container(
            height: 88,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [start, end],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -18,
                  top: -22,
                  child: _orb(kColorWhite.withValues(alpha: 0.18), 90),
                ),
                Positioned(
                  left: -12,
                  bottom: -28,
                  child: _orb(kColorWhite.withValues(alpha: 0.12), 80),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _statusChip(
                        label: act['status']?.toString() ?? 'Active',
                        color: statusColor,
                      ),
                      const Spacer(),
                      _timeChip(act['timeLeft']?.toString() ?? ''),
                    ],
                  ),
                ),
                Positioned(
                  left: 14,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kColorWhite.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: kColorWhite.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Icon(
                      _iconForIndex(index),
                      color: kColorWhite,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BoldText(
                  text: act['title']?.toString() ?? '',
                  fontSize: TextStyles.k16FontSize,
                  color: AppLightUi.title,
                ),
                Spacing.v6,
                AppText(
                  text: act['desc']?.toString() ?? '',
                  fontSize: TextStyles.k12FontSize,
                  color: AppLightUi.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                Spacing.v16,
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: start.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: start.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.emoji_events_rounded,
                              size: 16,
                              color: start,
                            ),
                            Spacing.h6,
                            Expanded(
                              child: AppText(
                                text: isSoon
                                    ? 'Coming soon — set a reminder'
                                    : 'Live event — join to compete',
                                fontSize: TextStyles.k10FontSize,
                                color: AppLightUi.body,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Spacing.h10,
                    _ctaButton(
                      label: isJoined
                          ? 'Joined'
                          : isSoon
                          ? 'Notify Me'
                          : 'Join Now',
                      enabled: !isJoined,
                      onTap: () => controller.openActivityDetails(
                        act['title']?.toString() ?? '',
                      ),
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

  Widget _statusChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: kColorWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: kColorBlack.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Spacing.h6,
          SemiBoldText(
            text: label,
            fontSize: TextStyles.k10FontSize,
            color: color,
          ),
        ],
      ),
    );
  }

  Widget _timeChip(String timeLeft) {
    if (timeLeft.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: kColorBlack.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_rounded, color: kColorWhite, size: 13),
          Spacing.h4,
          AppText(
            text: timeLeft,
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite,
          ),
        ],
      ),
    );
  }

  Widget _ctaButton({
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: enabled ? AppLightUi.familyCtaGradient : null,
            color: enabled ? null : const Color(0xFFE8DEEF),
            borderRadius: BorderRadius.circular(14),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppLightUi.pink.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: SemiBoldText(
              text: label,
              fontSize: TextStyles.k12FontSize,
              color: enabled ? kColorWhite : AppLightUi.subtitle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _orb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  IconData _iconForIndex(int index) {
    const icons = [
      Icons.sports_esports_rounded,
      Icons.favorite_rounded,
      Icons.flash_on_rounded,
      Icons.card_giftcard_rounded,
    ];
    return icons[index % icons.length];
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DatingEmptyHero(
              style: DatingEmptyHeroStyle.sparks,
              size: 160,
              accentColors: [AppLightUi.pink, AppLightUi.gold],
            ),
            Spacing.v16,
            const SemiBoldText(
              text: 'No hot activities yet',
              fontSize: TextStyles.k18FontSize,
              color: AppLightUi.title,
              align: TextAlign.center,
            ),
            Spacing.v8,
            const AppText(
              text:
                  'New events and challenges will show up here. Pull to refresh or check back soon!',
              fontSize: TextStyles.k12FontSize,
              color: AppLightUi.subtitle,
              align: TextAlign.center,
            ),
            Spacing.v24,
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: controller.fetchActivities,
                borderRadius: BorderRadius.circular(16),
                child: Ink(
                  height: 44,
                  width: 160,
                  decoration: BoxDecoration(
                    gradient: AppLightUi.familyCtaGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppLightUi.pink.withValues(alpha: 0.28),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: SemiBoldText(
                      text: 'Refresh',
                      fontSize: TextStyles.k14FontSize,
                      color: kColorWhite,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
