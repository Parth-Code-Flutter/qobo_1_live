/// Inbox preview types stored on `userChats/{userId}/rooms/{roomId}`.
abstract final class ChatInboxPreviewType {
  static const text = 'text';
  static const voiceCall = 'voice_call';
  static const videoCall = 'video_call';
  static const missedVoiceCall = 'missed_voice_call';
  static const missedVideoCall = 'missed_video_call';
  static const unansweredVoiceCall = 'unanswered_voice_call';
  static const unansweredVideoCall = 'unanswered_video_call';

  static bool isCallType(String? type) {
    if (type == null || type.isEmpty) return false;
    return type == voiceCall ||
        type == videoCall ||
        type == missedVoiceCall ||
        type == missedVideoCall ||
        type == unansweredVoiceCall ||
        type == unansweredVideoCall;
  }

  static bool isMissedCall(String? type) {
    return type == missedVoiceCall || type == missedVideoCall;
  }

  static bool isUnansweredCall(String? type) {
    return type == unansweredVoiceCall || type == unansweredVideoCall;
  }

  static bool isUnansweredOutcome(String outcome) {
    return outcome == 'missed' || outcome == 'cancelled';
  }

  static bool isCompletedCall({
    required String outcome,
    int? durationSeconds,
    bool peerJoined = false,
  }) {
    if (outcome == 'completed') return true;
    if (peerJoined && (durationSeconds ?? 0) > 0) return true;
    return false;
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
      case unansweredVoiceCall:
        return 'Unanswered voice call';
      case unansweredVideoCall:
        return 'Unanswered video call';
      default:
        return preview.isNotEmpty ? preview : '';
    }
  }

  /// Maps call outcome + per-user direction to inbox [lastMessageType].
  static String inboxTypeForUser({
    required bool isVideo,
    required String outcome,
    required bool isCallee,
    int? durationSeconds,
    bool peerJoined = false,
  }) {
    if (isCompletedCall(
      outcome: outcome,
      durationSeconds: durationSeconds,
      peerJoined: peerJoined,
    )) {
      return isVideo ? videoCall : voiceCall;
    }

    if (isCallee) {
      return isVideo ? missedVideoCall : missedVoiceCall;
    }
    return isVideo ? unansweredVideoCall : unansweredVoiceCall;
  }

  /// Chat thread + inbox subtitle label for the current user.
  static String chatLabelForUser({
    required bool isVideo,
    required String outcome,
    required bool isCallee,
    int? durationSeconds,
    bool peerJoined = false,
  }) {
    final type = inboxTypeForUser(
      isVideo: isVideo,
      outcome: outcome,
      isCallee: isCallee,
      durationSeconds: durationSeconds,
      peerJoined: peerJoined,
    );
    return displayLabel(type);
  }

  static bool isMissedForUser({
    required String outcome,
    required bool isCallee,
    int? durationSeconds,
    bool peerJoined = false,
  }) {
    if (isCompletedCall(
      outcome: outcome,
      durationSeconds: durationSeconds,
      peerJoined: peerJoined,
    )) {
      return false;
    }
    return isCallee;
  }

  static bool isUnansweredForUser({
    required String outcome,
    required bool isCallee,
    int? durationSeconds,
    bool peerJoined = false,
  }) {
    if (isCompletedCall(
      outcome: outcome,
      durationSeconds: durationSeconds,
      peerJoined: peerJoined,
    )) {
      return false;
    }
    return !isCallee;
  }
}
