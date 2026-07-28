import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/coin_seller_dev_config.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/models/seller_admin.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/models/seller_dashboard_data.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/models/seller_login_data.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/models/seller_metrics.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/models/seller_portal_parsers.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/models/seller_sale.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/models/seller_sale_user.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/widgets/seller_sell_success_dialog.dart';
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
  final obscurePassword = true.obs;

  final sellerEmail = ''.obs;
  final availableCoins = 0.obs;
  final totalRevenue = 0.0.obs;
  final totalCoinsSold = 0.obs;
  final totalTransactions = 0.obs;
  final salesLedger = <SellerSale>[].obs;

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

    final adminMap = await _storage.getSellerAdmin();
    if (adminMap != null) {
      final admin = SellerAdmin.fromJson(adminMap);
      sellerEmail.value = admin.email;
      availableCoins.value = admin.coinsBalance;
    }

    isAuthenticated.value = true;
    isBootstrapping.value = false;
    await loadDashboard(isShowLoader: false);
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
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

    final loginData =
        response != null ? SellerLoginData.tryParseEnvelope(response) : null;
    if (loginData != null) {
      if (!loginData.admin.isSellerAdmin &&
          loginData.admin.role.trim().isNotEmpty) {
        if (CoinSellerDevConfig.bypassAuthForFlowTest) {
          await _enterFlowTestDashboard(email: email);
          return;
        }
        _showError('This account is not a coin seller.');
        return;
      }

      await _storage.saveSellerSession(
        token: loginData.token,
        admin: loginData.admin.toJson(),
      );
      sellerEmail.value =
          loginData.admin.email.isNotEmpty ? loginData.admin.email : email;
      availableCoins.value = loginData.admin.coinsBalance;
      passwordController.clear();
      isAuthenticated.value = true;
      await loadDashboard();
      return;
    }

    if (CoinSellerDevConfig.bypassAuthForFlowTest) {
      await _enterFlowTestDashboard(email: email);
      return;
    }

    if (response == null) {
      _showError('Unable to login as coin seller.');
      return;
    }
    _showError(
      sellerPortalMessage(response, 'Unable to login as coin seller.'),
    );
  }

  Future<void> _enterFlowTestDashboard({required String email}) async {
    const admin = SellerAdmin(
      id: 'dev-seller',
      email: 'seller@test.com',
      role: 'seller_admin',
      coinsBalance: 15000,
    );
    await _storage.saveSellerSession(
      token: 'dev-flow-test-token',
      admin: SellerAdmin(
        id: admin.id,
        email: email.isNotEmpty ? email : admin.email,
        role: admin.role,
        coinsBalance: admin.coinsBalance,
      ).toJson(),
    );
    sellerEmail.value = email.isNotEmpty ? email : admin.email;
    availableCoins.value = admin.coinsBalance;
    passwordController.clear();
    isAuthenticated.value = true;
    await loadDashboard(isShowLoader: false);
  }

  /// Clears seller JWT only — does not touch the end-user session.
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

    if (isSellerPortalUnauthorized(response)) {
      if (CoinSellerDevConfig.bypassAuthForFlowTest) {
        _applyDashboard(_placeholderDashboard());
        return;
      }
      await logoutSeller();
      _showError('Seller session expired. Please login again.');
      return;
    }

    final dashboard = SellerDashboardData.tryParseEnvelope(response);
    if (dashboard == null) {
      if (CoinSellerDevConfig.bypassAuthForFlowTest) {
        _applyDashboard(_placeholderDashboard());
        return;
      }
      _showError(
        sellerPortalMessage(response, 'Unable to load seller dashboard.'),
      );
      return;
    }

    _applyDashboard(dashboard);
  }

  SellerDashboardData _placeholderDashboard() {
    return SellerDashboardData(
      coinsBalance: availableCoins.value > 0 ? availableCoins.value : 15000,
      metrics: const SellerMetrics(
        totalRevenue: 2500,
        totalCoinsSold: 10000,
        totalTransactions: 45,
      ),
      recentSales: [
        SellerSale(
          id: 'dev-sale-1',
          userId: 'user-demo-1',
          amount: 500,
          price: 100,
          currency: 'INR',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          user: const SellerSaleUser(
            id: 'user-demo-1',
            name: 'John Doe',
            email: 'john@example.com',
          ),
        ),
      ],
    );
  }

  void _applyDashboard(SellerDashboardData dashboard) {
    availableCoins.value = dashboard.coinsBalance;
    totalRevenue.value = dashboard.metrics.totalRevenue.toDouble();
    totalCoinsSold.value = dashboard.metrics.totalCoinsSold;
    totalTransactions.value = dashboard.metrics.totalTransactions;
    salesLedger.assignAll(dashboard.recentSales);
  }

  /// Validates form, confirms with the user, then calls sell API.
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

    final confirmed = await _confirmTransfer(
      buyerId: buyerId,
      amount: coinsToTransfer,
      price: price,
    );
    if (confirmed != true) return;

    isTransferring.value = true;
    final response = await _repo.sellCoins(
      userId: buyerId,
      amount: coinsToTransfer,
      price: price,
    );
    isTransferring.value = false;

    if (isSellerPortalUnauthorized(response)) {
      await logoutSeller();
      _showError('Seller session expired. Please login again.');
      return;
    }

    final sale = SellerSale.tryParseEnvelope(response);
    if (sale == null && !isSellerPortalSuccess(response)) {
      _showError(sellerPortalMessage(response, 'Unable to transfer coins.'));
      return;
    }

    userIdController.clear();
    coinsController.clear();
    priceController.clear();

    // Optimistic update; dashboard refresh is source of truth.
    if (sale != null) {
      salesLedger.insert(0, sale);
    }
    availableCoins.value =
        (availableCoins.value - coinsToTransfer).clamp(0, 1 << 30);
    totalCoinsSold.value += coinsToTransfer;
    totalTransactions.value += 1;
    totalRevenue.value += (sale?.price ?? price).toDouble();

    await loadDashboard(isShowLoader: false);

    await SellerSellSuccessDialog.show(
      amount: coinsToTransfer,
      recipient: buyerId,
      price: price,
      currency: sale?.currency ?? 'INR',
    );
  }

  Future<bool?> _confirmTransfer({
    required String buyerId,
    required int amount,
    required num price,
  }) {
    return Get.dialog<bool>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF1E1E2D),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Confirm transfer',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kColorWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Send $amount coins to\n$buyerId\nfor INR $price?\n\n'
                'Confirm only after you have received payment.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(result: false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kColorPrimary,
                        foregroundColor: kColorWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Get.back(result: true),
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
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
