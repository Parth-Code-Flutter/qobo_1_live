import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

/// Economy repository contains API calls for wallet, recharge, and gifts.
class EconomyRepo {
  EconomyRepo({ApiService? apiService}) : _apiService = apiService ?? ApiService();

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
  Future<Map<String, dynamic>?> rechargeCurrency({
    required int amount,
    required String method, // e.g. 'razorpay'
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: EconomyEndpoints.recharge,
      requestModel: <String, dynamic>{
        'amount': amount,
        'method': method,
      },
      isShowLoader: isShowLoader,
    );

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
  Future<Map<String, dynamic>?> getGiftList({
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: EconomyEndpoints.giftList,
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/economy/send-gift` to send a gift in a room.
  Future<Map<String, dynamic>?> sendGift({
    required String receiverId,
    required String giftId,
    required String roomId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: EconomyEndpoints.sendGift,
      requestModel: <String, dynamic>{
        'receiver_id': receiverId,
        'gift_id': giftId,
        'room_id': roomId,
      },
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }
}
