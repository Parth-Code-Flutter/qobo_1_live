import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/follow_list_controller.dart';

class FollowListView extends GetView<FollowListController> {
  const FollowListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              if (controller.tabIndex.value == 0) {
                return _buildList(controller.followingList, isFollowingTab: true);
              } else {
                return _buildList(controller.followersList, isFollowingTab: false);
              }
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

  Widget _buildList(List<Map<String, dynamic>> dataList, {required bool isFollowingTab}) {
    if (dataList.isEmpty) {
      return Center(
        child: AppText(
          text: 'No users found',
          color: kColorHint,
          fontSize: TextStyles.k14FontSize,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: dataList.length,
      separatorBuilder: (_, __) => const Divider(color: kColorBackground, height: 24),
      itemBuilder: (context, index) {
        final user = dataList[index];
        final bool isFollowing = user['isFollowing'];
        
        return Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundImage: AssetImage(user['image']),
            ),
            Spacing.h16,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SemiBoldText(
                    text: user['name'],
                    fontSize: TextStyles.k14FontSize,
                    color: kColorText,
                  ),
                  Spacing.v4,
                  AppText(
                    text: 'ID: 8374921',
                    fontSize: TextStyles.k12FontSize,
                    color: kColorHint,
                  ),
                ],
              ),
            ),
            Spacing.h8,
            SizedBox(
              width: 90,
              height: 32,
              child: appButton(
                onPressed: () => controller.toggleFollow(index, isFollowingTab),
                buttonText: isFollowing ? 'Following' : 'Follow',
                buttonColor: isFollowing ? kColorBackground : kColorPrimary,
                textColor: isFollowing ? kColorText : kColorWhite,
                borderRadius: 16,
              ),
            ),
          ],
        );
      },
    );
  }
}
