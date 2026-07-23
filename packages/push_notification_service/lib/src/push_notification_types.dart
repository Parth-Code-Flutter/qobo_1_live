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
  static bool isPkRequest(String type) => type == pkRequest;

  /// Other PK lifecycle pushes (open arena / refresh state).
  static bool isPkLifecycle(String type) =>
      type == pkAccepted ||
      type == pkRejected ||
      type == pkCancelled ||
      type == pkStarted ||
      type == pkCompleted;

  static bool isPkType(String type) => isPkRequest(type) || isPkLifecycle(type);

  /// True when the push should open the live-streaming (not room-call) UI.
  static bool isLiveStreamAlert(String type) =>
      type == liveStreamingCreated || type == liveStreamStarted;

  /// Types that require a `room_id` to Join a live room.
  static bool requiresRoomId(String type) =>
      type == roomInvite ||
      type == roomCreated ||
      type == liveStreamingCreated ||
      type == liveStreamStarted;
}
