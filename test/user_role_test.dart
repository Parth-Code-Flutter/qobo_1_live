import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/models/audio_room_models.dart';
import 'package:qobo_one_live/utils/user_role.dart';

void main() {
  test('role names normalize to the five account roles', () {
    expect(normalizeUserRole('Super Admin'), 'super_admin');
    expect(normalizeUserRole('agency_owner'), 'agency');
    expect(normalizeUserRole('Host'), 'host');
    expect(normalizeUserRole('coin_seller'), 'coins_seller');
    expect(normalizeUserRole('seller'), 'coins_seller');
    expect(normalizeUserRole(''), 'user');
    expect(normalizeUserRole('member'), 'user');
  });

  test('privileged flags win over a plain user role', () {
    expect(
      readUserRole({
        'role': 'user',
        'isCoinsSeller': true,
      }),
      'coins_seller',
    );
    expect(
      readUserRole({
        'userRole': 'host',
      }),
      'host',
    );
    expect(
      readUserRole({
        'roleFlags': {'isAgency': true},
      }),
      'agency',
    );
  });

  test('seat tags use the account role and mark the host seat', () {
    final speaker = AudioRoomSeatModel.fromMap({
      'seatNo': 2,
      'userId': 'a',
      'name': 'Rana',
      'role': 'speaker',
    });
    expect(speaker.badgeRole, 'user');

    final host = AudioRoomSeatModel.fromMap({
      'seatNo': 1,
      'userId': 'b',
      'name': 'Niks',
      'role': 'host',
    });
    expect(host.badgeRole, 'host');

    final seller = AudioRoomSeatModel.fromMap({
      'seatNo': 3,
      'userId': 'c',
      'name': 'Seller',
      'role': 'speaker',
      'isCoinsSeller': true,
    });
    expect(seller.badgeRole, 'coins_seller');
  });

  test('the signed-in account role replaces a host seat label', () {
    expect(
      roleShownForPerson(
        fallbackRole: 'host',
        personId: 'idc1057300',
        sessionUserId: 'idc1057300',
        sessionRole: 'super_admin',
      ),
      'super_admin',
    );
    expect(
      roleShownForPerson(
        fallbackRole: 'host',
        forceSessionRole: true,
        sessionRole: 'super_admin',
      ),
      'super_admin',
    );
    expect(
      roleShownForPerson(
        fallbackRole: 'host',
        personId: 'someone-else',
        sessionUserId: 'idc1057300',
        sessionRole: 'super_admin',
      ),
      'host',
    );
  });

  test('a room card keeps a privileged host role', () {
    expect(
      listingHostRole({
        'host': {'name': 'Mic King', 'role': 'user'},
      }),
      'host',
    );
    expect(
      listingHostRole({
        'host': {'role': 'coins_seller'},
      }),
      'coins_seller',
    );
  });
}
