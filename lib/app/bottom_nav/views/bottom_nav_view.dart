import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/live_room/views/live_room_view.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/bottom_nav_controller.dart';

class BottomNavView extends GetView<BottomNavController> {
  const BottomNavView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorWhite,
      body: Obx(
        () {
          if (controller.selectedIndex.value == 1) {
            return const LiveRoomView();
          }
          return Center(
            // Placeholder center content for tabs not implemented yet.
            child: BoldText(
              text:
                  '${(controller.items[controller.selectedIndex.value].label.isEmpty ? 'Heart' : controller.items[controller.selectedIndex.value].label)} Screen',
              fontSize: TextStyles.k22FontSize,
              color: kColorText,
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: controller.onCenterHeartSelected,
        backgroundColor: kColorWhite,
        elevation: 4,
        shape: const CircleBorder(),
        child: SvgPicture.asset(
          kIconHeart,
          width: 30,
          height: 30,
        ),
      ),
      bottomNavigationBar: Obx(
        () => AnimatedBottomNavigationBar.builder(
          itemCount: controller.navTabIndices.length,
          activeIndex: controller.navBarIndexFromSelected(),
          gapLocation: GapLocation.center,
          notchSmoothness: NotchSmoothness.verySmoothEdge,
          leftCornerRadius: 20,
          rightCornerRadius: 20,
          elevation: 0,
          height: 66,
          backgroundColor: kColorBottomNav,
          onTap: controller.onNavBarTabSelected,
          tabBuilder: (index, isActive) {
            final item = controller.items[controller.navTabIndices[index]];
            final color = isActive ? kColorWhite : kColorHint;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  item.iconPath,
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                ),
                const SizedBox(height: 3),
                AppText(
                  text: item.label,
                  fontSize: TextStyles.k10FontSize,
                  color: color,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
