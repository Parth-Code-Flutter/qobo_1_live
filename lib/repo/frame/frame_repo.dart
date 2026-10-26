import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

/// Shop and backpack filter from the frame contract.
///
/// Avatar borders use `type=frames`. VIP arrival animations use `type=entry`.
enum FrameCatalogType {
  avatar('frames'),
  entry('entry');

  const FrameCatalogType(this.queryValue);

  final String queryValue;
}

/// True when a shop row or backpack row is a VIP entry frame, not an avatar border.
///
/// Unknown rows stay avatar frames so older shop items keep their current tab.
bool frameCatalogIsEntry(
  Map<String, dynamic> raw, {
  Map<String, dynamic>? details,
}) {
  final own = _frameCatalogType(raw);
  if (own != null) return own == FrameCatalogType.entry;
  if (details == null) return false;
  return _frameCatalogType(details) == FrameCatalogType.entry;
}

FrameCatalogType? _frameCatalogType(Map<String, dynamic> raw) {
  final frameType = '${raw['frameType'] ?? ''}'.trim().toLowerCase();
  if (frameType == 'entry') return FrameCatalogType.entry;
  if (frameType == 'avatar') return FrameCatalogType.avatar;

  final type = '${raw['type'] ?? ''}'.trim().toLowerCase();
  if (type == 'entry' || type == 'vip') return FrameCatalogType.entry;
  if (type == 'avatar' || type == 'frames') return FrameCatalogType.avatar;

  // Backpack rows may send `itemType` or the newer `itemTypes` string.
  final itemType = _frameItemType(raw);
  if (itemType == 'VIP_FRAME') return FrameCatalogType.entry;
  if (itemType == 'AVATAR_FRAME') return FrameCatalogType.avatar;

  final category = '${raw['category'] ?? ''}'.trim().toLowerCase();
  if (category == 'vip') return FrameCatalogType.entry;
  return null;
}

String _frameItemType(Map<String, dynamic> raw) {
  for (final key in const ['itemType', 'itemTypes', 'item_type', 'item_types']) {
    final value = raw[key];
    if (value is List) {
      for (final part in value) {
        final token = '$part'.trim().toUpperCase();
        if (token == 'VIP_FRAME' || token == 'AVATAR_FRAME') return token;
      }
      continue;
    }
    final token = '${value ?? ''}'.trim().toUpperCase();
    if (token == 'VIP_FRAME' || token == 'AVATAR_FRAME') return token;
  }
  return '';
}

/// Avatar frame and VIP entry-frame storefront calls.
class FrameRepo {
  FrameRepo({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  /// Calls `GET /api/frame/shop`.
  ///
  /// Pass [type] so avatar borders and entry animations stay in separate lists.
  Future<Map<String, dynamic>?> getShopFrames({
    FrameCatalogType? type,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: _withType(FrameEndpoints.shop, type),
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

  /// Calls `GET /api/frame/my-backpack`.
  ///
  /// [type] limits the result to avatar borders or entry animations.
  /// Omitting it returns both, which equip still treats as separate slots.
  Future<Map<String, dynamic>?> getMyBackpack({
    FrameCatalogType? type,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: _withType(FrameEndpoints.myBackpack, type),
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  String _withType(String endpoint, FrameCatalogType? type) {
    if (type == null) return endpoint;
    return '$endpoint?type=${type.queryValue}';
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
