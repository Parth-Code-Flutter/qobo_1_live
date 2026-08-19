import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/zego_live_id_utils.dart';
import 'package:zego_uikit/zego_uikit.dart';

import '../controllers/live_broadcast_controller.dart';

/// Instagram-style live feed: **host camera only**, full bleed.
///
/// Host sees their own preview; audience sees the host stream. Prebuilt Live
/// PiP/gallery is hidden — this layer owns the single video surface.
class LiveHostVideoFill extends StatefulWidget {
  const LiveHostVideoFill({
    super.key,
    required this.isHost,
    required this.hostUserId,
    required this.hostName,
    this.hostAvatarUrl,
  });

  final bool isHost;
  final String hostUserId;
  final String hostName;
  final String? hostAvatarUrl;

  @override
  State<LiveHostVideoFill> createState() => _LiveHostVideoFillState();
}

class _LiveHostVideoFillState extends State<LiveHostVideoFill> {
  bool _screenUtilReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureScreenUtil();
  }

  void _ensureScreenUtil() {
    if (_screenUtilReady) return;
    if (MediaQuery.maybeOf(context) == null) return;
    try {
      final _ = ZegoScreenUtil().screenWidth;
      _screenUtilReady = true;
    } catch (_) {
      try {
        ZegoScreenUtil.init(context);
        _screenUtilReady = true;
      } catch (_) {
        _screenUtilReady = false;
      }
    }
    if (_screenUtilReady && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  Widget _fallback({Color color = const Color(0xFF12081C)}) {
    return ColoredBox(
      color: color,
      child: Center(
        child: AppUserAvatar(
          name: widget.hostName,
          imageUrl: widget.hostAvatarUrl,
          size: 96,
        ),
      ),
    );
  }

  ZegoUIKitUser? _resolveLocalHostPreview() {
    try {
      final local = ZegoUIKit().getLocalUser();
      if (!local.isEmpty()) return local;
    } catch (_) {}
    return null;
  }

  ZegoUIKitUser? _resolveRemoteHostUser(String targetSanitized) {
    try {
      final localId = ZegoUIKit().getLocalUser().id;

      ZegoUIKitUser? matched;
      for (final user in ZegoUIKit().getAudioVideoList()) {
        if (user.id == localId) continue;
        final id = ZegoLiveIdUtils.sanitizeUserId(user.id);
        if (targetSanitized.isNotEmpty && id == targetSanitized) {
          return user;
        }
        matched ??= user;
      }

      if (matched != null) return matched;

      for (final user in ZegoUIKit().getAllUsers()) {
        if (user.id == localId) continue;
        final id = ZegoLiveIdUtils.sanitizeUserId(user.id);
        if (targetSanitized.isNotEmpty && id == targetSanitized) {
          return user;
        }
        matched ??= user;
      }
      return matched;
    } catch (_) {
      return null;
    }
  }

  ZegoUIKitUser? _resolveVideoUser() {
    if (widget.isHost) {
      return _resolveLocalHostPreview();
    }
    final target = ZegoLiveIdUtils.sanitizeUserId(widget.hostUserId.trim());
    return _resolveRemoteHostUser(target);
  }

  Widget _videoSurface(ZegoUIKitUser user) {
    return SizedBox.expand(
      child: ZegoAudioVideoView(
        user: user,
        borderRadius: 0,
        borderColor: Colors.transparent,
        backgroundBuilder: (context, size, _, __) {
          return _fallback(color: Colors.black);
        },
        avatarConfig: ZegoAvatarConfig(
          showInAudioMode: true,
          showSoundWavesInAudioMode: true,
          builder: (context, size, _, __) {
            return AppUserAvatar(
              name: widget.hostName,
              imageUrl: widget.hostAvatarUrl,
              size: size.shortestSide * 0.28,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _ensureScreenUtil();

    final controller = Get.find<LiveBroadcastController>();
    return Obx(() {
      final _ = controller.zegoMediaUsersTick.value;

      if (!controller.isZegoConnected.value || !_screenUtilReady) {
        return _fallback();
      }

      final user = _resolveVideoUser();
      if (user == null) {
        return _fallback();
      }

      return ValueListenableBuilder<bool>(
        valueListenable: ZegoUIKit().getCameraStateNotifier(user.id),
        builder: (context, _, __) => _videoSurface(user),
      );
    });
  }
}
