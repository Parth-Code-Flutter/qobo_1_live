import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';

/// App-agnostic view of an FCM [RemoteMessage].
class PushNotificationMessage {
  const PushNotificationMessage({
    required this.messageId,
    required this.title,
    required this.body,
    required this.data,
    this.imageUrl,
    this.sentTime,
    this.from,
    this.collapseKey,
  });

  factory PushNotificationMessage.fromRemoteMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = Map<String, dynamic>.from(message.data);
    final titleFromData = data['title']?.toString().trim() ?? '';
    final bodyFromData = data['body']?.toString().trim() ?? '';
    return PushNotificationMessage(
      messageId: message.messageId ?? '',
      title: notification?.title?.trim().isNotEmpty == true
          ? notification!.title!.trim()
          : titleFromData,
      body: notification?.body?.trim().isNotEmpty == true
          ? notification!.body!.trim()
          : bodyFromData,
      data: data,
      imageUrl:
          notification?.android?.imageUrl ??
          notification?.apple?.imageUrl ??
          message.data['image']?.toString(),
      sentTime: message.sentTime,
      from: message.from,
      collapseKey: message.collapseKey,
    );
  }

  /// Rebuilds a message previously encoded into a local-notification payload.
  factory PushNotificationMessage.fromPayloadJson(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const PushNotificationMessage(
        messageId: '',
        title: '',
        body: '',
        data: <String, dynamic>{},
      );
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return PushNotificationMessage(
          messageId: '',
          title: '',
          body: '',
          data: <String, dynamic>{'raw': raw},
        );
      }
      final map = Map<String, dynamic>.from(decoded);
      final dataRaw = map['data'];
      return PushNotificationMessage(
        messageId: map['messageId']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        body: map['body']?.toString() ?? '',
        data: dataRaw is Map
            ? Map<String, dynamic>.from(dataRaw)
            : <String, dynamic>{},
      );
    } catch (_) {
      return PushNotificationMessage(
        messageId: '',
        title: '',
        body: '',
        data: <String, dynamic>{'raw': raw},
      );
    }
  }

  final String messageId;
  final String title;
  final String body;

  /// Custom key/value payload from the backend (all values are strings for FCM).
  final Map<String, dynamic> data;

  final String? imageUrl;
  final DateTime? sentTime;
  final String? from;
  final String? collapseKey;

  bool get hasNotificationContent => title.isNotEmpty || body.isNotEmpty;

  /// Serializes enough state for local-notification taps / action buttons.
  String toPayloadJson() {
    return jsonEncode(<String, dynamic>{
      'messageId': messageId,
      'title': title,
      'body': body,
      'data': data,
    });
  }

  PushNotificationMessage copyWith({
    String? messageId,
    String? title,
    String? body,
    Map<String, dynamic>? data,
  }) {
    return PushNotificationMessage(
      messageId: messageId ?? this.messageId,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      imageUrl: imageUrl,
      sentTime: sentTime,
      from: from,
      collapseKey: collapseKey,
    );
  }

  @override
  String toString() =>
      'PushNotificationMessage(id: $messageId, title: $title, data: $data)';
}
