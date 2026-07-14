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
    return PushNotificationMessage(
      messageId: message.messageId ?? '',
      title: notification?.title?.trim() ?? '',
      body: notification?.body?.trim() ?? '',
      data: Map<String, dynamic>.from(message.data),
      imageUrl: notification?.android?.imageUrl ??
          notification?.apple?.imageUrl ??
          message.data['image']?.toString(),
      sentTime: message.sentTime,
      from: message.from,
      collapseKey: message.collapseKey,
    );
  }

  final String messageId;
  final String title;
  final String body;

  /// Custom key/value payload from the backend.
  final Map<String, dynamic> data;

  final String? imageUrl;
  final DateTime? sentTime;
  final String? from;
  final String? collapseKey;

  bool get hasNotificationContent =>
      title.isNotEmpty || body.isNotEmpty;

  @override
  String toString() =>
      'PushNotificationMessage(id: $messageId, title: $title, data: $data)';
}
