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
    return outcome == 'completed';
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

  static String? callDurationLabel(int? seconds) {
    if (seconds == null || seconds <= 0) return null;
    if (seconds < 60) return '$seconds sec';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remMin = minutes % 60;
    if (remMin == 0) return '$hours hr';
    return '$hours hr $remMin min';
  }

  static String? callSubtitleForUser({
    required String outcome,
    required bool isCallee,
    int? durationSeconds,
  }) {
    if (isCompletedCall(outcome: outcome, durationSeconds: durationSeconds)) {
      return callDurationLabel(durationSeconds);
    }
    if (isMissedForUser(
      outcome: outcome,
      isCallee: isCallee,
      durationSeconds: durationSeconds,
    )) {
      return 'Missed call';
    }
    if (isUnansweredForUser(
      outcome: outcome,
      isCallee: isCallee,
      durationSeconds: durationSeconds,
    )) {
      return 'No answer';
    }
    return null;
  }
}
