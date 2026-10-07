import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/services/realtime/user_realtime_socket_service.dart';

void main() {
  test('live socket origin does not use port 0', () {
    final origin = realtimeSocketOrigin('https://api.qobo1live.in');
    final uri = Uri.parse(origin);

    expect(uri.host, 'api.qobo1live.in');
    expect(uri.port, 443);
    expect(origin.contains(':0'), isFalse);
  });

  test('an explicit bad port 0 is replaced', () {
    final origin = realtimeSocketOrigin('https://api.qobo1live.in:0');
    expect(Uri.parse(origin).port, 443);
    expect(origin.contains(':0'), isFalse);
  });

  test('websocket dial keeps an explicit port 443', () {
    final dial = realtimeSocketDialUri(
      Uri.parse(
        'wss://api.qobo1live.in/socket.io/?EIO=4&transport=websocket',
      ),
    );

    expect(dial.startsWith('wss://api.qobo1live.in:443/socket.io/'), isTrue);
    expect(dial.contains(':0'), isFalse);
    expect(Uri.parse(dial).port, 443);
    expect(Uri.parse(dial).hasPort, isTrue);
  });

  test('a portless wss URL is not dialed as port 0', () {
    final dial = realtimeSocketDialUri(
      Uri.parse('wss://api.qobo1live.in:0/socket.io/?EIO=4&transport=websocket'),
    );

    expect(dial.contains(':443'), isTrue);
    expect(dial.contains(':0'), isFalse);
  });
}
