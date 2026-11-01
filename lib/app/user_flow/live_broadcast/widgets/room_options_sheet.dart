import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/controllers/live_broadcast_controller.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';

enum _RoomOptionAction {
  mic,
  speaker,
  camera,
  filters,
  flipCamera,
  background,
  share,
  follow,
  leave,
}

class _RoomOption {
  const _RoomOption({
    required this.action,
    required this.icon,
    required this.label,
    required this.color,
    required this.gradient,
  });

  final _RoomOptionAction action;
  final IconData icon;
  final String label;
  final Color color;
  final List<Color> gradient;
}

class RoomOptionsSheet extends StatefulWidget {
  final bool isHost;
  final bool isVideoRoom;

  const RoomOptionsSheet({
    super.key,
    required this.isHost,
    this.isVideoRoom = false,
  });

  @override
  State<RoomOptionsSheet> createState() => _RoomOptionsSheetState();
}

class _RoomOptionsSheetState extends State<RoomOptionsSheet> {
  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<LiveBroadcastController>()) {
      Get.find<LiveBroadcastController>().syncDockAudioState();
    }
  }

  static const _mic = _RoomOption(
    action: _RoomOptionAction.mic,
    icon: Icons.mic_rounded,
    label: 'Mic',
    color: Color(0xFFFF6AD5),
    gradient: [Color(0xFFFF6AD5), Color(0xFF9B1FE8)],
  );
  static const _speaker = _RoomOption(
    action: _RoomOptionAction.speaker,
    icon: Icons.volume_up_rounded,
    label: 'Speaker',
    color: Color(0xFF7B5CFF),
    gradient: [Color(0xFF7B5CFF), Color(0xFF2ED3FF)],
  );
  static const _camera = _RoomOption(
    action: _RoomOptionAction.camera,
    icon: Icons.videocam_rounded,
    label: 'Camera',
    color: Color(0xFF7AD7FF),
    gradient: [Color(0xFF4FC3F7), Color(0xFF2979FF)],
  );
  static const _flip = _RoomOption(
    action: _RoomOptionAction.flipCamera,
    icon: Icons.cameraswitch_rounded,
    label: 'Flip',
    color: Color(0xFF7AD7FF),
    gradient: [Color(0xFF4FC3F7), Color(0xFF2979FF)],
  );
  static const _filters = _RoomOption(
    action: _RoomOptionAction.filters,
    icon: Icons.auto_fix_high_rounded,
    label: 'Filters',
    color: Color(0xFFFF6AD5),
    gradient: [Color(0xFFE12BC5), Color(0xFF9B1FE8)],
  );
  static const _background = _RoomOption(
    action: _RoomOptionAction.background,
    icon: Icons.image_rounded,
    label: 'Background',
    color: Color(0xFF7AD7FF),
    gradient: [Color(0xFF4FC3F7), Color(0xFF2979FF)],
  );
  static const _share = _RoomOption(
    action: _RoomOptionAction.share,
    icon: Icons.ios_share_rounded,
    label: 'Share',
    color: Color(0xFFB8A4FF),
    gradient: [Color(0xFF9B7BFF), Color(0xFF6C4DFF)],
  );
  static const _follow = _RoomOption(
    action: _RoomOptionAction.follow,
    icon: Icons.person_add_alt_1_rounded,
    label: 'Follow',
    color: Color(0xFFFF8FB8),
    gradient: [Color(0xFFFF8FB8), Color(0xFFFF4081)],
  );
  static const _leave = _RoomOption(
    action: _RoomOptionAction.leave,
    icon: Icons.logout_rounded,
    label: 'Leave',
    color: Color(0xFFFF3B5C),
    gradient: [Color(0xFFFF3B5C), Color(0xFFE11D48)],
  );

  /// Controls that left the dock. PK stays on the dock, and is omitted in battle.
  List<_RoomOption> get _options {
    final live =
        Get.isRegistered<LiveBroadcastController>() &&
        Get.find<LiveBroadcastController>().isLiveStreamingSession;

    if (live && widget.isHost) {
      return [
        _mic,
        _speaker,
        if (widget.isVideoRoom) _camera,
        if (widget.isVideoRoom) _flip,
        if (widget.isVideoRoom) _filters,
        _background,
        _share,
      ];
    }
    if (live) {
      return [_mic, _speaker, _share, _follow];
    }
    if (widget.isHost) {
      return [
        _mic,
        _speaker,
        if (widget.isVideoRoom) _camera,
        if (widget.isVideoRoom) _flip,
        if (widget.isVideoRoom) _filters,
        _background,
        _share,
      ];
    }
    return [
      _mic,
      _speaker,
      if (widget.isVideoRoom) _camera,
      if (widget.isVideoRoom) _flip,
      if (widget.isVideoRoom) _filters,
      _background,
      _share,
      if (widget.isVideoRoom) _follow,
      if (widget.isVideoRoom) _leave,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final options = _options;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(bottom: 24 + bottomInset),
        decoration: const BoxDecoration(
          color: Color(0xFF161622),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Spacing.v12,
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Spacing.v20,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final count = options.isEmpty ? 1 : options.length;
                  final slot = constraints.maxWidth / count;
                  final circle = (slot - 8).clamp(36.0, 48.0);
                  return Row(
                    children: [
                      for (final opt in options)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _onOptionTap(opt),
                            behavior: HitTestBehavior.opaque,
                            child: Obx(() {
                              final shown = _shownOption(opt);
                              final off = shown.off;
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: circle,
                                    height: circle,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: off
                                          ? null
                                          : LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: shown.gradient,
                                            ),
                                      color: off
                                          ? const Color(0xFF2A2438)
                                          : null,
                                      border: off
                                          ? Border.all(
                                              color: const Color(0xFFFF6B8A),
                                            )
                                          : null,
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              (off
                                                      ? const Color(0xFFFF6B8A)
                                                      : shown.color)
                                                  .withValues(
                                                    alpha: off ? 0.28 : 0.35,
                                                  ),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      shown.icon,
                                      color: off
                                          ? const Color(0xFFFF8AA0)
                                          : kColorWhite,
                                      size: circle * 0.46,
                                    ),
                                  ),
                                  Spacing.v8,
                                  AppText(
                                    text: shown.label,
                                    fontSize: 10,
                                    color: off
                                        ? const Color(0xFFFF8AA0)
                                        : shown.color,
                                    align: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  ({IconData icon, String label, Color color, List<Color> gradient, bool off})
  _shownOption(_RoomOption option) {
    final controller = Get.isRegistered<LiveBroadcastController>()
        ? Get.find<LiveBroadcastController>()
        : null;
    final muted = controller?.isMicMuted.value ?? false;
    final speaker = controller?.dockSpeakerMode.value ?? 'speaker';
    if (option.action == _RoomOptionAction.mic) {
      return (
        icon: muted ? Icons.mic_off_rounded : Icons.mic_rounded,
        label: muted ? 'Muted' : 'Mic on',
        color: option.color,
        gradient: option.gradient,
        off: muted,
      );
    }
    if (option.action == _RoomOptionAction.speaker) {
      final headset = speaker == 'headset';
      final off = speaker == 'off';
      return (
        icon: headset
            ? Icons.headset_rounded
            : off
            ? Icons.volume_off_rounded
            : Icons.volume_up_rounded,
        label: headset
            ? 'Headset'
            : off
            ? 'Speaker off'
            : 'Speaker on',
        color: option.color,
        gradient: option.gradient,
        off: off,
      );
    }
    return (
      icon: option.icon,
      label: option.label,
      color: option.color,
      gradient: option.gradient,
      off: false,
    );
  }

  void _onOptionTap(_RoomOption option) {
    Get.back();

    switch (option.action) {
      case _RoomOptionAction.mic:
        if (Get.isRegistered<LiveBroadcastController>()) {
          Get.find<LiveBroadcastController>().toggleDockMic();
        }
      case _RoomOptionAction.speaker:
        if (Get.isRegistered<LiveBroadcastController>()) {
          Get.find<LiveBroadcastController>().toggleDockSpeaker();
        }
      case _RoomOptionAction.camera:
        if (Get.isRegistered<LiveBroadcastController>()) {
          Get.find<LiveBroadcastController>().toggleDockCamera();
        }
      case _RoomOptionAction.filters:
        _runAfterClose(
          () => Get.find<LiveBroadcastController>().openLiveFiltersSheet(),
        );
      case _RoomOptionAction.flipCamera:
        if (Get.isRegistered<LiveBroadcastController>()) {
          Get.find<LiveBroadcastController>().flipDockCamera();
        }
      case _RoomOptionAction.background:
        _runAfterClose(
          () => Get.find<LiveBroadcastController>().openRoomBackgroundSheet(),
        );
      case _RoomOptionAction.share:
        if (Get.isRegistered<LiveBroadcastController>()) {
          _runAfterClose(() => Get.find<LiveBroadcastController>().shareRoom());
        }
      case _RoomOptionAction.follow:
        if (Get.isRegistered<LiveBroadcastController>()) {
          Get.find<LiveBroadcastController>().toggleFollowHost();
        }
      case _RoomOptionAction.leave:
        if (Get.isRegistered<LiveBroadcastController>()) {
          Get.find<LiveBroadcastController>().leaveRoom();
        }
    }
  }

  void _runAfterClose(VoidCallback action) {
    if (!Get.isRegistered<LiveBroadcastController>()) return;
    Future.delayed(const Duration(milliseconds: 120), action);
  }
}
