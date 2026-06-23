import 'package:qobo_one_live/models/geo/country_state_models.dart';
import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';

/// Public geo lookups — `GET /api/auth/countries` and `/api/auth/states`.
class GeoRepo {
  GeoRepo({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<List<CountryOption>> fetchCountries({bool isShowLoader = false}) async {
    final map = await _fetchGeoJson(
      endPoint: AuthEndpoints.countries,
      label: 'countries',
      isShowLoader: isShowLoader,
    );
    if (map == null) return const [];
    return CountryOption.listFromResponseData(map['data']);
  }

  Future<List<StateOption>> fetchStates({
    required String countryId,
    bool isShowLoader = false,
  }) async {
    final id = countryId.trim();
    if (id.isEmpty) return const [];

    final map = await _fetchGeoJson(
      endPoint: AuthEndpoints.states,
      label: 'states',
      queryParams: {'countryId': id},
      isShowLoader: isShowLoader,
    );
    if (map == null) return const [];
    return StateOption.listFromResponseData(map['data']);
  }

  Future<Map<String, dynamic>?> _fetchGeoJson({
    required String endPoint,
    required String label,
    Map<String, String>? queryParams,
    bool isShowLoader = false,
  }) async {
    // Public endpoint first (per backend docs).
    var response = await _apiService.getPublicRequest(
      endPoint: endPoint,
      queryParams: queryParams,
      isShowLoader: isShowLoader,
    );
    var map = response == null ? null : ApiResponseUtils.tryDecodeMap(response.body);

    if (_isSuccessWithData(map)) {
      LoggerUtils.logInfo('Geo $label loaded (public): ${_listLength(map?['data'])} items');
      return map;
    }

    // Fallback: some environments may require auth despite public docs.
    response = await _apiService.getRequest(
      endPoint: _withQuery(endPoint, queryParams),
      isShowLoader: isShowLoader,
    );
    map = response == null ? null : ApiResponseUtils.tryDecodeMap(response.body);

    if (_isSuccessWithData(map)) {
      LoggerUtils.logInfo('Geo $label loaded (auth): ${_listLength(map?['data'])} items');
      return map;
    }

    LoggerUtils.logWarning('Geo $label fetch failed or returned no data');
    return map;
  }

  bool _isSuccessWithData(Map<String, dynamic>? map) {
    if (!isGeoApiSuccess(map)) return false;
    final data = map?['data'];
    return data is List;
  }

  int _listLength(dynamic data) => data is List ? data.length : 0;

  String _withQuery(String endPoint, Map<String, String>? queryParams) {
    if (queryParams == null || queryParams.isEmpty) return endPoint;
    return '$endPoint?${Uri(queryParameters: queryParams).query}';
  }
}
