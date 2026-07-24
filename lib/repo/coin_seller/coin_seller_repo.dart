import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';
import 'package:qobo_one_live/utils/local_storage/controllers/local_storage_controller.dart';

/// Coin Seller Portal APIs (`seller_admin` JWT from `/api/admin/login`).
class CoinSellerRepo {
  CoinSellerRepo({
    ApiService? apiService,
    LocalStorage? storage,
  })  : _apiService = apiService ?? ApiService(),
        _storage = storage ?? LocalStorage.shared;

  final ApiService _apiService;
  final LocalStorage _storage;

  /// POST `/api/admin/login`
  Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: SellerPortalEndpoints.login,
      requestModel: <String, dynamic>{
        'email': email.trim(),
        'password': password,
      },
      isShowLoader: isShowLoader,
      isLoginCall: true,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// GET `/api/admin/seller-portal/dashboard`
  Future<Map<String, dynamic>?> getDashboard({
    bool isShowLoader = true,
  }) async {
    final token = await _storage.getSellerToken();
    if (token.trim().isEmpty) return null;

    final response = await _apiService.getRequest(
      endPoint: SellerPortalEndpoints.dashboard,
      isShowLoader: isShowLoader,
      bearerToken: token,
      skipUnauthorizedHandling: true,
    );
    if (response == null) return null;
    if (response.statusCode == 401) {
      return <String, dynamic>{
        'success': false,
        'statusCode': 401,
        'message': 'Seller session expired',
      };
    }
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// POST `/api/admin/seller-portal/sell`
  ///
  /// [userId] may be UUID, email, or phone per backend docs.
  Future<Map<String, dynamic>?> sellCoins({
    required String userId,
    required int amount,
    required num price,
    bool isShowLoader = true,
  }) async {
    final token = await _storage.getSellerToken();
    if (token.trim().isEmpty) return null;

    final response = await _apiService.postRequest(
      endPoint: SellerPortalEndpoints.sell,
      requestModel: <String, dynamic>{
        'userId': userId.trim(),
        'amount': amount,
        'price': price,
      },
      isShowLoader: isShowLoader,
      bearerToken: token,
      skipUnauthorizedHandling: true,
    );
    if (response == null) return null;
    if (response.statusCode == 401) {
      return <String, dynamic>{
        'success': false,
        'statusCode': 401,
        'message': 'Seller session expired',
      };
    }
    return ApiResponseUtils.tryDecodeMap(response.body);
  }
}
