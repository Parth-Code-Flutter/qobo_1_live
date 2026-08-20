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

  /// APNs / local-notification category for host join approval.
  static const String joinRequestCategory = 'JOIN_REQUEST';

  /// APNs / local-notification category for 1:1 incoming calls.
  static const String incomingCallCategory = 'INCOMING_CALL';

  /// Android channel for high-priority incoming call trays.
  /// Must match backend FCM `channel_id: incoming_call_channel`.
  static const String incomingCallChannelId = 'incoming_call_channel';

  static const String incomingCallChannelName = 'Incoming Calls';

  static const String incomingCallChannelDescription =
      'Ringing alerts for 1:1 voice and video calls.';

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

  /// Host approves a viewer join request.
  static const String approveJoin = 'APPROVE_JOIN';

  /// Host rejects a viewer join request.
  static const String rejectJoin = 'REJECT_JOIN';

  /// Accept an incoming 1:1 voice/video call.
  static const String acceptCall = 'ACCEPT_CALL';

  /// Reject an incoming 1:1 voice/video call.
  static const String rejectCall = 'REJECT_CALL';
}

/// Which action buttons to attach to a local notification.
enum PushNotificationActionSet {
  /// Direct invite (`room_invite`) → Join + Reject.
  joinReject,

  /// Broadcast / admin alert → Join + Dismiss.
  joinDismiss,

  /// PK challenge (`pk_request`) → Accept + Reject.
  pkAcceptReject,

  /// Host join request (`join_request`) → Approve + Reject.
  joinApproveReject,

  /// 1:1 incoming call (`incoming_call`) → Accept + Reject.
  callAcceptReject,

  /// No action buttons.
  none,
}
