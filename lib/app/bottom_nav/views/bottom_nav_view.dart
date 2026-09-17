import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/discover/discover_tab/views/discover_tab_view.dart';
import 'package:qobo_one_live/app/user_flow/live_room/views/live_room_view.dart';
import 'package:qobo_one_live/app/user_flow/live_room/views/rooms_tab_view.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/views/messages_tab_view.dart';
import 'package:qobo_one_live/app/user_flow/profile_tab/views/profile_tab_view.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/bottom_nav_controller.dart';

class BottomNavView extends GetView<BottomNavController> {
  const BottomNavView({super.key});

  /// Cool dating-app icons (labels stay from [BottomNavController.items]).
  static const _tabIcons = <(IconData, IconData)>[
    (Icons.explore_outlined, Icons.explore_rounded), // Discover
    (Icons.meeting_room_outlined, Icons.meeting_room_rounded), // Rooms
    (Icons.videocam_rounded, Icons.videocam_rounded), // Go Live (FAB)
    (Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded), // Messages
    (Icons.person_outline_rounded, Icons.person_rounded), // Profile
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: kColorLavenderBg,
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
        return Padding(
          padding: EdgeInsets.fromLTRB(14, 0, 14, bottomInset + 10),
          child: SizedBox(
            height: 78,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                // Frosted dating glass bar.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.92),
                              const Color(0xFFFFF0F7).withValues(alpha: 0.9),
                              Colors.white.withValues(alpha: 0.88),
                            ],
                          ),
                          border: Border.all(
                            color: AppLightUi.borderStrong.withValues(
                              alpha: 0.85,
                            ),
                            width: 1.1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppLightUi.pink.withValues(alpha: 0.14),
                              blurRadius: 22,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: AppLightUi.title.withValues(alpha: 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          height: 64,
                          child: Row(
                            children: List.generate(
                              controller.items.length,
                              (index) {
                                final isGoLive =
                                    index == BottomNavController.goLiveTabIndex;
                                if (isGoLive) {
                                  // Reserve center slot for floating FAB.
                                  return const Expanded(child: SizedBox());
                                }
                                final icons = _tabIcons[index];
                                final selected =
                                    controller.selectedIndex.value == index;
                                return Expanded(
                                  child: _DatingNavTab(
                                    label: controller.items[index].label,
                                    icon: icons.$1,
                                    selectedIcon: icons.$2,
                                    selected: selected,
                                    onTap: () =>
                                        controller.onNavBarTabSelected(index),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Floating Go Live heart/video CTA.
                Positioned(
                  top: -6,
                  child: _GoLiveNavAction(
                    label: controller
                        .items[BottomNavController.goLiveTabIndex].label,
                    selected: controller.selectedIndex.value ==
                        BottomNavController.goLiveTabIndex,
                    onTap: () => controller.onNavBarTabSelected(
                      BottomNavController.goLiveTabIndex,
                    ),
                  ),
                ),
              ],
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

class _DatingNavTab extends StatelessWidget {
  const _DatingNavTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? AppLightUi.pink : AppLightUi.muted.withValues(alpha: 0.9);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppLightUi.pink.withValues(alpha: 0.12),
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: selected ? 40 : 34,
              height: selected ? 40 : 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: selected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppLightUi.pink.withValues(alpha: 0.18),
                          AppLightUi.violet.withValues(alpha: 0.14),
                        ],
                      )
                    : null,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppLightUi.pink.withValues(alpha: 0.22),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                selected ? selectedIcon : icon,
                size: selected ? 22 : 20,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: selected
                  ? TextStyles.kSemiBoldPoppins(
                      fontSize: 10,
                      colors: AppLightUi.pink,
                    )
                  : TextStyles.kRegularPoppins(
                      fontSize: 10,
                      colors: AppLightUi.muted,
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF5C9A),
                  Color(0xFFFF2E83),
                  Color(0xFFB14DFF),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: selected ? 0.95 : 0.75),
                width: selected ? 2.4 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppLightUi.pink.withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: AppLightUi.violet.withValues(alpha: 0.28),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.videocam_rounded,
              color: kColorWhite,
              size: 28,
            ),
          ),
          const SizedBox(height: 4),
          SemiBoldText(
            text: label,
            fontSize: TextStyles.k10FontSize,
            color: selected ? AppLightUi.pink : AppLightUi.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
