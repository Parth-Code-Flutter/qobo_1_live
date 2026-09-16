import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/utils/zego_live_id_utils.dart';

void main() {
  group('ZegoLiveIdUtils.pinBackendRoomId', () {
    test('keeps UUID when join payload overwrites roomId with ls_ channel', () {
      final roomData = <String, dynamic>{
        'room_id': '11197e1d-be4b-4dc1-a796-0795616e41e6',
        'roomId': 'ls_1787331523501_934491',
        'id': 'ls_1787331523501_934491',
        'liveStreamingId': 'ls_1787331523501_934491',
        'zegoLiveId': 'ls_1787331523501_934491',
      };

      ZegoLiveIdUtils.pinBackendRoomId(
        roomData,
        preferredId: '11197e1d-be4b-4dc1-a796-0795616e41e6',
      );

      expect(roomData['backendRoomId'], '11197e1d-be4b-4dc1-a796-0795616e41e6');
      expect(roomData['room_id'], '11197e1d-be4b-4dc1-a796-0795616e41e6');
      expect(roomData['roomId'], '11197e1d-be4b-4dc1-a796-0795616e41e6');
      expect(roomData['liveStreamingId'], 'ls_1787331523501_934491');
    });
  });

  group('ZegoLiveIdUtils.resolveEconomyGiftRoomId', () {
    test('party room uses backend UUID only', () {
      final id = ZegoLiveIdUtils.resolveEconomyGiftRoomId(
        {
          'room_id': 'room-uuid-1',
          'liveStreamingId': 'ls_should_not_use',
          'zegoLiveId': 'ls_should_not_use',
        },
        isLiveStreaming: false,
      );
      expect(id, 'room-uuid-1');
    });

    test('live stream prefers liveStreamingId for gifts', () {
      final id = ZegoLiveIdUtils.resolveEconomyGiftRoomId(
        {
          'room_id': '11197e1d-be4b-4dc1-a796-0795616e41e6',
          'liveStreamingId': 'ls_1787331523501_934491',
          'zegoLiveId': 'ls_1787331523501_934491',
        },
        isLiveStreaming: true,
        liveStreamingId: 'ls_1787331523501_934491',
      );
      expect(id, 'ls_1787331523501_934491');
    });

    test('live stream falls back to UUID when channel missing', () {
      final id = ZegoLiveIdUtils.resolveEconomyGiftRoomId(
        {
          'backendRoomId': '11197e1d-be4b-4dc1-a796-0795616e41e6',
          'room_id': '11197e1d-be4b-4dc1-a796-0795616e41e6',
        },
        isLiveStreaming: true,
      );
      expect(id, '11197e1d-be4b-4dc1-a796-0795616e41e6');
    });

    test('live stream still resolves when only ls_ keys exist', () {
      final id = ZegoLiveIdUtils.resolveEconomyGiftRoomId(
        {
          'liveStreamingId': 'ls_only_channel',
          'zegoLiveId': 'ls_only_channel',
          'roomId': 'ls_only_channel',
        },
        isLiveStreaming: true,
      );
      expect(id, 'ls_only_channel');
    });
  });
}
