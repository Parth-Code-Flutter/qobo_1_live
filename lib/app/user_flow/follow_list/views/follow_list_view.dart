import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/follow_list_controller.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/social_user_card.dart';

class FollowListView extends GetView<FollowListController> {
  const FollowListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorWhite,
      appBar: const CommonAppBarWidget(
        title: 'Connections',
        useMaterialAppBar: true,
      ),
      body: Column(
        children: [
          Spacing.v12,
          _buildTabs(),
          Spacing.v12,
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: kColorPrimary),
                );
              }
              if (controller.tabIndex.value == 0) {
                return _buildList(
                  controller.followingList,
                  isFollowingTab: true,
                );
              }
              return _buildList(
                controller.followersList,
                isFollowingTab: false,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Obx(
        () => Row(
          children: [
            Expanded(child: _tabButton('Following', 0)),
            Spacing.h16,
            Expanded(child: _tabButton('Followers', 1)),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String title, int index) {
    final isSelected = controller.tabIndex.value == index;
    return GestureDetector(
      onTap: () => controller.changeTab(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? kColorPrimary : kColorBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: SemiBoldText(
            text: title,
            fontSize: TextStyles.k14FontSize,
            color: isSelected ? kColorWhite : kColorText,
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<SocialUserCard> users, {required bool isFollowingTab}) {
    if (users.isEmpty) {
      return Center(
        child: AppText(
          text: 'No users found',
          color: kColorHint,
          fontSize: TextStyles.k14FontSize,
        ),
      );
    }

    return RefreshIndicator(
      color: kColorPrimary,
      onRefresh: controller.loadFollowLists,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: users.length,
        separatorBuilder: (_, __) =>
            const Divider(color: kColorBackground, height: 24),
        itemBuilder: (context, index) {
          final user = users[index];
          final isProcessing = controller.processingFollowId.value == user.id;

          return Row(
            children: [
              AppUserAvatar(
                name: user.name,
                imageUrl: user.displayPicture,
                size: 52,
              ),
              Spacing.h16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemiBoldText(
                      text: user.name,
                      fontSize: TextStyles.k14FontSize,
                      color: kColorText,
                    ),
                    if (user.level > 0) ...[
                      Spacing.v4,
                      AppText(
                        text: 'Level ${user.level}',
                        fontSize: TextStyles.k12FontSize,
                        color: kColorHint,
                      ),
                    ],
                  ],
                ),
              ),
              Spacing.h8,
              SizedBox(
                width: 96,
                height: 32,
                child: appButton(
                  onPressed: isProcessing
                      ? () {}
                      : () => controller.toggleFollow(
                          user,
                          isFollowingTab: isFollowingTab,
                        ),
                  buttonText: isProcessing
                      ? '...'
                      : (user.isFollowing ? 'Following' : 'Follow'),
                  buttonColor:
                      user.isFollowing ? kColorBackground : kColorPrimary,
                  textColor: user.isFollowing ? kColorText : kColorWhite,
                  borderRadius: 16,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
