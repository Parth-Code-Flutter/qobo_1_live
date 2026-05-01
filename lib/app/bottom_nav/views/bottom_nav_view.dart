import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/app/user_flow/live_room/views/live_room_view.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/bottom_nav_controller.dart';

class BottomNavView extends GetView<BottomNavController> {
  const BottomNavView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorBottomNav,
      body: Obx(_buildTabBody),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  /// Shows dedicated tab screens; placeholders stay until real pages are ready.
  Widget _buildTabBody() {
    switch (controller.selectedIndex.value) {
      case 0:
        return _buildDefaultTabScreen('Discover');
      case 1:
        return const LiveRoomView();
      case 2:
        return _buildDefaultTabScreen('Heart');
      case 3:
        return _buildDefaultTabScreen('Messages');
      case 4:
        return _buildDefaultTabScreen('Profile');
      default:
        return _buildDefaultTabScreen('Discover');
    }
  }

  Widget _buildDefaultTabScreen(String title) {
    return SafeArea(
      child: Center(
        child: BoldText(
          text: '$title Page',
          fontSize: TextStyles.k24FontSize,
          color: kColorWhite,
        ),
      ),
    );
  }

  /// Builds a custom bottom bar matching the shared design reference.
  Widget _buildBottomNavBar() {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: kColorBottomNav,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Obx(
          () => Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildNavItem(0),
              _buildNavItem(1),
              _buildCenterActionItem(),
              _buildNavItem(3),
              _buildNavItem(4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = controller.items[index];
    final isSelected = controller.selectedIndex.value == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => controller.onTabSelected(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 18,
              color: isSelected ? kColorWhite : kColorHint,
            ),
            const SizedBox(height: 3),
            AppText(
              text: item.label,
              fontSize: 10,
              color: isSelected ? kColorWhite : kColorHint,
              align: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Special center tab with emphasized circular action style.
  Widget _buildCenterActionItem() {
    final isSelected = controller.selectedIndex.value == 2;

    return Expanded(
      child: GestureDetector(
        onTap: () => controller.onTabSelected(2),
        behavior: HitTestBehavior.opaque,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected ? kColorRed : kColorPrimary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border,
              color: kColorWhite,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
