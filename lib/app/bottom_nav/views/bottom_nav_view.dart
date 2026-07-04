import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/discover/discover_tab/views/discover_tab_view.dart';
import 'package:qobo_one_live/app/user_flow/live_room/views/live_room_view.dart';
import 'package:qobo_one_live/app/user_flow/live_room/views/rooms_tab_view.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/views/messages_tab_view.dart';
import 'package:qobo_one_live/app/user_flow/profile_tab/views/profile_tab_view.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
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

    return Scaffold(
      backgroundColor: kColorWhite,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Obx(() {
            if (controller.selectedIndex.value == 0) {
              return const DiscoverTabView();
            }
            if (controller.selectedIndex.value == 1) {
              return const RoomsTabView();
            }
            if (controller.selectedIndex.value == 2) {
              return const LiveRoomView();
            }
            if (controller.selectedIndex.value == 3) {
              return const MessagesTabView();
            }
            if (controller.selectedIndex.value == 4) {
              return ProfileTabView(
                onLogoutPressed: controller.onLogoutPressed,
              );
            }
            return Spacing.shrink;
          }),
          Obx(() {
            if (!controller.permissionBlocked.value) {
              return const SizedBox.shrink();
            }
            return _permissionBlockedOverlay();
          }),
        ],
      ),
      bottomNavigationBar: Obx(() {
        if (controller.permissionBlocked.value) {
          return const SizedBox.shrink();
        }
        return ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF181A5A).withValues(alpha: 0.86),
                    const Color(0xFF121644).withValues(alpha: 0.93),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(26),
                  topRight: Radius.circular(26),
                ),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 0.7,
                  ),
                ),
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
                              selected:
                                  controller.selectedIndex.value == index &&
                                  index != BottomNavController.goLiveTabIndex,
                              isAction:
                                  index == BottomNavController.goLiveTabIndex,
                              actionSelected:
                                  controller.selectedIndex.value == index,
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
        );
      }),
    );
  }

  Widget _permissionBlockedOverlay() {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.82),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mic_external_on_rounded,
                size: 56,
                color: kColorWhite.withValues(alpha: 0.9),
              ),
              Spacing.v20,
              SemiBoldText(
                text: 'Microphone & camera required',
                fontSize: TextStyles.k20FontSize,
                color: kColorWhite,
                align: TextAlign.center,
              ),
              Spacing.v12,
              AppText(
                text:
                    'Qobo Live needs microphone and camera access for calls and live streaming. Please allow both permissions to continue.',
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite.withValues(alpha: 0.78),
                align: TextAlign.center,
                maxLines: 6,
              ),
              Spacing.v28,
              appButton(
                onPressed: controller.retryMediaPermissions,
                buttonText: 'Allow access',
                isGradient: true,
              ),
              Obx(() {
                if (!controller.showOpenSettings.value) {
                  return const SizedBox.shrink();
                }
                return Column(
                  children: [
                    Spacing.v12,
                    appButton(
                      onPressed: controller.openDeviceSettings,
                      buttonText: 'Open Settings',
                      isGradient: false,
                      buttonColor: Colors.transparent,
                      buttonBorderColor: kColorWhite.withValues(alpha: 0.45),
                      textColor: kColorWhite,
                    ),
                  ],
                );
              }),
            ],
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
    required this.isAction,
    required this.actionSelected,
    required this.iconSize,
    required this.onTap,
  });

  final String label;
  final String iconPath;
  final String selectedIconPath;
  final bool selected;
  final bool isAction;
  final bool actionSelected;
  final double iconSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayIconPath = selected ? selectedIconPath : iconPath;
    final color = selected ? kColorWhite : Colors.white.withValues(alpha: 0.42);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white.withValues(alpha: 0.08),
        highlightColor: Colors.transparent,
        child: isAction
            ? _GoLiveNavAction(
                label: label,
                selected: actionSelected,
                onTap: onTap,
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    displayIconPath,
                    width: iconSize,
                    height: iconSize,
                    fit: BoxFit.contain,
                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  ),
                  Spacing.v6,
                  AppText(
                    text: label,
                    fontSize: TextStyles.k10FontSize,
                    style: selected
                        ? TextStyles.kSemiBoldPoppins(
                            fontSize: TextStyles.k12FontSize,
                            colors: kColorWhite,
                          )
                        : TextStyles.kRegularPoppins(
                            fontSize: TextStyles.k10FontSize,
                            colors: Colors.white.withValues(alpha: 0.45),
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoLiveNavAction extends StatelessWidget {
  const _GoLiveNavAction({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF2C4D), Color(0xFFFF7A45)],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: selected ? 0.72 : 0.28),
                  width: selected ? 1.4 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF3651).withValues(alpha: 0.36),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.videocam_rounded,
                color: kColorWhite,
                size: 25,
              ),
            ),
            Spacing.v4,
            SemiBoldText(
              text: label,
              fontSize: TextStyles.k10FontSize,
              color: selected
                  ? kColorWhite
                  : kColorWhite.withValues(alpha: 0.72),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
