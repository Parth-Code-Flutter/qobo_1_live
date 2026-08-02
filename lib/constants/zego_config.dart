/// ZEGOCLOUD credentials — separate console projects per UIKit use case.
///
/// Register bundle ID `com.qobo1live.live` (Android + iOS) under each AppID.
class ZegoConfig {
  ZegoConfig._();

  // ---------------------------------------------------------------------------
  // Live streaming — `zego_uikit_prebuilt_live_streaming` (Go Live tab)
  // Console: Live Streaming — AppID 649126544
  // ---------------------------------------------------------------------------

  static const int liveAppId = 649126544;
  static const String liveAppSign =
      '2f582137d20ced46da649a529210265b39d6dd0d1f749a9d5fa5089dbd614690';

  static const bool useSignalingPlugin = false;

  // ---------------------------------------------------------------------------
  // Video & audio rooms — `zego_uikit_prebuilt_call` group voice/video calls
  // Console: Rooms — AppID 1706479502
  // ---------------------------------------------------------------------------

  static const int roomAppId = 1706479502;
  static const String roomAppSign =
      '99735c22bd41649fc47fa59915a0caf10893df0e3cd10dbfdb2c53dfd6cc5187';

  // ---------------------------------------------------------------------------
  // Voice & video calling — `zego_uikit_prebuilt_call` (chat phone / video)
  // Console: Voice and Video calls — AppID 715045896
  // ---------------------------------------------------------------------------

  static const int callAppId = 715045896;
  static const String callAppSign =
      '0e2137631949beb909e882369177421e207376618839a0e8028b929522bea40b';

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
