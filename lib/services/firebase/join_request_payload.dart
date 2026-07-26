import 'package:push_notification_service/push_notification_service.dart';

/// Parsed join-request FCM / socket / API payloads.
class JoinRequestPayload {
  const JoinRequestPayload({
    required this.type,
    required this.requestId,
    required this.roomId,
    required this.sessionType,
    required this.roomTitle,
    required this.requesterId,
    required this.requesterName,
    required this.requesterAvatar,
    required this.notificationId,
    required this.expiresAt,
    this.hostId = '',
    this.hostName = '',
    this.message = '',
    this.status = '',
  });

  final String type;
  final String requestId;
  final String roomId;
  final String sessionType;
  final String roomTitle;
  final String requesterId;
  final String requesterName;
  final String requesterAvatar;
  final String notificationId;
  final DateTime? expiresAt;
  final String hostId;
  final String hostName;
  final String message;
  final String status;

  bool get isHostRequest => type == PushNotificationTypes.joinRequest;
  bool get isApproved =>
      type == PushNotificationTypes.joinApproved || status == 'approved';
  bool get isRejected =>
      type == PushNotificationTypes.joinRejected || status == 'rejected';
  bool get isExpired =>
      type == PushNotificationTypes.joinRequestExpired || status == 'expired';
  bool get isLiveStream =>
      sessionType == 'live_stream' || sessionType == 'livestream';

  bool get hasTimedOut {
    if (expiresAt == null) return false;
    return DateTime.now().toUtc().isAfter(expiresAt!.toUtc());
  }

  String get bannerTitle {
    if (isHostRequest) return 'Join Request';
    if (isApproved) return 'Join Approved';
    if (isRejected) return 'Join Declined';
    if (isExpired) return 'Request Expired';
    return 'Join Request';
  }

  String get bannerBody {
    if (message.trim().isNotEmpty) return message.trim();
    if (isHostRequest) {
      final name = requesterName.isNotEmpty ? requesterName : 'Someone';
      final room = roomTitle.isNotEmpty ? '"$roomTitle"' : 'your room';
      return '$name wants to join $room';
    }
    if (isApproved) return 'Host approved your request. Joining now…';
    if (isRejected) return 'Host declined your request to join';
    if (isExpired) return 'Your join request expired. Try again.';
    return '';
  }

  static JoinRequestPayload? tryParse(Map<String, dynamic> data) {
    final type =
        (_text(data['type']) ?? _text(data['event']))?.toLowerCase() ?? '';
    if (!PushNotificationTypes.isJoinRequestType(type) &&
        !_looksLikeJoinRequestMap(data)) {
      return null;
    }

    final requestId =
        _text(data['request_id']) ??
        _text(data['requestId']) ??
        _text(data['join_request_id']) ??
        '';
    final roomId = _text(data['room_id']) ?? _text(data['roomId']) ?? '';
    if (requestId.isEmpty && roomId.isEmpty) return null;

    final user = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'] as Map)
        : <String, dynamic>{};

    return JoinRequestPayload(
      type: type.isNotEmpty ? type : PushNotificationTypes.joinRequest,
      requestId: requestId,
      roomId: roomId,
      sessionType:
          (_text(data['session_type']) ??
              _text(data['sessionType']) ??
              'audio_room')
              .toLowerCase(),
      roomTitle:
          _text(data['room_title']) ??
          _text(data['roomTitle']) ??
          _text(data['title']) ??
          '',
      requesterId:
          _text(data['requester_id']) ??
          _text(data['requesterId']) ??
          _text(data['user_id']) ??
          _text(user['id']) ??
          '',
      requesterName:
          _text(data['requester_name']) ??
          _text(data['requesterName']) ??
          _text(user['name']) ??
          '',
      requesterAvatar:
          _text(data['requester_avatar']) ??
          _text(data['requesterAvatar']) ??
          _text(user['avatar']) ??
          '',
      notificationId: _text(data['notification_id']) ?? '',
      expiresAt: _parseDate(
        data['expires_at'] ?? data['expiresAt'],
      ),
      hostId: _text(data['host_id']) ?? _text(data['hostId']) ?? '',
      hostName: _text(data['host_name']) ?? _text(data['hostName']) ?? '',
      message: _text(data['message']) ?? '',
      status: (_text(data['status']) ?? '').toLowerCase(),
    );
  }

  static JoinRequestPayload? fromMessage(PushNotificationMessage message) {
    return tryParse(message.data);
  }

  static bool _looksLikeJoinRequestMap(Map<String, dynamic> data) {
    return (_text(data['request_id']) ?? _text(data['requestId'])) != null &&
        (_text(data['room_id']) ?? _text(data['roomId'])) != null;
  }

  static DateTime? _parseDate(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  static String? _text(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return null;
    return text;
  }
}

/// Outcome of a pending viewer join-request wait.
enum JoinRequestWaitResult {
  approved,
  rejected,
  expired,
  cancelled,
  failed,
}

class JoinRequestWaitOutcome {
  const JoinRequestWaitOutcome({
    required this.result,
    this.requestId = '',
    this.roomId = '',
    this.sessionType = '',
    this.message = '',
    this.joinPayload,
  });

  final JoinRequestWaitResult result;
  final String requestId;
  final String roomId;
  final String sessionType;
  final String message;
  final Map<String, dynamic>? joinPayload;

  bool get isApproved => result == JoinRequestWaitResult.approved;
}
