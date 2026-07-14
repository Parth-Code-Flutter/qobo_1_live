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
}
