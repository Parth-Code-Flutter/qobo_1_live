/// FCM `data.type` values agreed with the backend team.
abstract final class PushNotificationTypes {
  PushNotificationTypes._();

  /// Direct mic invitation → Join + Reject (Android data-only, iOS `ROOM_INVITE`).
  static const String roomInvite = 'room_invite';

  /// Followed host started an audio room → Join + Dismiss.
  static const String roomCreated = 'room_created';

  /// Followed host started a live video stream → Join + Dismiss.
  static const String liveStreamingCreated = 'live_streaming_created';

  /// Follower alert when a followed host goes live (FCM + socket guide).
  ///
  /// Backend may also send `event: host_live_started` alongside this type.
  static const String liveStreamStarted = 'live_stream_started';

  /// Admin-panel broadcast → Join + Dismiss (Join when `room_id` is present).
  static const String general = 'general';

  /// Alias of [general] used by some admin dispatches.
  static const String custom = 'custom';

  /// Incoming PK challenge for the opponent host.
  static const String pkRequest = 'pk_request';

  /// Challenger notified that opponent accepted.
  static const String pkAccepted = 'pk_accepted';

  /// Challenger notified that opponent rejected.
  static const String pkRejected = 'pk_rejected';

  /// Opponent notified that challenger cancelled.
  static const String pkCancelled = 'pk_cancelled';

  /// Both hosts — battle is active.
  static const String pkStarted = 'pk_started';

  /// Both hosts — battle finished.
  static const String pkCompleted = 'pk_completed';

  /// Audio-room follower PK lifecycle.
  static const String pkFollowerInvite = 'pk_follower_invite';
  static const String pkFollowerWaiting = 'pk_follower_waiting';
  static const String pkFollowerJoined = 'pk_follower_joined';
  static const String pkFollowerDurationSet = 'pk_follower_duration_set';
  static const String pkFollowerScoreUpdate = 'pk_follower_score_update';
  static const String pkFollowerCompleted = 'pk_follower_completed';
  static const String pkFollowerCancelled = 'pk_follower_cancelled';

  /// Host receives a viewer join-request (Approve / Reject).
  static const String joinRequest = 'join_request';

  /// Viewer notified that host approved admission.
  static const String joinApproved = 'join_approved';

  /// Viewer notified that host rejected admission.
  static const String joinRejected = 'join_rejected';

  /// Viewer (and optionally host) notified that the request timed out.
  static const String joinRequestExpired = 'join_request_expired';

  /// Host notified that the viewer cancelled their join request.
  static const String joinRequestCancelled = 'join_request_cancelled';

  /// 1:1 voice/video direct call ring → Accept + Reject.
  static const String incomingCall = 'incoming_call';

  /// Dismiss ringing UI when call cancelled, accepted elsewhere, or timed out.
  static const String callCancelled = 'call_cancelled';

  /// Optional missed-call alert to caller.
  static const String callMissed = 'call_missed';

  /// All types the app currently handles.
  static const Set<String> all = {
    roomInvite,
    roomCreated,
    liveStreamingCreated,
    liveStreamStarted,
    general,
    custom,
    pkRequest,
    pkAccepted,
    pkRejected,
    pkCancelled,
    pkStarted,
    pkCompleted,
    pkFollowerInvite,
    pkFollowerWaiting,
    pkFollowerJoined,
    pkFollowerDurationSet,
    pkFollowerScoreUpdate,
    pkFollowerCompleted,
    pkFollowerCancelled,
    joinRequest,
    joinApproved,
    joinRejected,
    joinRequestExpired,
    joinRequestCancelled,
    incomingCall,
    callCancelled,
    callMissed,
  };

  /// Direct invite that can be rejected on the server.
  static bool isDirectInvite(String type) => type == roomInvite;

  /// Broadcast / alert types that show Join + Dismiss.
  static bool isJoinDismiss(String type) =>
      type == roomCreated ||
      type == liveStreamingCreated ||
      type == liveStreamStarted ||
      type == general ||
      type == custom;

  /// PK challenge that shows Accept + Reject.
  static bool isPkRequest(String type) =>
      type == pkRequest || type == pkFollowerInvite;

  /// Other PK lifecycle pushes (open arena / refresh state).
  static bool isPkLifecycle(String type) =>
      type == pkAccepted ||
      type == pkRejected ||
      type == pkCancelled ||
      type == pkStarted ||
      type == pkCompleted;

  static bool isFollowerPkType(String type) => type.startsWith('pk_follower_');

  static bool isPkType(String type) =>
      isPkRequest(type) || isPkLifecycle(type) || isFollowerPkType(type);

  /// Host inbox for pending room/live admission.
  static bool isJoinRequest(String type) => type == joinRequest;

  /// Viewer-side join-request lifecycle events.
  static bool isJoinRequestLifecycle(String type) =>
      type == joinApproved ||
      type == joinRejected ||
      type == joinRequestExpired ||
      type == joinRequestCancelled;

  static bool isJoinRequestType(String type) =>
      isJoinRequest(type) || isJoinRequestLifecycle(type);

  /// True when the push should open the live-streaming (not room-call) UI.
  static bool isLiveStreamAlert(String type) =>
      type == liveStreamingCreated || type == liveStreamStarted;

  /// Types that require a `room_id` to Join a live room.
  static bool requiresRoomId(String type) =>
      type == roomInvite ||
      type == roomCreated ||
      type == liveStreamingCreated ||
      type == liveStreamStarted;

  /// 1:1 direct call ring with Accept / Reject tray actions.
  static bool isIncomingCall(String type) => type == incomingCall;

  /// Lifecycle pushes that dismiss an active ring UI.
  static bool isCallLifecycle(String type) =>
      type == callCancelled || type == callMissed;

  static bool isIncomingCallType(String type) =>
      isIncomingCall(type) || isCallLifecycle(type);
}
