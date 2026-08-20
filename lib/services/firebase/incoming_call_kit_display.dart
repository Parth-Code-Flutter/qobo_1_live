import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:push_notification_service/push_notification_service.dart';
import 'package:qobo_one_live/services/firebase/incoming_call_push_payload.dart';

/// Background-safe CallKit display (no GetX / UI imports).
///
/// Used from the FCM background isolate and the main [IncomingCallKitService].
abstract final class IncomingCallKitDisplay {
  IncomingCallKitDisplay._();

  static Future<void> handleBackgroundRemoteMessage(
    RemoteMessage message,
  ) async {
    final mapped = PushNotificationMessage.fromRemoteMessage(message);
    final type = PushNotificationTypes.resolveType(mapped.data);

    if (type == PushNotificationTypes.callCancelled ||
        type == PushNotificationTypes.callMissed) {
      await endForMessage(mapped);
      return;
    }

    if (!PushNotificationTypes.isIncomingCall(type)) return;

    final payload = IncomingCallPushPayload.fromMessage(mapped);
    if (payload == null || !payload.isIncomingRing || payload.isExpired) {
      return;
    }

    await showIncoming(payload, sourceData: mapped.data);
  }

  static Future<void> showIncoming(
    IncomingCallPushPayload payload, {
    Map<String, dynamic>? sourceData,
  }) async {
    final id = callKitIdFor(payload);

    final extra = <String, dynamic>{
      ...?sourceData,
      'type': payload.type,
      'call_id': payload.callId,
      'callId': payload.callId,
      'room_id': payload.roomId,
      'roomId': payload.roomId,
      'caller_id': payload.callerId,
      'caller_name': payload.callerName,
      'caller_avatar': payload.callerAvatar,
      'callee_id': payload.calleeId,
      'call_type': payload.callType,
      'callType': payload.callType,
      'zego_call_id': payload.zegoCallId,
      'history_doc_id': payload.historyDocId,
      'call_started_at': payload.callStartedAt,
      'record_call_history': payload.recordCallHistory ? 'true' : 'false',
      'title': payload.bannerTitle,
      'body': payload.bannerBody,
      if (payload.expiresAt != null)
        'expires_at': payload.expiresAt!.toUtc().toIso8601String(),
    };

    final params = CallKitParams(
      id: id,
      nameCaller: payload.callerName.trim().isEmpty
          ? 'Incoming call'
          : payload.callerName.trim(),
      appName: 'Qobo One Live',
      avatar: payload.callerAvatar.trim().isEmpty
          ? null
          : payload.callerAvatar.trim(),
      handle: payload.isVideo ? 'Video Call' : 'Voice Call',
      type: payload.isVideo ? 1 : 0,
      textAccept: 'Accept',
      textDecline: 'Decline',
      duration: 45000,
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: false,
        subtitle: 'Missed call',
      ),
      extra: extra,
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        // Matches android/app/src/main/res/raw/ringtone.wav
        ringtonePath: 'ringtone',
        backgroundColor: '#0E1628',
        actionColor: '#10B981',
        textColor: '#ffffff',
        incomingCallNotificationChannelName: 'Incoming Calls',
        missedCallNotificationChannelName: 'Missed Calls',
        isShowFullLockedScreen: true,
        isImportant: true,
      ),
      ios: IOSParams(
        handleType: 'generic',
        supportsVideo: payload.isVideo,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        ringtonePath: 'system_ringtone_default',
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  static Future<void> endForMessage(PushNotificationMessage message) async {
    final payload = IncomingCallPushPayload.fromMessage(message);
    if (payload != null) {
      await endForPayload(payload);
      return;
    }
    final id =
        message.data['call_id']?.toString() ??
        message.data['callId']?.toString() ??
        '';
    if (id.trim().isNotEmpty) {
      await FlutterCallkitIncoming.endCall(id.trim());
    }
  }

  static Future<void> endForPayload(IncomingCallPushPayload payload) async {
    final id = callKitIdFor(payload);
    if (id.isEmpty) return;
    try {
      await FlutterCallkitIncoming.endCall(id);
    } catch (_) {}
    try {
      await FlutterCallkitIncoming.hideCallkitIncoming(
        CallKitParams(id: id),
      );
    } catch (_) {}
  }

  static Future<void> endAll() async {
    try {
      await FlutterCallkitIncoming.endAllCalls();
    } catch (_) {}
  }

  static String callKitIdFor(IncomingCallPushPayload payload) {
    final id = payload.callId.trim().isNotEmpty
        ? payload.callId.trim()
        : (payload.notificationId.trim().isNotEmpty
            ? payload.notificationId.trim()
            : payload.zegoCallId.trim());
    return id.isEmpty
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : id;
  }
}
