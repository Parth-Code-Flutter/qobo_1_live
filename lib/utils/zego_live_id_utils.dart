import 'dart:math';

/// Helpers for Zego `liveID` / `userID` formatting.
abstract final class ZegoLiveIdUtils {
  /// Zego allows letters, digits, and underscore; max 128 bytes.
  static String sanitize(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
    if (cleaned.isEmpty) {
      return generate();
    }
    return cleaned.length > 128 ? cleaned.substring(0, 128) : cleaned;
  }

  /// Host channel id (no special chars beyond underscore).
  static String generate() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final suffix = Random().nextInt(999999).toString().padLeft(6, '0');
    return sanitize('ls_${ts}_$suffix');
  }

  /// Zego `userID` max 32 chars, alphanumeric recommended.
  static String sanitizeUserId(String raw) {
    var id = raw.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
    if (id.isEmpty) {
      id = 'user_${DateTime.now().millisecondsSinceEpoch}';
    }
    if (id.length > 32) {
      id = id.substring(0, 32);
    }
    return id;
  }

  /// Canonical Zego `liveID` for host publish **and** audience join.
  ///
  /// Per backend `LIVE_STREAMING_MOBILE_API_DOCUMENTATION.md`:
  /// - Zego channel = `zegoLiveId` / `liveStreamingId` (`ls_…`)
  /// - Backend UUID `room_id` / `id` is for REST join/leave/end only
  ///
  /// Prefer stream channel keys first. Fall back to UUID only when the payload
  /// has no `ls_…` / zegoLiveId (legacy).
  static String? resolveLiveChannelId(Map<String, dynamic> roomData) {
    String? text(dynamic value) {
      final t = value?.toString().trim();
      if (t == null || t.isEmpty || t == 'null') return null;
      return t;
    }

    Map<String, dynamic>? asMap(dynamic value) {
      if (value is Map) return Map<String, dynamic>.from(value);
      return null;
    }

    final nested =
        asMap(roomData['room']) ??
        asMap(roomData['liveStreaming']) ??
        asMap(roomData['live_streaming']) ??
        const <String, dynamic>{};

    final zegoStreaming = asMap(roomData['zegoStreaming']);

    // 1) Explicit Zego channel from create / list / join (ls_…).
    final streamChannel =
        text(roomData['zegoLiveId']) ??
        text(roomData['zego_live_id']) ??
        text(nested['zegoLiveId']) ??
        text(nested['zego_live_id']) ??
        text(roomData['channelName']) ??
        text(roomData['channel_name']) ??
        text(roomData['liveStreamingId']) ??
        text(roomData['live_streaming_id']) ??
        text(nested['liveStreamingId']) ??
        text(nested['live_streaming_id']) ??
        text(roomData['liveStreamId']) ??
        text(roomData['liveId']) ??
        (zegoStreaming != null
            ? text(zegoStreaming['roomId']) ??
                  text(zegoStreaming['room_id']) ??
                  text(zegoStreaming['liveId']) ??
                  text(zegoStreaming['live_id']) ??
                  text(zegoStreaming['zegoLiveId']) ??
                  text(zegoStreaming['zego_live_id'])
            : null);

    if (streamChannel != null && streamChannel.isNotEmpty) {
      return sanitize(streamChannel);
    }

    // 2) Legacy fallback — some older payloads only carry the UUID.
    final backendRoomId =
        text(roomData['room_id']) ??
        text(roomData['roomId']) ??
        text(roomData['_id']) ??
        text(roomData['id']) ??
        text(nested['room_id']) ??
        text(nested['roomId']) ??
        text(nested['_id']) ??
        text(nested['id']);

    if (backendRoomId == null || backendRoomId.isEmpty) return null;
    return sanitize(backendRoomId);
  }

  /// Writes [resolveLiveChannelId] onto the keys the broadcast screen reads.
  static Map<String, dynamic> applyLiveChannelId(
    Map<String, dynamic> roomData,
  ) {
    final channel = resolveLiveChannelId(roomData);
    if (channel == null || channel.isEmpty) return roomData;
    roomData['zegoLiveId'] = channel;
    roomData['channelName'] = channel;
    // Keep liveStreamingId as the ls_… / channel string for end/leave APIs
    // when it was missing or wrongly set to a UUID.
    final existing = roomData['liveStreamingId']?.toString().trim() ?? '';
    if (existing.isEmpty ||
        existing == 'null' ||
        (!existing.startsWith('ls') && channel.startsWith('ls'))) {
      roomData['liveStreamingId'] = channel;
      roomData['live_streaming_id'] = channel;
    }
    return roomData;
  }
}
