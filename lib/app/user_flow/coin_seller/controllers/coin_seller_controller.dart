import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';

class CoinSellerController extends GetxController {
  // Stats
  final availableCoins = 540000.obs;
  final todaySalesPkr = 14200.obs;
  final totalSalesPkr = 286500.obs;

  // Transfer Form
  final userIdController = TextEditingController();
  final coinsController = TextEditingController();

  // Buyer Requests List
  final buyerRequests = <Map<String, dynamic>>[].obs;

  // Sales Ledger
  final salesLedger = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadMockRequests();
    loadMockLedger();
  }

  void loadMockRequests() {
    buyerRequests.assignAll([
      {
        'id': 'REQ_001',
        'userId': 'user_8829',
        'userName': 'Zayn Malik',
        'coins': 1000,
        'pricePkr': 1200,
        'status': 'PENDING',
        'time': '10 mins ago',
      },
      {
        'id': 'REQ_002',
        'userId': 'user_4512',
        'userName': 'Kiran Khan',
        'coins': 5000,
        'pricePkr': 5800,
        'status': 'PENDING',
        'time': '34 mins ago',
      },
      {
        'id': 'REQ_003',
        'userId': 'user_0991',
        'userName': 'Farhan Shah',
        'coins': 10000,
        'pricePkr': 11500,
        'status': 'PENDING',
        'time': '2 hours ago',
      },
    ]);
  }

  void loadMockLedger() {
    salesLedger.assignAll([
      {
        'buyerId': 'user_7721',
        'buyerName': 'Raza Ali',
        'coins': 2000,
        'pricePkr': 2400,
        'date': 'Today, 12:40 PM',
        'status': 'COMPLETED',
      },
      {
        'buyerId': 'user_3049',
        'buyerName': 'Ayesha Bibi',
        'coins': 50000,
        'pricePkr': 55000,
        'date': 'Yesterday, 04:15 PM',
        'status': 'COMPLETED',
      },
      {
        'buyerId': 'user_5411',
        'buyerName': 'Hamza Sheikh',
        'coins': 500,
        'pricePkr': 600,
        'date': '18 May, 09:30 AM',
        'status': 'COMPLETED',
      },
    ]);
  }

  // Transfer manually
  void transferCoins() {
    final buyerId = userIdController.text.trim();
    final coinsStr = coinsController.text.trim();

    if (buyerId.isEmpty || coinsStr.isEmpty) {
      Get.snackbar(
        'Form Error',
        'Please enter a valid Buyer ID and Coins amount.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: kColorWhite,
      );
      return;
    }

    final int? coinsToTransfer = int.tryParse(coinsStr);
    if (coinsToTransfer == null || coinsToTransfer <= 0) {
      Get.snackbar(
        'Invalid Amount',
        'Please enter a positive numeric coin amount.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: kColorWhite,
      );
      return;
    }

    if (availableCoins.value < coinsToTransfer) {
      Get.snackbar(
        'Insufficient Coins',
        'You only have ${availableCoins.value} coins remaining to sell.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: kColorWhite,
      );
      return;
    }

    // Deduct & Transfer
    availableCoins.value -= coinsToTransfer;
    final int estimatedPkr = (coinsToTransfer * 1.15).round(); // 1.15 PKR rate
    todaySalesPkr.value += estimatedPkr;
    totalSalesPkr.value += estimatedPkr;

    // Add to ledger
    salesLedger.insert(0, {
      'buyerId': buyerId,
      'buyerName': 'Manual Transfer',
      'coins': coinsToTransfer,
      'pricePkr': estimatedPkr,
      'date': 'Just Now',
      'status': 'COMPLETED',
    });

    userIdController.clear();
    coinsController.clear();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF1E1E2D),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Transfer Successful',
                style: TextStyle(color: kColorWhite, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              Text(
                'Sent $coinsToTransfer Coins to $buyerId successfully.',
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  // Approve buyer request
  void approveRequest(Map<String, dynamic> request) {
    final int coinsToTransfer = request['coins'];
    final String reqId = request['id'];

    if (availableCoins.value < coinsToTransfer) {
      Get.snackbar(
        'Insufficient Coins',
        'You only have ${availableCoins.value} coins remaining to approve this request.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: kColorWhite,
      );
      return;
    }

    // Deduct & update stats
    availableCoins.value -= coinsToTransfer;
    todaySalesPkr.value += (request['pricePkr'] as int);
    totalSalesPkr.value += (request['pricePkr'] as int);

    // Remove from request list
    buyerRequests.removeWhere((r) => r['id'] == reqId);

    // Add to ledger
    salesLedger.insert(0, {
      'buyerId': request['userId'],
      'buyerName': request['userName'],
      'coins': coinsToTransfer,
      'pricePkr': request['pricePkr'],
      'date': 'Just Now',
      'status': 'COMPLETED',
    });

    Get.snackbar(
      'Request Approved',
      'Successfully approved request. Sent $coinsToTransfer Coins to ${request['userName']}.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: kColorWhite,
    );
  }

  // Reject buyer request
  void rejectRequest(String reqId) {
    buyerRequests.removeWhere((r) => r['id'] == reqId);
    Get.snackbar(
      'Request Rejected',
      'Buyer request was declined.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: kColorWhite,
    );
  }

  @override
  void onClose() {
    userIdController.dispose();
    coinsController.dispose();
    super.onClose();
  }
}
