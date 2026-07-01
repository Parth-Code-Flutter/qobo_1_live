/// ZEGOCLOUD credentials — separate console projects per UIKit use case.
///
/// Register bundle ID `com.qobo1live.live` (Android + iOS) under each AppID.
class ZegoConfig {
  ZegoConfig._();

  // ---------------------------------------------------------------------------
  // Live streaming — `zego_uikit_prebuilt_live_streaming` (Go Live tab)
  // ---------------------------------------------------------------------------

  static const int liveAppId = 1291066184;
  static const String liveAppSign =
      'f86c80a916d5d7dbd2d853037fdb9df0fd76d0fb4787e62c157374ea4024cd0c';

  static const bool useSignalingPlugin = false;

  // ---------------------------------------------------------------------------
  // Video rooms — `zego_uikit_prebuilt_video_conference` (Discover video rooms)
  // Console: Video Conference — AppID 90855422
  // ---------------------------------------------------------------------------

  static const int videoConferenceAppId = 90855422;
  static const String videoConferenceAppSign =
      '6a21e8cec9688779ffbc2a4e5c3db27c786a50fbde1fef555ce5ebfd77cc88b6';

  // ---------------------------------------------------------------------------
  // Voice & video calling — `zego_uikit_prebuilt_call` (chat phone / video)
  // Console: Voice & Video Call / Call Kit — AppID 1575915803
  // ---------------------------------------------------------------------------

  static const int callAppId = 1575915803;
  static const String callAppSign =
      'b099070a91f1da8776f0b691e307c4a46c5822369b6bc3756d09a8a5b51a775a';

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
