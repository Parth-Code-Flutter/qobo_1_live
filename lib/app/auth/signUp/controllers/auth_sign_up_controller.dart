import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/facebook_login_config.dart';
import 'package:qobo_one_live/constants/google_sign_in_config.dart';
import 'package:qobo_one_live/repo/auth/auth_repo.dart';
import 'package:qobo_one_live/repo/auth/models/request/social_login_request_model.dart';
import 'package:qobo_one_live/services/social_auth/facebook_social_auth_provider.dart';
import 'package:qobo_one_live/services/social_auth/google_social_auth_provider.dart';
import 'package:qobo_one_live/services/social_auth/social_auth_provider.dart';
import 'package:qobo_one_live/utils/auth/auth_session_helper.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

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

  /// Same behavior as login: native picker, optional `/api/auth/social` via flags.
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
        AppToast.showError(context, e.toString());
      }
    } finally {
      isGoogleLoginLoading.value = false;
    }
  }

  /// Same behavior as login: native picker, optional `/api/auth/social` via flags.
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
