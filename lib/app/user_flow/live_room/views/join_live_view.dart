import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
      backgroundColor: LiveRoomUiColors.screenGradientBottom,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage(kImgBG), fit: BoxFit.cover),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _topBar(),
              Expanded(
                child: RefreshIndicator(
                  color: kColorPrimary,
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
                        padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
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
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
      child: Row(
        children: [
          Material(
            color: kColorWhite.withValues(alpha: 0.12),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: Get.back<void>,
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: kColorWhite,
                  size: 18,
                ),
              ),
            ),
          ),
          Spacing.h12,
          const Expanded(
            child: SemiBoldText(
              text: 'Join Live',
              fontSize: TextStyles.k22FontSize,
              color: kColorWhite,
              align: TextAlign.center,
            ),
          ),
          const SizedBox(width: 54),
        ],
      ),
    );
  }

  Widget _manualJoinCard(LiveRoomController liveRoomController) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LiveRoomUiColors.cardSurface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: LiveRoomUiColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: kColorBlack.withValues(alpha: 0.24),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      LiveRoomUiColors.goLiveGradientStart,
                      LiveRoomUiColors.goLiveGradientEnd,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.sensors_rounded,
                  color: kColorWhite,
                  size: 22,
                ),
              ),
              Spacing.h12,
              const Expanded(
                child: SemiBoldText(
                  text: 'Manual Join',
                  fontSize: TextStyles.k18FontSize,
                  color: kColorWhite,
                ),
              ),
            ],
          ),
          Spacing.v16,
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: kColorWhite.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kColorWhite.withValues(alpha: 0.16)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.tag_rounded,
                  color: LiveRoomUiColors.joinLiveBorder,
                  size: 20,
                ),
                Spacing.h10,
                Expanded(
                  child: TextField(
                    controller: _liveIdController,
                    textInputAction: TextInputAction.go,
                    keyboardType: TextInputType.text,
                    style: TextStyles.kMediumPoppins(
                      fontSize: TextStyles.k14FontSize,
                      colors: kColorWhite,
                    ),
                    cursorColor: kColorWhite,
                    decoration: InputDecoration(
                      hintText: 'Enter live stream ID',
                      border: InputBorder.none,
                      hintStyle: TextStyles.kRegularPoppins(
                        fontSize: 13,
                        colors: kColorHint,
                      ),
                    ),
                    onSubmitted: liveRoomController.joinManualLive,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                liveRoomController.joinManualLive(_liveIdController.text);
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: const SemiBoldText(
                text: 'Join Manually',
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kColorPrimary,
                foregroundColor: kColorWhite,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(LiveRoomController liveRoomController) {
    return Obx(
      () => Row(
        children: [
          const SemiBoldText(
            text: 'Current Live Streams',
            fontSize: TextStyles.k16FontSize,
            color: kColorWhite,
          ),
          Spacing.h8,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: LiveRoomUiColors.liveDot.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SemiBoldText(
              text: '${liveRoomController.rooms.length} live',
              fontSize: TextStyles.k10FontSize,
              color: LiveRoomUiColors.liveDot,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: liveRoomController.fetchActiveRooms,
            child: const SemiBoldText(
              text: 'Refresh',
              fontSize: TextStyles.k12FontSize,
              color: LiveRoomUiColors.joinLiveBorder,
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveRoomTile(
    LiveRoomController liveRoomController,
    Map<String, dynamic> room,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => liveRoomController.joinRoom(room),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: LiveRoomUiColors.cardSurface.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kColorWhite.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _RoomThumb(path: room['image']?.toString() ?? kImgTemp3),
              ),
              Spacing.h12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemiBoldText(
                      text: room['nameAge']?.toString() ?? 'Live Room',
                      fontSize: 15,
                      color: kColorWhite,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        _miniPill(
                          Icons.circle,
                          'Live',
                          LiveRoomUiColors.goLiveGradientStart,
                        ),
                        Spacing.h8,
                        _miniPill(
                          room['roomType'] == 'AUDIO'
                              ? Icons.graphic_eq_rounded
                              : Icons.videocam_rounded,
                          room['roomType']?.toString() ?? 'VIDEO',
                          LiveRoomUiColors.joinLiveBorder,
                        ),
                      ],
                    ),
                    Spacing.v8,
                    AppText(
                      text:
                          '${room['location'] ?? 'IN'} • ${room['points'] ?? 0} watching',
                      fontSize: TextStyles.k12FontSize,
                      color: kColorHint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Spacing.h10,
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: kColorPrimary,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: kColorWhite,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniPill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: icon == Icons.circle ? 7 : 12),
          Spacing.h4,
          SemiBoldText(
            text: label,
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite,
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
                color: kColorWhite,
                size: 38,
              ),
            ),
            Spacing.v16,
            const SemiBoldText(
              text: 'No live streams yet',
              fontSize: TextStyles.k18FontSize,
              color: kColorWhite,
              align: TextAlign.center,
            ),
            Spacing.v8,
            AppText(
              text: 'Use manual join if you already have a live stream ID.',
              fontSize: TextStyles.k12FontSize,
              color: kColorHint,
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
                  color: kColorWhite,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kColorWhite,
                  side: const BorderSide(
                    color: LiveRoomUiColors.joinLiveBorder,
                  ),
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

class _RoomThumb extends StatelessWidget {
  const _RoomThumb({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: 82,
        height: 82,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    return Image.asset(
      path,
      width: 82,
      height: 82,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      width: 82,
      height: 82,
      color: LiveRoomUiColors.cardBorder,
      child: const Icon(Icons.live_tv_rounded, color: kColorWhite, size: 26),
    );
  }
}
