import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:just_audio/just_audio.dart';

/// Local, one-shot effects. Never reconfigures the live room's audio session.
class LuckyTapSound {
  AudioPlayer? _player;
  ZegoAudioEffectPlayer? _roomPlayer;
  final Map<String, String> _paths = {};
  int _generation = 0;
  Future<void> _work = Future.value();
  bool _open = false;
  static const files = [
    'confirmation_001',
    'confirmation_002',
    'confirmation_003',
    'glass_001',
    'glass_003',
    'pluck_001',
    'pluck_002',
  ];
  static String assetFor(String name, int index) {
    final letter = name.trim().toUpperCase();
    final slot = RegExp(r'^[A-G]$').hasMatch(letter)
        ? letter.codeUnitAt(0) - 65
        : (index < 0 ? 0 : index) % files.length;
    return 'assets/lucky_sounds/${files[slot]}.wav';
  }

  void open() {
    _open = true;
  }

  void tap(String name, int index) {
    if (!_open) return;
    final generation = ++_generation;
    _work = _work
        .then((_) async {
          if (!_open || generation != _generation) return;
          final asset = assetFor(name, index);
          if (await _playInRoom(asset, generation)) return;
          if (!_open || generation != _generation) return;
          final player = _player ??= AudioPlayer(
            handleAudioSessionActivation: false,
            handleInterruptions: false,
            androidApplyAudioAttributes: false,
          );
          await player.stop();
          if (!_open || generation != _generation) return;
          await player.setAsset(assetFor(name, index));
          if (!_open || generation != _generation) return;
          await player.setVolume(.65);
          if (!_open || generation != _generation) return;
          unawaited(player.play().catchError((_) {}));
        })
        .catchError((Object error) {
          debugPrint('Lucky tap sound failed: $error');
        });
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
      // One-shot, local feedback only; do not publish to other room members.
      await player.start(
        7101,
        path: path,
        config: ZegoAudioEffectPlayConfig(1, false),
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
