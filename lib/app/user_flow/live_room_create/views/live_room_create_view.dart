import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/live_room_create_controller.dart';

class LiveRoomCreateView extends GetView<LiveRoomCreateController> {
  const LiveRoomCreateView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorWhite,
      appBar: const CommonAppBarWidget(
        title: 'Create Room',
        useMaterialAppBar: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SemiBoldText(
              text: 'Room Name',
              fontSize: TextStyles.k14FontSize,
              color: kColorText,
            ),
            Spacing.v8,
            appTextField(
              textController: controller.roomNameController,
              hintText: 'Enter an amazing title...',
              fillColor: kColorBackground,
              borderRadius: 12,
            ),
            Spacing.v24,
            const SemiBoldText(
              text: 'Room Type',
              fontSize: TextStyles.k14FontSize,
              color: kColorText,
            ),
            Spacing.v12,
            Row(
              children: [
                Expanded(child: _buildTypeToggle('AUDIO', Icons.graphic_eq_rounded)),
                Spacing.h12,
                Expanded(child: _buildTypeToggle('VIDEO', Icons.videocam_rounded)),
              ],
            ),
            Spacing.v24,
            const SemiBoldText(
              text: 'Number of Seats',
              fontSize: TextStyles.k14FontSize,
              color: kColorText,
            ),
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
            Spacing.v40,
            appButton(
              onPressed: () => controller.createRoom(context),
              buttonText: 'Go Live Now',
              buttonColor: kColorPrimary,
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
            color: isSelected ? kColorPrimary.withValues(alpha: 0.1) : kColorBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? kColorPrimary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? kColorPrimary : kColorHint, size: 28),
              Spacing.v8,
              SemiBoldText(
                text: type,
                fontSize: TextStyles.k14FontSize,
                color: isSelected ? kColorPrimary : kColorHint,
              ),
            ],
          ),
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
            color: isSelected ? kColorPrimary : kColorBackground,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? kColorPrimary : kColorHint.withValues(alpha: 0.3),
            ),
          ),
          child: Center(
            child: SemiBoldText(
              text: seatCount,
              fontSize: TextStyles.k18FontSize,
              color: isSelected ? kColorWhite : kColorText,
            ),
          ),
        ),
      );
    });
  }
}
