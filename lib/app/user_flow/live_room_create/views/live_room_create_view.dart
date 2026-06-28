import 'dart:io';

import 'package:flutter/material.dart';
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
          image: DecorationImage(image: AssetImage(kImgBG), fit: BoxFit.cover),
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
        _coverPicker(context),
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
            Expanded(child: _buildTypeToggle('VIDEO', Icons.videocam_rounded)),
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

  /// Stream cover thumbnail picker.
  Widget _coverPicker(BuildContext context) {
    return Obx(() {
      final coverPath = controller.selectedCoverPath.value;
      final hasCover = coverPath != null && coverPath.isNotEmpty;
      return GestureDetector(
        onTap: () => controller.pickRoomCover(context),
        child: Container(
          height: 150,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: LiveRoomUiColors.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: LiveRoomUiColors.cardBorder, width: 1),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasCover)
                Image.file(
                  File(coverPath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _coverPlaceholder(),
                )
              else
                _coverPlaceholder(),
              if (hasCover)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.45),
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 12,
                right: hasCover ? 54 : 12,
                bottom: 12,
                child: SemiBoldText(
                  text: hasCover ? 'Tap to change cover' : 'Add Stream Cover',
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasCover)
                Positioned(
                  right: 10,
                  top: 10,
                  child: GestureDetector(
                    onTap: controller.clearRoomCover,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: kColorBlack.withValues(alpha: 0.48),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: kColorWhite.withValues(alpha: 0.18),
                        ),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: kColorWhite,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              if (!hasCover)
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 34,
                  child: AppText(
                    text: 'Recommended 16:9 · Tap to upload',
                    fontSize: TextStyles.k10FontSize,
                    color: kColorHint,
                    align: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _coverPlaceholder() {
    return Column(
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
      ],
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
        children: List.generate(LiveRoomCreateController.categories.length, (
          index,
        ) {
          final isSelected = controller.selectedCategoryIndex.value == index;
          return GestureDetector(
            onTap: () => controller.selectCategory(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: isSelected ? null : LiveRoomUiColors.cardSurface,
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
        }),
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
        }),
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
