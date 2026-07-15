import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/controllers/live_broadcast_controller.dart';
import 'package:qobo_one_live/repo/room/room_repo.dart';
import 'package:zego_uikit/zego_uikit.dart';

void main() {
  test('participant media errors do not become room login failures', () {
    final controller = LiveBroadcastController()
      ..isHost.value = true
      ..connectionIssue.value = '';

    controller.handleGroupCallRoomError(
      ZegoUIKitError(
        code: ZegoUIKitErrorCode.mediaPlayError,
        message: 'remote stream unavailable',
        method: 'playMedia',
      ),
    );

    expect(controller.connectionIssue.value, isEmpty);
    expect(controller.isZegoConnected.value, isFalse);
  });

  test('errors after group room connection do not disconnect the host', () {
    final controller = LiveBroadcastController()..isHost.value = true;
    controller.onGroupCallRoomConnected(bindMessages: false);

    controller.handleGroupCallRoomError(
      ZegoUIKitError(
        code: ZegoUIKitErrorCode.roomLoginError,
        message: 'late room event',
        method: 'loginRoom',
      ),
    );

    expect(controller.connectionIssue.value, isEmpty);
    expect(controller.isZegoConnected.value, isTrue);
  });

  test('host lifecycle exit never ends the backend room', () async {
    final roomRepo = _TrackingRoomRepo();
    final controller = LiveBroadcastController(roomRepo: roomRepo)
      ..isHost.value = true;

    controller.reportRoomExit();
    await Future<void>.delayed(Duration.zero);

    expect(roomRepo.endCalls, 0);
    expect(roomRepo.leaveCalls, 0);
    expect(controller.canProcessGroupCallEnd, isFalse);
  });

  test('viewer call-end events can still close the viewer route', () {
    final controller = LiveBroadcastController()..isHost.value = false;

    expect(controller.canProcessGroupCallEnd, isTrue);
  });
}

class _TrackingRoomRepo extends RoomRepo {
  int endCalls = 0;
  int leaveCalls = 0;

  @override
  Future<Map<String, dynamic>?> endRoom({
    required String roomId,
    bool isShowLoader = false,
  }) async {
    endCalls++;
    return <String, dynamic>{'statusCode': 200};
  }

  @override
  Future<Map<String, dynamic>?> leaveRoom({
    required String roomId,
    bool isShowLoader = false,
  }) async {
    leaveCalls++;
    return <String, dynamic>{'statusCode': 200};
  }
}
