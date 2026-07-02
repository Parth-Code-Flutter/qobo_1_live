/// ZEGOCLOUD credentials — separate console projects per UIKit use case.
///
/// Register bundle ID `com.qobo1live.live` (Android + iOS) under each AppID.
class ZegoConfig {
  ZegoConfig._();

  // ---------------------------------------------------------------------------
  // Live streaming — `zego_uikit_prebuilt_live_streaming` (Go Live tab)
  // ---------------------------------------------------------------------------

  static const int liveAppId = 1167746552;
  static const String liveAppSign =
      '974cb5ac211260781bbca784bc61cecd7408905ff27e9876ed286608b7579367';

  static const bool useSignalingPlugin = false;

  // ---------------------------------------------------------------------------
  // Video & audio rooms — `zego_uikit_prebuilt_call` group voice/video calls
  // Console: Video & Audio Rooms — AppID 2115598602
  // ---------------------------------------------------------------------------

  static const int roomAppId = 2115598602;
  static const String roomAppSign =
      'b91c588ac42b7ab43c18287a7992368119e4fb8f8aea856e0e1417f9e693ff9e';

  // ---------------------------------------------------------------------------
  // Voice & video calling — `zego_uikit_prebuilt_call` (chat phone / video)
  // Console: One-to-one voice/video calling — AppID 894046429
  // ---------------------------------------------------------------------------

  static const int callAppId = 894046429;
  static const String callAppSign =
      '4cc7ee106ff2cd8616f32f1abdfb73ea5d30e24938fe62dd013461b4470f8f09';

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
