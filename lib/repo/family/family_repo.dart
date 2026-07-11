import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

class FamilyRepo {
  FamilyRepo({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<Map<String, dynamic>?> getFamilies({bool isShowLoader = true}) async {
    final response = await _apiService.getRequest(
      endPoint: FamilyEndpoints.list,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> getMyFamily({bool isShowLoader = true}) async {
    final response = await _apiService.getRequest(
      endPoint: FamilyEndpoints.my,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> getFamilyDetail({
    required String familyId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.getRequest(
      endPoint:
          '${FamilyEndpoints.detail}/${Uri.encodeComponent(familyId.trim())}',
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> createFamily({
    required String name,
    required String description,
    String? logo,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: FamilyEndpoints.create,
      requestModel: <String, dynamic>{
        'name': name,
        'description': description,
        if ((logo ?? '').trim().isNotEmpty) 'logo': logo!.trim(),
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> joinFamily({
    required String familyId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: FamilyEndpoints.join,
      requestModel: <String, dynamic>{
        'family_id': familyId,
        'familyId': familyId,
        'id': familyId,
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> leaveFamily({bool isShowLoader = true}) async {
    final response = await _apiService.postRequest(
      endPoint: FamilyEndpoints.leave,
      requestModel: <String, dynamic>{},
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }
}
