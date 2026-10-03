import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/constants/live_room_ui_colors.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/live_room_controller.dart';

class JoinLiveView extends StatefulWidget {
  const JoinLiveView({super.key});

  @override
  State<JoinLiveView> createState() => _JoinLiveViewState();
}

class _JoinLiveViewState extends State<JoinLiveView> {
  final _liveIdController = TextEditingController();

  static const _thumbSize = 86.0;

  LiveRoomController get controller {
    if (Get.isRegistered<LiveRoomController>()) {
      return Get.find<LiveRoomController>();
    }
    return Get.put(LiveRoomController());
  }

  @override
  void dispose() {
    _liveIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liveRoomController = controller;

    return Scaffold(
      backgroundColor: kColorLavenderBg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: RefreshIndicator(
                color: kColorPrimary,
                backgroundColor: AppLightUi.card,
                onRefresh: liveRoomController.fetchActiveRooms,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                      sliver: SliverToBoxAdapter(
                        child: _manualJoinCard(liveRoomController),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
                      sliver: SliverToBoxAdapter(
                        child: _sectionHeader(liveRoomController),
                      ),
                    ),
                    Obx(() {
                      if (liveRoomController.isLoading.value) {
                        return const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: kColorPrimary,
                            ),
                          ),
                        );
                      }

                      if (liveRoomController.rooms.isEmpty) {
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          child: _emptyState(liveRoomController),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                        sliver: SliverList.separated(
                          itemCount: liveRoomController.rooms.length,
                          separatorBuilder: (_, __) => Spacing.v12,
                          itemBuilder: (context, index) {
                            final room = liveRoomController.rooms[index];
                            return _liveRoomTile(liveRoomController, room);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
      child: Row(
        children: [
          _circleIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: Get.back<void>,
          ),
          Spacing.h12,
          const Expanded(
            child: SemiBoldText(
              text: 'Join Live',
              fontSize: TextStyles.k22FontSize,
              color: AppLightUi.title,
              align: TextAlign.center,
            ),
          ),
          const SizedBox(width: 54),
        ],
      ),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 42,
    Color color = AppLightUi.title,
  }) {
    return Material(
      color: AppLightUi.card,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppLightUi.border),
          ),
          child: Icon(icon, color: color, size: size * 0.43),
        ),
      ),
    );
  }

  Widget _manualJoinCard(LiveRoomController liveRoomController) {
    return Container(
      padding: const EdgeInsets.all(1.4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppLightUi.pink.withValues(alpha: 0.45),
            AppLightUi.violet.withValues(alpha: 0.25),
            AppLightUi.border,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppLightUi.pink.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppLightUi.card,
          borderRadius: BorderRadius.circular(22.6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _manualJoinHeader(),
            Spacing.v16,
            _liveIdField(liveRoomController),
            const SizedBox(height: 14),
            _gradientCta(
              label: 'Join Stream',
              icon: Icons.play_arrow_rounded,
              onTap: () =>
                  liveRoomController.joinManualLive(_liveIdController.text),
            ),
          ],
        ),
      ),
    );
  }

  Widget _manualJoinHeader() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                LiveRoomUiColors.goLiveGradientStart,
                LiveRoomUiColors.goLiveGradientEnd,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: LiveRoomUiColors.goLiveGradientStart.withValues(
                  alpha: 0.30,
                ),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.sensors_rounded,
            color: kColorWhite,
            size: 22,
          ),
        ),
        Spacing.h12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SemiBoldText(
                text: 'Have a stream ID?',
                fontSize: TextStyles.k16FontSize,
                color: AppLightUi.title,
              ),
              const SizedBox(height: 2),
              AppText(
                text: 'Paste it below to jump straight into the live.',
                fontSize: TextStyles.k12FontSize,
                color: AppLightUi.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _liveIdField(LiveRoomController liveRoomController) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: AppLightUi.searchDecoration(radius: 16),
      child: Row(
        children: [
          const Icon(Icons.tag_rounded, color: AppLightUi.pink, size: 20),
          Spacing.h10,
          Expanded(
            child: TextField(
              controller: _liveIdController,
              textInputAction: TextInputAction.go,
              keyboardType: TextInputType.text,
              style: TextStyles.kMediumPoppins(
                fontSize: TextStyles.k14FontSize,
                colors: AppLightUi.body,
              ),
              cursorColor: AppLightUi.pink,
              decoration: InputDecoration(
                hintText: 'Enter live stream ID',
                border: InputBorder.none,
                hintStyle: TextStyles.kRegularPoppins(
                  fontSize: 13,
                  colors: AppLightUi.hint,
                ),
              ),
              onSubmitted: liveRoomController.joinManualLive,
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientCta({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [AppLightUi.pink, AppLightUi.violet],
          ),
          boxShadow: [
            BoxShadow(
              color: AppLightUi.pink.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 22),
          label: SemiBoldText(
            text: label,
            fontSize: TextStyles.k14FontSize,
            color: kColorWhite,
            maxLines: 1,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: kColorWhite,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(LiveRoomController liveRoomController) {
    return Obx(
      () => Row(
        children: [
          const Flexible(
            child: SemiBoldText(
              text: 'Live now',
              fontSize: TextStyles.k18FontSize,
              color: AppLightUi.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Spacing.h8,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: LiveRoomUiColors.goLiveGradientStart.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: LiveRoomUiColors.goLiveGradientStart.withValues(
                  alpha: 0.25,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _LivePulseDot(
                  color: LiveRoomUiColors.goLiveGradientStart,
                  size: 7,
                ),
                Spacing.h6,
                SemiBoldText(
                  text: '${liveRoomController.rooms.length} live',
                  fontSize: TextStyles.k10FontSize,
                  color: LiveRoomUiColors.goLiveGradientStart,
                ),
              ],
            ),
          ),
          const Spacer(),
          _circleIconButton(
            icon: Icons.refresh_rounded,
            onTap: liveRoomController.fetchActiveRooms,
            size: 38,
            color: AppLightUi.pink,
          ),
        ],
      ),
    );
  }

  Widget _liveRoomTile(
    LiveRoomController liveRoomController,
    Map<String, dynamic> room,
  ) {
    final title = room['nameAge']?.toString().trim();
    final location = room['location']?.toString().trim();
    final viewers = room['points']?.toString() ?? '0';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppLightUi.violet.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => liveRoomController.joinRoom(room),
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.all(10),
            decoration: AppLightUi.cardDecoration(radius: 20),
            child: Row(
              children: [
                _thumbWithBadges(
                  path: room['image']?.toString() ?? kImgTemp3,
                  viewers: viewers,
                ),
                Spacing.h12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SemiBoldText(
                        text: (title == null || title.isEmpty)
                            ? 'Live Room'
                            : title,
                        fontSize: 15,
                        color: AppLightUi.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Spacing.v8,
                      // Wrap (not Row) so chips drop to a new line instead of
                      // overflowing on narrow screens / long labels.
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _miniPill(
                            _roomTypeIcon(room['roomType']),
                            _roomTypeLabel(room['roomType']),
                            AppLightUi.violet,
                          ),
                          _miniPill(
                            Icons.public_rounded,
                            (location == null || location.isEmpty)
                                ? 'Global'
                                : location,
                            AppLightUi.cyan,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Spacing.h8,
                _joinArrow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _thumbWithBadges({required String path, required String viewers}) {
    return SizedBox(
      width: _thumbSize,
      height: _thumbSize,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _RoomThumb(path: path, size: _thumbSize),
          ),
          Positioned(
            left: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [
                    LiveRoomUiColors.goLiveGradientStart,
                    LiveRoomUiColors.goLiveGradientEnd,
                  ],
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LivePulseDot(color: kColorWhite, size: 5),
                  SizedBox(width: 4),
                  SemiBoldText(
                    text: 'LIVE',
                    fontSize: 9,
                    color: kColorWhite,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 6,
            right: 6,
            bottom: 6,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.visibility_rounded,
                      color: kColorWhite,
                      size: 11,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: SemiBoldText(
                        text: viewers,
                        fontSize: 9,
                        color: kColorWhite,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _joinArrow() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppLightUi.pink, AppLightUi.violet],
        ),
        boxShadow: [
          BoxShadow(
            color: AppLightUi.pink.withValues(alpha: 0.30),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.arrow_forward_rounded,
        color: kColorWhite,
        size: 20,
      ),
    );
  }

  IconData _roomTypeIcon(Object? type) {
    switch (type?.toString().toUpperCase()) {
      case 'AUDIO':
        return Icons.graphic_eq_rounded;
      case 'LIVE_STREAM':
        return Icons.live_tv_rounded;
      default:
        return Icons.videocam_rounded;
    }
  }

  String _roomTypeLabel(Object? type) {
    switch (type?.toString().toUpperCase()) {
      case 'AUDIO':
        return 'Audio room';
      case 'LIVE_STREAM':
        return 'Live stream';
      default:
        return 'Video room';
    }
  }

  Widget _miniPill(IconData icon, String label, Color color) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          Spacing.h4,
          Flexible(
            child: SemiBoldText(
              text: label,
              fontSize: TextStyles.k10FontSize,
              color: AppLightUi.body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(LiveRoomController liveRoomController) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: LiveRoomUiColors.chipInactiveBg,
                shape: BoxShape.circle,
                border: Border.all(color: LiveRoomUiColors.joinLiveBorder),
              ),
              child: const Icon(
                Icons.live_tv_rounded,
                color: AppLightUi.pink,
                size: 38,
              ),
            ),
            Spacing.v16,
            const SemiBoldText(
              text: 'No live streams yet',
              fontSize: TextStyles.k18FontSize,
              color: AppLightUi.title,
              align: TextAlign.center,
            ),
            Spacing.v8,
            AppText(
              text: 'Use manual join if you already have a live stream ID.',
              fontSize: TextStyles.k12FontSize,
              color: AppLightUi.subtitle,
              align: TextAlign.center,
            ),
            Spacing.v20,
            SizedBox(
              width: 170,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: liveRoomController.fetchActiveRooms,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const SemiBoldText(
                  text: 'Refresh',
                  fontSize: 13,
                  color: AppLightUi.pink,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppLightUi.pink,
                  side: const BorderSide(color: AppLightUi.borderStrong),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
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

/// Small pulsing dot used on LIVE badges.
class _LivePulseDot extends StatefulWidget {
  const _LivePulseDot({required this.color, this.size = 7});

  final Color color;
  final double size;

  @override
  State<_LivePulseDot> createState() => _LivePulseDotState();
}

class _LivePulseDotState extends State<_LivePulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(_anim),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

class _RoomThumb extends StatelessWidget {
  const _RoomThumb({required this.path, this.size = 82});

  final String path;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    return Image.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      color: AppLightUi.cardSoft,
      child: const Icon(
        Icons.live_tv_rounded,
        color: AppLightUi.pink,
        size: 26,
      ),
    );
  }
}
