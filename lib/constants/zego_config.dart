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

  static const int liveAppId = 486153055;
  static const String liveAppSign =
      'c73c84c94e2cb2c1cd0676c57427b07b6db1729ce92f00cf461741527525a298';

  static const bool useSignalingPlugin = false;

  // ---------------------------------------------------------------------------
  // Audio/video rooms — room seats, group voice rooms, group video rooms.
  // ---------------------------------------------------------------------------

  static const int roomAppId = 1670093313;
  static const String roomAppSign =
      'd797a07b64bd134e54ec08869810140e4b1c3066f45d25087b404dbb23096fa2';

  // ---------------------------------------------------------------------------
  // One-to-one voice/video calling — chat phone / video call flow.
  // ---------------------------------------------------------------------------

  static const int callAppId = 331480132;
  static const String callAppSign =
      'cb5ad945d8dcf6a1fd9e612051335a9ba301d810b8aade58c79448ba44b4e283';

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
