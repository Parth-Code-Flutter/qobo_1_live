import 'package:qobo_one_live/app/user_flow/referral/models/referral_models.dart';
import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

class ReferralRepo {
  ReferralRepo({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<Map<String, dynamic>?> verifyReferralCode({
    required String code,
    bool isShowLoader = false,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: AuthEndpoints.verifyReferralCode,
      requestModel: <String, dynamic>{'code': code.trim().toUpperCase()},
      isShowLoader: isShowLoader,
      isLoginCall: true,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<ReferralVerifyResult?> verifyReferralCodeParsed({
    required String code,
    bool isShowLoader = false,
  }) async {
    final map = await verifyReferralCode(code: code, isShowLoader: isShowLoader);
    if (!ApiResponseUtils.isBodySuccess(map)) return null;
    final data = map?['data'];
    if (data is! Map) return null;
    return ReferralVerifyResult.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Map<String, dynamic>?> generateReferralCode({
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: ReferralEndpoints.generate,
      requestModel: const <String, dynamic>{},
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<ReferralCodePayload?> generateReferralCodeParsed({
    bool isShowLoader = true,
  }) async {
    final map = await generateReferralCode(isShowLoader: isShowLoader);
    if (!ApiResponseUtils.isBodySuccess(map)) return null;
    final data = map?['data'];
    if (data is! Map) return null;
    return ReferralCodePayload.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Map<String, dynamic>?> getMyReferralCode({
    bool isShowLoader = false,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: ReferralEndpoints.myCode,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<ReferralMyCodeDetails?> getMyReferralCodeParsed({
    bool isShowLoader = false,
  }) async {
    final map = await getMyReferralCode(isShowLoader: isShowLoader);
    if (!ApiResponseUtils.isBodySuccess(map)) return null;
    final data = map?['data'];
    if (data is! Map) return null;
    return ReferralMyCodeDetails.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Map<String, dynamic>?> getReferralHistory({
    bool isShowLoader = false,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: ReferralEndpoints.history,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<List<ReferralEarningEntry>> getReferralHistoryParsed({
    bool isShowLoader = false,
  }) async {
    final map = await getReferralHistory(isShowLoader: isShowLoader);
    if (!ApiResponseUtils.isBodySuccess(map)) return const [];
    final data = map?['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => ReferralEarningEntry.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
