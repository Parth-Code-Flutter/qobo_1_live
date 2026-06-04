/// ZEGOCLOUD credentials for prebuilt live streaming.
///
/// Console: register bundle IDs `com.qobo1live.live` (Android + iOS) under this AppID.
class ZegoConfig {
  static const int appId = 1291066184;
  static const String appSign =
      'f86c80a916d5d7dbd2d853037fdb9df0fd76d0fb4787e62c157374ea4024cd0c';

  /// Enable only after **In-app Chat (ZIM)** is activated for this AppID
  /// in the ZEGOCLOUD console. Co-host / PK need signaling; basic live works
  /// without it.
  static const bool useSignalingPlugin = false;
}
