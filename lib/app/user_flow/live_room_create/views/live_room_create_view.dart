import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/constants/live_room_ui_colors.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/live_room_create_controller.dart';

class LiveRoomCreateView extends GetView<LiveRoomCreateController> {
  const LiveRoomCreateView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiveRoomUiColors.screenGradientBottom,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(kImgBG),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Obx(
            () => Column(
              children: [
                _header(
                  title: controller.isLiveStreamingMode
                      ? 'Live Streaming'
                      : 'Create Room',
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
        ),
      ),
    );
  }

  Widget _liveStreamingForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _liveStreamingIdCard(),
        Spacing.v24,
        _sectionLabel('Live Streaming Name', required: true),
        Spacing.v8,
        AppTextField(
          controller: controller.streamNameController,
          hintText: 'Enter your stream title...',
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
        Spacing.v20,
        _onlyFollowsToggle(),
        Spacing.v32,
        appButton(
          onPressed: () => controller.startLiveStreaming(context),
          buttonText: 'Go Live',
          isGradient: true,
          buttonIcon: const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(
              Icons.live_tv_rounded,
              color: kColorWhite,
              size: 20,
            ),
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
        _coverPicker(),
        Spacing.v24,
        _sectionLabel('Room Name', required: true),
        Spacing.v8,
        AppTextField(
          controller: controller.streamNameController,
          hintText: 'Enter an amazing title...',
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
        Spacing.v20,
        _sectionLabel('Room Type', required: true),
        Spacing.v12,
        Row(
          children: [
            Expanded(
              child: _buildTypeToggle('AUDIO', Icons.graphic_eq_rounded),
            ),
            Spacing.h12,
            Expanded(
              child: _buildTypeToggle('VIDEO', Icons.videocam_rounded),
            ),
          ],
        ),
        Spacing.v20,
        _sectionLabel('Category'),
        Spacing.v12,
        _categoryWrap(),
        Spacing.v20,
        _sectionLabel('Number of Seats'),
        Spacing.v12,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSeatToggle('4'),
            _buildSeatToggle('6'),
            _buildSeatToggle('8'),
            _buildSeatToggle('12'),
          ],
        ),
        Spacing.v20,
        _sectionLabel('Region'),
        Spacing.v12,
        _regionRow(),
        Spacing.v20,
        _sectionLabel('Welcome Announcement'),
        Spacing.v8,
        AppTextField(
          controller: controller.announcementController,
          hintText: 'Say hi to your audience (optional)',
          maxLines: 3,
          minLines: 2,
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
        Spacing.v20,
        _privacyToggle(),
        Spacing.v32,
        appButton(
          onPressed: () => controller.createRoom(context),
          buttonText: 'Go Live Now',
          isGradient: true,
          buttonIcon: const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(
              Icons.live_tv_rounded,
              color: kColorWhite,
              size: 20,
            ),
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

  Widget _liveStreamingIdCard() {
    return Obx(() {
      final id = controller.liveStreamingId.value;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LiveRoomUiColors.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: LiveRoomUiColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SemiBoldText(
              text: 'Live Streaming ID',
              fontSize: TextStyles.k14FontSize,
              color: kColorWhite,
            ),
            Spacing.v4,
            const AppText(
              text: 'Used as Zego channel name · Auto-generated',
              fontSize: TextStyles.k10FontSize,
              color: kColorHint,
            ),
            Spacing.v12,
            Row(
              children: [
                Expanded(
                  child: AppText(
                    text: id,
                    fontSize: TextStyles.k12FontSize,
                    color: kColorWhite,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: id));
                    Get.snackbar(
                      'Copied',
                      'Live streaming ID copied',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: LiveRoomUiColors.cardSurface,
                      colorText: kColorWhite,
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 2),
                    );
                  },
                  icon: const Icon(
                    Icons.copy_rounded,
                    color: kColorWhite,
                    size: 20,
                  ),
                ),
                IconButton(
                  onPressed: controller.regenerateLiveStreamingId,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: kColorWhite,
                    size: 22,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
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
          const Icon(Icons.people_outline_rounded, color: kColorWhite, size: 20),
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

  Widget _header({required String title}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: kColorWhite,
              size: 20,
            ),
          ),
          Spacing.h4,
          SemiBoldText(
            text: title,
            fontSize: TextStyles.k18FontSize,
            color: kColorWhite,
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, {bool required = false}) {
    return Row(
      children: [
        SemiBoldText(
          text: text,
          fontSize: TextStyles.k14FontSize,
          color: kColorWhite,
        ),
        if (required)
          const AppText(
            text: ' *',
            fontSize: TextStyles.k14FontSize,
            color: LiveRoomUiColors.goLiveGradientStart,
          ),
      ],
    );
  }

  /// Stream cover thumbnail picker (UI placeholder until upload is wired).
  Widget _coverPicker() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: LiveRoomUiColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: LiveRoomUiColors.cardBorder,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: LiveRoomUiColors.chipInactiveBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_a_photo_rounded,
                color: kColorWhite,
                size: 24,
              ),
            ),
            Spacing.v10,
            const SemiBoldText(
              text: 'Add Stream Cover',
              fontSize: TextStyles.k14FontSize,
              color: kColorWhite,
            ),
            Spacing.v4,
            const AppText(
              text: 'Recommended 16:9 · Tap to upload',
              fontSize: TextStyles.k10FontSize,
              color: kColorHint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle(String type, IconData icon) {
    return Obx(() {
      final isSelected = controller.roomType.value == type;
      return GestureDetector(
        onTap: () => controller.selectRoomType(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? kColorPrimary.withValues(alpha: 0.35)
                : LiveRoomUiColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? LiveRoomUiColors.joinLiveBorder
                  : LiveRoomUiColors.cardBorder,
              width: 1.4,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? kColorWhite : kColorHint,
                size: 26,
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
        spacing: 10,
        runSpacing: 10,
        children: List.generate(
          LiveRoomCreateController.categories.length,
          (index) {
            final isSelected = controller.selectedCategoryIndex.value == index;
            return GestureDetector(
              onTap: () => controller.selectCategory(index),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: isSelected
                      ? null
                      : LiveRoomUiColors.cardSurface,
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [
                            LiveRoomUiColors.goLiveGradientStart,
                            LiveRoomUiColors.goLiveGradientEnd,
                          ],
                        )
                      : null,
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : LiveRoomUiColors.cardBorder,
                  ),
                ),
                child: SemiBoldText(
                  text: LiveRoomCreateController.categories[index],
                  fontSize: TextStyles.k12FontSize,
                  color: isSelected ? kColorWhite : kColorHint,
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildSeatToggle(String seatCount) {
    return Obx(() {
      final isSelected = controller.seatCount.value == seatCount;
      return GestureDetector(
        onTap: () => controller.selectSeats(seatCount),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isSelected
                ? kColorPrimary.withValues(alpha: 0.35)
                : LiveRoomUiColors.cardSurface,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? LiveRoomUiColors.joinLiveBorder
                  : LiveRoomUiColors.cardBorder,
              width: 1.4,
            ),
          ),
          child: Center(
            child: SemiBoldText(
              text: seatCount,
              fontSize: TextStyles.k18FontSize,
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
        children: List.generate(
          LiveRoomCreateController.regions.length,
          (index) {
            final region = LiveRoomCreateController.regions[index];
            final isSelected = controller.selectedRegion.value == region.code;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right:
                      index == LiveRoomCreateController.regions.length - 1
                      ? 0
                      : 10,
                ),
                child: GestureDetector(
                  onTap: () => controller.selectRegion(region.code),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected
                          ? kColorPrimary.withValues(alpha: 0.35)
                          : LiveRoomUiColors.cardSurface,
                      border: Border.all(
                        color: isSelected
                            ? LiveRoomUiColors.joinLiveBorder
                            : LiveRoomUiColors.cardBorder,
                        width: 1.4,
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
          },
        ),
      );
    });
  }

  Widget _privacyToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: LiveRoomUiColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LiveRoomUiColors.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded, color: kColorWhite, size: 20),
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
                const AppText(
                  text: 'Only invited users can join',
                  fontSize: TextStyles.k10FontSize,
                  color: kColorHint,
                ),
              ],
            ),
          ),
          Obx(
            () => Switch(
              value: controller.isPrivate.value,
              onChanged: controller.setPrivate,
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
}
