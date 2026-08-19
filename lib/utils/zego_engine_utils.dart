import 'dart:async';

import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';
import 'package:zego_uikit/zego_uikit.dart';

/// Resets the shared Zego Express engine between Zego console projects.
///
/// Features use different App IDs. ZegoUIKit only initializes once per process,
/// so switching use cases must uninit the old engine first.
abstract final class ZegoEngineUtils {
  /// Native uninit can exceed 700ms. Joining before it finishes paints a black
  /// canvas, so callers must wait for this full reset (including settle delay).
  static const Duration resetTimeout = Duration(seconds: 3);

  static Future<void> resetForCallProject() async {
    await _resetEngine('call');
  }

  static Future<void> resetAfterCall() async {
    await _resetEngine('post-call');
  }

  static Future<void> resetForLiveProject() async {
    await _resetEngine('live');
  }

  static Future<void> resetForRoomProject() async {
    await _resetEngine('room-call');
  }

  static Future<void> _resetEngine(String reason) async {
    try {
      await Future<void>(() async {
        try {
          await ZegoUIKit().leaveRoom();
        } catch (e) {
          LoggerUtils.logWarning('ZegoEngineUtils: leaveRoom ($reason) — $e');
        }
        try {
          await ZegoUIKit().uninit();
          LoggerUtils.logInfo('ZegoEngineUtils: engine reset ($reason)');
        } catch (e) {
          LoggerUtils.logWarning('ZegoEngineUtils: uninit ($reason) — $e');
        }
        // Native teardown can lag uninit(); joining immediately causes a black canvas.
        await Future<void>.delayed(const Duration(milliseconds: 280));
      }).timeout(resetTimeout);
    } on TimeoutException {
      LoggerUtils.logWarning('ZegoEngineUtils: reset timed out ($reason)');
    }
  }
}
