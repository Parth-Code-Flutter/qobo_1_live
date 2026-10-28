import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/utils/app_widgets/beauty_filter_dock.dart';

import '../controllers/live_broadcast_controller.dart';

class LiveFiltersSheet extends GetView<LiveBroadcastController> {
  const LiveFiltersSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => BeautyFilterDock(
        enabled: controller.liveBeautyEnabled.value,
        smooth: controller.liveSmooth.value,
        skinTone: controller.liveSkinTone.value,
        blush: controller.liveBlush.value,
        sharpen: controller.liveSharpen.value,
        onEnabled: controller.setLiveBeautyEnabled,
        onChanged: controller.updateLiveFilter,
        onReset: controller.resetLiveFilters,
      ),
    );
  }
}
