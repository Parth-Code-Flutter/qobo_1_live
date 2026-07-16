/// Stable action / category ids shared with FCM/APNs contracts.
///
/// Backend iOS payloads must set `aps.category` to [roomInviteCategory].
abstract final class PushNotificationActions {
  PushNotificationActions._();

  /// APNs / local-notification category for room invitations.
  static const String roomInviteCategory = 'ROOM_INVITE';

  /// Accept / join the invited (or broadcast) room.
  static const String joinRoom = 'JOIN_ROOM';

  /// Reject a direct invitation (server-side).
  static const String rejectRoom = 'REJECT_ROOM';

  /// Local-only dismiss for broadcast `room_created` alerts.
  static const String dismissRoom = 'DISMISS_ROOM';
}

/// Which action buttons to attach to a local notification.
enum PushNotificationActionSet {
  /// Direct invite → Join + Reject.
  joinReject,

  /// Broadcast room alert → Join + Dismiss.
  joinDismiss,

  /// No action buttons.
  none,
}
