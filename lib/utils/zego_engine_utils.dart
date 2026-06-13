import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';
import 'package:zego_uikit/zego_uikit.dart';

/// Resets the shared Zego Express engine between live streaming and voice call.
///
/// Both features use different Zego console projects (App IDs). ZegoUIKit only
/// initializes once per process — without reset, voice call reuses the live
/// streaming engine and room login fails silently.
abstract final class ZegoEngineUtils {
  static Future<void> resetForCallProject() async {
    await _resetEngine('call');
  }

  static Future<void> resetAfterCall() async {
    await _resetEngine('post-call');
  }

  static Future<void> resetForLiveProject() async {
    await _resetEngine('live');
  }

  static Future<void> _resetEngine(String reason) async {
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
  }
}
