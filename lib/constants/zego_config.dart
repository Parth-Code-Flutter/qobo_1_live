/// ZEGOCLOUD credentials — separate console projects per UIKit use case.
///
/// Register bundle ID `com.qobo1live.live` (Android + iOS) under each AppID.
class ZegoConfig {
  ZegoConfig._();

  // ---------------------------------------------------------------------------
  // Live streaming — `zego_uikit_prebuilt_live_streaming` (Go Live tab)
  // Console: Live Streaming — AppID supplied by `/api/live-streaming/*`.
  //
  // These values are only fallbacks. The live broadcast screen now prefers the
  // `zegoStreaming.appId/appSign` values returned by the backend join/create
  // APIs so host and audience always open the same Zego project.
  // ---------------------------------------------------------------------------

  static const int liveAppId = 1538269104;
  static const String liveAppSign =
      '72022e423995fb9f3bc6d7ef3b084f2eaf421b49477b78048a75dca27ee7d101';

  static const bool useSignalingPlugin = false;

  // ---------------------------------------------------------------------------
  // Video & audio rooms — `zego_uikit_prebuilt_call` group voice/video calls
  // Console: Rooms — AppID 1198993913
  // ---------------------------------------------------------------------------

  static const int roomAppId = 1198993913;
  static const String roomAppSign =
      'a8f1e62765a44f5481038b82eeacb9cad362f9ac1dd07fe61d9dd0125c49f0d0';

  // ---------------------------------------------------------------------------
  // Voice & video calling — `zego_uikit_prebuilt_call` (chat phone / video)
  // Console: Voice and Video calls — AppID 688448832
  // ---------------------------------------------------------------------------

  static const int callAppId = 688448832;
  static const String callAppSign =
      '4ae92379800ff044bd72031cec03acc870fbbec13c001fdeb5e384c218c08fdc';

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
