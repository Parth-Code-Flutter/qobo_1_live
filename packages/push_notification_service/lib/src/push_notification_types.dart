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

  /// All types the app currently handles.
  static const Set<String> all = {
    roomInvite,
    roomCreated,
    liveStreamingCreated,
    liveStreamStarted,
    general,
    custom,
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
