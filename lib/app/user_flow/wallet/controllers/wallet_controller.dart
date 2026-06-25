import 'package:get/get.dart';
import 'package:qobo_one_live/repo/economy/economy_api_utils.dart';
import 'package:qobo_one_live/repo/economy/economy_repo.dart';

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
  String get priceLabel => '$currency ${price % 1 == 0 ? price.toInt() : price}';

  factory CoinPackage.fromJson(Map<String, dynamic> json) {
    final amountRaw = json['amount'];
    final priceRaw = json['price'];
    return CoinPackage(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Coin Package',
      amount: amountRaw is num
          ? amountRaw.round()
          : int.tryParse(amountRaw?.toString() ?? '') ?? 0,
      price: priceRaw is num
          ? priceRaw
          : num.tryParse(priceRaw?.toString() ?? '') ?? 0,
      currency: json['currency']?.toString().trim().isNotEmpty == true
          ? json['currency'].toString()
          : 'INR',
    );
  }
}

/// Controller for wallet flow.
class WalletController extends GetxController {
  WalletController({EconomyRepo? economyRepo})
    : _economyRepo = economyRepo ?? EconomyRepo();

  final EconomyRepo _economyRepo;

  final coinBalance = '0'.obs;
  final diamondBalance = '0'.obs;
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

  @override
  void onInit() {
    super.onInit();
    loadWallet();
    loadCoinPackages();
    loadWithdrawConfig();
    loadWithdrawHistory();
  }

  Future<void> loadWallet() async {
    final response = await _economyRepo.getWalletBalances(isShowLoader: false);
    final data = response?['data'];
    if (isEconomyApiSuccess(response) && data is Map) {
      coinBalance.value = _formatAmount(
        parseWalletAmount(
          data['coins'] ?? data['coin'] ?? data['balance'] ?? data['coinBalance'],
        ),
      );
      diamondBalance.value = _formatAmount(
        parseWalletAmount(
          data['diamonds'] ?? data['diamond'] ?? data['diamondBalance'],
        ),
      );
    }
  }

  Future<void> loadCoinPackages() async {
    isLoadingPackages.value = true;
    packageError.value = '';
    try {
      final response = await _economyRepo.getCoinPackages(isShowLoader: false);
      final data = response?['data'];
      if (isEconomyApiSuccess(response) && data is List) {
        final parsed = data
            .whereType<Map>()
            .map((e) => CoinPackage.fromJson(Map<String, dynamic>.from(e)))
            .where((e) => e.id.isNotEmpty && e.amount > 0)
            .toList();
        packages.assignAll(parsed);
        if (selectedPlanIndex.value >= parsed.length) {
          selectedPlanIndex.value = 0;
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
            response?['message']?.toString() ?? 'Unable to load withdrawal config.';
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
      final response = await _economyRepo.getWithdrawHistory(isShowLoader: false);
      final data = response?['data'];
      if (isEconomyApiSuccess(response) && data is List) {
        final parsed = data
            .whereType<Map>()
            .map((e) => WithdrawHistoryItem.fromJson(Map<String, dynamic>.from(e)))
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

  String tierLabel(int amount) =>
      '${withdrawCurrencySymbol.value}$amount';

  Future<bool> buySelectedPackage(String method) async {
    if (packages.isEmpty || selectedPlanIndex.value >= packages.length) {
      return false;
    }
    final package = packages[selectedPlanIndex.value];
    isBuying.value = true;
    try {
      final response = await _economyRepo.rechargeCurrency(
        amount: package.amount,
        method: method,
        isShowLoader: true,
      );
      if (isEconomyApiSuccess(response)) {
        await loadWallet();
        return true;
      }
      packageError.value = response?['message']?.toString() ?? 'Payment failed.';
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
