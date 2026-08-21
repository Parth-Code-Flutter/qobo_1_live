import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:push_notification_service/push_notification_service.dart';
import 'package:qobo_one_live/services/firebase/incoming_call_kit_display.dart';
import 'package:qobo_one_live/services/firebase/incoming_call_presentation.dart';
import 'package:qobo_one_live/services/firebase/incoming_call_push_handler.dart';
import 'package:qobo_one_live/services/firebase/incoming_call_push_payload.dart';
import 'package:qobo_one_live/utils/app_widgets/incoming_call_ring_ui.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';

/// Main-isolate CallKit wiring: permissions, accept/decline events, launch.
abstract final class IncomingCallKitService {
  IncomingCallKitService._();

  static StreamSubscription<CallEvent?>? _eventSub;
  static bool _listening = false;
  static _IncomingCallLifecycleObserver? _lifecycleObserver;

  static Future<void> initialize() async {
    if (kIsWeb) return;
    await _ensureEventListener();
    _ensureLifecycleObserver();
    try {
      await FlutterCallkitIncoming.requestNotificationPermission({
        'title': 'Call notifications',
        'rationaleMessagePermission':
            'Notification permission is required to show incoming calls.',
        'postNotificationMessageRequired':
            'Please allow notifications so you can receive voice and video calls.',
      });
    } catch (e) {
      LoggerUtils.logWarning('IncomingCallKit: notification permission — $e');
    }
    try {
      await FlutterCallkitIncoming.requestFullIntentPermission();
    } catch (e) {
      LoggerUtils.logWarning('IncomingCallKit: full-screen intent — $e');
    }
    await _consumeAcceptedCallOnLaunch();
    await onAppResumed();
  }

  static Future<void> endForPayload(IncomingCallPushPayload payload) {
    return IncomingCallKitDisplay.endForPayload(payload);
  }

  static Future<void> endForMessage(PushNotificationMessage message) {
    return IncomingCallKitDisplay.endForMessage(message);
  }

  /// When returning to foreground with CallKit still ringing: keep CallKit
  /// (user opened from notification). Do **not** dismiss an in-app ring that
  /// was shown while already foreground.
  static Future<void> onAppResumed() async {
    if (kIsWeb) return;
    IncomingCallPresentation.setAppLifecycle(AppLifecycleState.resumed);
  }

  static void _ensureLifecycleObserver() {
    if (_lifecycleObserver != null) return;
    _lifecycleObserver = _IncomingCallLifecycleObserver();
    WidgetsBinding.instance.addObserver(_lifecycleObserver!);
    final state = WidgetsBinding.instance.lifecycleState;
    if (state != null) {
      IncomingCallPresentation.setAppLifecycle(state);
    }
  }

  static Future<void> _ensureEventListener() async {
    if (_listening) return;
    _listening = true;
    await _eventSub?.cancel();
    _eventSub = FlutterCallkitIncoming.onEvent.listen(_onCallEvent);
  }

  static Future<void> _onCallEvent(CallEvent? event) async {
    if (event == null) return;
    final extra = _extraMap(event.body);
    final payload = IncomingCallPushPayload.tryParse(extra);
    final handler = IncomingCallPushHandler();
    final message = PushNotificationMessage(
      messageId: payload?.callId ?? '',
      title: payload?.bannerTitle ?? '',
      body: payload?.bannerBody ?? '',
      data: extra,
    );

    switch (event.event) {
      case Event.actionCallAccept:
        IncomingCallRingUi.dismissIfShowing();
        if (payload != null) {
          // Accept → respond + navigate to room (never re-show ringing UI).
          await handler.acceptCall(payload, sourceMessage: message);
        }
        return;
      case Event.actionCallDecline:
      case Event.actionCallTimeout:
        IncomingCallRingUi.dismissIfShowing();
        if (payload != null) {
          await handler.rejectCall(payload, sourceMessage: message);
        }
        return;
      case Event.actionCallEnded:
        IncomingCallRingUi.dismissIfShowing();
        if (payload != null) {
          IncomingCallPresentation.markHandled(payload.callId);
        }
        return;
      default:
        return;
    }
  }

  static Future<void> _consumeAcceptedCallOnLaunch() async {
    try {
      final calls = await FlutterCallkitIncoming.activeCalls();
      if (calls is! List || calls.isEmpty) return;
      for (final raw in calls) {
        if (raw is! Map) continue;
        final map = Map<String, dynamic>.from(raw);
        final accepted = map['accepted'] == true ||
            map['isAccepted'] == true ||
            map['status']?.toString() == 'accepted';
        if (!accepted) continue;
        final extra = _extraMap(map);
        final payload = IncomingCallPushPayload.tryParse(extra);
        if (payload == null) continue;
        await IncomingCallPushHandler().acceptCall(
          payload,
          sourceMessage: PushNotificationMessage(
            messageId: payload.callId,
            title: payload.bannerTitle,
            body: payload.bannerBody,
            data: extra,
          ),
        );
        break;
      }
    } catch (e) {
      LoggerUtils.logWarning('IncomingCallKit: launch accept check — $e');
    }
  }

  static Map<String, dynamic> _extraMap(dynamic body) {
    if (body is! Map) return <String, dynamic>{};
    final map = Map<String, dynamic>.from(body);
    final nested = map['extra'];
    if (nested is Map) {
      return {...map, ...Map<String, dynamic>.from(nested)};
    }
    if (nested is String && nested.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(nested);
        if (decoded is Map) {
          return {...map, ...Map<String, dynamic>.from(decoded)};
        }
      } catch (_) {}
    }
    return map;
  }
}

class _IncomingCallLifecycleObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    IncomingCallPresentation.setAppLifecycle(state);
    if (state == AppLifecycleState.resumed) {
      unawaited(IncomingCallKitService.onAppResumed());
    }
  }
}
