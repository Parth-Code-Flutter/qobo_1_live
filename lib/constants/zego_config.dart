/// ZEGOCLOUD credentials — **two separate console projects**.
///
/// Register bundle ID `com.qobo1live.live` (Android + iOS) under **both** AppIDs.
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
