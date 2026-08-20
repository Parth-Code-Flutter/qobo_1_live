import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/incoming_call_ring_ui.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// WhatsApp-style incoming 1:1 call sheet — avatar, ring pulse, green/red phones.
class IncomingCallRingDialog extends StatefulWidget {
  const IncomingCallRingDialog({
    super.key,
    required this.callerName,
    required this.subtitle,
    required this.isVideo,
    this.avatarUrl,
    required this.onDecline,
    required this.onAccept,
  });

  final String callerName;
  final String subtitle;
  final bool isVideo;
  final String? avatarUrl;
  final Future<void> Function() onDecline;
  final Future<void> Function() onAccept;

  @override
  State<IncomingCallRingDialog> createState() => _IncomingCallRingDialogState();
}

class _IncomingCallRingDialogState extends State<IncomingCallRingDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handle(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    // Mark closed + pop BEFORE reject/accept work. Those handlers also call
    // dismissIfShowing(); a second Get.back() would pop the page underneath
    // and leave a black screen.
    IncomingCallRingUi.prepareClose();
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop<void>();
    }
    try {
      await action();
    } catch (_) {
      // Decline/accept API errors must not leave the UI stuck.
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatar = ApiImageUtils.normalize(widget.avatarUrl) ?? '';

    return PopScope(
      canPop: false,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0E1628).withValues(alpha: 0.98),
                    const Color(0xFF060910).withValues(alpha: 0.99),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  _PulsingAvatar(
                    controller: _pulseController,
                    avatarUrl: avatar,
                    isVideo: widget.isVideo,
                  ),
                  Spacing.v20,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SemiBoldText(
                      text: widget.callerName,
                      fontSize: TextStyles.k22FontSize,
                      color: kColorWhite,
                      align: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Spacing.v8,
                  AppText(
                    text: widget.subtitle,
                    fontSize: TextStyles.k14FontSize,
                    color: kColorWhite.withValues(alpha: 0.72),
                    align: TextAlign.center,
                  ),
                  const Spacer(flex: 3),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(36, 0, 36, 28),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _PhoneActionOrb(
                          icon: Icons.call_end_rounded,
                          colors: const [Color(0xFFFF6B8A), Color(0xFFE53935)],
                          glow: const Color(0xFFE53935),
                          enabled: !_busy,
                          onTap: () => _handle(widget.onDecline),
                        ),
                        _PhoneActionOrb(
                          icon: widget.isVideo
                              ? Icons.videocam_rounded
                              : Icons.call_rounded,
                          colors: const [Color(0xFF34D399), Color(0xFF10B981)],
                          glow: const Color(0xFF10B981),
                          enabled: !_busy,
                          onTap: () => _handle(widget.onAccept),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_busy)
              const ColoredBox(
                color: Color(0x33000000),
                child: Center(
                  child: CircularProgressIndicator(color: kColorWhite),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PulsingAvatar extends StatelessWidget {
  const _PulsingAvatar({
    required this.controller,
    required this.avatarUrl,
    required this.isVideo,
  });

  final AnimationController controller;
  final String avatarUrl;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final scale = 1 + (controller.value * 0.14);
        final opacity = 0.45 - (controller.value * 0.35);
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: scale,
              child: Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: opacity),
                    width: 3,
                  ),
                ),
              ),
            ),
            child!,
          ],
        );
      },
      child: Container(
        width: 108,
        height: 108,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFFF5CAB), Color(0xFF9C6BFF)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9C6BFF).withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(3),
        child: ClipOval(
          child: avatarUrl.isNotEmpty
              ? Image.network(
                  avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallback(isVideo),
                )
              : _fallback(isVideo),
        ),
      ),
    );
  }

  Widget _fallback(bool isVideo) {
    return ColoredBox(
      color: const Color(0xFF1E1E2D),
      child: Icon(
        isVideo ? Icons.videocam_rounded : Icons.person_rounded,
        color: kColorWhite.withValues(alpha: 0.75),
        size: 42,
      ),
    );
  }
}

class _PhoneActionOrb extends StatelessWidget {
  const _PhoneActionOrb({
    required this.icon,
    required this.colors,
    required this.glow,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final List<Color> colors;
  final Color glow;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            boxShadow: [
              BoxShadow(
                color: glow.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: kColorWhite,
            size: 32,
          ),
        ),
      ),
    );
  }
}
