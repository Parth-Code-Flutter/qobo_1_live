import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/models/audio_room_models.dart';

void main() {
  test('seat SVIP flag follows membership, not a plain VIP frame', () {
    final frameOnly = AudioRoomSeatModel.fromMap({
      'seatNo': 2,
      'userId': 'frame-user',
      'isVip': true,
      'vipLevel': 1,
    });
    final niks = AudioRoomSeatModel.fromMap({
      'seatNo': 3,
      'userId': 'idc8783562',
      'name': 'Niks',
      'isVip': true,
      'vipLevel': 5,
    });
    final micKing = AudioRoomSeatModel.fromMap({
      'seatNo': 4,
      'userId': 'idc6497937',
      'name': 'Mic King',
      'isVip': false,
      'vipLevel': 1,
    });
    final nested = AudioRoomSeatModel.fromMap({
      'seatNo': 5,
      'occupant': {'id': 'svip-user', 'isSvip': true, 'vipLevel': 0},
    });
    final expired = AudioRoomSeatModel.fromMap({
      'seatNo': 6,
      'userId': 'old',
      'svipExpiresAt': '2020-01-01T00:00:00.000Z',
    });

    expect(frameOnly.isSvip, isFalse);
    expect(niks.isSvip, isTrue);
    expect(micKing.isSvip, isFalse);
    expect(nested.isSvip, isTrue);
    expect(expired.isSvip, isFalse);
  });

  test('floor audience uses the same SVIP rule', () {
    final niks = FloorAudienceUser.fromMap({
      'userId': 'idc8783562',
      'name': 'Niks',
      'isVip': true,
      'vipLevel': 5,
    });
    final micKing = FloorAudienceUser.fromMap({
      'userId': 'idc6497937',
      'name': 'Mic King',
      'vipLevel': 1,
    });

    expect(niks.isSvip, isTrue);
    expect(micKing.isSvip, isFalse);
  });
}
