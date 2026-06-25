import 'package:flutter/material.dart';
import 'package:zego_uikit/zego_uikit.dart';

/// Mic toggle — only changes local publish mute; never touches speaker route.
class ChatCallMicButton extends StatelessWidget {
  const ChatCallMicButton({super.key, this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) {
    final userId = ZegoUIKit().getLocalUser().id;
    return ValueListenableBuilder<bool>(
      valueListenable: ZegoUIKit().getMicrophoneStateNotifier(userId),
      builder: (context, isOn, _) {
        return _CallCircleButton(
          size: size,
          isActive: isOn,
          activeIcon: Icons.mic_rounded,
          inactiveIcon: Icons.mic_off_rounded,
          onTap: () {
            ZegoUIKit().turnMicrophoneOn(
              !isOn,
              muteMode: true,
            );
          },
        );
      },
    );
  }
}

/// Speaker / earpiece toggle — only changes local playback route.
class ChatCallSpeakerButton extends StatelessWidget {
  const ChatCallSpeakerButton({super.key, this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) {
    final userId = ZegoUIKit().getLocalUser().id;
    return ValueListenableBuilder<ZegoUIKitAudioRoute>(
      valueListenable: ZegoUIKit().getAudioOutputDeviceNotifier(userId),
      builder: (context, route, _) {
        final isSpeaker = route == ZegoUIKitAudioRoute.speaker;
        final isLocked = route == ZegoUIKitAudioRoute.headphone ||
            route == ZegoUIKitAudioRoute.bluetooth;

        return _CallCircleButton(
          size: size,
          isActive: isSpeaker,
          activeIcon: Icons.volume_up_rounded,
          inactiveIcon: Icons.hearing_rounded,
          onTap: isLocked
              ? null
              : () => ZegoUIKit().setAudioOutputToSpeaker(!isSpeaker),
        );
      },
    );
  }
}

class _CallCircleButton extends StatelessWidget {
  const _CallCircleButton({
    required this.size,
    required this.isActive,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.onTap,
  });

  final double size;
  final bool isActive;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? Colors.white.withValues(alpha: 0.28)
                : Colors.white.withValues(alpha: 0.12),
          ),
          child: Icon(
            isActive ? activeIcon : inactiveIcon,
            color: Colors.white,
            size: size * 0.46,
          ),
        ),
      ),
    );
  }
}
