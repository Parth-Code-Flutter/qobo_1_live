import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:qobo_one_live/repo/economy/economy_repo.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';

/// Keep disabled until the verification API and product catalog are deployed.
const googlePlayCheckoutEnabled = bool.fromEnvironment(
  'GOOGLE_PLAY_BILLING_ENABLED',
);

abstract class PlayStoreGateway {
  Stream<List<PurchaseDetails>> get purchases;
  Future<bool> isAvailable();
  Future<ProductDetailsResponse> products(Set<String> ids);
  Future<bool> buy(ProductDetails product, String accountId);
  Future<void> recover();
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
}

typedef PlayVerifier =
    Future<Map<String, dynamic>?> Function(String productId, String token);

/// Lives beyond the wallet route. The server verifies, credits and consumes;
/// the client NEVER grants coins or acknowledges an unverified transaction.
class GooglePlayBillingService extends GetxService with WidgetsBindingObserver {
  GooglePlayBillingService({
    required this.store,
    required this.verify,
    required this.currentUserId,
    this.enabled = googlePlayCheckoutEnabled,
  });

  factory GooglePlayBillingService.production() => GooglePlayBillingService(
    store: GooglePlayStoreGateway(),
    verify: (productId, token) => EconomyRepo().verifyGooglePlayPurchase(
      productId: productId,
      purchaseToken: token,
    ),
    currentUserId: () => Get.isRegistered<UserSessionController>()
        ? Get.find<UserSessionController>().userId
        : '',
  );

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static String accountId(String userId) =>
      sha256.convert(utf8.encode('qobo-play:$userId')).toString();
  final PlayStoreGateway store;
  final PlayVerifier verify;
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
    if (busy.value) return;
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
      message.value = started
          ? 'Complete your payment in Google Play.'
          : 'Unable to open Google Play checkout.';
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
    final userId = currentUserId().trim();
    final token = purchase.verificationData.serverVerificationData;
    if (userId.isEmpty ||
        token.isEmpty ||
        _processing.contains(token) ||
        _finished.contains(token)) {
      return;
    }
    _processing.add(token);
    message.value = 'Confirming your purchase…';
    try {
      final response = await verify(
        purchase.productID,
        token,
      ).timeout(const Duration(seconds: 30));
      final data = response?['data'];
      // Strict contract: an HTTP/business success alone is NOT proof of delivery.
      // Server must also validate Google's obfuscatedAccountId against this user.
      final completed =
          response?['success'] == true &&
          data is Map &&
          data['productId'] == purchase.productID &&
          data['userId'] == userId &&
          data['credited'] == true &&
          data['consumed'] == true;
      if (completed) {
        _finished.add(token);
        if (currentUserId().trim() == userId) {
          walletRevision.value++;
          message.value = 'Purchase confirmed. Your wallet has been updated.';
        }
      } else if (currentUserId().trim() == userId) {
        message.value = 'Purchase awaiting confirmation. Please retry shortly.';
      }
    } catch (_) {
      if (currentUserId().trim() == userId) {
        message.value =
            'Purchase awaiting confirmation. We will retry automatically.';
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
