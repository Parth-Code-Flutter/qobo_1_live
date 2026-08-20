import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:push_notification_service/push_notification_service.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/services/firebase/incoming_call_push_handler.dart';
import 'package:qobo_one_live/services/firebase/incoming_call_push_payload.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Foreground fallback when Firestore ring is unavailable (e.g. no Firebase).
abstract final class IncomingCallInAppBanner {
  IncomingCallInAppBanner._();

  static bool _isShowing = false;

  static void dismissIfShowing() {
    if (_isShowing && (Get.isDialogOpen ?? false)) {
      Get.back<void>();
    }
  }

  /// Returns true when custom UI was shown (skip duplicate OS tray).
  static Future<bool> tryShow(
    PushNotificationMessage message, {
    IncomingCallPushHandler? handler,
  }) async {
    final payload = IncomingCallPushPayload.fromMessage(message);
    if (payload == null || !payload.isIncomingRing) return false;

    final context = Get.overlayContext ?? Get.context;
    if (context == null) return false;
    if (_isShowing) return true;

    _isShowing = true;
    final callHandler = handler ?? IncomingCallPushHandler();

    try {
      await Get.dialog<void>(
        _IncomingCallBannerDialog(
          message: message,
          payload: payload,
          handler: callHandler,
        ),
        barrierDismissible: false,
        barrierColor: kColorBlack.withValues(alpha: 0.62),
      );
    } finally {
      _isShowing = false;
    }
    return true;
  }
}

class _IncomingCallBannerDialog extends StatelessWidget {
  const _IncomingCallBannerDialog({
    required this.message,
    required this.payload,
    required this.handler,
  });

  final PushNotificationMessage message;
  final IncomingCallPushPayload payload;
  final IncomingCallPushHandler handler;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = ApiImageUtils.normalize(payload.callerAvatar) ?? '';
    final isVideo = payload.isVideo;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A1638), Color(0xFF140C22), Color(0xFF0C0814)],
          ),
          border: Border.all(
            color: const Color(0xFF9C6BFF).withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9C6BFF).withValues(alpha: 0.22),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5CAB), Color(0xFF9C6BFF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5CAB).withValues(alpha: 0.35),
                    blurRadius: 18,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(3),
              child: ClipOval(
                child: avatarUrl.isNotEmpty
                    ? Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fallbackAvatar(isVideo),
                      )
                    : _fallbackAvatar(isVideo),
              ),
            ),
            Spacing.v16,
            SemiBoldText(
              text: payload.bannerTitle,
              fontSize: TextStyles.k18FontSize,
              color: kColorWhite,
              align: TextAlign.center,
            ),
            Spacing.v6,
            AppText(
              text: payload.bannerBody,
              fontSize: TextStyles.k14FontSize,
              color: kColorWhite.withValues(alpha: 0.78),
              align: TextAlign.center,
            ),
            Spacing.v20,
            Row(
              children: [
                Expanded(
                  child: _CallActionButton(
                    label: 'Decline',
                    icon: Icons.call_end_rounded,
                    colors: const [Color(0xFFFF6B8A), Color(0xFFE53935)],
                    onTap: () async {
                      Get.back<void>();
                      await handler.handleNotificationAction(
                        actionId: PushNotificationActions.rejectCall,
                        message: message,
                      );
                    },
                  ),
                ),
                Spacing.h12,
                Expanded(
                  child: _CallActionButton(
                    label: 'Accept',
                    icon: isVideo
                        ? Icons.videocam_rounded
                        : Icons.call_rounded,
                    colors: const [Color(0xFF34D399), Color(0xFF10B981)],
                    onTap: () async {
                      Get.back<void>();
                      await handler.handleNotificationAction(
                        actionId: PushNotificationActions.acceptCall,
                        message: message,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackAvatar(bool isVideo) {
    return ColoredBox(
      color: const Color(0xFF1E1E2D),
      child: Icon(
        isVideo ? Icons.videocam_rounded : Icons.person_rounded,
        color: kColorWhite.withValues(alpha: 0.7),
        size: 34,
      ),
    );
  }
}

class _CallActionButton extends StatelessWidget {
  const _CallActionButton({
    required this.label,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(colors: colors),
            boxShadow: [
              BoxShadow(
                color: colors.first.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: kColorWhite, size: 20),
              const SizedBox(width: 8),
              SemiBoldText(
                text: label,
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
