import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/utils/live_room_listing_utils.dart';

void main() {
  test('same channel across different API record IDs appears once', () {
    final first = {
      'roomData': {'id': 'room-1', 'zegoLiveId': 'ls_1'},
      'image': 'cover',
    };
    final second = {
      'roomData': {'id': 'stream-1', 'liveStreamingId': 'ls_1'},
    };
    expect(uniqueLiveRoomListings([first, second]), [first]);
  });
  test('room ID aliases deduplicate within and across sources', () {
    expect(
      uniqueLiveRoomListings([
        {'id': '1'},
        {'room_id': '1'},
        {'roomId': '1'},
      ]).length,
      1,
    );
  });
  test('same host or name does not hide different streams or missing IDs', () {
    final rooms = [
      {'id': '1', 'hostId': 'h', 'name': 'Dilip'},
      {'id': '2', 'hostId': 'h', 'name': 'Dilip'},
      {'name': 'Dilip'},
      {'name': 'Dilip'},
    ];
    expect(uniqueLiveRoomListings(rooms), rooms);
  });
}
