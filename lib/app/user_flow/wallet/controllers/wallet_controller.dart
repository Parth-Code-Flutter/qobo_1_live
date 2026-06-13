import 'package:get/get.dart';
import 'package:qobo_one_live/repo/economy/economy_repo.dart';

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
  }

  Future<void> loadWallet() async {
    final response = await _economyRepo.getWalletBalances(isShowLoader: false);
    final data = response?['data'];
    if (_isSuccess(response) && data is Map) {
      coinBalance.value = _formatAmount(
        data['coins'] ?? data['coin'] ?? data['balance'] ?? data['coinBalance'],
      );
      diamondBalance.value = _formatAmount(
        data['diamonds'] ?? data['diamond'] ?? data['diamondBalance'],
      );
      withdrawalLimit.value = _formatAmount(
        data['withdrawalLimit'] ??
            data['withdrawlimit'] ??
            data['withdraw_limit'],
      );
    }
  }

  Future<void> loadCoinPackages() async {
    isLoadingPackages.value = true;
    packageError.value = '';
    try {
      final response = await _economyRepo.getCoinPackages(isShowLoader: false);
      final data = response?['data'];
      if (_isSuccess(response) && data is List) {
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
      if (_isSuccess(response)) {
        await loadWallet();
        return true;
      }
      packageError.value = response?['message']?.toString() ?? 'Payment failed.';
      return false;
    } finally {
      isBuying.value = false;
    }
  }

  bool _isSuccess(Map<String, dynamic>? response) {
    if (response == null) return false;
    if (response['success'] == true) return true;
    final code = response['statusCode'];
    if (code is int) return code == 1 || code == 200 || code == 201;
    return code?.toString() == '1' ||
        code?.toString() == '200' ||
        code?.toString() == '201';
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
