import 'package:push_notification_service/push_notification_service.dart';

/// Parsed FCM payload for 1:1 voice/video incoming call pushes.
class IncomingCallPushPayload {
  const IncomingCallPushPayload({
    required this.type,
    required this.notificationId,
    required this.callId,
    required this.roomId,
    required this.callerId,
    required this.callerName,
    required this.callerAvatar,
    required this.calleeId,
    required this.callType,
    required this.zegoCallId,
    required this.historyDocId,
    required this.callStartedAt,
    required this.recordCallHistory,
    required this.expiresAt,
    required this.pushTitle,
    required this.pushBody,
    this.cancelReason = '',
  });

  final String type;
  final String notificationId;
  final String callId;
  final String roomId;
  final String callerId;
  final String callerName;
  final String callerAvatar;
  final String calleeId;
  final String callType;
  final String zegoCallId;
  final String historyDocId;
  final String callStartedAt;
  final bool recordCallHistory;
  final DateTime? expiresAt;
  final String pushTitle;
  final String pushBody;
  final String cancelReason;

  bool get isIncomingRing => type == PushNotificationTypes.incomingCall;
  bool get isCancelled => type == PushNotificationTypes.callCancelled;
  bool get isVideo => callType.trim().toLowerCase() == 'video';

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().toUtc().isAfter(expiresAt!.toUtc());
  }

  String get bannerTitle {
    if (pushTitle.trim().isNotEmpty) return pushTitle.trim();
    return isVideo ? 'Incoming video call' : 'Incoming voice call';
  }

  String get bannerBody {
    if (pushBody.trim().isNotEmpty) return pushBody.trim();
    final name = callerName.trim().isNotEmpty ? callerName.trim() : 'Someone';
    return isVideo ? '$name is video calling you' : '$name is calling you';
  }

  static IncomingCallPushPayload? tryParse(Map<String, dynamic> data) {
    final type = PushNotificationTypes.resolveType(data);
    if (!PushNotificationTypes.isIncomingCallType(type)) return null;

    final notificationId =
        _text(data['notification_id']) ??
        _text(data['notificationId']) ??
        _text(data['call_id']) ??
        _text(data['callId']) ??
        '';

    final callId =
        _text(data['call_id']) ??
        _text(data['callId']) ??
        _text(data['zego_call_id']) ??
        _text(data['zegoCallId']) ??
        '';

    return IncomingCallPushPayload(
      type: type,
      notificationId: notificationId,
      callId: callId,
      roomId: _text(data['room_id']) ?? _text(data['roomId']) ?? '',
      callerId: _text(data['caller_id']) ?? _text(data['callerId']) ?? '',
      callerName: _text(data['caller_name']) ?? _text(data['callerName']) ?? '',
      callerAvatar:
          _text(data['caller_avatar']) ?? _text(data['callerAvatar']) ?? '',
      calleeId: _text(data['callee_id']) ?? _text(data['calleeId']) ?? '',
      callType: _text(data['call_type']) ?? _text(data['callType']) ?? 'voice',
      zegoCallId:
          _text(data['zego_call_id']) ??
          _text(data['zegoCallId']) ??
          callId,
      historyDocId:
          _text(data['history_doc_id']) ?? _text(data['historyDocId']) ?? '',
      callStartedAt:
          _text(data['call_started_at']) ??
          _text(data['callStartedAt']) ??
          '',
      recordCallHistory: _boolString(
        data['record_call_history'] ?? data['recordCallHistory'],
        defaultValue: true,
      ),
      expiresAt: _parseDate(
        _text(data['expires_at']) ?? _text(data['expiresAt']),
      ),
      pushTitle: _text(data['title']) ?? '',
      pushBody: _text(data['body']) ?? '',
      cancelReason: _text(data['reason']) ?? '',
    );
  }

  static IncomingCallPushPayload? fromMessage(PushNotificationMessage message) {
    return tryParse(message.data);
  }

  static String? _text(dynamic value) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  static bool _boolString(dynamic value, {required bool defaultValue}) {
    if (value == null) return defaultValue;
    final raw = value.toString().trim().toLowerCase();
    if (raw == 'true' || raw == '1') return true;
    if (raw == 'false' || raw == '0') return false;
    return defaultValue;
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}
