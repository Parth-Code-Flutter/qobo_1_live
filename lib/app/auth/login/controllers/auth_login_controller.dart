import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/facebook_login_config.dart';
import 'package:qobo_one_live/constants/google_sign_in_config.dart';
import 'package:qobo_one_live/generated/locales.g.dart';
import 'package:qobo_one_live/repo/auth/auth_repo.dart';
import 'package:qobo_one_live/repo/auth/models/request/social_login_request_model.dart';
import 'package:qobo_one_live/services/social_auth/facebook_social_auth_provider.dart';
import 'package:qobo_one_live/services/social_auth/google_social_auth_provider.dart';
import 'package:qobo_one_live/services/social_auth/social_auth_provider.dart';
import 'package:qobo_one_live/utils/auth/auth_session_helper.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

class AuthLoginController extends GetxController {
  AuthLoginController({
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
  final passwordController = TextEditingController();
  final isPasswordHidden = true.obs;
  final isLoginLoading = false.obs;
  final isGoogleLoginLoading = false.obs;
  final isFacebookLoginLoading = false.obs;
  final isPhoneInput = false.obs;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  bool validateForm() {
    return formKey.currentState?.validate() ?? false;
  }

  /// Detect phone vs email mode from first typed character (digits → phone).
  void onUsernameChanged(String value) {
    final trimmed = value.trimLeft();
    if (trimmed.isEmpty) {
      isPhoneInput.value = false;
      return;
    }
    final first = trimmed[0];
    isPhoneInput.value = RegExp(r'^\d$').hasMatch(first);
  }

  String? validateUsername(BuildContext context, String? value) {
    final username = (value ?? '').trim();
    if (username.isEmpty) {
      return LocaleKeys.loginUsernameRequired.tr;
    }
    if (isPhoneInput.value) {
      if (!RegExp(r'^\d{10}$').hasMatch(username)) {
        return LocaleKeys.loginEmailOrPhoneInvalid.tr;
      }
      return null;
    }
    if (!username.isEmail) {
      return LocaleKeys.loginEmailOrPhoneInvalid.tr;
    }
    return null;
  }

  /// API-friendly login username.
  /// Backend expects raw phone digits for phone login (no dial-code prefix).
  String get resolvedLoginUsername {
    final username = emailController.text.trim();
    return username;
  }

  Future<void> onLoginPressed(BuildContext context) async {
    if (isLoginLoading.value) return;
    if (!validateForm()) return;

    try {
      isLoginLoading.value = true;
      final response = await _authRepo.login(
        username: resolvedLoginUsername,
        password: passwordController.text.trim(),
        isShowLoader: false,
      );
      if (!context.mounted) return;
      await AuthSessionHelper.handleAuthApiResponse(context, response);
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, e.toString());
      }
    } finally {
      isLoginLoading.value = false;
    }
  }

  /// Opens the **Google account picker** ([GoogleSocialAuthProvider]); optionally calls
  /// `/api/auth/social` when [GoogleSignInConfig.submitGoogleLoginToBackend] is enabled.
  Future<void> onGoogleLoginPressed(BuildContext context) async {
    if (isLoginLoading.value ||
        isGoogleLoginLoading.value ||
        isFacebookLoginLoading.value) {
      return;
    }

    try {
      isGoogleLoginLoading.value = true;
      final socialUser = await _googleSocialAuth.signIn();
      if (!context.mounted) return;
      if (socialUser == null) return;

      // Demo / pre-release: only native Google UI — flip flag when backend is ready.
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
        AppToast.showError(context, e.toString());
      }
    } finally {
      isGoogleLoginLoading.value = false;
    }
  }

  /// Facebook Login → optional `POST /api/auth/social` (see [FacebookLoginConfig]).
  Future<void> onFacebookLoginPressed(BuildContext context) async {
    if (isLoginLoading.value ||
        isGoogleLoginLoading.value ||
        isFacebookLoginLoading.value) {
      return;
    }

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
