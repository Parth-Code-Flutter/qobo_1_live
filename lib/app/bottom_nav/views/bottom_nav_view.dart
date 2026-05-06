import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/live_room/views/live_room_view.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/generated/locales.g.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/bottom_nav_controller.dart';

class BottomNavView extends GetView<BottomNavController> {
  const BottomNavView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorWhite,
      extendBody: true,
      body: Obx(
        () {
          if (controller.selectedIndex.value == 1) {
            return const LiveRoomView();
          }
          if (controller.selectedIndex.value == 4) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BoldText(
                      text: 'Profile Screen',
                      fontSize: TextStyles.k22FontSize,
                      color: kColorText,
                    ),
                    const SizedBox(height: 16),
                    appButton(
                      onPressed: controller.onLogoutPressed,
                      buttonText: LocaleKeys.logoutButtonText.tr,
                      isGradient: false,
                      buttonColor: kColorPrimary,
                      borderRadius: 14,
                    ),
                  ],
                ),
              ),
            );
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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0x26FFFFFF), width: 0.5)),
          boxShadow: [
            // Soft top shadow to separate nav from active screen background.
            BoxShadow(
              color: Color(0x33000000),
              offset: Offset(0, -2),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Obx(
          () => AnimatedBottomNavigationBar.builder(
            itemCount: controller.navTabIndices.length,
            activeIndex: controller.navBarIndexFromSelected(),
            gapLocation: GapLocation.center,
            notchSmoothness: NotchSmoothness.verySmoothEdge,
            leftCornerRadius: 20,
            rightCornerRadius: 20,
            elevation: 0,
            height: 66,
            backgroundColor: Colors.transparent,
            onTap: controller.onNavBarTabSelected,
            tabBuilder: (index, _) {
              final tabIndex = controller.navTabIndices[index];
              final item = controller.items[tabIndex];
              final isHighlighted = controller.selectedIndex.value == tabIndex;
              final color = isHighlighted ? kColorWhite : kColorHint;
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
                    style: isHighlighted
                        ? TextStyles.kSemiBoldPoppins(
                            fontSize: TextStyles.k10FontSize,
                            colors: color,
                          )
                        : TextStyles.kRegularPoppins(
                            fontSize: TextStyles.k10FontSize,
                            colors: color,
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
