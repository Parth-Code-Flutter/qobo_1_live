import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:qobo_one_live/utils/local_storage/controllers/local_storage_controller.dart';
import 'play_purchase_queue.dart';
import 'package:qobo_one_live/repo/economy/economy_repo.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';

/// Set false for a build that must not offer checkout.
const googlePlayCheckoutEnabled = bool.fromEnvironment(
  'GOOGLE_PLAY_BILLING_ENABLED',
  defaultValue: true,
);

abstract class PlayStoreGateway {
  Stream<List<PurchaseDetails>> get purchases;
  Future<bool> isAvailable();
  Future<ProductDetailsResponse> products(Set<String> ids);
  Future<bool> buy(ProductDetails product, String accountId);
  Future<void> recover();
  Future<bool> consume(PlayPurchaseReceipt receipt);
}

class GooglePlayStoreGateway implements PlayStoreGateway {
  final InAppPurchase _store = InAppPurchase.instance;
  @override
  Stream<List<PurchaseDetails>> get purchases => _store.purchaseStream;
  @override
  Future<bool> isAvailable() => _store.isAvailable();
  @override
  Future<ProductDetailsResponse> products(Set<String> ids) =>
      _store.queryProductDetails(ids);
  @override
  Future<bool> buy(ProductDetails product, String accountId) =>
      _store.buyConsumable(
        purchaseParam: PurchaseParam(
          productDetails: product,
          applicationUserName: accountId,
        ),
        autoConsume: false,
      );
  @override
  Future<void> recover() => _store.restorePurchases();
  @override
  Future<bool> consume(PlayPurchaseReceipt receipt) async {
    final result = await _store
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>()
        .consumePurchase(
          PurchaseDetails(
            productID: receipt.productId,
            purchaseID: receipt.orderId,
            transactionDate: null,
            verificationData: PurchaseVerificationData(
              localVerificationData: '',
              serverVerificationData: receipt.token,
              source: 'google_play',
            ),
            status: PurchaseStatus.purchased,
          ),
        );
    // Only called AFTER persisted backend credit. itemNotOwned handles a prior
    // successful consume whose response was lost; it is not payment verification.
    return result.responseCode == BillingResponse.ok ||
        result.responseCode == BillingResponse.itemNotOwned;
  }
}

typedef PlayConfirmer =
    Future<Map<String, dynamic>?> Function(
      PlayPurchaseReceipt receipt,
      String userId,
    );

/// App-wide listener: mobile reports purchase, backend credits, mobile consumes.
class GooglePlayBillingService extends GetxService with WidgetsBindingObserver {
  GooglePlayBillingService({
    required this.store,
    required this.confirm,
    required this.queue,
    required this.currentUserId,
    this.enabled = googlePlayCheckoutEnabled,
  });

  static String _sessionUserId() => Get.isRegistered<UserSessionController>()
      ? Get.find<UserSessionController>().userId.trim()
      : '';

  factory GooglePlayBillingService.production() => GooglePlayBillingService(
    store: GooglePlayStoreGateway(),
    queue: SecurePlayPurchaseQueue(),
    confirm: (receipt, owner) async {
      // Capture the bearer token, then re-check owner after the storage await.
      // The request cannot accidentally use a newly signed-in user's session.
      final token = await LocalStorage.shared.getToken();
      if (token.isEmpty || _sessionUserId() != owner) return null;
      return EconomyRepo().confirmGooglePlayPurchase(
        productId: receipt.productId,
        purchaseToken: receipt.token,
        orderId: receipt.orderId,
        bearerToken: token,
      );
    },
    currentUserId: _sessionUserId,
  );

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static String accountId(String userId) =>
      sha256.convert(utf8.encode('qobo-play:$userId')).toString();
  final PlayStoreGateway store;
  final PlayConfirmer confirm;
  final PlayPurchaseQueue queue;
  final String Function() currentUserId;
  final bool enabled;
  final products = <String, ProductDetails>{}.obs;
  final message = ''.obs;
  final busy = false.obs;
  final walletRevision = 0.obs;
  final Set<String> _processing = {};
  final Set<String> _finished = {};
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Timer? _retry;
  bool _recovering = false;
  bool _loadingProducts = false;

  @override
  void onInit() {
    super.onInit();
    if (!enabled) return;
    WidgetsBinding.instance.addObserver(this);
    _subscription = store.purchases.listen(
      (items) {
        for (final item in items) {
          unawaited(handlePurchase(item));
        }
      },
      onError: (Object _) {
        busy.value = false;
        message.value = 'Unable to check purchases. Please try again.';
      },
    );
    unawaited(recover());
    _retry = Timer.periodic(const Duration(seconds: 60), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        unawaited(recover());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(recover());
  }

  Future<void> loadProducts(Set<String> ids) async {
    if (!enabled) {
      message.value = 'Coin purchases are temporarily unavailable.';
      return;
    }
    if (_loadingProducts) return;
    _loadingProducts = true;
    products.clear();
    try {
      if (!await store.isAvailable().timeout(const Duration(seconds: 20))) {
        message.value = 'Google Play is unavailable on this device.';
        return;
      }
      if (ids.isEmpty) {
        message.value = 'Coin purchases are temporarily unavailable.';
        return;
      }
      final result = await store
          .products(ids)
          .timeout(const Duration(seconds: 20));
      if (result.error != null) {
        message.value = 'Unable to load Google Play prices. Please retry.';
        return;
      }
      products.assignAll({for (final p in result.productDetails) p.id: p});
      message.value = result.notFoundIDs.isEmpty
          ? ''
          : 'Some coin packs are currently unavailable.';
      await recover();
    } catch (_) {
      message.value = 'Unable to connect to Google Play. Please retry.';
    } finally {
      _loadingProducts = false;
    }
  }

  Future<void> buy(String productId) async {
    if (busy.value || _processing.isNotEmpty) return;
    final userId = currentUserId().trim();
    final product = products[productId];
    if (!enabled || product == null) {
      message.value = 'This coin pack is currently unavailable.';
      return;
    }
    if (userId.isEmpty) {
      message.value = 'Please sign in before purchasing coins.';
      return;
    }
    busy.value = true;
    message.value = 'Opening Google Play…';
    try {
      final started = await store
          .buy(product, accountId(userId))
          .timeout(const Duration(seconds: 60));
      if (message.value == 'Opening Google Play…') {
        message.value = started
            ? 'Complete your payment in Google Play.'
            : 'Unable to open Google Play checkout.';
      }
    } catch (_) {
      message.value = 'Unable to start payment. Please retry.';
    } finally {
      // Google owns the sheet; do not leave the wallet stuck if it is dismissed.
      busy.value = false;
    }
  }

  Future<void> recover() async {
    if (!enabled || _recovering || currentUserId().trim().isEmpty) return;
    _recovering = true;
    try {
      for (final receipt in await queue.read()) {
        await _processReceipt(receipt);
      }
      if (await store.isAvailable().timeout(const Duration(seconds: 20))) {
        await store.recover().timeout(const Duration(seconds: 20));
      }
    } catch (_) {
      // Keep purchases owned by Play; retry on resume or next foreground tick.
    } finally {
      _recovering = false;
    }
  }

  Future<void> handlePurchase(PurchaseDetails purchase) async {
    if (!enabled) return;
    switch (purchase.status) {
      case PurchaseStatus.pending:
        message.value =
            'Payment pending. Coins will be added after confirmation.';
        return;
      case PurchaseStatus.canceled:
        message.value = 'Payment cancelled.';
        return;
      case PurchaseStatus.error:
        message.value = 'Payment could not be completed. Please try again.';
        return;
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        break;
    }
    // Native account binding survives app restarts and account switches. Never
    // assign an unbound/other-account purchase to the currently signed-in user.
    if (purchase is! GooglePlayPurchaseDetails) return;
    final native = purchase.billingClientPurchase;
    final owner = native.obfuscatedAccountId?.trim() ?? '';
    final token = purchase.verificationData.serverVerificationData;
    if (native.packageName != 'com.qobo1live.live' ||
        native.purchaseState != PurchaseStateWrapper.purchased ||
        token.isEmpty ||
        owner.isEmpty ||
        _finished.contains(token)) {
      return;
    }
    await _processReceipt(
      PlayPurchaseReceipt(
        productId: purchase.productID,
        token: token,
        accountId: owner,
        orderId: purchase.purchaseID,
      ),
    );
  }

  Future<void> _processReceipt(PlayPurchaseReceipt receipt) async {
    final token = receipt.token;
    if (_processing.contains(token) || _finished.contains(token)) return;
    _processing.add(token);
    final userId = currentUserId().trim();
    try {
      // Preserve the persisted credit marker if Play redelivers the receipt.
      final saved = (await queue.read()).where((r) => r.token == token);
      if (saved.isNotEmpty) {
        final previous = saved.first;
        if (previous.accountId != receipt.accountId ||
            previous.productId != receipt.productId) {
          return;
        }
        receipt = previous;
      }
      await queue.save(receipt);
      if (userId.isEmpty ||
          accountId(userId) != receipt.accountId ||
          currentUserId().trim() != userId) {
        message.value =
            'Sign in to the account that started this purchase to finish it.';
        return;
      }
      if (!receipt.credited) {
        message.value = 'Adding your purchased coins…';
        final response = await confirm(
          receipt,
          userId,
        ).timeout(const Duration(seconds: 30));
        final data = response?['data'];
        final credited =
            response?['success'] == true &&
            data is Map &&
            data['productId'] == receipt.productId &&
            data['userId'] == userId &&
            data['credited'] == true &&
            data['coinsAdded'] is num &&
            (data['coinsAdded'] as num) > 0;
        if (!credited) {
          if (currentUserId().trim() == userId) {
            message.value = response?['code'] == 'PURCHASE_TOKEN_ALREADY_USED'
                ? 'This purchase is already assigned to another account or pack. Contact support.'
                : 'Coins are awaiting confirmation. We will retry automatically.';
          }
          return;
        }
        receipt = receipt.withCredit();
        await queue.save(receipt);
      }
      // A matching authenticated response is wallet delivery, not independent
      // payment verification. Never credit again during consumption retries.
      if (currentUserId().trim() != userId) return;
      walletRevision.value++;
      message.value = 'Coins added. Finishing your purchase…';
      final consumed = await store
          .consume(receipt)
          .timeout(const Duration(seconds: 20));
      if (!consumed) {
        if (currentUserId().trim() == userId) {
          message.value =
              'Coins added. Purchase completion will retry automatically.';
        }
        return;
      }
      await queue.remove(token);
      _finished.add(token);
      if (currentUserId().trim() == userId) {
        message.value = 'Purchase complete. Your coins are ready to use.';
      }
    } catch (_) {
      if (currentUserId().trim() == userId) {
        message.value =
            'Purchase completion is pending. We will retry automatically.';
      }
    } finally {
      _processing.remove(token);
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _retry?.cancel();
    _subscription?.cancel();
    super.onClose();
  }
}
