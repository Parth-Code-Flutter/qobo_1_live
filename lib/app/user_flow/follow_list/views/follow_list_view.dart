import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/social_user_card.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/app_widgets/dating_empty_hero.dart';
import 'package:qobo_one_live/utils/app_widgets/rooms_empty_state.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/follow_list_controller.dart';

class FollowListView extends GetView<FollowListController> {
  const FollowListView({super.key});

  static const _tabs = <({int index, String label, IconData icon})>[
    (
      index: FollowListController.friendsTab,
      label: 'Friends',
      icon: Icons.favorite_rounded,
    ),
    (
      index: FollowListController.followingTab,
      label: 'Following',
      icon: Icons.person_rounded,
    ),
    (
      index: FollowListController.followersTab,
      label: 'Followers',
      icon: Icons.groups_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorLavenderBg,
      appBar: const CommonAppBarWidget(
        title: 'Connections',
        subtitle: 'Friends · Following · Followers',
      ),
      body: Column(
        children: [
          Spacing.v10,
          _buildTabs(),
          Spacing.v10,
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: kColorPrimary),
                );
              }
              return _buildList(controller.listForCurrentTab());
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() {
        final selected = controller.tabIndex.value;
        return Container(
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppLightUi.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppLightUi.borderStrong),
            boxShadow: AppLightUi.cardShadow,
          ),
          child: Row(
            children: [
              for (final tab in _tabs)
                Expanded(
                  child: _ConnectionTabCell(
                    label: tab.label,
                    icon: tab.icon,
                    selected: selected == tab.index,
                    onTap: () => controller.changeTab(tab.index),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildList(List<SocialUserCard> users) {
    if (users.isEmpty) {
      return RefreshIndicator(
        color: kColorPrimary,
        onRefresh: controller.loadFollowLists,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                child: RoomsEmptyState(
                  title: _emptyTitle(),
                  subtitle: 'Pull down to refresh your connections',
                  accentColors: const [AppLightUi.pink, AppLightUi.violet],
                  heroStyle: DatingEmptyHeroStyle.sparks,
                  hint: 'Pull down to refresh',
                ),
              ),
            );
          },
        ),
      );
    }

    return RefreshIndicator(
      color: kColorPrimary,
      onRefresh: controller.loadFollowLists,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: users.length,
        separatorBuilder: (_, __) => Spacing.v10,
        itemBuilder: (context, index) {
          final user = users[index];
          final isProcessing = controller.processingFollowId.value == user.id;
          final subtitle = [
            if (user.country.isNotEmpty) user.country,
            if (user.level > 0) 'Level ${user.level}',
            if (user.isMutual) 'Friends',
          ].join(' · ');

          return Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            decoration: BoxDecoration(
              color: AppLightUi.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppLightUi.border),
              boxShadow: AppLightUi.cardShadow,
            ),
            child: Row(
              children: [
                AppUserAvatar(
                  name: user.name,
                  imageUrl: user.displayPicture,
                  frameUrl: user.avatarFrameUrl,
                  frameSeed: user.id,
                  size: 52,
                ),
                Spacing.h12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SemiBoldText(
                        text: user.name,
                        fontSize: TextStyles.k14FontSize,
                        color: AppLightUi.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle.isNotEmpty) ...[
                        Spacing.v4,
                        AppText(
                          text: subtitle,
                          fontSize: TextStyles.k10FontSize,
                          color: AppLightUi.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Spacing.h8,
                _FollowActionButton(
                  isFollowing: user.isFollowing,
                  isProcessing: isProcessing,
                  label: _followButtonLabel(user),
                  onTap: isProcessing
                      ? null
                      : () => controller.toggleFollow(user),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _followButtonLabel(SocialUserCard user) {
    if (user.isFollowing) return 'Following';
    // Followers tab: nudge with Follow back when they follow you.
    if (controller.tabIndex.value == FollowListController.followersTab &&
        !user.isMutual) {
      return 'Follow back';
    }
    return 'Follow';
  }

  String _emptyTitle() {
    return switch (controller.tabIndex.value) {
      FollowListController.friendsTab => 'No friends yet',
      FollowListController.followingTab => 'Not following anyone',
      _ => 'No followers yet',
    };
  }
}

class _FollowActionButton extends StatelessWidget {
  const _FollowActionButton({
    required this.isFollowing,
    required this.isProcessing,
    required this.label,
    required this.onTap,
  });

  final bool isFollowing;
  final bool isProcessing;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final followingStyle = isFollowing;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: followingStyle ? 102 : 96,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: followingStyle ? null : AppLightUi.familyCtaGradient,
            color: followingStyle ? AppLightUi.cardSoft : null,
            border: Border.all(
              color: followingStyle
                  ? AppLightUi.borderStrong
                  : Colors.transparent,
            ),
            boxShadow: followingStyle
                ? null
                : [
                    BoxShadow(
                      color: AppLightUi.pink.withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: isProcessing
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: followingStyle ? AppLightUi.violet : kColorWhite,
                  ),
                )
              : SemiBoldText(
                  text: label,
                  fontSize: TextStyles.k10FontSize,
                  color: followingStyle ? AppLightUi.title : kColorWhite,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
        ),
      ),
    );
  }
}

class _ConnectionTabCell extends StatelessWidget {
  const _ConnectionTabCell({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: selected ? AppLightUi.familyCtaGradient : null,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppLightUi.pink.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? kColorWhite : AppLightUi.muted,
              ),
              const SizedBox(height: 2),
              SemiBoldText(
                text: label,
                fontSize: TextStyles.k10FontSize,
                color: selected ? kColorWhite : AppLightUi.body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
