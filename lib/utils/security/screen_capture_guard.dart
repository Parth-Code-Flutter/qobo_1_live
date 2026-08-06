import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';
import 'package:screen_protector/screen_protector.dart';

/// Blocks screenshots / screen recording while sensitive UI is visible.
///
/// **Android** — [FLAG_SECURE] on the activity window **plus** `SurfaceView.setSecure`
/// (needed for Zego / Flutter PlatformViews that can otherwise leak past the flag).
/// **iOS** — secure-window layer so captures render as black / blank.
///
/// Call [enable] when entering a protected screen and [disable] when leaving.
/// Uses a ref-count so nested enable/disable pairs stay balanced.
abstract final class ScreenCaptureGuard {
  ScreenCaptureGuard._();

  /// Custom channel (MainActivity / AppDelegate) — walks SurfaceViews on Android.
  static const _channel = MethodChannel(
    'com.qobo1live.live/screen_capture_guard',
  );

  /// How many active "protect" requests are outstanding.
  static int _lockCount = 0;

  /// Delayed re-applies so late-created Zego SurfaceViews get marked secure.
  static final List<Timer> _reapplyTimers = [];

  /// Turn protection on (no-op if already active from a prior enable).
  static Future<void> enable() async {
    _lockCount++;
    if (_lockCount > 1) {
      // Extra callers still re-apply — Zego may have added new surfaces.
      await _apply(protected: true);
      return;
    }

    final ok = await _apply(protected: true);
    if (!ok) {
      LoggerUtils.logWarning('ScreenCaptureGuard: enable failed on all backends');
      _lockCount = (_lockCount - 1).clamp(0, 1 << 20);
      return;
    }

    LoggerUtils.logInfo('ScreenCaptureGuard: enabled');
    _scheduleSurfaceReapply();
  }

  /// Turn protection off when the last caller releases their lock.
  static Future<void> disable() async {
    if (_lockCount <= 0) return;
    _lockCount--;
    if (_lockCount > 0) return;

    _cancelSurfaceReapply();
    await _apply(protected: false);
    LoggerUtils.logInfo('ScreenCaptureGuard: disabled');
  }

  /// Re-apply while still locked (app resume, late PlatformViews, etc.).
  static Future<void> reapply() async {
    if (_lockCount <= 0) return;
    await _apply(protected: true);
  }

  /// Force-clear the lock (e.g. app lifecycle edge cases). Prefer [disable].
  static Future<void> forceDisable() async {
    _lockCount = 0;
    _cancelSurfaceReapply();
    await _apply(protected: false);
  }

  /// Hits both the pub plugin and our native channel (belt-and-suspenders).
  static Future<bool> _apply({required bool protected}) async {
    if (kIsWeb) return false;

    var anyOk = false;

    // 1) screen_protector — registered via GeneratedPluginRegistrant.
    try {
      if (protected) {
        // Android: FLAG_SECURE. iOS: preventScreenshotOn is a no-op for capture
        // content; we also enable the color / blur secure overlay below.
        await ScreenProtector.preventScreenshotOn();
        if (Platform.isAndroid) {
          await ScreenProtector.protectDataLeakageOn();
        } else if (Platform.isIOS) {
          await ScreenProtector.protectDataLeakageWithColor(
            const Color(0xFF000000),
          );
        }
      } else {
        if (Platform.isIOS) {
          await ScreenProtector.protectDataLeakageWithColorOff();
        }
        await ScreenProtector.protectDataLeakageOff();
        await ScreenProtector.preventScreenshotOff();
      }
      anyOk = true;
    } catch (error) {
      LoggerUtils.logWarning(
        'ScreenCaptureGuard: screen_protector failed — $error',
      );
    }

    // 2) App-owned channel — Android also marks every SurfaceView.setSecure.
    try {
      await _channel.invokeMethod<void>(protected ? 'enable' : 'disable');
      anyOk = true;
    } catch (error) {
      LoggerUtils.logWarning(
        'ScreenCaptureGuard: native channel failed — $error',
      );
    }

    return anyOk;
  }

  /// Zego attaches video SurfaceViews after join — re-scan a few times.
  static void _scheduleSurfaceReapply() {
    _cancelSurfaceReapply();
    if (!Platform.isAndroid) return;

    for (final delayMs in const [300, 800, 1600, 3000]) {
      _reapplyTimers.add(
        Timer(Duration(milliseconds: delayMs), () {
          if (_lockCount <= 0) return;
          unawaited(_apply(protected: true));
        }),
      );
    }
  }

  static void _cancelSurfaceReapply() {
    for (final timer in _reapplyTimers) {
      timer.cancel();
    }
    _reapplyTimers.clear();
  }
}
