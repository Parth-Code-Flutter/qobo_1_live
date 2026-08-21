/// Active audio / video / live session on a public Discover profile card.
///
/// Parsed from `GET /api/user/public/:id` nested `activeSession` or flat aliases.
class UserActiveSession {
  const UserActiveSession({
    required this.isLive,
    this.roomId,
    this.roomType,
    this.sessionType,
    this.title,
    this.hostId,
    this.viewerCount = 0,
    this.joinApprovalRequired = false,
    this.liveStreamingId,
    this.coverUrl,
  });

  final bool isLive;
  final String? roomId;
  final String? roomType;
  final String? sessionType;
  final String? title;
  final String? hostId;
  final int viewerCount;
  final bool joinApprovalRequired;
  final String? liveStreamingId;
  final String? coverUrl;

  /// Ready for Join / Enter (live + joinable room id).
  bool get isJoinable {
    final id = roomId?.trim() ?? '';
    return isLive && id.isNotEmpty;
  }

  bool get isLiveStream {
    final type = (roomType ?? '').toUpperCase();
    final session = (sessionType ?? '').toLowerCase();
    return type.contains('LIVE') || session.contains('live');
  }

  /// Normalized UI type: `AUDIO` | `VIDEO` | `LIVE_STREAM`.
  String get normalizedRoomType {
    final raw = (roomType ?? sessionType ?? '').trim().toUpperCase();
    if (raw.contains('LIVE')) return 'LIVE_STREAM';
    if (raw.contains('AUDIO')) return 'AUDIO';
    if (raw.contains('VIDEO')) return 'VIDEO';
    if (isLiveStream) return 'LIVE_STREAM';
    return 'VIDEO';
  }

  /// Value for `POST /api/room/join` `session_type`.
  String get resolvedSessionType {
    final explicit = sessionType?.trim() ?? '';
    if (explicit.isNotEmpty) return explicit;
    switch (normalizedRoomType) {
      case 'AUDIO':
        return 'audio_room';
      case 'LIVE_STREAM':
        return 'live_stream';
      default:
        return 'video_room';
    }
  }

  String get joinButtonLabel {
    switch (normalizedRoomType) {
      case 'AUDIO':
        return 'Join Audio Room';
      case 'VIDEO':
        return 'Join Video Room';
      case 'LIVE_STREAM':
        return 'Join Live Stream';
      default:
        return 'Enter Room';
    }
  }

  String get liveBadgeLabel {
    switch (normalizedRoomType) {
      case 'AUDIO':
        return 'LIVE · AUDIO';
      case 'VIDEO':
        return 'LIVE · VIDEO';
      case 'LIVE_STREAM':
        return 'LIVE';
      default:
        return 'LIVE';
    }
  }

  factory UserActiveSession.fromJson(Map<String, dynamic> json) {
    final nested = json['activeSession'] ?? json['active_session'];
    final Map<String, dynamic> source;
    if (nested is Map) {
      source = {...json, ...Map<String, dynamic>.from(nested)};
    } else {
      source = json;
    }

    final roomId = _text(source['roomId'] ?? source['room_id']);

    return UserActiveSession(
      isLive: _bool(source['isLive'] ?? source['is_live']),
      roomId: roomId,
      roomType: _text(source['roomType'] ?? source['room_type']),
      sessionType: _text(source['sessionType'] ?? source['session_type']),
      title: _text(source['title']),
      hostId: _text(source['hostId'] ?? source['host_id']),
      viewerCount: _int(source['viewerCount'] ?? source['viewer_count']),
      joinApprovalRequired: _bool(
        source['joinApprovalRequired'] ?? source['join_approval_required'],
      ),
      liveStreamingId: _text(
        source['liveStreamingId'] ?? source['live_streaming_id'],
      ),
      coverUrl: _text(source['coverUrl'] ?? source['cover_url']),
    );
  }

  /// Prefer nested `activeSession`; fall back to flat aliases on the card.
  static UserActiveSession? tryParse(Map<String, dynamic> json) {
    final nested = json['activeSession'] ?? json['active_session'];
    if (nested is Map) {
      return UserActiveSession.fromJson(Map<String, dynamic>.from(nested));
    }

    final hasFlatHint =
        json.containsKey('isLive') ||
        json.containsKey('is_live') ||
        json.containsKey('roomId') ||
        json.containsKey('room_id') ||
        json.containsKey('roomType') ||
        json.containsKey('room_type');
    if (!hasFlatHint) return null;
    return UserActiveSession.fromJson(json);
  }

  static String? _text(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return null;
    return text;
  }

  static bool _bool(dynamic value) {
    if (value == true) return true;
    if (value == false || value == null) return false;
    final text = value.toString().trim().toLowerCase();
    return text == 'true' || text == '1';
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
