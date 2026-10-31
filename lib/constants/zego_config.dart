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

  static const int liveAppId = 178284329;
  static const String liveAppSign =
      '820e667bf67fc3a9f446bd702919d1630699f55e43a2d6314efe8fecf965b194';

  static const bool useSignalingPlugin = false;

  // ---------------------------------------------------------------------------
  // Audio/video rooms — room seats, group voice rooms, group video rooms.
  // ---------------------------------------------------------------------------

  static const int roomAppId = 751866448;
  static const String roomAppSign =
      'daab62bdae4f751220197338475f57f643078984ed858a36ca1f58d7db11a325';

  // ---------------------------------------------------------------------------
  // One-to-one voice/video calling — chat phone / video call flow.
  // ---------------------------------------------------------------------------

  static const int callAppId = 594656264;
  static const String callAppSign =
      'f136312c029fccdaff192dac63d8b5fde2f712fdb924a807b75495e4bf232b0c';

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
