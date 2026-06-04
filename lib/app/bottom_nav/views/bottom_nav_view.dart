import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/discover/discover_tab/views/discover_tab_view.dart';
import 'package:qobo_one_live/app/user_flow/live_room/views/live_room_view.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/views/messages_tab_view.dart';
import 'package:qobo_one_live/app/user_flow/profile_tab/views/profile_tab_view.dart';
import 'package:qobo_one_live/app/user_flow/live_action/views/live_action_view.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/theme/theme_context.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/bottom_nav_controller.dart';

class BottomNavView extends GetView<BottomNavController> {
  const BottomNavView({super.key});

  static const double _iconSize = 18;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: Obx(() {
        if (controller.selectedIndex.value == 0) {
          return const DiscoverTabView();
        }
        if (controller.selectedIndex.value == 1) {
          return const LiveRoomView();
        }
        if (controller.selectedIndex.value == 2) {
          return const LiveActionView();
        }
        if (controller.selectedIndex.value == 3) {
          return const MessagesTabView();
        }
        if (controller.selectedIndex.value == 4) {
          return ProfileTabView(onLogoutPressed: controller.onLogoutPressed);
        }
        return Spacing.shrink;
      }),
      bottomNavigationBar: ClipRect(
        child: Obx(
          () => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [colors.navBarTop, colors.navBarBottom],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(26),
                  topRight: Radius.circular(26),
                ),
                border: Border(
                  top: BorderSide(color: colors.navBarBorder, width: 0.7),
                ),
                boxShadow: colors.isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, -2),
                        ),
                      ],
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: SizedBox(
                  height: 84,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: List.generate(
                          controller.items.length,
                          (index) => Expanded(
                            child: _BottomNavTab(
                              label: controller.items[index].label,
                              iconPath: controller.items[index].iconPath,
                              selectedIconPath:
                                  controller.items[index].selectedIconPath,
                              selected: controller.selectedIndex.value == index,
                              iconSize: _iconSize,
                              onTap: () =>
                                  controller.onNavBarTabSelected(index),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavTab extends StatelessWidget {
  const _BottomNavTab({
    required this.label,
    required this.iconPath,
    required this.selectedIconPath,
    required this.selected,
    required this.iconSize,
    required this.onTap,
  });

  final String label;
  final String iconPath;
  final String selectedIconPath;
  final bool selected;
  final double iconSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isCenterTab = iconPath == kIconHeart;
    final displayIconPath = selected ? selectedIconPath : iconPath;
    final color = selected
        ? colors.navLabelSelected
        : colors.navLabelUnselected;
    final tintIcon = iconPath != kIconHeart;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: colors.navLabelUnselected.withValues(alpha: 0.12),
        highlightColor: Colors.transparent,
        child: isCenterTab
            ? Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: selected ? 66 : 62,
                  height: selected ? 66 : 62,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE6252F),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE6252F).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      displayIconPath,
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    displayIconPath,
                    width: iconSize,
                    height: iconSize,
                    fit: BoxFit.contain,
                    colorFilter: tintIcon
                        ? ColorFilter.mode(color, BlendMode.srcIn)
                        : null,
                  ),
                  Spacing.v6,
                  AppText(
                    text: label,
                    fontSize: TextStyles.k10FontSize,
                    style: selected
                        ? TextStyles.kSemiBoldPoppins(
                            fontSize: TextStyles.k12FontSize,
                            colors: colors.navLabelSelected,
                          )
                        : TextStyles.kRegularPoppins(
                            fontSize: TextStyles.k10FontSize,
                            colors: colors.navLabelUnselected,
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
