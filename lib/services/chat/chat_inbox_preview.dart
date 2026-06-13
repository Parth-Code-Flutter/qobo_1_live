/// Inbox preview types stored on `userChats/{userId}/rooms/{roomId}`.
abstract final class ChatInboxPreviewType {
  static const text = 'text';
  static const voiceCall = 'voice_call';
  static const videoCall = 'video_call';
  static const missedVoiceCall = 'missed_voice_call';
  static const missedVideoCall = 'missed_video_call';

  static bool isCallType(String? type) {
    if (type == null || type.isEmpty) return false;
    return type == voiceCall ||
        type == videoCall ||
        type == missedVoiceCall ||
        type == missedVideoCall;
  }

  static bool isMissedCall(String? type) {
    return type == missedVoiceCall || type == missedVideoCall;
  }

  static String displayLabel(String? type, {String? fallbackPreview}) {
    final preview = fallbackPreview?.trim() ?? '';
    if (preview.isNotEmpty && !isCallType(type)) return preview;

    switch (type) {
      case voiceCall:
        return 'Voice call';
      case videoCall:
        return 'Video call';
      case missedVoiceCall:
        return 'Missed voice call';
      case missedVideoCall:
        return 'Missed video call';
      default:
        return preview.isNotEmpty ? preview : '';
    }
  }

  /// Maps call outcome + per-user direction to inbox [lastMessageType].
  static String inboxTypeForUser({
    required bool isVideo,
    required String outcome,
    required bool isCallee,
  }) {
    final missed = outcome == 'missed';
    if (missed && isCallee) {
      return isVideo ? missedVideoCall : missedVoiceCall;
    }
    return isVideo ? videoCall : voiceCall;
  }
}
