import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

/// Profile background storefront and backpack API calls.
class BackgroundRepo {
  BackgroundRepo({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  /// Calls `GET /api/background/shop` to load purchasable profile backgrounds.
  Future<Map<String, dynamic>?> getShopBackgrounds({
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: BackgroundEndpoints.shop,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/background/buy` to purchase one profile background.
  Future<Map<String, dynamic>?> buyBackground({
    required String backgroundId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: BackgroundEndpoints.buy,
      requestModel: <String, dynamic>{'background_id': backgroundId},
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `GET /api/background/my-backpack` to load owned profile backgrounds.
  Future<Map<String, dynamic>?> getMyBackpack({
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: BackgroundEndpoints.myBackpack,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/background/equip` to equip or un-equip a background.
  Future<Map<String, dynamic>?> equipBackground({
    required String backpackItemId,
    required bool equip,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: BackgroundEndpoints.equip,
      requestModel: <String, dynamic>{
        'backpack_item_id': backpackItemId,
        'equip': equip,
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }
}
