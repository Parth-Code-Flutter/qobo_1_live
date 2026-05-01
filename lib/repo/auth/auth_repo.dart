import 'package:qobo_one_live/app/auth/verifyAccount/models/request/login_with_otp_request_model.dart';
import 'package:qobo_one_live/app/auth/verifyAccount/models/response/login_with_otp_response_model.dart';
import 'package:qobo_one_live/app/auth/verifyAccount/models/request/verify_otp_request_model.dart';
import 'package:qobo_one_live/app/auth/verifyAccount/models/response/verify_otp_response_model.dart';
import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

/// Auth repository contains API calls for authentication flows.
class AuthRepo {
  AuthRepo({
    ApiService? apiService,
  }) : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  /// Calls `POST /api/auth/login-phone` to send OTP to the user.
  ///
  /// Returns parsed [LoginWithOtpResponseModel] on success, otherwise `null`.
  Future<LoginWithOtpResponseModel?> loginWithOtp({
    required String phone,
    required String countryCode,
    bool isShowLoader = true,
  }) async {
    final request = LoginWithOtpRequestModel(
      phone: phone,
      countryCode: countryCode,
    );

    final response = await _apiService.postRequest(
      endPoint: AuthEndpoints.loginPhone,
      requestModel: request.toJson(),
      isShowLoader: isShowLoader,
      isLoginCall: true,
    );

    if (response == null) return null;

    final jsonMap = ApiResponseUtils.tryDecodeMap(response.body);
    if (jsonMap == null) return null;

    return LoginWithOtpResponseModel.fromJson(jsonMap);
  }

  /// Calls `POST /api/auth/verify-otp` to validate OTP and obtain session token.
  ///
  /// Returns parsed [VerifyOtpResponseModel] on success, otherwise `null`.
  /// Uses [isShowLoader]: `false` by default so callers can use local UI loading
  /// on the verify screen without requiring global overlay dependencies.
  Future<VerifyOtpResponseModel?> verifyOtp({
    required String phone,
    required String otp,
    bool isShowLoader = false,
  }) async {
    final request = VerifyOtpRequestModel(phone: phone, otp: otp);

    final response = await _apiService.postRequest(
      endPoint: AuthEndpoints.verifyOtp,
      requestModel: request.toJson(),
      isShowLoader: isShowLoader,
      isLoginCall: true,
    );

    if (response == null) return null;

    final jsonMap = ApiResponseUtils.tryDecodeMap(response.body);
    if (jsonMap == null) return null;

    return VerifyOtpResponseModel.fromJson(jsonMap);
  }
}

