import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:qobo_one_live/services/payment/google_play_billing_service.dart';
import 'package:qobo_one_live/app/user_flow/wallet/controllers/wallet_controller.dart';

class FakeStore implements PlayStoreGateway {
  final events = StreamController<List<PurchaseDetails>>.broadcast();
  int buys = 0;
  String? account;
  bool available = true;
  bool failBuy = false;
  @override
  Stream<List<PurchaseDetails>> get purchases => events.stream;
  @override
  Future<bool> isAvailable() async => available;
  @override
  Future<ProductDetailsResponse> products(Set<String> ids) async =>
      ProductDetailsResponse(
        productDetails: ids.contains('coins_100') ? [product] : [],
        notFoundIDs: ids.where((id) => id != 'coins_100').toList(),
      );
  @override
  Future<bool> buy(ProductDetails p, String accountId) async {
    buys++;
    account = accountId;
    if (failBuy) throw StateError('offline');
    return true;
  }

  @override
  Future<void> recover() async {}
}

final product = ProductDetails(
  id: 'coins_100',
  title: '100 Coins',
  description: 'Coins',
  price: '₹99.00',
  rawPrice: 99,
  currencyCode: 'INR',
);
PurchaseDetails purchase([PurchaseStatus status = PurchaseStatus.purchased]) =>
    PurchaseDetails(
      productID: 'coins_100',
      verificationData: PurchaseVerificationData(
        localVerificationData: '',
        serverVerificationData: 'test-token',
        source: 'google_play',
      ),
      transactionDate: '1',
      status: status,
    )..pendingCompletePurchase = true;
Map<String, dynamic> confirmed() => {
  'success': true,
  'data': {
    'productId': 'coins_100',
    'userId': 'user-a',
    'credited': true,
    'consumed': true,
  },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeStore store;
  late GooglePlayBillingService service;
  late String user;
  late int verifications;
  late Map<String, dynamic>? result;
  setUp(() {
    store = FakeStore();
    user = 'user-a';
    verifications = 0;
    result = confirmed();
    service = GooglePlayBillingService(
      store: store,
      enabled: true,
      currentUserId: () => user,
      verify: (_, _) async {
        verifications++;
        return result;
      },
    );
  });
  tearDown(() async {
    service.onClose();
    await store.events.close();
  });

  test(
    'disabled rollout cannot initiate checkout or verify purchases',
    () async {
      final disabled = GooglePlayBillingService(
        store: store,
        enabled: false,
        currentUserId: () => user,
        verify: (_, _) async {
          fail('must not verify');
        },
      );
      await disabled.loadProducts({'coins_100'});
      await disabled.buy('coins_100');
      await disabled.handlePurchase(purchase());
      expect(store.buys, 0);
      expect(disabled.walletRevision.value, 0);
    },
  );
  test('uses store localized price and an opaque account binding', () async {
    await service.loadProducts({'coins_100'});
    expect(service.products['coins_100']!.price, '₹99.00');
    await service.buy('coins_100');
    expect(store.buys, 1);
    expect(store.account, GooglePlayBillingService.accountId(user));
    expect(store.account!.length, 64);
    expect(store.account, isNot(user));
  });
  test('missing product or logged out user cannot start purchase', () async {
    await service.buy('missing');
    await service.loadProducts({'coins_100'});
    user = '';
    await service.buy('coins_100');
    expect(store.buys, 0);
  });
  test(
    'cancelled pending and failed payments never verify or refresh wallet',
    () async {
      for (final state in [
        PurchaseStatus.pending,
        PurchaseStatus.canceled,
        PurchaseStatus.error,
      ]) {
        await service.handlePurchase(purchase(state));
      }
      expect(verifications, 0);
      expect(service.walletRevision.value, 0);
    },
  );
  test(
    'generic success and credit without consumption are not delivery',
    () async {
      for (final response in [
        <String, dynamic>{'success': true},
        {
          'success': true,
          'data': {
            'productId': 'coins_100',
            'userId': user,
            'credited': true,
            'consumed': false,
          },
        },
      ]) {
        result = response;
        await service.handlePurchase(purchase());
        expect(service.walletRevision.value, 0);
      }
    },
  );
  test('confirmed duplicate token refreshes once', () async {
    await service.handlePurchase(purchase());
    await service.handlePurchase(purchase());
    expect(verifications, 1);
    expect(service.walletRevision.value, 1);
  });
  test('unconfirmed purchase can recover later', () async {
    result = null;
    await service.handlePurchase(purchase());
    expect(service.walletRevision.value, 0);
    result = confirmed();
    await service.handlePurchase(purchase(PurchaseStatus.restored));
    expect(verifications, 2);
    expect(service.walletRevision.value, 1);
  });
  test('wrong product or wrong account response is rejected', () async {
    result!['data']['productId'] = 'wrong';
    await service.handlePurchase(purchase());
    result = confirmed();
    result!['data']['userId'] = 'other';
    await service.handlePurchase(purchase());
    expect(service.walletRevision.value, 0);
  });
  test(
    'account switch during verification does not update new user wallet',
    () async {
      final pending = Completer<Map<String, dynamic>?>();
      service = GooglePlayBillingService(
        store: store,
        enabled: true,
        currentUserId: () => user,
        verify: (_, _) => pending.future,
      );
      final work = service.handlePurchase(purchase());
      user = 'user-b';
      pending.complete(confirmed());
      await work;
      expect(service.walletRevision.value, 0);
    },
  );
  test('simultaneous callbacks for same token verify once', () async {
    await Future.wait([
      service.handlePurchase(purchase()),
      service.handlePurchase(purchase()),
    ]);
    expect(verifications, 1);
  });
  test('checkout error releases busy state', () async {
    await service.loadProducts({'coins_100'});
    store.failBuy = true;
    await service.buy('coins_100');
    expect(service.busy.value, false);
    expect(service.message.value, contains('Unable'));
  });
  test('catalog requires explicit product mapping', () {
    final pack = CoinPackage.fromJson({'id': 'a', 'amount': 100, 'price': 99});
    expect(pack.googlePlayProductId, '');
    final mapped = CoinPackage.fromJson({
      'id': 'a',
      'amount': 100,
      'price': 99,
      'googlePlayProductId': 'coins_100',
    });
    expect(mapped.googlePlayProductId, 'coins_100');
  });
}
