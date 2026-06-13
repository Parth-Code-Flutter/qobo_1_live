import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

/// Camera + microphone access required for video live hosts.
class LiveStreamingPermissions {
  LiveStreamingPermissions._();

  static Future<bool> ensureHostVideoPermissions(BuildContext context) async {
    final camera = await Permission.camera.request();
    if (!camera.isGranted) {
      if (context.mounted) {
        AppToast.showError(
          context,
          'Camera permission is required to broadcast video',
        );
      }
      return false;
    }

    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      if (context.mounted) {
        AppToast.showError(
          context,
          'Microphone permission is required to go live',
        );
      }
      return false;
    }

    return true;
  }

  static Future<bool> ensureHostAudioPermissions(BuildContext context) async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      if (context.mounted) {
        AppToast.showError(
          context,
          'Microphone permission is required to go live',
        );
      }
      return false;
    }
    return true;
  }
}
