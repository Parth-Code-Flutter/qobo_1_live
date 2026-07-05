import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

/// Support repository contains API calls for helpdesk tickets.
class SupportRepo {
  SupportRepo({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<Map<String, dynamic>?> getFaqs({bool isShowLoader = true}) async {
    final response = await _apiService.getRequest(
      endPoint: SupportEndpoints.faqs,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> createTicket({
    required String subject,
    required String description,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: SupportEndpoints.ticket,
      requestModel: <String, dynamic>{
        'subject': subject,
        'description': description,
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> getTickets({bool isShowLoader = true}) async {
    final response = await _apiService.getRequest(
      endPoint: SupportEndpoints.tickets,
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  Future<Map<String, dynamic>?> sendChatMessage({
    required String message,
    String? ticketId,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: SupportEndpoints.chatSend,
      requestModel: <String, dynamic>{
        'message': message,
        if ((ticketId ?? '').trim().isNotEmpty) 'ticketId': ticketId!.trim(),
      },
      isShowLoader: isShowLoader,
    );
    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }
}
