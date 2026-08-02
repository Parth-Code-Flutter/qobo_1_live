import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/models/room_background_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/constants/live_room_ui_colors.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/live_room_create_controller.dart';

class LiveRoomCreateView extends GetView<LiveRoomCreateController> {
  const LiveRoomCreateView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiveRoomUiColors.screenGradientBottom,
      body: Obx(() {
        // Preview the selected room background on this create screen
        // (audio + video share the same create form).
        final previewUrl = controller.selectedBackgroundImage.value?.trim();
        final hasPreview =
            previewUrl != null &&
            previewUrl.isNotEmpty &&
            !controller.isLiveStreamingMode;

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: hasPreview
                  ? Image.network(
                      previewUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        kImgBG,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(kImgBG, fit: BoxFit.cover),
            ),
            // Keep form readable over bright background photos.
            if (hasPreview)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.55),
                        Colors.black.withValues(alpha: 0.72),
                        Colors.black.withValues(alpha: 0.82),
                      ],
                    ),
                  ),
                ),
              ),
            SafeArea(
              child: Column(
                children: [
                  _header(
                    title: controller.isLiveStreamingMode
                        ? 'Live Streaming'
                        : 'Create Room',
                    showCreatorProfile: !controller.isLiveStreamingMode,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: controller.isLiveStreamingMode
                          ? _liveStreamingForm(context)
                          : _audioVideoRoomForm(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _liveStreamingForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _livePreviewCard(),
        Spacing.v20,
        _sectionLabel('Live Title', required: true),
        Spacing.v8,
        AppTextField(
          controller: controller.streamNameController,
          hintText: 'What are you going live about?',
          maxLength: 40,
          showCounter: false,
          fillColor: LiveRoomUiColors.cardSurface,
          borderColor: LiveRoomUiColors.cardBorder,
          inputBorderRadius: BorderRadius.circular(12),
          textStyle: TextStyles.kRegularPoppins(
            colors: kColorWhite,
            fontSize: TextStyles.k14FontSize,
          ),
          hintStyle: TextStyles.kRegularPoppins(
            colors: kColorHint,
            fontSize: TextStyles.k14FontSize,
          ),
        ),
        Spacing.v16,
        _onlyFollowsToggle(),
        Spacing.v12,
        _joinApprovalToggle(),
        Spacing.v24,
        appButton(
          onPressed: () => controller.startLiveStreaming(context),
          buttonText: 'Start Live',
          isGradient: true,
          buttonIcon: const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.live_tv_rounded, color: kColorWhite, size: 20),
          ),
          gradientColors: const [
            LiveRoomUiColors.goLiveGradientStart,
            LiveRoomUiColors.goLiveGradientEnd,
          ],
        ),
        Spacing.v12,
      ],
    );
  }

  Widget _audioVideoRoomForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Host profile is in the app bar — start with room background + setup.
        _sectionLabel('Room Background'),
        Spacing.v10,
        _backgroundBannerPicker(),
        Spacing.v20,
        _sectionLabel('Room Type', required: true),
        Spacing.v10,
        Row(
          children: [
            Expanded(
              child: _buildTypeToggle(
                'AUDIO',
                Icons.graphic_eq_rounded,
                const [Color(0xFF7B5CFF), Color(0xFF2ED3FF)],
              ),
            ),
            Spacing.h10,
            Expanded(
              child: _buildTypeToggle(
                'VIDEO',
                Icons.videocam_rounded,
                const [Color(0xFFFF4DC4), Color(0xFFFF6A3D)],
              ),
            ),
          ],
        ),
        Spacing.v20,
        _sectionLabel('Category'),
        Spacing.v10,
        _categoryWrap(),
        Spacing.v20,
        _sectionLabel('Number of Seats'),
        Spacing.v10,
        _seatsRow(),
        Spacing.v20,
        _sectionLabel('Region'),
        Spacing.v10,
        _regionRow(),
        Spacing.v20,
        _sectionLabel('Welcome Announcement'),
        Spacing.v8,
        AppTextField(
          controller: controller.announcementController,
          hintText: 'Say hi to your audience (optional)',
          maxLines: 3,
          minLines: 2,
          fillColor: LiveRoomUiColors.cardSurface.withValues(alpha: 0.72),
          borderColor: kColorWhite.withValues(alpha: 0.10),
          inputBorderRadius: BorderRadius.circular(16),
          textStyle: TextStyles.kRegularPoppins(
            colors: kColorWhite,
            fontSize: TextStyles.k14FontSize,
          ),
          hintStyle: TextStyles.kRegularPoppins(
            colors: kColorHint,
            fontSize: TextStyles.k14FontSize,
          ),
        ),
        Spacing.v16,
        _privacyToggle(),
        Spacing.v12,
        _joinApprovalToggle(),
        Spacing.v28,
        appButton(
          onPressed: () => controller.createRoom(context),
          buttonText: 'Create Room',
          isGradient: true,
          buttonIcon: const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(
              Icons.meeting_room_rounded,
              color: kColorWhite,
              size: 20,
            ),
          ),
          gradientColors: const [
            Color(0xFFFF4DC4),
            Color(0xFFFF2D7B),
            Color(0xFFFF6A3D),
          ],
        ),
        Spacing.v12,
      ],
    );
  }

  Widget _livePreviewCard() {
    return Container(
      height: 190,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LiveRoomUiColors.cardBorder),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            LiveRoomUiColors.goLiveGradientStart.withValues(alpha: 0.55),
            LiveRoomUiColors.cardSurface,
            LiveRoomUiColors.screenGradientBottom.withValues(alpha: 0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: kColorBlack.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: kColorWhite.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: kColorWhite.withValues(alpha: 0.16),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.fiber_manual_record_rounded,
                      color: kColorRed,
                      size: 10,
                    ),
                    Spacing.h6,
                    const SemiBoldText(
                      text: 'LIVE',
                      fontSize: TextStyles.k10FontSize,
                      color: kColorWhite,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: kColorWhite.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: kColorWhite.withValues(alpha: 0.18),
                  ),
                ),
                child: const Icon(
                  Icons.videocam_rounded,
                  color: kColorWhite,
                  size: 21,
                ),
              ),
            ],
          ),
          const Spacer(),
          const SemiBoldText(
            text: 'Ready to go live?',
            fontSize: TextStyles.k20FontSize,
            color: kColorWhite,
          ),
          Spacing.v6,
          const AppText(
            text: 'Add a title, choose who can join, then start your stream.',
            fontSize: TextStyles.k12FontSize,
            color: kColorHint,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _onlyFollowsToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: LiveRoomUiColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LiveRoomUiColors.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.people_outline_rounded,
            color: kColorWhite,
            size: 20,
          ),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SemiBoldText(
                  text: 'Only Follows',
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite,
                ),
                Spacing.v2,
                const AppText(
                  text: 'Only users who follow you can join',
                  fontSize: TextStyles.k10FontSize,
                  color: kColorHint,
                ),
              ],
            ),
          ),
          Obx(
            () => Switch(
              value: controller.onlyFollows.value,
              onChanged: controller.setOnlyFollows,
              activeColor: kColorWhite,
              activeTrackColor: LiveRoomUiColors.goLiveGradientStart,
              inactiveThumbColor: kColorWhite,
              inactiveTrackColor: LiveRoomUiColors.chipInactiveBg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _joinApprovalToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: LiveRoomUiColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LiveRoomUiColors.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.how_to_reg_rounded,
            color: kColorWhite,
            size: 20,
          ),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SemiBoldText(
                  text: 'Require Join Approval',
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite,
                ),
                Spacing.v2,
                const AppText(
                  text: 'Viewers wait until you Add or Reject their request',
                  fontSize: TextStyles.k10FontSize,
                  color: kColorHint,
                ),
              ],
            ),
          ),
          Obx(
            () => Switch(
              value: controller.joinApprovalRequired.value,
              onChanged: controller.setJoinApprovalRequired,
              activeColor: kColorWhite,
              activeTrackColor: LiveRoomUiColors.goLiveGradientStart,
              inactiveThumbColor: kColorWhite,
              inactiveTrackColor: LiveRoomUiColors.chipInactiveBg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _header({
    required String title,
    bool showCreatorProfile = false,
  }) {
    if (!showCreatorProfile) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Row(
          children: [
            _backButton(),
            Spacing.h10,
            SemiBoldText(
              text: title,
              fontSize: TextStyles.k18FontSize,
              color: kColorWhite,
            ),
          ],
        ),
      );
    }

    // Audio/video create: host profile in the app bar (no body profile card).
    final session = Get.isRegistered<UserSessionController>()
        ? Get.find<UserSessionController>()
        : Get.put(UserSessionController(), permanent: true);

    return GetBuilder<UserSessionController>(
      init: session,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
          child: Row(
            children: [
              _backButton(),
              Spacing.h10,
              FramedUserAvatar(
                name: controller.creatorDisplayName,
                imageUrl: controller.creatorAvatarUrl,
                frameUrl: controller.creatorFrameUrl,
                frameSeed: controller.creatorUserId,
                size: 36,
                fontSize: TextStyles.k10FontSize,
              ),
              Spacing.h10,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemiBoldText(
                      text: controller.creatorDisplayName,
                      fontSize: TextStyles.k18FontSize,
                      color: kColorWhite,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacing.v4,
                    SemiBoldText(
                      text: controller.creatorRoomTitle,
                      fontSize: TextStyles.k14FontSize,
                      color: const Color(0xFFFF9AD5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _backButton() {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: Get.back,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: kColorWhite.withValues(alpha: 0.08),
            border: Border.all(color: kColorWhite.withValues(alpha: 0.12)),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: kColorWhite,
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, {bool required = false}) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 14,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFF4DC4), Color(0xFF7B5CFF)],
            ),
          ),
        ),
        Spacing.h8,
        SemiBoldText(
          text: text,
          fontSize: TextStyles.k14FontSize,
          color: kColorWhite,
        ),
        if (required)
          const AppText(
            text: ' *',
            fontSize: TextStyles.k14FontSize,
            color: Color(0xFFFF6A3D),
          ),
      ],
    );
  }

  /// Horizontal catalog from `GET /api/room/backgrounds`.
  Widget _backgroundBannerPicker() {
    return Obx(() {
      // Touch the selection obs first so Obx always rebuilds on tap.
      final selectedId = controller.selectedBackgroundId.value;

      if (controller.isLoadingBackgrounds.value &&
          controller.roomBackgrounds.isEmpty) {
        return Container(
          height: 118,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: LiveRoomUiColors.cardSurface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kColorWhite.withValues(alpha: 0.1)),
          ),
          child: const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: Color(0xFFFF4DC4),
            ),
          ),
        );
      }

      final themes = controller.roomBackgrounds.toList();
      if (themes.isEmpty) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: LiveRoomUiColors.cardSurface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kColorWhite.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.wallpaper_rounded,
                color: kColorWhite.withValues(alpha: 0.55),
                size: 22,
              ),
              Spacing.h10,
              Expanded(
                child: AppText(
                  text: 'No room backgrounds available yet.',
                  fontSize: TextStyles.k12FontSize,
                  color: kColorWhite.withValues(alpha: 0.65),
                ),
              ),
              GestureDetector(
                onTap: controller.loadRoomBackgrounds,
                child: const SemiBoldText(
                  text: 'Retry',
                  fontSize: TextStyles.k12FontSize,
                  color: Color(0xFFFF9AD5),
                ),
              ),
            ],
          ),
        );
      }

      return SizedBox(
        height: 132,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: themes.length,
          separatorBuilder: (_, __) => Spacing.h10,
          itemBuilder: (context, index) {
            final theme = themes[index];
            return _backgroundTile(
              theme: theme,
              selected: selectedId != null &&
                  selectedId.isNotEmpty &&
                  selectedId == theme.id,
            );
          },
        ),
      );
    });
  }

  /// One selectable room-background thumbnail.
  ///
  /// Border lives on an outer box so `clipBehavior` does not chop it into a
  /// bottom-only line (common Flutter quirk with border + Clip.antiAlias).
  Widget _backgroundTile({
    required RoomBackgroundTheme theme,
    required bool selected,
  }) {
    const selectedPink = Color(0xFFFF4DC4);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.selectBackground(theme),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 112,
          padding: EdgeInsets.all(selected ? 2.5 : 1.2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFF4DC4), Color(0xFF9B5CFF)],
                  )
                : null,
            border: selected
                ? null
                : Border.all(
                    color: kColorWhite.withValues(alpha: 0.18),
                    width: 1.2,
                  ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: selectedPink.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(selected ? 13.5 : 14.5),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  theme.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => ColoredBox(
                    color: LiveRoomUiColors.cardSurface,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: kColorWhite.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xDD0A0614)],
                      ),
                    ),
                    child: SemiBoldText(
                      text: theme.name,
                      fontSize: TextStyles.k10FontSize,
                      color: kColorWhite,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (theme.isDefault)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const AppText(
                        text: 'Default',
                        fontSize: 9,
                        color: kColorWhite,
                      ),
                    ),
                  ),
                if (selected)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.35),
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: selectedPink,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeToggle(
    String type,
    IconData icon,
    List<Color> accentColors,
  ) {
    return Obx(() {
      final isSelected = controller.roomType.value == type;
      return GestureDetector(
        onTap: () => controller.selectRoomType(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColors.first.withValues(alpha: 0.55),
                      accentColors.last.withValues(alpha: 0.28),
                    ],
                  )
                : null,
            color: isSelected ? null : LiveRoomUiColors.cardSurface,
            border: Border.all(
              color: isSelected
                  ? accentColors.first.withValues(alpha: 0.85)
                  : kColorWhite.withValues(alpha: 0.10),
              width: isSelected ? 1.6 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentColors.first.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isSelected
                      ? LinearGradient(colors: accentColors)
                      : null,
                  color: isSelected
                      ? null
                      : kColorWhite.withValues(alpha: 0.08),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? kColorWhite : kColorHint,
                  size: 22,
                ),
              ),
              Spacing.v8,
              SemiBoldText(
                text: type,
                fontSize: TextStyles.k14FontSize,
                color: isSelected ? kColorWhite : kColorHint,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _categoryWrap() {
    return Obx(() {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(LiveRoomCreateController.categories.length, (
          index,
        ) {
          final isSelected = controller.selectedCategoryIndex.value == index;
          return GestureDetector(
            onTap: () => controller.selectCategory(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFFFF4DC4), Color(0xFF7B5CFF)],
                      )
                    : null,
                color: isSelected
                    ? null
                    : LiveRoomUiColors.cardSurface.withValues(alpha: 0.9),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : kColorWhite.withValues(alpha: 0.10),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(
                            0xFFFF2D7B,
                          ).withValues(alpha: 0.28),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: SemiBoldText(
                text: LiveRoomCreateController.categories[index],
                fontSize: TextStyles.k12FontSize,
                color: isSelected ? kColorWhite : kColorHint,
              ),
            ),
          );
        }),
      );
    });
  }

  Widget _seatsRow() {
    return Row(
      children: [
        for (final seat in ['4', '6', '8', '12']) ...[
          Expanded(child: _buildSeatToggle(seat)),
          if (seat != '12') Spacing.h8,
        ],
      ],
    );
  }

  Widget _buildSeatToggle(String seatCount) {
    return Obx(() {
      final isSelected = controller.seatCount.value == seatCount;
      return GestureDetector(
        onTap: () => controller.selectSeats(seatCount),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF7B5CFF), Color(0xFF4F7CFF)],
                  )
                : null,
            color: isSelected ? null : LiveRoomUiColors.cardSurface,
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : kColorWhite.withValues(alpha: 0.10),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF5B6CFF).withValues(alpha: 0.32),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: SemiBoldText(
              text: seatCount,
              fontSize: TextStyles.k16FontSize,
              color: isSelected ? kColorWhite : kColorHint,
            ),
          ),
        ),
      );
    });
  }

  Widget _regionRow() {
    return Obx(() {
      return Row(
        children: List.generate(LiveRoomCreateController.regions.length, (
          index,
        ) {
          final region = LiveRoomCreateController.regions[index];
          final isSelected = controller.selectedRegion.value == region.code;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index == LiveRoomCreateController.regions.length - 1
                    ? 0
                    : 8,
              ),
              child: GestureDetector(
                onTap: () => controller.selectRegion(region.code),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFF2ED3FF), Color(0xFF7B5CFF)],
                          )
                        : null,
                    color: isSelected ? null : LiveRoomUiColors.cardSurface,
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : kColorWhite.withValues(alpha: 0.10),
                    ),
                  ),
                  child: SemiBoldText(
                    text: region.label,
                    fontSize: TextStyles.k12FontSize,
                    color: isSelected ? kColorWhite : kColorHint,
                  ),
                ),
              ),
            ),
          );
        }),
      );
    });
  }

  Widget _privacyToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            LiveRoomUiColors.cardSurface,
            LiveRoomUiColors.cardSurface.withValues(alpha: 0.72),
          ],
        ),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF4DC4).withValues(alpha: 0.35),
                  const Color(0xFF7B5CFF).withValues(alpha: 0.28),
                ],
              ),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: kColorWhite,
              size: 18,
            ),
          ),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SemiBoldText(
                  text: 'Private Room',
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite,
                ),
                Spacing.v2,
                AppText(
                  text: 'Only invited users can join',
                  fontSize: TextStyles.k10FontSize,
                  color: kColorWhite.withValues(alpha: 0.55),
                ),
              ],
            ),
          ),
          Obx(
            () => Switch(
              value: controller.isPrivate.value,
              onChanged: controller.setPrivate,
              activeThumbColor: kColorWhite,
              activeTrackColor: const Color(0xFFFF4DC4),
              inactiveThumbColor: kColorWhite,
              inactiveTrackColor: LiveRoomUiColors.chipInactiveBg,
            ),
          ),
        ],
      ),
    );
  }
}
