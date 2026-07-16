import 'package:push_notification_service/push_notification_service.dart';

/// Parsed FCM data for `room_invite` / `room_created` pushes.
class RoomInvitePushPayload {
  const RoomInvitePushPayload({
    required this.type,
    required this.roomId,
    required this.roomType,
    required this.hostId,
    required this.hostName,
    required this.roomTitle,
    required this.notificationId,
    required this.invitationId,
    required this.expiresAt,
  });

  /// `room_invite` (Join+Reject) or `room_created` (Join+Dismiss).
  final String type;
  final String roomId;
  final String roomType;
  final String hostId;
  final String hostName;
  final String roomTitle;
  final String notificationId;
  final String invitationId;
  final DateTime? expiresAt;

  bool get isDirectInvite => type == 'room_invite';
  bool get isBroadcastAlert => type == 'room_created';
  bool get hasInvitationId => invitationId.isNotEmpty;

  /// True when [expiresAt] is present and already in the past.
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().toUtc().isAfter(expiresAt!.toUtc());
  }

  /// Returns null when the payload is not a supported room push type.
  static RoomInvitePushPayload? tryParse(Map<String, dynamic> data) {
    final type = _text(data['type'])?.toLowerCase() ?? '';
    if (type != 'room_invite' && type != 'room_created') return null;

    final roomId = _text(data['room_id']) ?? _text(data['roomId']) ?? '';
    if (roomId.isEmpty) return null;

    return RoomInvitePushPayload(
      type: type,
      roomId: roomId,
      roomType: (_text(data['room_type']) ?? _text(data['roomType']) ?? 'video')
          .toLowerCase(),
      hostId: _text(data['host_id']) ?? _text(data['hostId']) ?? '',
      hostName: _text(data['host_name']) ?? _text(data['hostName']) ?? 'Host',
      roomTitle:
          _text(data['room_title']) ??
          _text(data['roomTitle']) ??
          _text(data['title']) ??
          'Live room',
      notificationId: _text(data['notification_id']) ?? '',
      invitationId: _text(data['invitation_id']) ?? '',
      expiresAt: _parseExpiresAt(_text(data['expires_at'])),
    );
  }

  static RoomInvitePushPayload? fromMessage(PushNotificationMessage message) {
    return tryParse(message.data);
  }

  static DateTime? _parseExpiresAt(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static String? _text(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return null;
    return text;
  }
}
