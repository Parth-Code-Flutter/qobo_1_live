import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:qobo_one_live/services/payment/google_play_billing_service.dart';
import 'package:qobo_one_live/services/payment/play_purchase_queue.dart';
import 'package:qobo_one_live/app/user_flow/wallet/controllers/wallet_controller.dart';

class MemoryQueue implements PlayPurchaseQueue {
  final values = <String, PlayPurchaseReceipt>{};
  bool failSave = false;
  @override
  Future<List<PlayPurchaseReceipt>> read() async => values.values.toList();
  @override
  Future<void> save(PlayPurchaseReceipt r) async {
    if (failSave) throw StateError('disk unavailable');
    values[r.token] = r;
  }

  @override
  Future<void> remove(String token) async {
    values.remove(token);
  }
}

class FakeStore implements PlayStoreGateway {
  final events = StreamController<List<PurchaseDetails>>.broadcast();
  int buys = 0;
  int consumes = 0;
  String? account;
  bool available = true;
  bool failBuy = false;
  bool consumeResult = true;
  List<PurchaseDetails> owned = [];
  @override
  Stream<List<PurchaseDetails>> get purchases => events.stream;
  @override
  Future<bool> isAvailable() async => available;
  @override
  Future<ProductDetailsResponse> products(Set<String> ids) async =>
      ProductDetailsResponse(
        productDetails: ids.contains('qobo_coins_4000') ? [product] : [],
        notFoundIDs: ids.where((id) => id != 'qobo_coins_4000').toList(),
      );
  @override
  Future<bool> buy(ProductDetails p, String accountId) async {
    buys++;
    account = accountId;
    if (failBuy) throw StateError('offline');
    return true;
  }

  @override
  Future<void> recover() async {
    events.add(owned);
  }

  @override
  Future<bool> consume(PlayPurchaseReceipt receipt) async {
    consumes++;
    return consumeResult;
  }
}

final product = ProductDetails(
  id: 'qobo_coins_4000',
  title: '4,000 Coins',
  description: 'Coins',
  price: '₹50.00',
  rawPrice: 50,
  currencyCode: 'INR',
);
GooglePlayPurchaseDetails purchase({
  PurchaseStatus status = PurchaseStatus.purchased,
  String token = 'test-token',
  String? owner = 'user-a',
  String package = 'com.qobo1live.live',
}) {
  final native = PurchaseWrapper(
    orderId: 'GPA.test',
    packageName: package,
    purchaseTime: 1,
    purchaseToken: token,
    signature: '',
    products: ['qobo_coins_4000'],
    isAutoRenewing: false,
    originalJson: '{}',
    isAcknowledged: false,
    purchaseState: status == PurchaseStatus.pending
        ? PurchaseStateWrapper.pending
        : PurchaseStateWrapper.purchased,
    obfuscatedAccountId: owner == null
        ? null
        : GooglePlayBillingService.accountId(owner),
  );
  return GooglePlayPurchaseDetails(
    productID: 'qobo_coins_4000',
    purchaseID: 'GPA.test',
    verificationData: PurchaseVerificationData(
      localVerificationData: '{}',
      serverVerificationData: token,
      source: 'google_play',
    ),
    transactionDate: '1',
    billingClientPurchase: native,
    status: status,
  );
}

Map<String, dynamic> confirmed({bool duplicate = false}) => {
  'success': true,
  'data': {
    'productId': 'qobo_coins_4000',
    'userId': 'user-a',
    'credited': true,
    'coinsAdded': 4000,
    'alreadyCredited': duplicate,
  },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeStore store;
  late MemoryQueue queue;
  late GooglePlayBillingService service;
  late String user;
  late int confirmations;
  late Map<String, dynamic>? result;
  late bool failConfirm;
  late PlayPurchaseReceipt? sent;
  GooglePlayBillingService makeService() => GooglePlayBillingService(
    store: store,
    enabled: true,
    queue: queue,
    currentUserId: () => user,
    confirm: (r, owner) async {
      confirmations++;
      sent = r;
      expect(owner, 'user-a');
      expect(store.consumes, 0);
      if (failConfirm) throw StateError('network');
      return result;
    },
  );
  setUp(() {
    store = FakeStore();
    queue = MemoryQueue();
    user = 'user-a';
    confirmations = 0;
    result = confirmed();
    failConfirm = false;
    sent = null;
    service = makeService();
  });
  tearDown(() async {
    service.onClose();
    await store.events.close();
  });

  test('disabled build cannot start checkout or credit purchases', () async {
    final disabled = GooglePlayBillingService(
      store: store,
      enabled: false,
      queue: queue,
      currentUserId: () => user,
      confirm: (_, _) async {
        fail('must not confirm');
      },
    );
    await disabled.loadProducts({'qobo_coins_4000'});
    await disabled.buy('qobo_coins_4000');
    await disabled.handlePurchase(purchase());
    expect(store.buys, 0);
    expect(store.consumes, 0);
  });
  test(
    'store price and opaque account binding; launch alone never credits',
    () async {
      await service.loadProducts({'qobo_coins_4000'});
      expect(service.products['qobo_coins_4000']!.price, '₹50.00');
      await service.buy('qobo_coins_4000');
      expect(store.buys, 1);
      expect(store.account, GooglePlayBillingService.accountId(user));
      expect(store.account!.length, 64);
      expect(confirmations, 0);
      expect(store.consumes, 0);
    },
  );
  test('missing product or logged out user cannot buy', () async {
    await service.buy('missing');
    await service.loadProducts({'qobo_coins_4000'});
    user = '';
    await service.buy('qobo_coins_4000');
    expect(store.buys, 0);
  });
  test('pending cancelled and error events do not credit or consume', () async {
    for (final state in [
      PurchaseStatus.pending,
      PurchaseStatus.canceled,
      PurchaseStatus.error,
    ]) {
      await service.handlePurchase(purchase(status: state));
    }
    expect(confirmations, 0);
    expect(store.consumes, 0);
    expect(queue.values, isEmpty);
  });
  test(
    'credit confirmation precedes consumption and includes Google order',
    () async {
      await service.handlePurchase(purchase());
      expect(confirmations, 1);
      expect(sent!.orderId, 'GPA.test');
      expect(store.consumes, 1);
      expect(service.walletRevision.value, 1);
      expect(queue.values, isEmpty);
      expect(service.message.value, contains('complete'));
    },
  );
  test('generic success or credited false never consumes', () async {
    for (final r in [
      <String, dynamic>{'success': true},
      {
        'success': true,
        'data': {
          'productId': 'qobo_coins_4000',
          'userId': user,
          'credited': false,
          'coinsAdded': 4000,
        },
      },
    ]) {
      result = r;
      await service.handlePurchase(purchase());
    }
    expect(store.consumes, 0);
    expect(queue.values.length, 1);
  });
  test('duplicate callbacks credit and consume once', () async {
    await Future.wait([
      service.handlePurchase(purchase()),
      service.handlePurchase(purchase()),
    ]);
    await service.handlePurchase(purchase());
    expect(confirmations, 1);
    expect(store.consumes, 1);
  });
  test(
    'backend alreadyCredited response still completes consumption',
    () async {
      result = confirmed(duplicate: true);
      await service.handlePurchase(purchase());
      expect(store.consumes, 1);
      expect(queue.values, isEmpty);
    },
  );
  test('backend failure retains receipt and retries after restart', () async {
    failConfirm = true;
    await service.handlePurchase(purchase());
    expect(store.consumes, 0);
    expect(queue.values.length, 1);
    service.onClose();
    service = makeService();
    failConfirm = false;
    await service.recover();
    expect(confirmations, 2);
    expect(store.consumes, 1);
    expect(queue.values, isEmpty);
  });
  test(
    'consumption failure persists credit and retries without second API call',
    () async {
      store.consumeResult = false;
      await service.handlePurchase(purchase());
      expect(queue.values.values.single.credited, true);
      service.onClose();
      service = makeService();
      store.consumeResult = true;
      await service.recover();
      expect(confirmations, 1);
      expect(store.consumes, 2);
      expect(queue.values, isEmpty);
    },
  );
  test('redelivery does not erase persisted credited marker', () async {
    store.consumeResult = false;
    await service.handlePurchase(purchase());
    store.consumeResult = true;
    await service.handlePurchase(purchase(status: PurchaseStatus.restored));
    expect(confirmations, 1);
    expect(store.consumes, 2);
  });
  test('unbound and foreign-package purchases are ignored', () async {
    await service.handlePurchase(purchase(owner: null));
    await service.handlePurchase(purchase(package: 'another.app'));
    expect(confirmations, 0);
    expect(store.consumes, 0);
  });
  test('wrong account waits for original owner without credit', () async {
    user = 'user-b';
    await service.handlePurchase(purchase());
    expect(confirmations, 0);
    expect(queue.values.length, 1);
    user = 'user-a';
    await service.recover();
    expect(confirmations, 1);
    expect(store.consumes, 1);
  });
  test(
    'logged out event is persisted until original account signs in',
    () async {
      user = '';
      await service.handlePurchase(purchase());
      expect(confirmations, 0);
      user = 'user-a';
      await service.recover();
      expect(store.consumes, 1);
    },
  );
  test(
    'wrong account or product in backend response does not consume',
    () async {
      result!['data']['userId'] = 'other';
      await service.handlePurchase(purchase());
      result = confirmed();
      result!['data']['productId'] = 'wrong';
      await service.handlePurchase(purchase());
      expect(store.consumes, 0);
    },
  );
  test(
    'account switch while request in flight preserves original credit for retry',
    () async {
      final pending = Completer<Map<String, dynamic>?>();
      final started = Completer<void>();
      service = GooglePlayBillingService(
        store: store,
        enabled: true,
        queue: queue,
        currentUserId: () => user,
        confirm: (_, _) {
          started.complete();
          return pending.future;
        },
      );
      final work = service.handlePurchase(purchase());
      await started.future;
      user = 'user-b';
      pending.complete(confirmed());
      await work;
      expect(store.consumes, 0);
      expect(service.walletRevision.value, 0);
      expect(queue.values.values.single.credited, true);
      user = 'user-a';
      await service.recover();
      expect(store.consumes, 1);
    },
  );
  test('disk failure prevents credit and consumption', () async {
    queue.failSave = true;
    await service.handlePurchase(purchase());
    expect(confirmations, 0);
    expect(store.consumes, 0);
  });
  test('conflict response never consumes', () async {
    result = {'success': false, 'code': 'PURCHASE_TOKEN_ALREADY_USED'};
    await service.handlePurchase(purchase());
    expect(store.consumes, 0);
    expect(service.message.value, contains('another account'));
  });
  test('new token allows repeat pack purchase', () async {
    await service.handlePurchase(purchase());
    // Each new token is a distinct purchase. Prior consumption is expected here.
    service.onClose();
    service = GooglePlayBillingService(
      store: store,
      enabled: true,
      queue: queue,
      currentUserId: () => user,
      confirm: (_, _) async {
        confirmations++;
        return confirmed();
      },
    );
    await service.handlePurchase(purchase(token: 'second-token'));
    expect(confirmations, 2);
    expect(store.consumes, 2);
  });
  test('checkout error releases busy state', () async {
    await service.loadProducts({'qobo_coins_4000'});
    store.failBuy = true;
    await service.buy('qobo_coins_4000');
    expect(service.busy.value, false);
  });
  test('20 coin package retains backend Google Play product mapping', () async {
    final pack = CoinPackage.fromJson({
      'id': 'small-pack',
      'amount': 20,
      'price': 1,
      'googlePlayProductId': 'qobo_coins_20',
    });
    expect(pack.amount, 20);
    expect(pack.googlePlayProductId, 'qobo_coins_20');
    service.products[pack.googlePlayProductId] = ProductDetails(
      id: pack.googlePlayProductId,
      title: '20 coins',
      description: 'Small pack',
      price: '₹1.00',
      rawPrice: 1,
      currencyCode: 'INR',
    );
    await service.buy(pack.googlePlayProductId);
    expect(store.buys, 1);
    expect(confirmations, 0); // Checkout alone must never grant coins.
    expect(store.account, GooglePlayBillingService.accountId(user));
  });
  test('catalog needs explicit product mapping', () {
    final p = CoinPackage.fromJson({'id': 'a', 'amount': 4000, 'price': 50});
    expect(p.googlePlayProductId, '');
    final mapped = CoinPackage.fromJson({
      'id': 'a',
      'amount': 4000,
      'price': 50,
      'googlePlayProductId': 'qobo_coins_4000',
    });
    expect(mapped.googlePlayProductId, 'qobo_coins_4000');
  });
}
