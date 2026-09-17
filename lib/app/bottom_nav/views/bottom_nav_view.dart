import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
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

  static const _barColor = Color(0xFF6B4EFF);
  static const _activeButton = Color(0xFFFF2E83);
  static const _iconIdle = Color(0xFFE8DEFF);
  static const _iconActive = kColorWhite;

  static const _navIcons = <IconData>[
    Icons.travel_explore_rounded, // Discover
    Icons.meeting_room_rounded, // Rooms
    Icons.videocam_rounded, // Go Live
    Icons.forum_rounded, // Messages
    Icons.account_circle_rounded, // Profile
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorLavenderBg,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Obx(() {
            switch (controller.selectedIndex.value) {
              case 0:
                return const DiscoverTabView();
              case 1:
                return const RoomsTabView();
              case 2:
                return const LiveRoomView();
              case 3:
                return const MessagesTabView();
              case 4:
                return ProfileTabView(
                  onLogoutPressed: controller.onLogoutPressed,
                );
              default:
                return Spacing.shrink;
            }
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
        final selected = controller.selectedIndex.value;
        return CurvedNavigationBar(
          index: selected,
          height: 62,
          backgroundColor: Colors.transparent,
          color: _barColor,
          buttonBackgroundColor: _activeButton,
          animationCurve: Curves.easeOutCubic,
          animationDuration: const Duration(milliseconds: 380),
          items: List.generate(_navIcons.length, (i) {
            final isActive = selected == i;
            return Icon(
              _navIcons[i],
              size: isActive ? 30 : 26,
              color: isActive ? _iconActive : _iconIdle,
            );
          }),
          onTap: controller.onNavBarTabSelected,
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
