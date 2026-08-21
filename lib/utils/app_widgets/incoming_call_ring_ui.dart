import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/services/chat/incoming_call_ringer.dart';
import 'package:qobo_one_live/utils/app_widgets/incoming_call_ring_dialog.dart';

/// Shows / dismisses the shared WhatsApp-style incoming call ring UI.
abstract final class IncomingCallRingUi {
  IncomingCallRingUi._();

  static bool _isShowing = false;

  static bool get isShowing => _isShowing;

  static Future<void> show({
    required String callerName,
    required String subtitle,
    required bool isVideo,
    String? avatarUrl,
    required Future<void> Function() onDecline,
    required Future<void> Function() onAccept,
  }) async {
    if (_isShowing) return;
    _isShowing = true;
    await IncomingCallRinger.start();
    try {
      // Ensure overlay exists (FCM can arrive before first frame after resume).
      var attempts = 0;
      while (Get.overlayContext == null && attempts < 20) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        attempts++;
      }
      await Get.dialog<void>(
        IncomingCallRingDialog(
          callerName: callerName,
          subtitle: subtitle,
          isVideo: isVideo,
          avatarUrl: avatarUrl,
          onDecline: onDecline,
          onAccept: onAccept,
        ),
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.92),
        useSafeArea: false,
      );
    } finally {
      await IncomingCallRinger.stop();
      _isShowing = false;
    }
  }

  /// Call before popping the ring dialog so reject/accept cannot Get.back() again.
  static void prepareClose() {
    IncomingCallRinger.stop();
    _isShowing = false;
  }

  static void dismissIfShowing() {
    IncomingCallRinger.stop();
    if (!_isShowing) return;
    final dialogOpen = Get.isDialogOpen ?? false;
    _isShowing = false;
    // Only close the ring dialog — never pop an underlying page.
    if (dialogOpen) {
      Get.back<void>();
    }
  }
}
