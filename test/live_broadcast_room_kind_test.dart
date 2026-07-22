import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/controllers/live_broadcast_controller.dart';

void main() {
  tearDown(Get.reset);

  LiveBroadcastController _controllerWithArgs(Map<String, dynamic> args) {
    Get.testMode = true;
    Get.routing.args = args;
    return LiveBroadcastController();
  }

  test('VIDEO create args open group-call UI even without payload type', () {
    final controller = _controllerWithArgs({
      'isHost': true,
      'roomType': 'VIDEO',
      'roomData': {'id': 'room-1', 'name': "Star's Room"},
    });
    controller.onInit();

    expect(controller.isAudioVideoRoom, isTrue);
    expect(controller.isVideoRoom, isTrue);
    expect(controller.isLiveStreamingSession, isFalse);
    expect(controller.isAudioRoom, isFalse);
  });

  test('AUDIO create args open audio group-call UI', () {
    final controller = _controllerWithArgs({
      'isHost': true,
      'roomType': 'AUDIO',
      'roomData': {'id': 'room-2', 'name': "Star's Room"},
    });
    controller.onInit();

    expect(controller.isAudioVideoRoom, isTrue);
    expect(controller.isVideoRoom, isFalse);
    expect(controller.isAudioRoom, isTrue);
    expect(controller.isLiveStreamingSession, isFalse);
  });

  test('live_stream payload keeps live streaming UI', () {
    final controller = _controllerWithArgs({
      'isHost': true,
      'roomType': 'LIVE_STREAM',
      'roomData': {
        'type': 'live_stream',
        'id': 'live-1',
        'room_id': 'live-1',
        'zegoLiveId': 'live-1',
      },
    });
    controller.onInit();

    expect(controller.isAudioVideoRoom, isFalse);
    expect(controller.isLiveStreamingSession, isTrue);
    expect(controller.isVideoRoom, isTrue);
  });

  test('legacy VIDEO nav + live_stream type still opens live UI', () {
    final controller = _controllerWithArgs({
      'isHost': false,
      'roomType': 'VIDEO',
      'roomData': {
        'type': 'live_stream',
        'id': 'live-2',
        'room_id': 'live-2',
        'zegoLiveId': 'live-2',
      },
    });
    controller.onInit();

    expect(controller.isAudioVideoRoom, isFalse);
    expect(controller.isLiveStreamingSession, isTrue);
  });
}
