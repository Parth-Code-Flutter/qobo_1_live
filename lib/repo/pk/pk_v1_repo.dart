import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

/// Repository for the host-vs-host PK Battle v1 API (`/api/v1/pk/*`).
///
/// Every method returns the fully-decoded response body (`{success, message,
/// data}`) or `null` on transport failure — mirroring the existing repo
/// convention. Callers use [PkV1Repo.dataOf] / [PkV1Repo.isSuccess] to unwrap.
class PkV1Repo {
  PkV1Repo({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  // ---- response helpers ---------------------------------------------------

  static bool isSuccess(Map<String, dynamic>? body) {
    if (body == null) return false;
    final success = body['success'];
    if (success is bool) return success;
    return ApiResponseUtils.isBodySuccess(body);
  }

  static Map<String, dynamic> dataOf(Map<String, dynamic>? body) {
    final data = body?['data'];
    if (data is Map) {
      return data.map((k, v) => MapEntry(k.toString(), v));
    }
    return <String, dynamic>{};
  }

  static String messageOf(Map<String, dynamic>? body) {
    return body?['message']?.toString() ?? '';
  }

  // ---- eligible hosts -----------------------------------------------------

  /// GET /api/v1/pk/eligible-hosts
  Future<Map<String, dynamic>?> getEligibleHosts({
    int page = 1,
    int pageSize = 20,
    String? search,
    bool isShowLoader = false,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'pageSize': '$pageSize',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };
    final response = await _apiService.getRequest(
      endPoint: '${PkV1Endpoints.eligibleHosts}?${_encodeQuery(query)}',
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  // ---- invitations --------------------------------------------------------

  /// POST /api/v1/pk/invitations
  Future<Map<String, dynamic>?> sendInvitation({
    required String targetUserId,
    String mode = 'ONE_VS_ONE',
    int durationSec = 180,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: PkV1Endpoints.invitations,
      requestModel: <String, dynamic>{
        'targetUserId': targetUserId,
        'mode': mode,
        'durationSec': durationSec,
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// GET /api/v1/pk/invitations?type=incoming|outgoing
  Future<Map<String, dynamic>?> getInvitations({
    String? type,
    bool isShowLoader = false,
  }) async {
    final suffix = (type != null && type.trim().isNotEmpty)
        ? '?type=${Uri.encodeComponent(type.trim())}'
        : '';
    final response = await _apiService.getRequest(
      endPoint: '${PkV1Endpoints.invitationsList}$suffix',
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// POST /api/v1/pk/invitations/{id}/accept
  Future<Map<String, dynamic>?> acceptInvitation({
    required String invitationId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: PkV1Endpoints.acceptInvitation(invitationId),
      requestModel: const <String, dynamic>{},
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// POST /api/v1/pk/invitations/{id}/reject
  Future<Map<String, dynamic>?> rejectInvitation({
    required String invitationId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: PkV1Endpoints.rejectInvitation(invitationId),
      requestModel: const <String, dynamic>{},
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// POST /api/v1/pk/invitations/{id}/cancel
  Future<Map<String, dynamic>?> cancelInvitation({
    required String invitationId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: PkV1Endpoints.cancelInvitation(invitationId),
      requestModel: const <String, dynamic>{},
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  // ---- session / scoring --------------------------------------------------

  /// GET /api/v1/pk/{pkId}
  Future<Map<String, dynamic>?> getSession({
    required String pkId,
    bool isShowLoader = false,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: PkV1Endpoints.session(pkId),
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// POST /api/v1/pk/{pkId}/gifts — send a gift to a side.
  ///
  /// [clientRequestId] MUST be unique per logical send for idempotency so a
  /// network retry never double-charges the viewer.
  Future<Map<String, dynamic>?> sendGift({
    required String pkId,
    required String giftId,
    required int quantity,
    required String targetSide,
    required String clientRequestId,
    bool isShowLoader = false,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: PkV1Endpoints.sendGift(pkId),
      requestModel: <String, dynamic>{
        'giftId': giftId,
        'quantity': quantity,
        'targetSide': targetSide,
        'clientRequestId': clientRequestId,
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// GET /api/v1/pk/{pkId}/gifts — gift transactions during a battle.
  Future<Map<String, dynamic>?> getGiftTransactions({
    required String pkId,
    bool isShowLoader = false,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: PkV1Endpoints.giftTransactions(pkId),
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// POST /api/v1/pk/{pkId}/leave — host leaves / forfeits.
  Future<Map<String, dynamic>?> leave({
    required String pkId,
    String reason = 'host_leave',
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: PkV1Endpoints.leave(pkId),
      requestModel: <String, dynamic>{'reason': reason},
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// POST /api/v1/pk/{pkId}/report
  Future<Map<String, dynamic>?> report({
    required String pkId,
    required String reportedUserId,
    required String reason,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: PkV1Endpoints.report(pkId),
      requestModel: <String, dynamic>{
        'reportedUserId': reportedUserId,
        'reason': reason,
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// GET /api/v1/pk/{pkId}/result
  Future<Map<String, dynamic>?> getResult({
    required String pkId,
    bool isShowLoader = false,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: PkV1Endpoints.result(pkId),
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// GET /api/v1/pk/history
  Future<Map<String, dynamic>?> getHistory({
    int page = 1,
    int pageSize = 20,
    bool isShowLoader = true,
  }) async {
    final query = <String, String>{'page': '$page', 'pageSize': '$pageSize'};
    final response = await _apiService.getRequest(
      endPoint: '${PkV1Endpoints.history}?${_encodeQuery(query)}',
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// GET /api/v1/pk/gifts — available gift catalog.
  Future<Map<String, dynamic>?> getGiftCatalog({
    bool isShowLoader = false,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: PkV1Endpoints.giftCatalog,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  String _encodeQuery(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
  }
}
