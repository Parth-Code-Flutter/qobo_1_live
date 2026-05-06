import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
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
        () => Center(
          // Placeholder center content for each tab for now.
          child: BoldText(
            text: '${controller.items[controller.selectedIndex.value].label} Screen',
            fontSize: TextStyles.k22FontSize,
            color: kColorText,
          ),
        ),
      ),
      bottomNavigationBar: Obx(
        () => AnimatedBottomNavigationBar.builder(
          itemCount: controller.items.length,
          activeIndex: controller.selectedIndex.value,
          gapLocation: GapLocation.none,
          notchSmoothness: NotchSmoothness.sharpEdge,
          elevation: 0,
          height: 66,
          backgroundColor: kColorBottomNav,
          onTap: controller.onTabSelected,
          tabBuilder: (index, isActive) {
            final item = controller.items[index];
            final color = isActive ? kColorWhite : kColorHint;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: color, size: 20),
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
