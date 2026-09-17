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
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/bottom_nav_controller.dart';

/// Figma Spark bottom nav — dark glass dock + neon selected / muted deselected icons.
class BottomNavView extends GetView<BottomNavController> {
  const BottomNavView({super.key});

  static const _idle = Color(0xFF9D8EC0);
  static const _barBg = Color(0xF2150F2F); // rgba(21,15,47,0.95)
  static const _discover = Color(0xFFFF5388);
  static const _rooms = Color(0xFFC084FC);
  static const _messages = Color(0xFFFF5388);
  static const _profile = Color(0xFFFFD700);
  static const _livePink = Color(0xFFFF2A7A);
  static const _liveRose = Color(0xFFE11D48);
  static const _liveViolet = Color(0xFF8017DE);

  /// Opaque bar content height (home-indicator inset is added separately).
  static const double barHeight = 72;

  /// How far the Live FAB sits above the bar top.
  static const double liveFabLift = 18;

  static const double liveFabSize = 56;

  static const _tabs = <({
    String label,
    String onIcon,
    String offIcon,
    Color accent,
  })>[
    (
      label: 'Discover',
      onIcon: kNavDiscoverOn,
      offIcon: kNavDiscoverOff,
      accent: _discover,
    ),
    (
      label: 'Rooms',
      onIcon: kNavRoomsOn,
      offIcon: kNavRoomsOff,
      accent: _rooms,
    ),
    (
      label: 'Live',
      onIcon: '',
      offIcon: '',
      accent: _livePink,
    ),
    (
      label: 'Messages',
      onIcon: kNavMessagesOn,
      offIcon: kNavMessagesOff,
      accent: _messages,
    ),
    (
      label: 'Profile',
      onIcon: kNavProfileOn,
      offIcon: kNavProfileOff,
      accent: _profile,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: kColorLavenderBg,
      // FAB lifts into the body; body is padded so list content isn't covered.
      extendBody: true,
      body: Obx(() {
        final navVisible = !controller.permissionBlocked.value;
        final mq = MediaQuery.of(context);
        // Clear full opaque dock (bar + home indicator). Zero bottom padding
        // so tab SafeAreas don't double-count the inset.
        return MediaQuery(
          data: mq.copyWith(
            padding: mq.padding.copyWith(bottom: 0),
            viewPadding: mq.viewPadding.copyWith(bottom: 0),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: navVisible ? barHeight + bottomInset : 0,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                switch (controller.selectedIndex.value) {
                  0 => const DiscoverTabView(),
                  1 => const RoomsTabView(),
                  2 => const LiveRoomView(),
                  3 => const MessagesTabView(),
                  4 => ProfileTabView(
                      onLogoutPressed: controller.onLogoutPressed,
                    ),
                  _ => Spacing.shrink,
                },
                if (controller.permissionBlocked.value)
                  _permissionBlockedOverlay(),
              ],
            ),
          ),
        );
      }),
      bottomNavigationBar: Obx(() {
        if (controller.permissionBlocked.value) {
          return const SizedBox.shrink();
        }
        return _SparkBottomNavBar(
          selectedIndex: controller.selectedIndex.value,
          bottomInset: bottomInset,
          onTap: controller.onNavBarTabSelected,
          tabs: _tabs,
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

class _SparkBottomNavBar extends StatelessWidget {
  const _SparkBottomNavBar({
    required this.selectedIndex,
    required this.bottomInset,
    required this.onTap,
    required this.tabs,
  });

  final int selectedIndex;
  final double bottomInset;
  final ValueChanged<int> onTap;
  final List<
      ({
        String label,
        String onIcon,
        String offIcon,
        Color accent,
      })> tabs;

  @override
  Widget build(BuildContext context) {
    // Extra top space so the elevated Live FAB isn't clipped by the scaffold.
    final topLift = BottomNavView.liveFabLift;
    final totalHeight =
        topLift + BottomNavView.barHeight + bottomInset;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Opaque glass bar (labels + side icons).
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  decoration: BoxDecoration(
                    color: BottomNavView._barBg,
                    border: Border(
                      top: BorderSide(
                        color: kColorWhite.withValues(alpha: 0.10),
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.55),
                        blurRadius: 30,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    height: BottomNavView.barHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: List.generate(tabs.length, (i) {
                        final isLive = i == BottomNavController.goLiveTabIndex;
                        if (isLive) {
                          return Expanded(
                            child: _LiveLabelSlot(
                              selected: selectedIndex == i,
                              onTap: () => onTap(i),
                            ),
                          );
                        }
                        return Expanded(
                          child: _SideTab(
                            label: tabs[i].label,
                            onIcon: tabs[i].onIcon,
                            offIcon: tabs[i].offIcon,
                            accent: tabs[i].accent,
                            selected: selectedIndex == i,
                            showMessageBadge:
                                i == BottomNavController.messagesTabIndex,
                            onTap: () => onTap(i),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Center column keeps equal spacing; Live chrome is drawn as one unit below.
          // Live FAB + "Live" label sit together so the text stays under the icon.
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset + 6,
            child: Center(
              child: _LiveFabWithLabel(
                selected: selectedIndex == BottomNavController.goLiveTabIndex,
                onTap: () => onTap(BottomNavController.goLiveTabIndex),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideTab extends StatelessWidget {
  const _SideTab({
    required this.label,
    required this.onIcon,
    required this.offIcon,
    required this.accent,
    required this.selected,
    required this.onTap,
    this.showMessageBadge = false,
  });

  final String label;
  final String onIcon;
  final String offIcon;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;
  final bool showMessageBadge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? accent : BottomNavView._idle;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 40,
              height: 28,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (selected)
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: 0.14),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.32),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  SvgPicture.asset(
                    selected ? onIcon : offIcon,
                    width: 26,
                    height: 26,
                  ),
                  if (showMessageBadge)
                    Positioned(
                      right: -2,
                      top: -4,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 15),
                        height: 15,
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: BottomNavView._livePink,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(0xFF150F2F),
                            width: 1,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '3',
                            style: TextStyle(
                              color: kColorWhite,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                height: 1.2,
                letterSpacing: -0.2,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            SizedBox(
              height: 4,
              child: AnimatedOpacity(
                opacity: selected ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Center slot — empty hit target; label lives under the FAB column.
class _LiveLabelSlot extends StatelessWidget {
  const _LiveLabelSlot({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: const SizedBox.expand(),
    );
  }
}

/// Live circle + "Live" caption + active dot as one column (caption always under icon).
class _LiveFabWithLabel extends StatelessWidget {
  const _LiveFabWithLabel({required this.selected, required this.onTap});

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
          _LiveFabButton(selected: selected),
          const SizedBox(height: 4),
          Text(
            'Live',
            maxLines: 1,
            style: TextStyle(
              fontSize: 10,
              height: 1.2,
              letterSpacing: -0.2,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? BottomNavView._discover : BottomNavView._idle,
            ),
          ),
          const SizedBox(height: 3),
          SizedBox(
            height: 4,
            child: AnimatedOpacity(
              opacity: selected ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: BottomNavView._discover,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveFabButton extends StatelessWidget {
  const _LiveFabButton({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: BottomNavView.liveFabSize,
      height: BottomNavView.liveFabSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: selected
            ? const LinearGradient(
                begin: Alignment(-0.6, -1),
                end: Alignment(0.8, 1),
                colors: [
                  BottomNavView._livePink,
                  BottomNavView._liveRose,
                  BottomNavView._liveViolet,
                ],
              )
            : null,
        color: selected ? null : const Color(0xFF1C153B),
        border: Border.all(
          color: selected
              ? kColorWhite.withValues(alpha: 0.40)
              : BottomNavView._idle.withValues(alpha: 0.55),
          width: selected ? 2 : 1.5,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: BottomNavView._livePink.withValues(alpha: 0.45),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: selected ? _liveSelectedGlyph() : _liveIdleGlyph(),
        ),
      ),
    );
  }

  Widget _liveSelectedGlyph() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.sensors_rounded,
          size: 11,
          color: kColorWhite.withValues(alpha: 0.95),
        ),
        const SizedBox(height: 1),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 11,
              decoration: BoxDecoration(
                color: kColorWhite,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Center(
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: BottomNavView._livePink,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            CustomPaint(
              size: const Size(4, 7),
              painter: _LensConePainter(color: kColorWhite),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: kColorWhite,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'LIVE',
            style: TextStyle(
              color: Color(0xFFE60067),
              fontSize: 7,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _liveIdleGlyph() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.videocam_outlined, size: 20, color: BottomNavView._idle),
        const SizedBox(height: 2),
        Text(
          'LIVE',
          style: TextStyle(
            color: BottomNavView._idle,
            fontSize: 7,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _LensConePainter extends CustomPainter {
  _LensConePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 1)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, size.height - 1)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _LensConePainter oldDelegate) =>
      oldDelegate.color != color;
}
