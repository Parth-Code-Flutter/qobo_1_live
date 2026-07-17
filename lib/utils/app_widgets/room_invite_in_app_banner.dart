import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:push_notification_service/push_notification_service.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/live_room_ui_colors.dart';
import 'package:qobo_one_live/services/firebase/room_invite_push_handler.dart';
import 'package:qobo_one_live/services/firebase/room_invite_push_payload.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Branded foreground invite card — system tray buttons cannot use app gradients.
abstract final class RoomInviteInAppBanner {
  RoomInviteInAppBanner._();

  static bool _isShowing = false;

  /// Returns true when the custom UI was shown (host should skip system tray).
  static Future<bool> tryShow(
    PushNotificationMessage message, {
    RoomInvitePushHandler? handler,
  }) async {
    final payload = RoomInvitePushPayload.fromMessage(message);
    if (payload == null) return false;

    final context = Get.overlayContext ?? Get.context;
    if (context == null) return false;
    if (_isShowing) return true;

    _isShowing = true;
    final inviteHandler = handler ?? RoomInvitePushHandler();

    try {
      await Get.dialog<void>(
        _RoomInviteBannerDialog(
          message: message,
          payload: payload,
          handler: inviteHandler,
        ),
        barrierDismissible: true,
        barrierColor: kColorBlack.withValues(alpha: 0.55),
      );
    } finally {
      _isShowing = false;
    }
    return true;
  }
}

class _RoomInviteBannerDialog extends StatelessWidget {
  const _RoomInviteBannerDialog({
    required this.message,
    required this.payload,
    required this.handler,
  });

  final PushNotificationMessage message;
  final RoomInvitePushPayload payload;
  final RoomInvitePushHandler handler;

  @override
  Widget build(BuildContext context) {
    final isInvite = payload.isDirectInvite;
    final secondaryLabel = isInvite ? 'Reject' : 'Dismiss';
    final secondaryAction = isInvite
        ? PushNotificationActions.rejectRoom
        : PushNotificationActions.dismissRoom;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2B1654), Color(0xFF171339)],
          ),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.16)),
          boxShadow: [
            BoxShadow(
              color: LiveRoomUiColors.goLiveGradientStart.withValues(
                alpha: 0.28,
              ),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF355D), Color(0xFFFF3EA5)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 7, color: kColorWhite),
                      SizedBox(width: 5),
                      SemiBoldText(
                        text: 'LIVE',
                        fontSize: TextStyles.k10FontSize,
                        color: kColorWhite,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Get.back<void>(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: kColorWhite.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
            Spacing.v12,
            SemiBoldText(
              text: payload.bannerTitle,
              fontSize: TextStyles.k18FontSize,
              color: kColorWhite,
            ),
            Spacing.v6,
            AppText(
              text: payload.bannerBody,
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite.withValues(alpha: 0.78),
            ),
            Spacing.v16,
            // Vertical primary/secondary actions — fully branded (unlike OS tray).
            _GradientActionButton(
              label: 'Join Now',
              icon: Icons.play_arrow_rounded,
              onTap: () async {
                Get.back<void>();
                await handler.handleNotificationAction(
                  actionId: PushNotificationActions.joinRoom,
                  message: message,
                );
              },
            ),
            Spacing.v10,
            _SecondaryActionButton(
              label: secondaryLabel,
              icon: isInvite ? Icons.block_rounded : Icons.close_rounded,
              onTap: () async {
                Get.back<void>();
                await handler.handleNotificationAction(
                  actionId: secondaryAction,
                  message: message,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                LiveRoomUiColors.goLiveGradientStart,
                LiveRoomUiColors.goLiveGradientEnd,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: LiveRoomUiColors.goLiveGradientStart.withValues(
                  alpha: 0.40,
                ),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: kColorWhite, size: 26),
              Spacing.h6,
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

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: kColorWhite.withValues(alpha: 0.08),
            border: Border.all(color: kColorWhite.withValues(alpha: 0.16)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: kColorWhite.withValues(alpha: 0.82), size: 20),
              Spacing.h6,
              SemiBoldText(
                text: label,
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite.withValues(alpha: 0.90),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
