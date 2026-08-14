import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/controllers/pk_v1_controller.dart';

import '../controllers/live_broadcast_controller.dart';
import 'in_room_pk_stage_overlay.dart';

/// Shared in-room PK stage used by live streaming (and any room without the
/// audio seat grid). Mirrors the audio-room PK slot sizing.
class LiveRoomPkStageSlot extends StatelessWidget {
  const LiveRoomPkStageSlot({
    super.key,
    this.minHeight = 240,
    this.maxHeightCap = 480,
    this.padding,
  });

  final double minHeight;
  final double maxHeightCap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final live = Get.find<LiveBroadcastController>();
    return Obx(() {
      if (!live.isInRoomPkActive || !Get.isRegistered<PkV1Controller>()) {
        return const SizedBox.shrink();
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final compact = MediaQuery.sizeOf(context).width < 390;
          final stageH = constraints.maxHeight.clamp(minHeight, maxHeightCap);
          return Padding(
            padding: padding ??
                EdgeInsets.fromLTRB(
                  compact ? 8 : 10,
                  compact ? 4 : 8,
                  compact ? 8 : 10,
                  0,
                ),
            child: InRoomPkStageOverlay(
              controller: Get.find<PkV1Controller>(),
              compact: compact,
              maxHeight: stageH,
            ),
          );
        },
      );
    });
  }
}

/// Gradient backdrop shown behind the PK split stage (matches audio-room chrome).
class LiveRoomPkBattleBackdrop extends StatelessWidget {
  const LiveRoomPkBattleBackdrop({super.key});

  static const _roomTop = Color(0xFF4A073F);
  static const _roomMid = Color(0xFF30105F);
  static const _roomBottom = Color(0xFF07103F);

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_roomTop, _roomMid, _roomBottom],
          stops: [0, 0.46, 1],
        ),
      ),
    );
  }
}
