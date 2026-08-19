import 'package:qobo_one_live/utils/api_response_utils.dart';

bool isReferralApiSuccess(Map<String, dynamic>? response) {
  return ApiResponseUtils.isBodySuccess(response);
}

String referralApiMessage(Map<String, dynamic>? response, String fallback) {
  return ApiResponseUtils.tryGetMessage(response) ?? fallback;
}
