import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/app_widgets/dating_empty_hero.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/visitors_controller.dart';

class VisitorsView extends GetView<VisitorsController> {
  const VisitorsView({super.key});

  static const double _avatarSize = 46;
  static const double _frameExtent = _avatarSize * 1.34;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorLavenderBg,
      appBar: const CommonAppBarWidget(
        title: 'Profile Visitors',
        subtitle: 'Who checked your profile lately',
        trailingIcon: Icons.visibility_rounded,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.visitors.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppLightUi.pink),
          );
        }

        if (controller.visitors.isEmpty) {
          return _emptyState();
        }

        return RefreshIndicator(
          color: AppLightUi.pink,
          backgroundColor: AppLightUi.card,
          onRefresh: controller.loadVisitors,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            itemCount: controller.visitors.length,
            separatorBuilder: (_, __) => Spacing.v12,
            itemBuilder: (context, index) => _visitorCard(index),
          ),
        );
      }),
    );
  }

  Widget _visitorCard(int index) {
    final visitor = controller.visitors[index];
    final isFollowing = visitor['isFollowing'] == true;
    final vipBadge = visitor['vip']?.toString() ?? '';
    final level = visitor['level'] is int
        ? visitor['level'] as int
        : int.tryParse('${visitor['level']}') ?? 0;
    final name = visitor['name']?.toString() ?? 'Unknown User';
    final avatarUrl = visitor['avatarUrl']?.toString() ?? '';
    final frameUrl = visitor['frameUrl']?.toString();
    final userId = visitor['id']?.toString() ?? '';
    final time = visitor['time']?.toString() ?? 'Just now';
    final vipColor = _vipColor(vipBadge);

    return Container(
      constraints: const BoxConstraints(minHeight: 84),
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
      decoration: AppLightUi.cardDecoration(radius: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _framedAvatar(
            name: name,
            avatarUrl: avatarUrl,
            frameUrl: frameUrl,
            seed: userId.isNotEmpty ? userId : name,
          ),
          Spacing.h8,
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: SemiBoldText(
                        text: name,
                        fontSize: TextStyles.k14FontSize,
                        color: AppLightUi.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (vipBadge.isNotEmpty) ...[
                      Spacing.h6,
                      _vipChip(vipBadge, vipColor),
                    ],
                  ],
                ),
                Spacing.v6,
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppLightUi.familyCtaGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: AppText(
                        text: 'Lv.$level',
                        fontSize: TextStyles.k10FontSize,
                        color: kColorWhite,
                      ),
                    ),
                    Spacing.h8,
                    const Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: AppLightUi.subtitle,
                    ),
                    Spacing.h4,
                    Flexible(
                      child: AppText(
                        text: time,
                        fontSize: TextStyles.k12FontSize,
                        color: AppLightUi.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Spacing.h8,
          _actionButton(
            label: isFollowing ? 'Following' : 'Follow',
            following: isFollowing,
            onTap: () => controller.toggleFollow(index),
          ),
        ],
      ),
    );
  }

  /// Same framed-avatar treatment as Messages inbox (real SVGA/image frames).
  Widget _framedAvatar({
    required String name,
    required String avatarUrl,
    required String? frameUrl,
    required String seed,
  }) {
    return SizedBox(
      width: _frameExtent,
      height: _frameExtent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: _frameExtent,
            height: _frameExtent,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppLightUi.glossRingGradient,
              boxShadow: [
                BoxShadow(
                  color: AppLightUi.title.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          Container(
            width: _frameExtent - 3.5,
            height: _frameExtent - 3.5,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: kColorWhite,
            ),
          ),
          FramedUserAvatar(
            name: name,
            imageUrl: avatarUrl.isNotEmpty ? avatarUrl : null,
            frameUrl: (frameUrl != null && frameUrl.trim().isNotEmpty)
                ? frameUrl
                : null,
            frameSeed: seed,
            size: _avatarSize,
            fontSize: TextStyles.k12FontSize,
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required bool following,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 36,
          width: 96,
          decoration: BoxDecoration(
            gradient: following ? null : AppLightUi.familyCtaGradient,
            color: following ? AppLightUi.cardSoft : null,
            borderRadius: BorderRadius.circular(16),
            border: following
                ? Border.all(color: AppLightUi.borderStrong)
                : null,
            boxShadow: following
                ? null
                : [
                    BoxShadow(
                      color: AppLightUi.pink.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: SemiBoldText(
              text: label,
              fontSize: TextStyles.k12FontSize,
              color: following ? AppLightUi.title : kColorWhite,
            ),
          ),
        ),
      ),
    );
  }

  Widget _vipChip(String vip, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: AppText(
        text: vip,
        fontSize: TextStyles.k8FontSize,
        color: color,
      ),
    );
  }

  Color _vipColor(String vip) {
    switch (vip.toUpperCase()) {
      case 'SVIP':
        return const Color(0xFFB7791F);
      case 'VIP':
        return AppLightUi.violet;
      default:
        return AppLightUi.pink;
    }
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
              accentColors: [AppLightUi.violet, AppLightUi.pink],
            ),
            Spacing.v16,
            const SemiBoldText(
              text: 'No visitors yet',
              fontSize: TextStyles.k18FontSize,
              color: AppLightUi.title,
              align: TextAlign.center,
            ),
            Spacing.v8,
            const AppText(
              text: 'Share your profile to attract more fans and visitors!',
              fontSize: TextStyles.k12FontSize,
              color: AppLightUi.subtitle,
              align: TextAlign.center,
            ),
            Spacing.v24,
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: controller.loadVisitors,
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
