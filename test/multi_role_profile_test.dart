import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late UserSessionController session;
  setUp(() => session = UserSessionController());
  List<bool> icons() => [
    session.showSuperAdminIcon,
    session.showAgencyIcon,
    session.showHostIcon,
    session.showCoinsSellerIcon,
  ];

  test('new user sees all application shortcuts', () async {
    await session.saveProfile({'role': 'user'});
    expect(icons(), [true, true, true, true]);
  });
  for (final entry in {
    'super_admin': 0,
    'agency': 1,
    'host': 2,
    'coins_seller': 3,
    'agency_owner': 1,
    'seller': 3,
    'coin_seller': 3,
  }.entries) {
    test(
      '${entry.key} sees only its own dashboard despite stale icon flags',
      () async {
        await session.saveProfile({
          'role': entry.key,
          'roleIcons': {
            'showSuperAdmin': true,
            'showAgency': true,
            'showHost': true,
            'showCoinsSeller': true,
          },
        });
        expect(icons(), List.generate(4, (index) => index == entry.value));
      },
    );
  }
  test('nested approval flag is recognized when role is still user', () async {
    await session.saveProfile({
      'user': {
        'role': 'user',
        'roleFlags': {'isCoinsSeller': true},
      },
    });
    expect(session.isCoinSeller, isTrue);
    expect(icons(), [false, false, false, true]);
  });
  test(
    'explicit privileged role overrides stale seller compatibility flag',
    () async {
      await session.saveProfile({'role': 'host', 'isCoinsSeller': true});
      expect(session.isCoinSeller, isFalse);
      expect(icons(), [false, false, true, false]);
    },
  );
  test('server can hide application shortcuts for normal users', () async {
    await session.saveProfile({
      'role': 'user',
      'roleIcons': {'showAgency': false},
    });
    expect(icons(), [true, false, true, true]);
  });
  test('pending seller is not granted seller dashboard role', () async {
    await session.saveProfile({'role': 'user', 'coinsSellerStatus': 'pending'});
    expect(session.isCoinSeller, isFalse);
    expect(icons(), [true, true, true, true]);
  });
  test(
    'fresh profile replaces previous approved role after account change',
    () async {
      await session.saveProfile({'role': 'super_admin'});
      await session.saveProfile({'role': 'user'});
      expect(icons(), [true, true, true, true]);
    },
  );
}
