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
import 'package:qobo_one_live/utils/app_widgets/glossy_auth_field_border.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/bottom_nav_controller.dart';

class BottomNavView extends GetView<BottomNavController> {
  const BottomNavView({super.key});

  /// Per-tab colorful icons (outline / filled) + accent color.
  static const _tabs = <_NavTabStyle>[
    _NavTabStyle(
      icon: Icons.explore_outlined,
      selectedIcon: Icons.explore_rounded,
      color: Color(0xFF5B8CFF), // Discover — sky
    ),
    _NavTabStyle(
      icon: Icons.meeting_room_outlined,
      selectedIcon: Icons.meeting_room_rounded,
      color: Color(0xFFFFB020), // Rooms — gold
    ),
    _NavTabStyle(
      icon: Icons.videocam_rounded,
      selectedIcon: Icons.videocam_rounded,
      color: Color(0xFFFF2E83), // Go Live — hot pink
    ),
    _NavTabStyle(
      icon: Icons.chat_bubble_outline_rounded,
      selectedIcon: Icons.chat_bubble_rounded,
      color: Color(0xFFFF6B8A), // Messages — rose
    ),
    _NavTabStyle(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      color: Color(0xFF9B6DFF), // Profile — violet
    ),
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
        // Float above home indicator — reads as a glass dock, not edge-stuck.
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 18),
          child: SizedBox(
            height: 84,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _FloatingGlossyNavBar(
                    child: SizedBox(
                      height: 66,
                      child: Row(
                        children: List.generate(
                          controller.items.length,
                          (index) {
                            final isGoLive =
                                index == BottomNavController.goLiveTabIndex;
                            if (isGoLive) {
                              return const Expanded(child: SizedBox());
                            }
                            final style = _tabs[index];
                            final selected =
                                controller.selectedIndex.value == index;
                            return Expanded(
                              child: _DatingNavTab(
                                label: controller.items[index].label,
                                icon: style.icon,
                                selectedIcon: style.selectedIcon,
                                accent: style.color,
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
                Positioned(
                  top: -10,
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

class _NavTabStyle {
  const _NavTabStyle({
    required this.icon,
    required this.selectedIcon,
    required this.color,
  });

  final IconData icon;
  final IconData selectedIcon;
  final Color color;
}

/// Floating glass dock with sweep glossy ring — no drop shadow.
class _FloatingGlossyNavBar extends StatelessWidget {
  const _FloatingGlossyNavBar({required this.child});

  final Widget child;

  static const _radius = 30.0;
  static const _borderWidth = 1.7;

  @override
  Widget build(BuildContext context) {
    final innerRadius = _radius - _borderWidth;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        gradient: GlossyAuthFieldBorder.authSweepGradient,
      ),
      padding: const EdgeInsets.all(_borderWidth),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(innerRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(innerRadius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.94),
                  const Color(0xFFFFF5FA).withValues(alpha: 0.9),
                  Colors.white.withValues(alpha: 0.9),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.65),
                width: 0.6,
              ),
            ),
            child: child,
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
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? accent : accent.withValues(alpha: 0.72);
    final labelColor =
        selected ? accent : AppLightUi.muted.withValues(alpha: 0.95);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: accent.withValues(alpha: 0.14),
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutBack,
              width: selected ? 42 : 36,
              height: selected ? 42 : 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: selected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.withValues(alpha: 0.22),
                          accent.withValues(alpha: 0.08),
                        ],
                      )
                    : null,
                border: selected
                    ? Border.all(
                        color: accent.withValues(alpha: 0.35),
                        width: 1,
                      )
                    : null,
              ),
              child: Icon(
                selected ? selectedIcon : icon,
                size: selected ? 23 : 21,
                color: iconColor,
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
                      colors: labelColor,
                    )
                  : TextStyles.kRegularPoppins(
                      fontSize: 10,
                      colors: labelColor,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoLiveNavAction extends StatefulWidget {
  const _GoLiveNavAction({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_GoLiveNavAction> createState() => _GoLiveNavActionState();
}

class _GoLiveNavActionState extends State<_GoLiveNavAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              final t = Curves.easeInOut.transform(_pulse.value);
              final scale = 1.0 + (t * 0.04);
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: GlossyAuthFieldBorder.authSweepGradient,
              ),
              padding: const EdgeInsets.all(2.2),
              child: DecoratedBox(
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
                    color: Colors.white.withValues(
                      alpha: widget.selected ? 0.95 : 0.8,
                    ),
                    width: widget.selected ? 2.2 : 1.6,
                  ),
                ),
                child: const Icon(
                  Icons.videocam_rounded,
                  color: kColorWhite,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SemiBoldText(
            text: widget.label,
            fontSize: TextStyles.k10FontSize,
            color: widget.selected
                ? const Color(0xFFFF2E83)
                : AppLightUi.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
