import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:just_audio/just_audio.dart';

/// Local lucky-gift tunes. Never reconfigures the live room's audio session.
///
/// A selected gift loops until that send settles. Other gifts are untouched.
class LuckyTapSound {
  AudioPlayer? _player;
  ZegoAudioEffectPlayer? _roomPlayer;
  final Map<String, String> _paths = {};
  int _generation = 0;
  Future<void> _work = Future.value();
  bool _open = false;
  String? _armedAsset;

  /// Crown, hookah, blue box, chest. Extra catalog rows reuse these.
  static const files = [
    'magic_spell_02',
    'magical_whoosh',
    'bonus_earned',
    'treasure_success',
  ];

  static String assetFor(String name, int index) {
    final text = name.toLowerCase();
    if (text.contains('chest') || text.contains('treasure')) {
      return _asset(3);
    }
    if (text.contains('hookah') || text.contains('shisha')) return _asset(1);
    if (text.contains('box') || text.contains('clover')) return _asset(2);
    if (text.contains('crown') || text.contains('royal')) return _asset(0);
    // "A" or "Gift C": A–B crown, C hookah, D box, E chest.
    final letter = RegExp(r'(?:^|\bgift\s+)([a-g])$').firstMatch(text.trim());
    if (letter != null) {
      const slots = [0, 0, 1, 2, 3, 2, 3];
      return _asset(slots[letter.group(1)!.codeUnitAt(0) - 97]);
    }
    return _asset((index < 0 ? 0 : index) % files.length);
  }

  static String _asset(int slot) => 'assets/lucky_sounds/${files[slot]}.mp3';

  void open() {
    _open = true;
  }

  /// Loop this gift's tune. The same tune already playing is left alone.
  void arm(String name, int index) {
    if (!_open) return;
    final asset = assetFor(name, index);
    if (_armedAsset == asset) return;
    final generation = ++_generation;
    _armedAsset = asset;
    _work = _work
        .then((_) => _start(asset, generation))
        .catchError((Object error) {
          debugPrint('Lucky tap sound failed: $error');
        });
  }

  /// Stop the loop. The player stays ready for the next selection.
  void release() {
    final generation = ++_generation;
    _armedAsset = null;
    _work = _work
        .then((_) async {
          if (generation != _generation) return;
          await _stopPlayback();
        })
        .catchError((Object error) {
          debugPrint('Lucky sound stop: $error');
        });
  }

  Future<void> _start(String asset, int generation) async {
    if (!_open || generation != _generation) return;
    if (await _playInRoom(asset, generation)) return;
    if (!_open || generation != _generation) return;
    final player = _player ??= AudioPlayer(
      handleAudioSessionActivation: false,
      handleInterruptions: false,
      androidApplyAudioAttributes: false,
    );
    await player.stop();
    if (!_open || generation != _generation) return;
    await player.setLoopMode(LoopMode.one);
    await player.setAsset(asset);
    if (!_open || generation != _generation) return;
    await player.setVolume(.65);
    if (!_open || generation != _generation) return;
    unawaited(player.play().catchError((_) {}));
  }

  Future<void> _stopPlayback() async {
    try {
      await _roomPlayer?.stopAll();
    } catch (error) {
      debugPrint('Lucky sound stop: $error');
    }
    try {
      await _player?.stop();
    } catch (error) {
      debugPrint('Lucky sound stop: $error');
    }
  }

  Future<bool> _playInRoom(String asset, int generation) async {
    if (!ZegoUIKit().engineCreatedNotifier.value) return false;
    try {
      var player = _roomPlayer;
      if (player == null) {
        player = await ZegoExpressEngine.instance.createAudioEffectPlayer();
        if (player == null) return false;
        if (!_open || generation != _generation) {
          await _releaseRoomPlayer(player);
          return true;
        }
        _roomPlayer = player;
      }
      var path = _paths[asset];
      if (path == null) {
        final bytes = await rootBundle.load(asset);
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/lucky_${asset.split('/').last}');
        await file.writeAsBytes(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          flush: true,
        );
        path = file.path;
        _paths[asset] = path;
      }
      if (!_open || generation != _generation) return true;
      await player.stopAll();
      if (!_open || generation != _generation) return true;
      // Loop locally until release(). playCount 0 repeats. Do not publish.
      await player.start(
        7101,
        path: path,
        config: ZegoAudioEffectPlayConfig(0, false),
      );
      if (!_open || generation != _generation) await player.stop(7101);
      return true;
    } catch (error) {
      debugPrint('Lucky room sound unavailable: $error');
      return false;
    }
  }

  Future<void> _releaseRoomPlayer(ZegoAudioEffectPlayer player) async {
    try {
      await player.stopAll();
      await ZegoExpressEngine.instance.destroyAudioEffectPlayer(player);
    } catch (error) {
      debugPrint('Lucky sound cleanup: $error');
    }
  }

  void close() {
    _open = false;
    _armedAsset = null;
    ++_generation; // Invalidate loads waiting on the platform before playback.
    final roomPlayer = _roomPlayer;
    _roomPlayer = null;
    if (roomPlayer != null) unawaited(_releaseRoomPlayer(roomPlayer));
    final player = _player;
    _player = null;
    if (player != null) {
      unawaited(player.dispose().catchError((_) {}));
    }
  }
}
