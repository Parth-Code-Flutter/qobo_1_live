import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

/// Plays the device default ringtone + vibration while an incoming call UI shows.
abstract final class IncomingCallRinger {
  IncomingCallRinger._();

  static bool _ringing = false;
  static Timer? _hapticTimer;

  static Future<void> start() async {
    if (_ringing) return;
    _ringing = true;

    unawaited(_playRingtone());
    _startHapticPulse();
  }

  static Future<void> stop() async {
    if (!_ringing) return;
    _ringing = false;
    _hapticTimer?.cancel();
    _hapticTimer = null;
    try {
      await FlutterRingtonePlayer().stop();
    } catch (_) {}
  }

  static Future<void> _playRingtone() async {
    try {
      await FlutterRingtonePlayer().playRingtone(
        looping: true,
        volume: 1,
        asAlarm: false,
      );
    } catch (_) {
      // Fallback when ringtone API is unavailable.
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }
  }

  static void _startHapticPulse() {
    _hapticTimer?.cancel();
    unawaited(HapticFeedback.heavyImpact());
    _hapticTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!_ringing) return;
      HapticFeedback.heavyImpact();
    });
  }
}
