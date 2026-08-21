import 'package:flutter/widgets.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

/// Cross-path dedupe for 1:1 rings (FCM, CallKit, Firestore).
///
/// CallKit may be shown from the FCM **background isolate**. That isolate's
/// static fields are not shared with the main isolate, so when the user opens
/// the app we must consult native [FlutterCallkitIncoming.activeCalls].
///
/// When the app is **foreground**, we always prefer the in-app green/red ring
/// UI — CallKit alone must not suppress it.
abstract final class IncomingCallPresentation {
  IncomingCallPresentation._();

  static final Set<String> _handledCallIds = <String>{};
  static String? _inAppCallId;
  static bool _appInForeground = true;

  static String? get inAppCallId => _inAppCallId;

  static bool get isAppInForeground => _appInForeground;

  static void setAppLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _appInForeground = true;
      case AppLifecycleState.inactive:
        // Transient (e.g. control center) — still treat as open for ring UI.
        _appInForeground = true;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _appInForeground = false;
    }
  }

  static void markInAppShowing(String callId) {
    final id = callId.trim();
    if (id.isEmpty) return;
    _inAppCallId = id;
  }

  static void clearInAppShowing([String? callId]) {
    final id = callId?.trim() ?? '';
    if (id.isEmpty || _inAppCallId == id) {
      _inAppCallId = null;
    }
  }

  /// Accept / reject / cancel / miss — never re-open ring UI for this call.
  static void markHandled(String callId) {
    final id = callId.trim();
    if (id.isEmpty) return;
    _handledCallIds.add(id);
    clearInAppShowing(id);
  }

  static bool isHandled(String callId) {
    final id = callId.trim();
    return id.isNotEmpty && _handledCallIds.contains(id);
  }

  /// True when we should **not** open another ring surface.
  ///
  /// In foreground, CallKit does not count — in-app full-screen owns the UI.
  static Future<bool> isAlreadyPresented(String callId) async {
    final id = callId.trim();
    if (id.isEmpty) return false;
    if (_handledCallIds.contains(id)) return true;
    if (_inAppCallId == id) return true;
    if (_appInForeground) return false;
    return hasActiveCallKit(id);
  }

  static Future<bool> hasActiveCallKit(String callId) async {
    final id = callId.trim();
    if (id.isEmpty) return false;
    final active = await activeCallKitIds();
    return active.contains(id);
  }

  /// Native CallKit session ids still ringing (survives isolate boundaries).
  static Future<Set<String>> activeCallKitIds() async {
    final ids = <String>{};
    try {
      final calls = await FlutterCallkitIncoming.activeCalls();
      if (calls is! List) return ids;
      for (final raw in calls) {
        if (raw is! Map) continue;
        final map = Map<String, dynamic>.from(raw);
        for (final candidate in _idsFromCallMap(map)) {
          if (candidate.isNotEmpty) ids.add(candidate);
        }
      }
    } catch (_) {}
    return ids;
  }

  static Iterable<String> _idsFromCallMap(Map<String, dynamic> map) sync* {
    yield map['id']?.toString().trim() ?? '';
    yield map['call_id']?.toString().trim() ?? '';
    yield map['callId']?.toString().trim() ?? '';
    final extra = map['extra'];
    if (extra is Map) {
      final nested = Map<String, dynamic>.from(extra);
      yield nested['id']?.toString().trim() ?? '';
      yield nested['call_id']?.toString().trim() ?? '';
      yield nested['callId']?.toString().trim() ?? '';
      yield nested['zego_call_id']?.toString().trim() ?? '';
      yield nested['zegoCallId']?.toString().trim() ?? '';
    }
  }
}
