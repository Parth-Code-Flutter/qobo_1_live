import 'dart:math';

import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

/// Economy repository contains API calls for wallet, recharge, and gifts.
class EconomyRepo {
  EconomyRepo({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  /// Calls `GET /api/economy/wallet` to retrieve current user wallet balances.
  Future<Map<String, dynamic>?> getWalletBalances({
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: EconomyEndpoints.wallet,
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/economy/recharge` to purchase virtual currency.
  ///
  /// Preferred body after Razorpay Checkout success:
  /// `{ packageId, amount, method, paymentId, orderId, signature }`.
  Future<Map<String, dynamic>?> rechargeCurrency({
    required int amount,
    required String method, // e.g. 'razorpay'
    String? packageId,
    String? paymentId,
    String? orderId,
    String? signature,
    num? paidAmount,
    String? currency,
    bool isShowLoader = true,
  }) async {
    final body = <String, dynamic>{
      'amount': amount,
      'method': method,
      if (packageId != null && packageId.isNotEmpty) 'packageId': packageId,
      if (packageId != null && packageId.isNotEmpty) 'package_id': packageId,
      if (paymentId != null && paymentId.isNotEmpty) 'paymentId': paymentId,
      if (paymentId != null && paymentId.isNotEmpty) 'payment_id': paymentId,
      if (orderId != null && orderId.isNotEmpty) 'orderId': orderId,
      if (orderId != null && orderId.isNotEmpty) 'order_id': orderId,
      if (signature != null && signature.isNotEmpty) 'signature': signature,
      if (paidAmount != null) 'paidAmount': paidAmount,
      if (paidAmount != null) 'paid_amount': paidAmount,
      if (currency != null && currency.isNotEmpty) 'currency': currency,
    };

    final response = await _apiService.postRequest(
      endPoint: EconomyEndpoints.recharge,
      requestModel: body,
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `GET /api/economy/package-list` to fetch active coin packages.
  Future<Map<String, dynamic>?> getCoinPackages({
    bool isShowLoader = true,
  }) async {
    var response = await _apiService.getRequest(
      endPoint: EconomyEndpoints.packageList,
      isShowLoader: isShowLoader,
    );

    if (response?.statusCode == 404) {
      response = await _apiService.getRequest(
        endPoint: EconomyEndpoints.packageListLegacy,
        isShowLoader: isShowLoader,
      );
    }

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `GET /api/economy/history` to fetch the transaction history log.
  Future<Map<String, dynamic>?> getTransactionHistory({
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: EconomyEndpoints.history,
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `GET /api/economy/gift-list` to fetch the available room gifts list.
  Future<Map<String, dynamic>?> getGiftList({bool isShowLoader = true}) async {
    final response = await _apiService.getRequest(
      endPoint: EconomyEndpoints.giftList,
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/economy/send-gift` to send a gift in a room.
  Future<Map<String, dynamic>?> sendGift({
    String? receiverId,
    required String giftId,
    required String roomId,
    int quantity = 1,
    String scope = 'user',
    String? clientGiftId,
    bool isShowLoader = true,
  }) async {
    final normalizedScope = scope.trim().isEmpty
        ? 'user'
        : scope.trim().toLowerCase();
    final normalizedReceiverId = receiverId?.trim() ?? '';
    final resolvedClientGiftId = clientGiftId?.trim().isNotEmpty == true
        ? clientGiftId!.trim()
        : _newClientGiftId();
    final body = <String, dynamic>{
      'roomId': roomId,
      'giftId': giftId,
      if (normalizedReceiverId.isNotEmpty) 'receiverId': normalizedReceiverId,
      'quantity': quantity,
      'scope': normalizedScope,
      'clientGiftId': resolvedClientGiftId,
    };

    var response = await _apiService.postRequest(
      endPoint: EconomyEndpoints.sendGift,
      requestModel: body,
      isShowLoader: isShowLoader,
    );

    if (response?.statusCode == 404) {
      response = await _apiService.postRequest(
        endPoint: EconomyEndpoints.sendGiftTransactionsLegacy,
        requestModel: body,
        isShowLoader: isShowLoader,
      );
    }

    if (response?.statusCode == 404) {
      response = await _apiService.postRequest(
        endPoint: EconomyEndpoints.sendGiftLegacy,
        requestModel: <String, dynamic>{
          if (normalizedReceiverId.isNotEmpty)
            'receiver_id': normalizedReceiverId,
          'gift_id': giftId,
          'room_id': roomId,
          'quantity': quantity,
          'scope': normalizedScope,
          'client_gift_id': resolvedClientGiftId,
        },
        isShowLoader: isShowLoader,
      );
    }

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  String _newClientGiftId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final randomPart = Random().nextInt(1 << 32).toRadixString(16);
    return 'gift_${timestamp}_$randomPart';
  }

  /// Calls `GET /api/withdraw/config` for withdrawal tiers and eligibility.
  Future<Map<String, dynamic>?> getWithdrawConfig({
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: EconomyEndpoints.withdrawConfig,
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `GET /api/withdraw/history` for past withdrawal requests.
  Future<Map<String, dynamic>?> getWithdrawHistory({
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: EconomyEndpoints.withdrawHistory,
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/withdraw/request` to submit a withdrawal request.
  Future<Map<String, dynamic>?> requestWithdrawal({
    required int amount,
    String? accountNumber,
    String? ifscCode,
    String? upiId,
    bool isShowLoader = true,
  }) async {
    final bankDetails = <String, dynamic>{
      if ((accountNumber ?? '').trim().isNotEmpty)
        'account_number': accountNumber!.trim(),
      if ((ifscCode ?? '').trim().isNotEmpty) 'ifsc_code': ifscCode!.trim(),
      if ((upiId ?? '').trim().isNotEmpty) 'upi_id': upiId!.trim(),
    };

    final requestModel = <String, dynamic>{
      'amount': amount,
      'bank_details': bankDetails,
    };

    var response = await _apiService.postRequest(
      endPoint: EconomyEndpoints.withdrawRequest,
      requestModel: requestModel,
      isShowLoader: isShowLoader,
    );

    if (response?.statusCode == 404) {
      response = await _apiService.postRequest(
        endPoint: EconomyEndpoints.withdraw,
        requestModel: requestModel,
        isShowLoader: isShowLoader,
      );
    }

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `GET /api/economy/vip-packages`.
  Future<Map<String, dynamic>?> getVipPackages({
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: EconomyEndpoints.vipPackages,
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/economy/buy-vip`.
  Future<Map<String, dynamic>?> buyVip({
    required String packageId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: EconomyEndpoints.buyVip,
      requestModel: <String, dynamic>{
        'id': packageId,
        'packageId': packageId,
        'package_id': packageId,
      },
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `GET /api/economy/mall`.
  Future<Map<String, dynamic>?> getMallItems({bool isShowLoader = true}) async {
    final response = await _apiService.getRequest(
      endPoint: EconomyEndpoints.mallList,
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/economy/mall/buy`.
  Future<Map<String, dynamic>?> buyMallItem({
    required String itemId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: EconomyEndpoints.mallBuy,
      requestModel: <String, dynamic>{
        'id': itemId,
        'itemId': itemId,
        'item_id': itemId,
      },
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `GET /api/economy/aristocracy/packages`.
  Future<Map<String, dynamic>?> getAristocracyPackages({
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: EconomyEndpoints.aristocracyPackages,
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/economy/aristocracy/buy`.
  Future<Map<String, dynamic>?> buyAristocracy({
    required String packageId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: EconomyEndpoints.buyAristocracy,
      requestModel: <String, dynamic>{
        'id': packageId,
        'packageId': packageId,
        'package_id': packageId,
      },
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/economy/seller/transfer`.
  Future<Map<String, dynamic>?> sellerTransfer({
    required String receiverPhone,
    required int amount,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: EconomyEndpoints.sellerTransfer,
      requestModel: <String, dynamic>{
        'receiverPhone': receiverPhone,
        'amount': amount,
      },
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `GET /api/economy/seller/dashboard`.
  Future<Map<String, dynamic>?> getSellerDashboard({
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: EconomyEndpoints.sellerDashboard,
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }
}
