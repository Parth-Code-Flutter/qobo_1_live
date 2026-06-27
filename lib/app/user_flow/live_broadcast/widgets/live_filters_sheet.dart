import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/live_broadcast_controller.dart';

class LiveFiltersSheet extends GetView<LiveBroadcastController> {
  const LiveFiltersSheet({super.key});

  static const Color _panel = Color(0xFF161622);
  static const Color _card = Color(0xFF202033);
  static const Color _accent = Color(0xFFE12BC5);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      decoration: const BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Spacing.v16,
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.auto_fix_high_rounded,
                      color: _accent,
                      size: 22,
                    ),
                  ),
                  Spacing.h12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SemiBoldText(
                          text: 'Live Filters',
                          fontSize: TextStyles.k18FontSize,
                          color: kColorWhite,
                        ),
                        SizedBox(height: 2),
                        AppText(
                          text: 'Basic camera polish for your live stream.',
                          fontSize: TextStyles.k10FontSize,
                          color: kColorHint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: controller.liveBeautyEnabled.value,
                    activeColor: kColorWhite,
                    activeTrackColor: _accent,
                    inactiveThumbColor: kColorWhite,
                    inactiveTrackColor: Colors.white24,
                    onChanged: controller.setLiveBeautyEnabled,
                  ),
                ],
              ),
              Spacing.v16,
              _filterSlider(
                icon: Icons.blur_on_rounded,
                label: 'Smooth',
                value: controller.liveSmooth.value,
                onChanged: (value) =>
                    controller.updateLiveFilter(smooth: value.round()),
              ),
              _filterSlider(
                icon: Icons.wb_sunny_outlined,
                label: 'Skin tone',
                value: controller.liveSkinTone.value,
                onChanged: (value) =>
                    controller.updateLiveFilter(skinTone: value.round()),
              ),
              _filterSlider(
                icon: Icons.favorite_border_rounded,
                label: 'Blush',
                value: controller.liveBlush.value,
                onChanged: (value) =>
                    controller.updateLiveFilter(blush: value.round()),
              ),
              _filterSlider(
                icon: Icons.high_quality_rounded,
                label: 'Sharpen',
                value: controller.liveSharpen.value,
                onChanged: (value) =>
                    controller.updateLiveFilter(sharpen: value.round()),
              ),
              Spacing.v12,
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: controller.resetLiveFilters,
                      icon: const Icon(Icons.restart_alt_rounded, size: 18),
                      label: const SemiBoldText(
                        text: 'Reset',
                        fontSize: TextStyles.k12FontSize,
                        color: kColorWhite,
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: kColorWhite,
                        backgroundColor: Colors.white10,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: kColorWhite.withValues(alpha: 0.10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Spacing.h10,
                  Expanded(
                    child: TextButton(
                      onPressed: Get.back,
                      style: TextButton.styleFrom(
                        foregroundColor: kColorWhite,
                        backgroundColor: _accent,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const SemiBoldText(
                        text: 'Done',
                        fontSize: TextStyles.k12FontSize,
                        color: kColorWhite,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterSlider({
    required IconData icon,
    required String label,
    required int value,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: kColorWhite.withValues(alpha: 0.78), size: 18),
              Spacing.h8,
              Expanded(
                child: SemiBoldText(
                  text: label,
                  fontSize: TextStyles.k12FontSize,
                  color: kColorWhite,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppText(
                text: '$value%',
                fontSize: TextStyles.k10FontSize,
                color: kColorWhite.withValues(alpha: 0.70),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _accent,
              inactiveTrackColor: Colors.white12,
              thumbColor: kColorWhite,
              overlayColor: _accent.withValues(alpha: 0.18),
              trackHeight: 4,
            ),
            child: Slider(
              value: value.clamp(0, 100).toDouble(),
              min: 0,
              max: 100,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
