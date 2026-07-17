import 'package:push_notification_service/push_notification_service.dart';

/// Parsed FCM data for actionable room / live / broadcast pushes.
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
    this.title = '',
    this.body = '',
  });

  /// One of [PushNotificationTypes.all].
  final String type;
  final String roomId;
  final String roomType;
  final String hostId;
  final String hostName;
  final String roomTitle;
  final String notificationId;
  final String invitationId;
  final DateTime? expiresAt;

  /// Optional FCM notification title/body (admin / general dispatches).
  final String title;
  final String body;

  bool get isDirectInvite => PushNotificationTypes.isDirectInvite(type);

  /// Join + Dismiss broadcast types (`room_created`, live stream, general…).
  bool get isBroadcastAlert => PushNotificationTypes.isJoinDismiss(type);

  bool get hasInvitationId => invitationId.isNotEmpty;
  bool get hasRoomId => roomId.isNotEmpty;

  /// True when [expiresAt] is present and already in the past.
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().toUtc().isAfter(expiresAt!.toUtc());
  }

  /// Headline for in-app Join/Dismiss (or Join/Reject) banner.
  String get bannerTitle {
    if (title.trim().isNotEmpty) return title.trim();
    switch (type) {
      case PushNotificationTypes.roomInvite:
        return 'Room Invitation';
      case PushNotificationTypes.roomCreated:
      case PushNotificationTypes.liveStreamingCreated:
        return 'Live Stream Alert';
      case PushNotificationTypes.general:
      case PushNotificationTypes.custom:
        return 'Notification';
      default:
        return 'Notification';
    }
  }

  /// Supporting copy for the in-app banner.
  String get bannerBody {
    if (body.trim().isNotEmpty) return body.trim();
    switch (type) {
      case PushNotificationTypes.roomInvite:
        return '$hostName invited you to join "$roomTitle"';
      case PushNotificationTypes.roomCreated:
        return '$hostName started a $roomType room: "$roomTitle"';
      case PushNotificationTypes.liveStreamingCreated:
        return '$hostName started a live video stream: "$roomTitle"';
      case PushNotificationTypes.general:
      case PushNotificationTypes.custom:
        return roomTitle.isNotEmpty && roomTitle != 'Live room'
            ? roomTitle
            : 'Tap Join Now to open';
      default:
        return '';
    }
  }

  /// Returns null when the payload is not a supported actionable push type.
  static RoomInvitePushPayload? tryParse(
    Map<String, dynamic> data, {
    String title = '',
    String body = '',
  }) {
    final type = _text(data['type'])?.toLowerCase() ?? '';
    if (!PushNotificationTypes.all.contains(type)) return null;

    final roomId = _text(data['room_id']) ?? _text(data['roomId']) ?? '';
    if (PushNotificationTypes.requiresRoomId(type) && roomId.isEmpty) {
      return null;
    }

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
      title: title,
      body: body,
    );
  }

  static RoomInvitePushPayload? fromMessage(PushNotificationMessage message) {
    return tryParse(message.data, title: message.title, body: message.body);
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
