import 'package:qobo_one_live/utils/zego_live_id_utils.dart';

/// Stable Zego `callID` for 1:1 chat voice calls.
abstract final class ZegoCallIdUtils {
  /// Use chat `roomId` as the Zego call channel (max 128 chars, alphanumeric + _).
  static String fromRoomId(String roomId) {
    final sanitized = ZegoLiveIdUtils.sanitize(roomId);
    if (sanitized.isEmpty) {
      return ZegoLiveIdUtils.generate().replaceFirst('ls_', 'vc_');
    }
    return sanitized.startsWith('vc_') ? sanitized : 'vc_$sanitized';
  }
}
