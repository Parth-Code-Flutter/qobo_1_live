import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

/// Avatar frame storefront and backpack API calls.
class FrameRepo {
  FrameRepo({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  /// Calls `GET /api/frame/shop` to load purchasable avatar frames.
  Future<Map<String, dynamic>?> getShopFrames({
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: FrameEndpoints.shop,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/frame/buy` to purchase one avatar / VIP frame.
  Future<Map<String, dynamic>?> buyFrame({
    required String frameId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: FrameEndpoints.buy,
      requestModel: <String, dynamic>{'frame_id': frameId},
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `GET /api/frame/my-backpack` to load purchased avatar frames.
  Future<Map<String, dynamic>?> getMyBackpack({
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: FrameEndpoints.myBackpack,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/frame/equip` to equip or un-equip a purchased frame.
  Future<Map<String, dynamic>?> equipFrame({
    required String backpackItemId,
    required bool equip,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: FrameEndpoints.equip,
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
