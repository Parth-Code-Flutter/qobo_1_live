import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/coin_seller_dev_config.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/models/seller_dashboard_data.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/models/seller_metrics.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/models/seller_portal_parsers.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/models/seller_sale.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/models/seller_transactions_page.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/widgets/coin_seller_transaction_detail_sheet.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/widgets/seller_sell_success_dialog.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/local_storage_constants.dart';
import 'package:qobo_one_live/repo/coin_seller/coin_seller_repo.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/local_storage/controllers/local_storage_controller.dart';

enum CoinSellerScreenState { checking, apply, pending, approved }

enum CoinSellerTransactionFilter { all, completed, reversed }

class CoinSellerController extends GetxController {
  CoinSellerController({CoinSellerRepo? repo})
      : _repo = repo ?? CoinSellerRepo();

  final CoinSellerRepo _repo;
  final LocalStorage _storage = LocalStorage.shared;

  static const _pendingApplyKey = kStorageCoinsSellerApplyPending;

  final screenState = CoinSellerScreenState.checking.obs;
  final dashboardTabIndex = 0.obs;
  final transactionFilter = CoinSellerTransactionFilter.all.obs;

  final isBootstrapping = true.obs;
  final isApplying = false.obs;
  final isLoadingDashboard = false.obs;
  final isLoadingTransactions = false.obs;
  final isTransferring = false.obs;
  final isReversing = false.obs;
  final isUpdatingTransaction = false.obs;
  final reversingSaleId = ''.obs;

  final sellerLabel = ''.obs;
  final availableCoins = 0.obs;
  final totalRevenue = 0.0.obs;
  final totalCoinsSold = 0.obs;
  final totalTransactions = 0.obs;
  final salesLedger = <SellerSale>[].obs;

  final transactionsPage = 1.obs;
  final hasMoreTransactions = false.obs;
  final transactionsApiAvailable = true.obs;

  final detailsController = TextEditingController();
  final userIdController = TextEditingController();
  final coinsController = TextEditingController();
  final priceController = TextEditingController();

  List<SellerSale> get filteredSales {
    final filter = transactionFilter.value;
    if (filter == CoinSellerTransactionFilter.all) return salesLedger;
    if (filter == CoinSellerTransactionFilter.completed) {
      return salesLedger.where((s) => !s.isReversed).toList();
    }
    return salesLedger.where((s) => s.isReversed).toList();
  }

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    isBootstrapping.value = true;
    screenState.value = CoinSellerScreenState.checking;
    await _storage.clearSellerSession();
    _hydrateSellerLabel();
    await loadDashboard(isShowLoader: false);
    isBootstrapping.value = false;
  }

  void _hydrateSellerLabel() {
    if (!Get.isRegistered<UserSessionController>()) {
      sellerLabel.value = '';
      return;
    }
    final session = Get.find<UserSessionController>();
    final name = session.displayName.trim();
    final email = session.email.trim();
    sellerLabel.value = name.isNotEmpty
        ? name
        : (email.isNotEmpty ? email : session.userId);
  }

  Future<bool> _wasApplyMarkedPending() async {
    try {
      final raw = await _storage.getStringFromStorage(_pendingApplyKey);
      return raw == '1' || raw == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<void> _markApplyPending(bool pending) async {
    try {
      await _storage.writeStringStorage(_pendingApplyKey, pending ? '1' : '0');
    } catch (_) {}
  }

  Future<void> applyToBecomeSeller() async {
    if (isApplying.value) return;
    final details = detailsController.text.trim();
    if (details.isEmpty) {
      _showError('Tell us briefly how you plan to sell coins.');
      return;
    }
    if (details.length < 10) {
      _showError('Please add a bit more detail (at least 10 characters).');
      return;
    }

    isApplying.value = true;
    final response = await _repo.apply(details: details);
    isApplying.value = false;

    if (isSellerPortalSuccess(response)) {
      await _markApplyPending(true);
      detailsController.clear();
      screenState.value = CoinSellerScreenState.pending;
      _showSuccess(
        sellerPortalMessage(
          response,
          'Application submitted. We will notify you after review.',
        ),
      );
      return;
    }
    _showError(
      sellerPortalMessage(response, 'Unable to submit seller application.'),
    );
  }

  Future<void> loadDashboard({bool isShowLoader = true}) async {
    isLoadingDashboard.value = true;
    final response = await _repo.getDashboard(isShowLoader: isShowLoader);
    isLoadingDashboard.value = false;

    if (isSellerPortalUnauthorized(response)) {
      screenState.value = CoinSellerScreenState.apply;
      _showError('Please sign in again to manage coin seller.');
      return;
    }

    if (isSellerPortalForbidden(response)) {
      final pending = await _wasApplyMarkedPending();
      screenState.value = pending
          ? CoinSellerScreenState.pending
          : CoinSellerScreenState.apply;
      return;
    }

    final dashboard = SellerDashboardData.tryParseEnvelope(response);
    if (dashboard == null) {
      if (CoinSellerDevConfig.bypassAuthForFlowTest) {
        _applyDashboard(_placeholderDashboard());
        screenState.value = CoinSellerScreenState.approved;
        return;
      }
      final pending = await _wasApplyMarkedPending();
      screenState.value = pending
          ? CoinSellerScreenState.pending
          : CoinSellerScreenState.apply;
      if (response != null) {
        _showError(
          sellerPortalMessage(response, 'Unable to load seller dashboard.'),
        );
      }
      return;
    }

    await _markApplyPending(false);
    _applyDashboard(dashboard);
    screenState.value = CoinSellerScreenState.approved;
    await loadTransactions(refresh: true, isShowLoader: false);
  }

  Future<void> loadTransactions({
    bool refresh = false,
    bool isShowLoader = false,
  }) async {
    if (screenState.value != CoinSellerScreenState.approved) return;
    if (isLoadingTransactions.value) return;

    if (refresh) {
      transactionsPage.value = 1;
      hasMoreTransactions.value = false;
    }

    isLoadingTransactions.value = true;
    final statusFilter = switch (transactionFilter.value) {
      CoinSellerTransactionFilter.completed => 'completed',
      CoinSellerTransactionFilter.reversed => 'reversed',
      CoinSellerTransactionFilter.all => null,
    };

    final response = await _repo.getTransactions(
      page: transactionsPage.value,
      limit: 25,
      status: statusFilter,
      isShowLoader: isShowLoader,
    );
    isLoadingTransactions.value = false;

    if (response != null && response['statusCode'] == 404) {
      transactionsApiAvailable.value = false;
      return;
    }

    final page = SellerTransactionsPage.tryParseEnvelope(response);
    if (page != null) {
      transactionsApiAvailable.value = true;
      hasMoreTransactions.value = page.hasMore;
      if (refresh || transactionsPage.value <= 1) {
        salesLedger.assignAll(page.items);
      } else {
        final existing = salesLedger.map((e) => e.id).toSet();
        salesLedger.addAll(
          page.items.where((item) => !existing.contains(item.id)),
        );
      }
      return;
    }

    transactionsApiAvailable.value = false;
  }

  Future<void> loadMoreTransactions() async {
    if (!hasMoreTransactions.value || isLoadingTransactions.value) return;
    transactionsPage.value += 1;
    await loadTransactions(isShowLoader: false);
  }

  void setTransactionFilter(CoinSellerTransactionFilter filter) {
    if (transactionFilter.value == filter) return;
    transactionFilter.value = filter;
    if (transactionsApiAvailable.value) {
      unawaited(loadTransactions(refresh: true));
    }
  }

  Future<void> openTransactionDetail(SellerSale sale) async {
    SellerSale resolved = sale;
    if (sale.id.trim().isNotEmpty) {
      final response = await _repo.getTransaction(transactionId: sale.id);
      if (response != null && response['statusCode'] != 404) {
        final fresh = SellerSale.tryParseEnvelope(response);
        if (fresh != null) resolved = fresh;
      }
    }
    await CoinSellerTransactionDetailSheet.show(
      sale: resolved,
      controller: this,
    );
  }

  Future<void> openEditTransaction(SellerSale sale) async {
    if (!sale.canEdit) return;
    final priceCtrl = TextEditingController(text: sale.price.toString());
    final noteCtrl = TextEditingController(text: sale.note ?? '');

    final confirmed = await Get.dialog<bool>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: const Color(0xFF1E1E2D),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Edit transaction',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kColorWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: priceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: kColorWhite),
                decoration: _inputDecoration('Price (INR)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteCtrl,
                maxLines: 2,
                style: const TextStyle(color: kColorWhite),
                decoration: _inputDecoration('Note (optional)'),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(result: false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(result: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kColorPrimary,
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) {
      priceCtrl.dispose();
      noteCtrl.dispose();
      return;
    }

    final newPrice = num.tryParse(priceCtrl.text.trim());
    final note = noteCtrl.text.trim();
    priceCtrl.dispose();
    noteCtrl.dispose();

    if (newPrice == null || newPrice < 0) {
      _showError('Enter a valid price.');
      return;
    }

    isUpdatingTransaction.value = true;
    var response = await _repo.updateTransaction(
      transactionId: sale.id,
      price: newPrice,
      note: note.isEmpty ? null : note,
    );

    // Some backends expose reverse via DELETE instead of PATCH for metadata.
    if (response != null && response['statusCode'] == 404) {
      response = null;
    }
    isUpdatingTransaction.value = false;

    if (response == null || !isSellerPortalSuccess(response)) {
      _showError(
        sellerPortalMessage(response, 'Unable to update this transaction.'),
      );
      return;
    }

    final updated = SellerSale.tryParseEnvelope(response);
    final index = salesLedger.indexWhere((item) => item.id == sale.id);
    if (index >= 0) {
      salesLedger[index] = (updated ?? sale).copyWith(
        price: newPrice,
        note: note.isEmpty ? sale.note : note,
      );
      salesLedger.refresh();
    }
    _showSuccess('Transaction updated.');
    await loadDashboard(isShowLoader: false);
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
      filled: true,
      fillColor: Colors.white10,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white12),
      ),
    );
  }

  Future<void> transferCoins() async {
    if (isTransferring.value) return;
    if (screenState.value != CoinSellerScreenState.approved) return;

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

    if (isSellerPortalForbidden(response)) {
      screenState.value = CoinSellerScreenState.apply;
      _showError('Seller access was revoked. Please re-apply if needed.');
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

    await loadDashboard(isShowLoader: false);
    dashboardTabIndex.value = 1;

    await SellerSellSuccessDialog.show(
      amount: coinsToTransfer,
      recipient: buyerId,
      price: price,
      currency: sale?.currency ?? 'INR',
    );
  }

  Future<void> reverseSale(SellerSale sale) async {
    if (isReversing.value || !sale.canReverse) return;

    final confirmed = await Get.dialog<bool>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF1E1E2D),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Reverse this sale?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kColorWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Reverse ${sale.amount} coins sold to ${sale.displayName}?\n\n'
                'This fails if the buyer already spent those coins.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(result: false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                      onPressed: () => Get.back(result: true),
                      child: const Text('Reverse'),
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
    if (confirmed != true) return;

    isReversing.value = true;
    reversingSaleId.value = sale.id;

    var response = await _repo.reverseTransaction(transactionId: sale.id);
    if (response != null && !isSellerPortalSuccess(response)) {
      response = await _repo.deleteTransaction(transactionId: sale.id);
    }

    isReversing.value = false;
    reversingSaleId.value = '';

    if (!isSellerPortalSuccess(response)) {
      _showError(
        sellerPortalMessage(
          response,
          'Unable to reverse this sale. The buyer may have spent the coins.',
        ),
      );
      return;
    }

    final index = salesLedger.indexWhere((item) => item.id == sale.id);
    if (index >= 0) {
      salesLedger[index] = sale.copyWith(status: 'reversed');
      salesLedger.refresh();
    }
    await loadDashboard(isShowLoader: false);
    _showSuccess('Sale reversed successfully.');
  }

  SellerDashboardData _placeholderDashboard() {
    return SellerDashboardData(
      coinsBalance: availableCoins.value > 0 ? availableCoins.value : 15000,
      metrics: const SellerMetrics(
        totalRevenue: 2500,
        totalCoinsSold: 10000,
        totalTransactions: 45,
      ),
      recentSales: const [],
    );
  }

  void _applyDashboard(SellerDashboardData dashboard) {
    availableCoins.value = dashboard.coinsBalance;
    totalRevenue.value = dashboard.metrics.totalRevenue.toDouble();
    totalCoinsSold.value = dashboard.metrics.totalCoinsSold;
    totalTransactions.value = dashboard.metrics.totalTransactions;
    if (!transactionsApiAvailable.value || salesLedger.isEmpty) {
      salesLedger.assignAll(dashboard.recentSales);
    }
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
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kColorPrimary,
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

  void _showSuccess(String message) {
    Get.snackbar(
      'Coin Seller',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withValues(alpha: 0.92),
      colorText: kColorWhite,
    );
  }

  @override
  void onClose() {
    detailsController.dispose();
    userIdController.dispose();
    coinsController.dispose();
    priceController.dispose();
    super.onClose();
  }
}
