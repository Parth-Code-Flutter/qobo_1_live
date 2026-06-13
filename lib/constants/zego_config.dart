/// ZEGOCLOUD credentials — **two separate console projects**.
///
/// Register bundle ID `com.qobo1live.live` (Android + iOS) under **both** AppIDs.
class ZegoConfig {
  ZegoConfig._();

  // ---------------------------------------------------------------------------
  // Live streaming — `zego_uikit_prebuilt_live_streaming` (Go Live tab)
  // Console: Live Streaming product
  // ---------------------------------------------------------------------------

  static const int liveAppId = 1291066184;
  static const String liveAppSign =
      'f86c80a916d5d7dbd2d853037fdb9df0fd76d0fb4787e62c157374ea4024cd0c';

  /// Enable only after **In-app Chat (ZIM)** is activated on the **live** AppID.
  /// Co-host / PK need signaling; basic live works without it.
  static const bool useSignalingPlugin = false;

  // ---------------------------------------------------------------------------
  // Voice & video calling — `zego_uikit_prebuilt_call` (chat phone icon)
  // Console: Voice & Video Call / Call Kit product
  // ---------------------------------------------------------------------------

  static const int callAppId = 1417441758;
  static const String callAppSign =
      '5a8954f1c4b9f9b64880e48011f346f8e97a7c58d7b59db68685a65a4eff01f6';

  static const bool voiceCallEnabled = true;

  // ---------------------------------------------------------------------------
  // Back-compat aliases (live streaming — existing imports)
  // ---------------------------------------------------------------------------

  @Deprecated('Use ZegoConfig.liveAppId for live streaming')
  static const int appId = liveAppId;

  @Deprecated('Use ZegoConfig.liveAppSign for live streaming')
  static const String appSign = liveAppSign;
}
