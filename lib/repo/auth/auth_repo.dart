import 'dart:io';

import 'package:qobo_one_live/repo/auth/models/request/social_login_request_model.dart';
import 'package:qobo_one_live/app/auth/verifyAccount/models/request/login_with_otp_request_model.dart';
import 'package:qobo_one_live/app/auth/verifyAccount/models/response/forgot_password_send_result.dart';
import 'package:qobo_one_live/app/auth/verifyAccount/models/response/login_with_otp_response_model.dart';
import 'package:qobo_one_live/app/auth/new_password/models/request/reset_password_request_model.dart';
import 'package:qobo_one_live/app/auth/new_password/models/response/reset_password_response_model.dart';
import 'package:qobo_one_live/app/auth/verifyAccount/models/request/verify_otp_request_model.dart';
import 'package:qobo_one_live/app/auth/verifyAccount/models/response/verify_otp_response_model.dart';
import 'package:qobo_one_live/app/user_flow/update_profile/models/request/update_profile_request_model.dart';
import 'package:qobo_one_live/app/user_flow/update_profile/models/response/update_profile_response_model.dart';
import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

/// Auth repository contains API calls for authentication flows.
class AuthRepo {
  AuthRepo({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  /// Calls `POST /api/auth/login` with username + password.
  ///
  /// Returns decoded JSON map on success, otherwise `null`.
  Future<Map<String, dynamic>?> login({
    required String username,
    required String password,
    bool isShowLoader = false,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: AuthEndpoints.login,
      requestModel: <String, dynamic>{
        'username': username,
        'password': password,
      },
      isShowLoader: isShowLoader,
      isLoginCall: true,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/auth/social` with OAuth profile payload (Google, etc.).
  ///
  /// Returns decoded JSON map on success, otherwise `null`.
  Future<Map<String, dynamic>?> socialLogin({
    required SocialLoginRequestModel request,
    bool isShowLoader = false,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: AuthEndpoints.socialLogin,
      requestModel: request.toJson(),
      isShowLoader: isShowLoader,
      isLoginCall: true,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `GET /api/user/profile`.
  ///
  /// Returns decoded JSON map on success, otherwise `null`.
  Future<Map<String, dynamic>?> getProfile({bool isShowLoader = false}) async {
    final response = await _apiService.getRequest(
      endPoint: AuthEndpoints.getProfile,
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

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

  /// Calls `POST /api/auth/forgot-password` to send a reset OTP to [phone]
  /// (10-digit local number in the JSON body, as required by the backend).
  ///
  /// Success follows [ForgotPasswordSendResult.fromResponse] (HTTP 2xx and
  /// optional JSON `statusCode` 1 / 200 / 201).
  Future<ForgotPasswordSendResult?> forgotPasswordSendOtp({
    required String phone,
    bool isShowLoader = false,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: AuthEndpoints.forgotPassword,
      requestModel: <String, dynamic>{'phone': phone},
      isShowLoader: isShowLoader,
      isLoginCall: true,
    );

    return ForgotPasswordSendResult.fromResponse(response);
  }

  /// Calls `POST /api/auth/reset-password` after forgot-password OTP.
  ///
  /// Body: `{ "phone", "otp", "password" }` — [phone] is the 10-digit local number.
  /// Returns parsed JSON (`statusCode`, `message`), or `null` if the request failed.
  Future<ResetPasswordResponseModel?> resetPassword({
    required String phone,
    required String otp,
    required String password,
    bool isShowLoader = false,
  }) async {
    final request = ResetPasswordRequestModel(
      phone: phone,
      otp: otp,
      password: password,
    );

    final response = await _apiService.postRequest(
      endPoint: AuthEndpoints.resetPassword,
      requestModel: request.toJson(),
      isShowLoader: isShowLoader,
      isLoginCall: true,
    );

    if (response == null) return null;

    final jsonMap = ApiResponseUtils.tryDecodeMap(response.body);
    if (jsonMap == null) return null;

    return ResetPasswordResponseModel.fromJson(jsonMap);
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

  /// Calls `PUT /api/user/update` to update profile details.
  ///
  /// Uses multipart/form-data (`displayPicture` file + optional text fields).
  Future<UpdateProfileResponseModel?> updateProfile({
    required UpdateProfileRequestModel request,
    bool isShowLoader = false,
  }) async {
    if (!request.hasAnyField) return null;

    final files = request.displayPicture == null
        ? null
        : <File>[request.displayPicture!];
    final response = await _apiService.multipartFormRequest(
      endPoint: AuthEndpoints.updateProfile,
      fields: request.toFormFields(),
      files: files,
      fileFieldName: 'displayPicture',
      method: 'PUT',
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;

    final jsonMap = ApiResponseUtils.tryDecodeMap(response.body);
    if (jsonMap == null) return null;

    return UpdateProfileResponseModel.fromJson(jsonMap);
  }

  /// Calls `POST /api/user/poster-upload` to upload custom public poster.
  Future<Map<String, dynamic>?> uploadPoster({
    required File posterFile,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.multipartFormRequest(
      endPoint: AuthEndpoints.posterUpload,
      fields: const {},
      files: [posterFile],
      fileFieldName: 'poster',
      method: 'POST',
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;

    final jsonMap = ApiResponseUtils.tryDecodeMap(response.body);
    if (jsonMap == null) return null;

    return jsonMap;
  }

  /// Calls `GET /api/user/search?query=...` to search active users.
  Future<Map<String, dynamic>?> searchUsers({
    required String query,
    bool isShowLoader = false,
  }) async {
    final response = await _apiService.getRequest(
      endPoint: '${AuthEndpoints.searchUsers}?query=${Uri.encodeComponent(query)}',
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }

  /// Calls `POST /api/user/follow-unfollow` to follow or unfollow a user.
  Future<Map<String, dynamic>?> followUnfollow({
    required String targetId,
    required String action,
    bool isShowLoader = true,
  }) async {
    final response = await _apiService.postRequest(
      endPoint: AuthEndpoints.followUnfollow,
      requestModel: {
        'target_id': targetId,
        'action': action,
      },
      isShowLoader: isShowLoader,
    );

    if (response == null) return null;
    return ApiResponseUtils.tryDecodeMap(response.body);
  }
}
