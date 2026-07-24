import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/repo/coin_seller/coin_seller_repo.dart';
import 'package:qobo_one_live/utils/local_storage/controllers/local_storage_controller.dart';

class CoinSellerController extends GetxController {
  CoinSellerController({CoinSellerRepo? repo})
    : _repo = repo ?? CoinSellerRepo();

  final CoinSellerRepo _repo;
  final LocalStorage _storage = LocalStorage.shared;

  final isBootstrapping = true.obs;
  final isAuthenticated = false.obs;
  final isLoggingIn = false.obs;
  final isLoadingDashboard = false.obs;
  final isTransferring = false.obs;

  final sellerEmail = ''.obs;
  final availableCoins = 0.obs;
  final totalRevenue = 0.obs;
  final totalCoinsSold = 0.obs;
  final totalTransactions = 0.obs;
  final salesLedger = <Map<String, dynamic>>[].obs;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final userIdController = TextEditingController();
  final coinsController = TextEditingController();
  final priceController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    isBootstrapping.value = true;
    final token = await _storage.getSellerToken();
    if (token.trim().isEmpty) {
      isAuthenticated.value = false;
      isBootstrapping.value = false;
      return;
    }

    final admin = await _storage.getSellerAdmin();
    if (admin != null) {
      sellerEmail.value = admin['email']?.toString() ?? '';
      availableCoins.value =
          int.tryParse(admin['coinsBalance']?.toString() ?? '') ?? 0;
    }

    isAuthenticated.value = true;
    isBootstrapping.value = false;
    await loadDashboard(isShowLoader: false);
  }

  Future<void> login() async {
    if (isLoggingIn.value) return;
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showError('Enter seller email and password.');
      return;
    }

    isLoggingIn.value = true;
    final response = await _repo.login(email: email, password: password);
    isLoggingIn.value = false;

    if (!_isSuccess(response)) {
      _showError(_message(response, 'Unable to login as coin seller.'));
      return;
    }

    final data = _asMap(response?['data']);
    final token = data['token']?.toString().trim() ?? '';
    final admin = _asMap(data['admin']);
    final role = admin['role']?.toString().toLowerCase() ?? '';

    if (token.isEmpty) {
      _showError('Login succeeded but no token was returned.');
      return;
    }
    if (role.isNotEmpty && role != 'seller_admin') {
      _showError('This account is not a coin seller.');
      return;
    }

    await _storage.saveSellerSession(token: token, admin: admin);
    sellerEmail.value = admin['email']?.toString() ?? email;
    availableCoins.value =
        int.tryParse(admin['coinsBalance']?.toString() ?? '') ?? 0;
    passwordController.clear();
    isAuthenticated.value = true;
    await loadDashboard();
  }

  Future<void> logoutSeller() async {
    await _storage.clearSellerSession();
    isAuthenticated.value = false;
    availableCoins.value = 0;
    totalRevenue.value = 0;
    totalCoinsSold.value = 0;
    totalTransactions.value = 0;
    salesLedger.clear();
    sellerEmail.value = '';
  }

  Future<void> loadDashboard({bool isShowLoader = true}) async {
    if (!isAuthenticated.value) return;

    isLoadingDashboard.value = true;
    final response = await _repo.getDashboard(isShowLoader: isShowLoader);
    isLoadingDashboard.value = false;

    if (_isUnauthorized(response)) {
      await logoutSeller();
      _showError('Seller session expired. Please login again.');
      return;
    }

    if (!_isSuccess(response)) {
      _showError(_message(response, 'Unable to load seller dashboard.'));
      return;
    }

    final data = _asMap(response?['data']);
    availableCoins.value =
        int.tryParse(data['coinsBalance']?.toString() ?? '') ??
        availableCoins.value;

    final metrics = _asMap(data['metrics']);
    totalRevenue.value =
        _toInt(metrics['totalRevenue']) ?? totalRevenue.value;
    totalCoinsSold.value =
        _toInt(metrics['totalCoinsSold']) ?? totalCoinsSold.value;
    totalTransactions.value =
        _toInt(metrics['totalTransactions']) ?? totalTransactions.value;

    final recent = data['recentSales'];
    if (recent is List) {
      salesLedger.assignAll(
        recent
            .whereType<Map>()
            .map((item) => _normalizeSale(Map<String, dynamic>.from(item)))
            .toList(),
      );
    } else {
      salesLedger.clear();
    }
  }

  Future<void> transferCoins() async {
    if (isTransferring.value) return;
    final buyerId = userIdController.text.trim();
    final coinsStr = coinsController.text.trim();
    final priceStr = priceController.text.trim();

    if (buyerId.isEmpty || coinsStr.isEmpty || priceStr.isEmpty) {
      _showError('Enter user (id / email / phone), coins, and price.');
      return;
    }

    final coinsToTransfer = int.tryParse(coinsStr);
    if (coinsToTransfer == null || coinsToTransfer <= 0) {
      _showError('Enter a positive coin amount.');
      return;
    }

    final price = num.tryParse(priceStr);
    if (price == null || price < 0) {
      _showError('Enter a valid price.');
      return;
    }

    if (availableCoins.value < coinsToTransfer) {
      _showError(
        'You only have ${availableCoins.value} coins remaining to sell.',
      );
      return;
    }

    isTransferring.value = true;
    final response = await _repo.sellCoins(
      userId: buyerId,
      amount: coinsToTransfer,
      price: price,
    );
    isTransferring.value = false;

    if (_isUnauthorized(response)) {
      await logoutSeller();
      _showError('Seller session expired. Please login again.');
      return;
    }

    if (!_isSuccess(response)) {
      _showError(_message(response, 'Unable to transfer coins.'));
      return;
    }

    userIdController.clear();
    coinsController.clear();
    priceController.clear();

    final sale = _normalizeSale(_asMap(response?['data']));
    salesLedger.insert(0, sale);
    availableCoins.value = (availableCoins.value - coinsToTransfer)
        .clamp(0, 1 << 30);
    totalCoinsSold.value += coinsToTransfer;
    totalTransactions.value += 1;
    totalRevenue.value += _toInt(sale['price']) ?? price.round();

    await loadDashboard(isShowLoader: false);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF1E1E2D),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Transfer Successful',
                style: TextStyle(
                  color: kColorWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sent $coinsToTransfer coins to $buyerId.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kColorPrimary,
                    foregroundColor: kColorWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Get.back(),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _normalizeSale(Map<String, dynamic> raw) {
    final user = _asMap(raw['user']);
    final amount = _toInt(raw['amount']) ?? 0;
    final price = _toInt(raw['price']) ?? 0;
    final currency = raw['currency']?.toString().trim().isNotEmpty == true
        ? raw['currency'].toString()
        : 'INR';
    final buyerName = user['name']?.toString().trim().isNotEmpty == true
        ? user['name'].toString()
        : (raw['userId']?.toString() ?? 'User');
    final buyerId =
        user['id']?.toString() ??
        raw['userId']?.toString() ??
        '';
    return <String, dynamic>{
      ...raw,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerEmail': user['email']?.toString() ?? '',
      'coins': amount,
      'price': price,
      'currency': currency,
      'date': _formatDate(raw['createdAt']?.toString()),
    };
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Just now';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final local = parsed.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  bool _isSuccess(Map<String, dynamic>? response) {
    if (response == null) return false;
    if (response['success'] == true) return true;
    final code = response['statusCode'];
    return code == 1 ||
        code == 200 ||
        code == 201 ||
        code?.toString() == '1' ||
        code?.toString() == '200' ||
        code?.toString() == '201';
  }

  bool _isUnauthorized(Map<String, dynamic>? response) {
    if (response == null) return false;
    final code = response['statusCode'];
    return code == 401 || code?.toString() == '401';
  }

  String _message(Map<String, dynamic>? response, String fallback) {
    final message = response?['message']?.toString().trim();
    return message == null || message.isEmpty ? fallback : message;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString());
  }

  void _showError(String message) {
    Get.snackbar(
      'Coin Seller',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent.withValues(alpha: 0.92),
      colorText: kColorWhite,
    );
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    userIdController.dispose();
    coinsController.dispose();
    priceController.dispose();
    super.onClose();
  }
}
