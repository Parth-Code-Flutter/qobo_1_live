/// Stable action / category ids shared with FCM/APNs contracts.
///
/// Backend iOS payloads should set `aps.category` to:
/// - [roomInviteCategory] for `room_invite` (Join + Reject)
/// - [roomBroadcastCategory] for Join + Dismiss types
/// - [pkRequestCategory] for `pk_request` (Accept + Reject)
abstract final class PushNotificationActions {
  PushNotificationActions._();

  /// APNs / local-notification category for direct room invitations.
  static const String roomInviteCategory = 'ROOM_INVITE';

  /// APNs / local-notification category for Join + Dismiss alerts
  /// (`room_created`, `live_streaming_created`, `general`, `custom`).
  static const String roomBroadcastCategory = 'ROOM_BROADCAST';

  /// APNs / local-notification category for PK challenges.
  static const String pkRequestCategory = 'PK_REQUEST';

  /// Accept / join the invited (or broadcast) room.
  static const String joinRoom = 'JOIN_ROOM';

  /// Reject a direct invitation (server-side).
  static const String rejectRoom = 'REJECT_ROOM';

  /// Local-only dismiss for Join + Dismiss broadcast alerts.
  static const String dismissRoom = 'DISMISS_ROOM';

  /// Accept an incoming PK challenge.
  static const String acceptPk = 'ACCEPT_PK';

  /// Reject an incoming PK challenge.
  static const String rejectPk = 'REJECT_PK';
}

/// Which action buttons to attach to a local notification.
enum PushNotificationActionSet {
  /// Direct invite (`room_invite`) → Join + Reject.
  joinReject,

  /// Broadcast / admin alert → Join + Dismiss.
  joinDismiss,

  /// PK challenge (`pk_request`) → Accept + Reject.
  pkAcceptReject,

  /// No action buttons.
  none,
}
