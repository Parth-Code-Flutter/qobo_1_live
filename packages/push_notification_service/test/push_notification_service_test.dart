import 'package:flutter_test/flutter_test.dart';
import 'package:push_notification_service/push_notification_service.dart';

void main() {
  test('PushNotificationMessage holds payload fields', () {
    const message = PushNotificationMessage(
      messageId: 'abc',
      title: 'Hello',
      body: 'World',
      data: {'type': 'chat', 'roomId': '12'},
    );

    expect(message.hasNotificationContent, isTrue);
    expect(message.data['type'], 'chat');
    expect(message.toString(), contains('Hello'));
  });

  test('PushNotificationConfig defaults are stable for Android channel', () {
    const config = PushNotificationConfig();
    expect(config.androidNotificationChannelId, 'high_importance_channel');
    expect(config.showForegroundNotifications, isTrue);
    expect(config.requestPermissionsOnInit, isTrue);
  });

  test('payload JSON round-trip preserves FCM data map', () {
    const message = PushNotificationMessage(
      messageId: 'id-1',
      title: 'Room Invitation',
      body: 'Join',
      data: {
        'type': 'room_invite',
        'invitation_id': 'inv-1',
        'room_id': 'room-1',
      },
    );

    final restored = PushNotificationMessage.fromPayloadJson(
      message.toPayloadJson(),
    );
    expect(restored.data['invitation_id'], 'inv-1');
    expect(restored.title, 'Room Invitation');
  });

  test('action set mapping follows backend type contract', () {
    expect(
      PushNotificationService.actionSetForData({'type': 'room_invite'}),
      PushNotificationActionSet.joinReject,
    );
    expect(
      PushNotificationService.actionSetForData({'type': 'room_created'}),
      PushNotificationActionSet.joinDismiss,
    );
    expect(
      PushNotificationService.actionSetForData({
        'type': 'live_streaming_created',
      }),
      PushNotificationActionSet.joinDismiss,
    );
    expect(
      PushNotificationService.actionSetForData({'type': 'general'}),
      PushNotificationActionSet.joinDismiss,
    );
    expect(
      PushNotificationService.actionSetForData({'type': 'custom'}),
      PushNotificationActionSet.joinDismiss,
    );
  });
}
