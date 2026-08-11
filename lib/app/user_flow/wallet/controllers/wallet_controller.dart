import 'package:get/get.dart';
import 'package:qobo_one_live/constants/razorpay_config.dart';
import 'package:qobo_one_live/repo/economy/economy_api_utils.dart';
import 'package:qobo_one_live/repo/economy/economy_repo.dart';
import 'package:qobo_one_live/services/payment/razorpay_payment_service.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';

import '../models/withdraw_config.dart';
import '../models/withdraw_history_item.dart';
import '../models/withdraw_request_result.dart';

class CoinPackage {
  const CoinPackage({
    required this.id,
    required this.name,
    required this.amount,
    required this.price,
    required this.currency,
  });

  final String id;
  final String name;
  final int amount;
  final num price;
  final String currency;

  String get coinsLabel => '$amount Coins';
  String get priceLabel =>
      '$currency ${price % 1 == 0 ? price.toInt() : price}';

  /// Razorpay expects amount in the smallest currency unit (paise for INR).
  int get priceInMinorUnits {
    final scaled = (price * 100).round();
    return scaled < 0 ? 0 : scaled;
  }

  factory CoinPackage.fromJson(Map<String, dynamic> json) {
    final amountRaw =
        json['amount'] ??
        json['coins'] ??
        json['coin'] ??
        json['coinAmount'] ??
        json['coin_amount'];
    final priceRaw =
        json['price'] ??
        json['amountInr'] ??
        json['amount_inr'] ??
        json['inr'] ??
        json['cost'];
    final id =
        json['id']?.toString() ??
        json['_id']?.toString() ??
        json['packageId']?.toString() ??
        json['package_id']?.toString() ??
        '';
    final currencyRaw =
        json['currency']?.toString() ??
        json['currencyCode']?.toString() ??
        json['currency_code']?.toString() ??
        'INR';

    return CoinPackage(
      id: id,
      name: json['name']?.toString() ??
          json['title']?.toString() ??
          'Coin Package',
      amount: amountRaw is num
          ? amountRaw.round()
          : int.tryParse(amountRaw?.toString() ?? '') ?? 0,
      price: priceRaw is num
          ? priceRaw
          : num.tryParse(priceRaw?.toString() ?? '') ?? 0,
      currency: currencyRaw.trim().isNotEmpty ? currencyRaw.trim() : 'INR',
    );
  }
}

/// Controller for wallet flow.
class WalletController extends GetxController {
  WalletController({
    EconomyRepo? economyRepo,
    RazorpayPaymentService? razorpayPaymentService,
  }) : _economyRepo = economyRepo ?? EconomyRepo(),
       _razorpay = razorpayPaymentService ?? RazorpayPaymentService();

  final EconomyRepo _economyRepo;
  final RazorpayPaymentService _razorpay;

  final coinBalance = '0'.obs;
  final diamondBalance = '0'.obs;
  /// USD equivalent from wallet API (`dollars` / diamonds÷1000).
  final dollarBalance = '\$0.00'.obs;
  final dollarBalanceValue = 0.0.obs;
  final withdrawalLimit = '0'.obs;
  final withdrawableBalance = '0'.obs;
  final withdrawCurrencySymbol = '\$'.obs;
  final isEligibleForWithdrawThisWeek = true.obs;
  final allowedWithdrawTiers = <int>[].obs;
  final withdrawHistory = <WithdrawHistoryItem>[].obs;
  final selectedWithdrawTier = RxnInt();
  final isLoadingWithdrawConfig = false.obs;
  final isLoadingWithdrawHistory = false.obs;
  final isSubmittingWithdrawal = false.obs;
  final withdrawError = ''.obs;
  final packages = <CoinPackage>[].obs;
  final selectedPlanIndex = 0.obs;
  final isLoadingPackages = false.obs;
  final packageError = ''.obs;
  final isBuying = false.obs;

  CoinPackage? get selectedPackage {
    if (packages.isEmpty) return null;
    final index = selectedPlanIndex.value;
    if (index < 0 || index >= packages.length) return null;
    return packages[index];
  }

  @override
  void onInit() {
    super.onInit();
    loadWallet();
    loadCoinPackages();
    loadWithdrawConfig();
    loadWithdrawHistory();
  }

  @override
  void onClose() {
    _razorpay.dispose();
    super.onClose();
  }

  Future<void> loadWallet() async {
    final response = await _economyRepo.getWalletBalances(isShowLoader: false);
    final data = response?['data'];
    if (isEconomyApiSuccess(response) && data is Map) {
      final coins = parseWalletAmount(
        data['coins'] ??
            data['coin'] ??
            data['balance'] ??
            data['coinBalance'],
      );
      final diamonds = parseWalletAmount(
        data['diamonds'] ?? data['diamond'] ?? data['diamondBalance'],
      );
      coinBalance.value = _formatAmount(coins);
      diamondBalance.value = _formatAmount(diamonds);
      final dollars = resolveEarnedDollars(
        data: data,
        diamondsFallback: diamonds,
        coinsFallback: coins,
      );
      dollarBalanceValue.value = dollars;
      dollarBalance.value = formatUsd(dollars);
    }
  }

  Future<void> loadCoinPackages() async {
    isLoadingPackages.value = true;
    packageError.value = '';
    try {
      final response = await _economyRepo.getCoinPackages(isShowLoader: false);
      final data = response?['data'];
      final list = _extractPackageList(data);
      if (isEconomyApiSuccess(response) && list != null) {
        final parsed = list
            .whereType<Map>()
            .map((e) => CoinPackage.fromJson(Map<String, dynamic>.from(e)))
            .where((e) => e.id.isNotEmpty && e.amount > 0 && e.price > 0)
            .toList();
        packages.assignAll(parsed);
        if (selectedPlanIndex.value >= parsed.length) {
          selectedPlanIndex.value = 0;
        }
        if (parsed.isEmpty) {
          packageError.value = 'No coin packages found.';
        }
      } else {
        packages.clear();
        packageError.value =
            response?['message']?.toString() ?? 'No coin packages found.';
      }
    } catch (_) {
      packages.clear();
      packageError.value = 'Unable to load coin packages.';
    } finally {
      isLoadingPackages.value = false;
    }
  }

  List? _extractPackageList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      final nested =
          data['packages'] ??
          data['items'] ??
          data['list'] ??
          data['plans'] ??
          data['coinPackages'];
      if (nested is List) return nested;
    }
    return null;
  }

  Future<void> loadWithdrawConfig() async {
    isLoadingWithdrawConfig.value = true;
    withdrawError.value = '';
    try {
      final response = await _economyRepo.getWithdrawConfig(isShowLoader: false);
      final data = response?['data'];
      if (isEconomyApiSuccess(response) && data is Map) {
        final config = WithdrawConfig.fromJson(Map<String, dynamic>.from(data));
        allowedWithdrawTiers.assignAll(config.allowedTiers);
        withdrawCurrencySymbol.value = config.currencySymbol;
        isEligibleForWithdrawThisWeek.value = config.isEligibleThisWeek;
        withdrawableBalance.value = _formatAmount(config.userBalance);
        withdrawalLimit.value = _formatAmount(config.maxLimit);
        if (selectedWithdrawTier.value != null &&
            !config.allowedTiers.contains(selectedWithdrawTier.value)) {
          selectedWithdrawTier.value = null;
        }
      } else {
        withdrawError.value =
            response?['message']?.toString() ??
            'Unable to load withdrawal config.';
      }
    } catch (_) {
      withdrawError.value = 'Unable to load withdrawal config.';
    } finally {
      isLoadingWithdrawConfig.value = false;
    }
  }

  Future<void> loadWithdrawHistory() async {
    isLoadingWithdrawHistory.value = true;
    try {
      final response = await _economyRepo.getWithdrawHistory(
        isShowLoader: false,
      );
      final data = response?['data'];
      if (isEconomyApiSuccess(response) && data is List) {
        final parsed = data
            .whereType<Map>()
            .map(
              (e) =>
                  WithdrawHistoryItem.fromJson(Map<String, dynamic>.from(e)),
            )
            .where((e) => e.transactionId.isNotEmpty)
            .toList();
        withdrawHistory.assignAll(parsed);
      } else {
        withdrawHistory.clear();
      }
    } catch (_) {
      withdrawHistory.clear();
    } finally {
      isLoadingWithdrawHistory.value = false;
    }
  }

  void selectWithdrawTier(int amount) {
    if (!allowedWithdrawTiers.contains(amount)) return;
    selectedWithdrawTier.value = amount;
  }

  Future<WithdrawRequestResult?> submitWithdrawalRequest({
    String? accountNumber,
    String? ifscCode,
    String? upiId,
  }) async {
    final amount = selectedWithdrawTier.value;
    if (amount == null) {
      withdrawError.value = 'Please select a withdrawal amount.';
      return null;
    }
    if (!isEligibleForWithdrawThisWeek.value) {
      withdrawError.value = 'You have already requested a weekly withdrawal.';
      return null;
    }

    isSubmittingWithdrawal.value = true;
    withdrawError.value = '';
    try {
      final response = await _economyRepo.requestWithdrawal(
        amount: amount,
        accountNumber: accountNumber,
        ifscCode: ifscCode,
        upiId: upiId,
        isShowLoader: true,
      );
      final data = response?['data'];
      if (isEconomyApiSuccess(response) && data is Map) {
        final result = WithdrawRequestResult.fromJson(
          Map<String, dynamic>.from(data),
        );
        await Future.wait([
          loadWallet(),
          loadWithdrawConfig(),
          loadWithdrawHistory(),
        ]);
        return result;
      }
      withdrawError.value =
          response?['message']?.toString() ?? 'Withdrawal request failed.';
      return null;
    } finally {
      isSubmittingWithdrawal.value = false;
    }
  }

  String tierLabel(int amount) => '${withdrawCurrencySymbol.value}$amount';

  /// Opens Razorpay Checkout for [package] (or the selected plan), then credits
  /// coins via `POST /api/economy/recharge` with payment references.
  Future<bool> buyPackageWithRazorpay({CoinPackage? package}) async {
    final plan = package ?? selectedPackage;
    if (plan == null) {
      packageError.value = 'No coin package selected.';
      return false;
    }
    if (plan.priceInMinorUnits <= 0) {
      packageError.value = 'Invalid package price.';
      return false;
    }
    if (RazorpayConfig.isPlaceholderKey &&
        !RazorpayConfig.allowPlaceholderCheckout) {
      packageError.value =
          'Razorpay key not configured. Replace RazorpayConfig.keyId.';
      return false;
    }

    isBuying.value = true;
    packageError.value = '';
    try {
      String? email;
      String? phone;
      String? name;
      if (Get.isRegistered<UserSessionController>()) {
        final session = Get.find<UserSessionController>();
        email = session.email;
        phone = session.phone;
        name = session.userName;
      }

      final checkout = await _razorpay.openCheckout(
        amountMinorUnits: plan.priceInMinorUnits,
        currency: plan.currency,
        description: plan.coinsLabel,
        receipt: 'pkg_${plan.id}',
        email: email,
        contact: phone,
        customerName: name,
      );

      if (!checkout.success) {
        if (checkout.cancelled) {
          packageError.value = 'Payment cancelled.';
        } else {
          packageError.value =
              checkout.errorMessage?.trim().isNotEmpty == true
              ? checkout.errorMessage!
              : 'Payment failed.';
        }
        return false;
      }

      final paymentId = checkout.paymentId?.trim() ?? '';
      if (paymentId.isEmpty) {
        packageError.value = 'Missing Razorpay payment id.';
        return false;
      }

      final response = await _economyRepo.rechargeCurrency(
        amount: plan.amount,
        method: 'razorpay',
        packageId: plan.id,
        paymentId: paymentId,
        orderId: checkout.orderId,
        signature: checkout.signature,
        paidAmount: plan.price,
        currency: plan.currency,
        isShowLoader: true,
      );

      if (isEconomyApiSuccess(response)) {
        await loadWallet();
        return true;
      }

      packageError.value =
          response?['message']?.toString() ??
          'Payment received but coin credit failed. Contact support with $paymentId.';
      return false;
    } catch (error) {
      packageError.value = 'Unable to start Razorpay checkout.';
      return false;
    } finally {
      isBuying.value = false;
    }
  }

  /// Legacy non-gateway path (Google Pay / PayPal placeholders). Prefer
  /// [buyPackageWithRazorpay] for real purchases.
  Future<bool> buySelectedPackage(String method) async {
    final normalized = method.trim().toLowerCase();
    if (normalized.contains('razor')) {
      return buyPackageWithRazorpay();
    }

    final package = selectedPackage;
    if (package == null) {
      packageError.value = 'No coin package selected.';
      return false;
    }
    isBuying.value = true;
    try {
      final response = await _economyRepo.rechargeCurrency(
        amount: package.amount,
        method: normalized,
        packageId: package.id,
        paidAmount: package.price,
        currency: package.currency,
        isShowLoader: true,
      );
      if (isEconomyApiSuccess(response)) {
        await loadWallet();
        return true;
      }
      packageError.value =
          response?['message']?.toString() ?? 'Payment failed.';
      return false;
    } finally {
      isBuying.value = false;
    }
  }

  String _formatAmount(dynamic value) {
    final number = value is num
        ? value.round()
        : int.tryParse(value?.toString() ?? '') ?? 0;
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}
