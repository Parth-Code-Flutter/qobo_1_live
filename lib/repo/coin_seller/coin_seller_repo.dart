import 'package:http/http.dart' as http;
import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

/// User P2P Coins Seller APIs (`/api/user/coins-seller/*`).
///
/// Uses the **standard user JWT** from [HeaderData] — no separate seller login.
class CoinSellerRepo {
  CoinSellerRepo({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  /// POST `/api/user/coins-seller/apply`
  Future<Map<String, dynamic>?> apply({
    required String details,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: UserCoinsSellerEndpoints.apply,
      requestModel: <String, dynamic>{
        'details': details.trim(),
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return _decode(response);
  }

  /// GET `/api/user/coins-seller/dashboard`
  Future<Map<String, dynamic>?> getDashboard({
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: UserCoinsSellerEndpoints.dashboard,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return _decode(response);
  }

  /// GET `/api/user/coins-seller/transactions`
  Future<Map<String, dynamic>?> getTransactions({
    int page = 1,
    int limit = 20,
    String? status,
    bool isShowLoader = false,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'limit': '$limit',
    };
    if (status != null && status.trim().isNotEmpty) {
      query['status'] = status.trim();
    }

    final response = await _apiService.getRequest(
      endPoint: UserCoinsSellerEndpoints.transactions,
      queryParams: query,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return _decode(response, allowNotFound: true);
  }

  /// GET `/api/user/coins-seller/transaction/:id`
  Future<Map<String, dynamic>?> getTransaction({
    required String transactionId,
    bool isShowLoader = false,
  }) async {
    final id = transactionId.trim();
    if (id.isEmpty) return null;

    final response = await _apiService.getRequest(
      endPoint: UserCoinsSellerEndpoints.transaction(id),
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return _decode(response, allowNotFound: true);
  }

  /// POST `/api/user/coins-seller/sell`
  Future<Map<String, dynamic>?> sellCoins({
    required String userId,
    required int amount,
    required num price,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: UserCoinsSellerEndpoints.sell,
      requestModel: <String, dynamic>{
        'userId': userId.trim(),
        'amount': amount,
        'price': price,
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return _decode(response);
  }

  /// PATCH `/api/user/coins-seller/transaction/:id` — update price / note.
  Future<Map<String, dynamic>?> updateTransaction({
    required String transactionId,
    num? price,
    String? note,
    bool isShowLoader = true,
  }) async {
    final id = transactionId.trim();
    if (id.isEmpty) return null;

    final body = <String, dynamic>{};
    if (price != null) body['price'] = price;
    if (note != null) body['note'] = note.trim();
    if (body.isEmpty) return null;

    final response = await _apiService.patchRequest(
      endPoint: UserCoinsSellerEndpoints.transaction(id),
      requestModel: body,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return _decode(response, allowNotFound: true);
  }

  /// PUT `/api/user/coins-seller/transaction/:id` — reverse sale.
  Future<Map<String, dynamic>?> reverseTransaction({
    required String transactionId,
    bool isShowLoader = true,
  }) async {
    final id = transactionId.trim();
    if (id.isEmpty) return null;

    final response = await _apiService.putRequest(
      endPoint: UserCoinsSellerEndpoints.reverseTransaction(id),
      requestModel: <String, dynamic>{},
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return _decode(response);
  }

  /// DELETE `/api/user/coins-seller/transaction/:id` — alias for reverse when supported.
  Future<Map<String, dynamic>?> deleteTransaction({
    required String transactionId,
    bool isShowLoader = true,
  }) async {
    final id = transactionId.trim();
    if (id.isEmpty) return null;

    final response = await _apiService.deleteRequest(
      endPoint: UserCoinsSellerEndpoints.transaction(id),
      requestModel: null,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return _decode(response, allowNotFound: true);
  }

  Map<String, dynamic> _decode(
    http.Response response, {
    bool allowNotFound = false,
  }) {
    final decoded =
        ApiResponseUtils.tryDecodeMap(response.body) ?? <String, dynamic>{};

    if (response.statusCode == 404 && allowNotFound) {
      return <String, dynamic>{
        ...decoded,
        'success': false,
        'statusCode': 404,
        'message': decoded['message']?.toString() ?? 'Not found',
      };
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      return <String, dynamic>{
        ...decoded,
        'success': false,
        'statusCode': response.statusCode,
        'message': (decoded['message']?.toString().trim().isNotEmpty == true)
            ? decoded['message']
            : (response.statusCode == 403
                ? 'Access Denied'
                : 'Unauthorized'),
      };
    }

    if (!decoded.containsKey('statusCode')) {
      decoded['statusCode'] = response.statusCode;
    }
    if (response.statusCode == 201 && decoded['success'] != true) {
      final code = decoded['statusCode'];
      if (code != 1 && code != 200 && code != 201 && code?.toString() != '201') {
        decoded['statusCode'] = 201;
      }
    }
    return decoded;
  }
}
