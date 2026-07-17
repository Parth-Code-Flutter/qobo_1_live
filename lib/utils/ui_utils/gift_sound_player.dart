import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:zego_uikit/zego_uikit.dart';

/// Plays short gift sound effects during live rooms/calls without breaking Zego audio.
class GiftSoundPlayer {
  just_audio.AudioPlayer? _justAudioPlayer;
  ZegoAudioEffectPlayer? _zegoEffectPlayer;
  int? _zegoEffectId;

  /// Normalizes API-relative paths and returns an https URL when playable.
  static String? resolvePlayableUrl(String? raw) {
    final normalized = ApiImageUtils.normalize(raw);
    if (normalized == null) return null;
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized;
    }
    return null;
  }

  Future<void> play(String? soundUrl) async {
    final url = resolvePlayableUrl(soundUrl);
    if (url == null) return;

    if (await _tryPlayWithZego(url)) return;
    await _playWithJustAudio(url);
  }

  Future<void> dispose() async {
    final effectId = _zegoEffectId;
    final zego = _zegoEffectPlayer;
    _zegoEffectId = null;
    _zegoEffectPlayer = null;
    if (zego != null && effectId != null) {
      await zego.stop(effectId).catchError((_) {});
      await zego.unloadResource(effectId).catchError((_) {});
    }

    final player = _justAudioPlayer;
    _justAudioPlayer = null;
    if (player != null) {
      await player.stop().catchError((_) {});
      await player.dispose().catchError((_) {});
    }
  }

  bool get _isZegoEngineReady => ZegoUIKit().engineCreatedNotifier.value;

  Future<bool> _tryPlayWithZego(String url) async {
    if (!_isZegoEngineReady) return false;

    try {
      final player =
          _zegoEffectPlayer ??
          await ZegoExpressEngine.instance.createAudioEffectPlayer();
      if (player == null) return false;
      _zegoEffectPlayer = player;

      final effectId = url.hashCode & 0x7fffffff;
      _zegoEffectId = effectId;

      await player.stop(effectId).catchError((_) {});

      final loadResult = await player.loadResource(effectId, url);
      if (loadResult.errorCode != 0) return false;

      await player.start(
        effectId,
        config: ZegoAudioEffectPlayConfig(1, false),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _playWithJustAudio(String url) async {
    final session = await AudioSession.instance;
    final current = session.configuration;
    await session.configure(
      (current ?? const AudioSessionConfiguration.music()).copyWith(
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.mixWithOthers,
        androidAudioFocusGainType:
            AndroidAudioFocusGainType.gainTransientMayDuck,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.sonification,
          usage: AndroidAudioUsage.assistanceSonification,
        ),
      ),
    );

    final player = just_audio.AudioPlayer(
      handleInterruptions: false,
      handleAudioSessionActivation: true,
      androidApplyAudioAttributes: true,
    );
    _justAudioPlayer = player;

    try {
      await player.setUrl(url);
      await player.setVolume(1);
      unawaited(player.play().catchError((_) {}));
    } catch (_) {
      if (_justAudioPlayer == player) {
        _justAudioPlayer = null;
        await player.dispose().catchError((_) {});
      }
    }
  }
}
