import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

/// Ads / banners API — `GET /api/admin/ads-config` (§7.11).
class AdsRepo {
  AdsRepo({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  /// Lists configured ad banners for selection / display.
  Future<Map<String, dynamic>?> getAdsConfig({
    bool isShowLoader = false,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: AdsEndpoints.adsConfig,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }
}
