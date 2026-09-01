/// ZEGOCLOUD credentials — separate console projects per feature group.
///
/// Keep this file in sync with `docs/zego_config.env.example` and backend
/// token/signing configuration so mobile and API responses never mix AppIDs.
class ZegoConfig {
  ZegoConfig._();

  // ---------------------------------------------------------------------------
  // Live streaming — Go Live tab / standalone live audience flow.
  //
  // These values are only fallbacks. The live broadcast screen now prefers the
  // `zegoStreaming.appId/appSign` values returned by the backend join/create
  // APIs so host and audience always open the same Zego project.
  // ---------------------------------------------------------------------------

  static const int liveAppId = 180684874;
  static const String liveAppSign =
      '0790436a0c50552e7ff6be0e80a38fc43d5b90ca1eae6e50a4f057f09126aed3';

  static const bool useSignalingPlugin = false;

  // ---------------------------------------------------------------------------
  // Audio/video rooms — room seats, group voice rooms, group video rooms.
  // ---------------------------------------------------------------------------

  static const int roomAppId = 1090026199;
  static const String roomAppSign =
      '0be9166b63e954e162bc37192a223fcd9e6a4e7c6d75c4cfd577dadd73bdffd5';

  // ---------------------------------------------------------------------------
  // One-to-one voice/video calling — chat phone / video call flow.
  // ---------------------------------------------------------------------------

  static const int callAppId = 399563556;
  static const String callAppSign =
      'e1846298731d7e86eb7ee8d878ab6e2d00a59851a0c196323601b3d95f939ad1';

  static const bool callEnabled = true;

  @Deprecated('Use ZegoConfig.callEnabled')
  static const bool voiceCallEnabled = callEnabled;

  // ---------------------------------------------------------------------------
  // Back-compat aliases (live streaming)
  // ---------------------------------------------------------------------------

  @Deprecated('Use ZegoConfig.liveAppId for live streaming')
  static const int appId = liveAppId;

  @Deprecated('Use ZegoConfig.liveAppSign for live streaming')
  static const String appSign = liveAppSign;
}
