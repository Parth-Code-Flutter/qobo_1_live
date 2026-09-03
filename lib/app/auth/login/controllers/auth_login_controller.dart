import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
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
import 'package:qobo_one_live/utils/app_dialogs/common_app_dialog.dart';
import 'package:qobo_one_live/utils/app_widgets/admin_agency_chrome.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

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
  final isAppleLoginLoading = false.obs;
  final isFirebaseLoginLoading = false.obs;
  final isPhoneInput = false.obs;

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

  /// Google account picker → **`POST /api/auth/social`** when
  /// [GoogleSignInConfig.submitGoogleLoginToBackend] is enabled (default: on).
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
      if (socialUser == null) {
        AppToast.showError(
          context,
          'Google sign-in was cancelled or failed before account details were returned.',
        );
        return;
      }

      if (!GoogleSignInConfig.submitGoogleLoginToBackend) {
        debugPrint(
          '[AuthLogin] GOOGLE_SUBMIT_TO_BACKEND=false; skipping /api/auth/social',
        );
        AppToast.showSuccess(
          context,
          'Google account selected: ${socialUser.email}',
        );
        return;
      }

      debugPrint('[AuthLogin] Calling POST /api/auth/social for Google login');
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

  /// Apple Sign-in simulation (`AUTH-12`)
  Future<void> onAppleLoginPressed(BuildContext context) async {
    if (isLoginLoading.value || isAppleLoginLoading.value) return;

    try {
      isAppleLoginLoading.value = true;
      Get.dialog(
        Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: const Color(0xFF1E1E2D),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.apple_rounded, color: kColorWhite, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Sign In with Apple',
                  style: TextStyle(
                    color: kColorWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Simulating secure native Apple Authentication sheet...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 20),
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(kColorPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      await Future.delayed(const Duration(seconds: 2));
      Get.back(); // close modal
      if (!context.mounted) return;
      AppToast.showSuccess(context, 'Successfully signed in with Apple ID!');
      Get.offAllNamed(Routes.BOTTOM_NAV);
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, e.toString());
      }
    } finally {
      isAppleLoginLoading.value = false;
    }
  }

  /// Firebase Phone Login simulation (`AUTH-11`)
  Future<void> onFirebasePhoneLoginPressed(BuildContext context) async {
    if (isLoginLoading.value || isFirebaseLoginLoading.value) return;

    final phoneController = TextEditingController();

    CommonAppDialog.showGet(
      title: 'Firebase Phone Login',
      message:
          'Enter your phone number to receive a verification code via SMS.',
      icon: Icons.sms_rounded,
      iconAccent: AdminAgencyUi.sky,
      content: TextField(
        controller: phoneController,
        keyboardType: TextInputType.phone,
        style: TextStyles.kRegularPoppins(
          fontSize: TextStyles.k14FontSize,
          colors: kColorWhite,
        ),
        decoration: InputDecoration(
          hintText: 'e.g. +923001234567',
          hintStyle: TextStyle(color: kColorWhite.withValues(alpha: 0.4)),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: kColorWhite.withValues(alpha: 0.25)),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AdminAgencyUi.pink),
          ),
        ),
      ),
      actions: [
        const CommonAppDialogAction(label: 'Cancel'),
        CommonAppDialogAction(
          label: 'Send SMS',
          isPrimary: true,
          onPressed: () {
            final number = phoneController.text.trim();
            if (number.isEmpty) return;
            _verifyFirebasePhoneCode(context, number);
          },
        ),
      ],
    );
  }

  void _verifyFirebasePhoneCode(BuildContext context, String phone) {
    final codeController = TextEditingController();

    CommonAppDialog.showGet(
      title: 'Verify SMS Code',
      message: 'Enter the 6-digit code sent to $phone.',
      icon: Icons.lock_rounded,
      iconAccent: AdminAgencyUi.violet,
      content: TextField(
        controller: codeController,
        keyboardType: TextInputType.number,
        maxLength: 6,
        style: TextStyles.kRegularPoppins(
          fontSize: TextStyles.k14FontSize,
          colors: kColorWhite,
        ),
        decoration: InputDecoration(
          hintText: 'e.g. 123456',
          hintStyle: TextStyle(color: kColorWhite.withValues(alpha: 0.4)),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: kColorWhite.withValues(alpha: 0.25)),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AdminAgencyUi.violet),
          ),
        ),
      ),
      actions: [
        const CommonAppDialogAction(label: 'Cancel'),
        CommonAppDialogAction(
          label: 'Verify',
          isPrimary: true,
          onPressed: () {
            final code = codeController.text.trim();
            if (code.length != 6) return;
            Get.dialog(
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(kColorPrimary),
                ),
              ),
              barrierDismissible: false,
            );
            Future.delayed(const Duration(seconds: 2), () {
              Get.back();
              if (!context.mounted) return;
              AppToast.showSuccess(
                context,
                'Firebase authentication successful!',
              );
              Get.offAllNamed(Routes.BOTTOM_NAV);
            });
          },
        ),
      ],
    );
  }
}
