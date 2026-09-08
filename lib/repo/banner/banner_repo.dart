import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

class BannerRepo {
  BannerRepo({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<Map<String, dynamic>?> getActiveBanners({String type = 'all'}) async {
    final response = await _apiService.getPublicRequest(
      endPoint: BannerEndpoints.active,
      queryParams: <String, String>{'type': type},
      isShowLoader: false,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }
}
