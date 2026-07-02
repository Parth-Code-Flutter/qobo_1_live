import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/constants/facebook_login_config.dart';
import 'package:qobo_one_live/constants/google_sign_in_config.dart';
import 'package:qobo_one_live/repo/auth/auth_repo.dart';
import 'package:qobo_one_live/repo/auth/models/request/social_login_request_model.dart';
import 'package:qobo_one_live/services/social_auth/facebook_social_auth_provider.dart';
import 'package:qobo_one_live/services/social_auth/google_social_auth_provider.dart';
import 'package:qobo_one_live/services/social_auth/social_auth_provider.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';
import 'package:qobo_one_live/utils/auth/auth_session_helper.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

import '../widgets/email_otp_dialog.dart';

class AuthSignUpController extends GetxController {
  AuthSignUpController({
    AuthRepo? authRepo,
    SocialAuthProvider? googleSocialAuth,
    SocialAuthProvider? facebookSocialAuth,
  }) : _authRepo = authRepo ?? AuthRepo(),
       _googleSocialAuth = googleSocialAuth ?? GoogleSocialAuthProvider(),
       _facebookSocialAuth = facebookSocialAuth ?? FacebookSocialAuthProvider();

  final AuthRepo _authRepo;
  final SocialAuthProvider _googleSocialAuth;
  final SocialAuthProvider _facebookSocialAuth;

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final isPasswordHidden = true.obs;
  final isGoogleLoginLoading = false.obs;
  final isFacebookLoginLoading = false.obs;
  final isSignUpLoading = false.obs;

  Future<void> onSignUpPressed(BuildContext context) async {
    if (isSignUpLoading.value) return;
    if (!validateForm()) return;

    final email = emailController.text.trim();

    try {
      isSignUpLoading.value = true;
      final otpSent = await _sendEmailOtp(context, email: email);
      if (!context.mounted || !otpSent) return;
    } finally {
      isSignUpLoading.value = false;
    }

    final verified = await Get.dialog<bool>(
      EmailOtpDialog(
        email: email,
        onVerify: (otp) => _verifyEmailOtp(context, email: email, otp: otp),
        onResend: () => _sendEmailOtp(
          context,
          email: email,
          showSuccessMessage: true,
        ),
      ),
      barrierDismissible: false,
    );

    if (!context.mounted || verified != true) return;
    await _completeRegistration(context);
  }

  Future<void> _completeRegistration(BuildContext context) async {
    try {
      isSignUpLoading.value = true;
      final response = await _authRepo.register(
        email: emailController.text.trim(),
        username: usernameController.text.trim(),
        password: passwordController.text.trim(),
        isShowLoader: false,
      );
      if (!context.mounted) return;
      if (_isSuccessResponse(response)) {
        AppToast.showSuccess(context, 'Registration successful!');
        Get.toNamed(Routes.AUTH_VERIFY_ACCOUNT);
      } else {
        AppToast.showError(
          context,
          _responseMessage(response, 'Registration failed. Please try again.'),
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, e.toString());
      }
    } finally {
      isSignUpLoading.value = false;
    }
  }

  Future<bool> _sendEmailOtp(
    BuildContext context, {
    required String email,
    bool showSuccessMessage = false,
  }) async {
    try {
      final response = await _authRepo.sendEmailOtp(
        email: email,
        isShowLoader: false,
      );
      if (!context.mounted) return false;

      if (_isSuccessResponse(response)) {
        if (showSuccessMessage) {
          AppToast.showSuccess(context, 'OTP sent successfully.');
        }
        return true;
      }

      AppToast.showError(
        context,
        _responseMessage(response, 'Unable to send OTP. Please try again.'),
      );
      return false;
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, e.toString());
      }
      return false;
    }
  }

  Future<bool> _verifyEmailOtp(
    BuildContext context, {
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _authRepo.verifyEmailOtp(
        email: email,
        otp: otp,
        isShowLoader: false,
      );
      if (!context.mounted) return false;

      if (_isSuccessResponse(response)) return true;

      AppToast.showError(
        context,
        _responseMessage(response, 'Invalid OTP. Please try again.'),
      );
      return false;
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, e.toString());
      }
      return false;
    }
  }

  bool _isSuccessResponse(Map<String, dynamic>? response) {
    if (response == null) return false;
    return ApiResponseUtils.isBodySuccess(response);
  }

  String _responseMessage(
    Map<String, dynamic>? response,
    String fallback,
  ) {
    return ApiResponseUtils.tryGetMessage(response) ?? fallback;
  }

  String _friendlyGoogleError(Object error) {
    final text = error.toString();
    if (text.contains('clientConfigurationError') ||
        text.contains('default_web_client_id') ||
        text.contains('GOOGLE_WEB_CLIENT_ID') ||
        text.contains('GOOGLE_SERVER_CLIENT_ID') ||
        text.contains('Web application')) {
      return 'Google Sign-In is not configured for Android. '
          'In Google Cloud (qobo1live-496317): verify SHA-1 for package '
          'com.qobo1live.live, create a **Web application** OAuth client, '
          'update google-services.json, then run flutter clean && reinstall.';
    }
    if (text.startsWith('StateError: ')) {
      return text.replaceFirst('StateError: ', '');
    }
    return text;
  }

  @override
  void onClose() {
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  bool validateForm() {
    return formKey.currentState?.validate() ?? false;
  }

  /// Same as login: Google picker → **`POST /api/auth/social`** when enabled (default on).
  Future<void> onGoogleSignUpPressed(BuildContext context) async {
    if (isGoogleLoginLoading.value || isFacebookLoginLoading.value) return;

    try {
      isGoogleLoginLoading.value = true;
      final socialUser = await _googleSocialAuth.signIn();
      if (!context.mounted) return;
      if (socialUser == null) return;

      if (!GoogleSignInConfig.submitGoogleLoginToBackend) {
        AppToast.showSuccess(
          context,
          'Google account selected: ${socialUser.email}',
        );
        return;
      }

      final response = await _authRepo.socialLogin(
        request: SocialLoginRequestModel.fromSocialUser(socialUser),
        isShowLoader: false,
      );
      if (!context.mounted) return;
      await AuthSessionHelper.handleAuthApiResponse(context, response);
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, _friendlyGoogleError(e));
      }
    } finally {
      isGoogleLoginLoading.value = false;
    }
  }

  /// Facebook picker → **`POST /api/auth/social`** when [FacebookLoginConfig] enables it.
  Future<void> onFacebookSignUpPressed(BuildContext context) async {
    if (isGoogleLoginLoading.value || isFacebookLoginLoading.value) return;

    try {
      isFacebookLoginLoading.value = true;
      final socialUser = await _facebookSocialAuth.signIn();
      if (!context.mounted) return;
      if (socialUser == null) return;

      if (!FacebookLoginConfig.submitFacebookLoginToBackend) {
        AppToast.showSuccess(
          context,
          'Facebook account selected: ${socialUser.displayName}',
        );
        return;
      }

      final response = await _authRepo.socialLogin(
        request: SocialLoginRequestModel.fromSocialUser(socialUser),
        isShowLoader: false,
      );
      if (!context.mounted) return;
      await AuthSessionHelper.handleAuthApiResponse(context, response);
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, e.toString());
      }
    } finally {
      isFacebookLoginLoading.value = false;
    }
  }
}
