import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/local_storage_constants.dart';
import 'package:qobo_one_live/repo/auth/auth_repo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/utils/error_handler_utils.dart';
import 'package:qobo_one_live/utils/local_storage/controllers/local_storage_controller.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';
import 'package:qobo_one_live/utils/validations/text_field_validations.dart';

import '../models/response/verify_otp_response_model.dart';

class AuthVerifyAccountController extends GetxController {
  AuthVerifyAccountController({AuthRepo? authRepo})
      : _authRepo = authRepo ?? AuthRepo();

  final AuthRepo _authRepo;

  final formKey = GlobalKey<FormState>();
  final phoneNumberController = TextEditingController();
  final emailController = TextEditingController();
  final selectedDialCode = '+91'.obs;
  final isOtpView = false.obs;
  final isContinueLoading = false.obs;
  final otpError = RxnString();
  final otpControllers = List.generate(4, (_) => TextEditingController());
  final otpFocusNodes = List.generate(4, (_) => FocusNode());
  bool isFromLoginWithOtp = false;

  /// Phone or email string last used with `login-phone` (must match `verify-otp`).
  String _otpRecipient = '';

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['isFromLoginWithOtp'] == true) {
      isFromLoginWithOtp = true;
    }
  }

  void onCountryCodeChanged(String dialCode) {
    selectedDialCode.value = dialCode;
  }

  void showOtpView() {
    isOtpView.value = true;
    otpError.value = null;
  }

  void showPhoneNumberView() {
    isOtpView.value = false;
    _otpRecipient = '';
  }

  bool handleBackAction() {
    if (isOtpView.value) {
      showPhoneNumberView();
      return false;
    }
    return true;
  }

  void onOtpChanged({
    required int index,
    required String value,
  }) {
    otpError.value = null;
    if (value.isNotEmpty && index < otpFocusNodes.length - 1) {
      otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      otpFocusNodes[index - 1].requestFocus();
    }
  }

  bool validateContactStep(BuildContext context) {
    final state = formKey.currentState;
    if (state == null) return false;
    if (!state.validate()) return false;
    final p = phoneNumberController.text.trim();
    final e = emailController.text.trim();
    final phoneOk = p.length == 10;
    final emailOk =
        e.isNotEmpty && Validate.emailValidation(context, e) == null;
    return phoneOk || emailOk;
  }

  bool validateOtp(BuildContext context) {
    final otpValue = otpControllers.map((controller) => controller.text).join();
    final validationMessage = Validate.otpValidation(
      context,
      otpValue,
      otpLength: 4,
    );
    otpError.value = validationMessage;
    return validationMessage == null;
  }

  void setContinueLoading(bool value) {
    isContinueLoading.value = value;
  }

  LocalStorage _resolveLocalStorage() {
    if (Get.isRegistered<LocalStorage>()) {
      return Get.find<LocalStorage>();
    }
    return Get.put(LocalStorage(), permanent: true);
  }

  /// Save auth payload from OTP verification for follow-up authenticated calls.
  Future<void> _persistVerifiedSession(VerifyOtpData data) async {
    final storage = _resolveLocalStorage();
    if (data.token.isNotEmpty) {
      await storage.writeStringStorage(kStorageToken, data.token);
    }
    await storage.writeJsonStorage(kStorageUserData, data.user.toJson());
  }

  /// Continue CTA: requests OTP on phone step, verifies OTP on OTP step.
  Future<void> onContinuePressed(BuildContext context) async {
    if (isContinueLoading.value) return;

    if (isOtpView.value) {
      await _submitVerifyOtp(context);
      return;
    }

    await _submitLoginPhoneOtp(context);
  }

  Future<void> _submitLoginPhoneOtp(BuildContext context) async {
    if (!validateContactStep(context)) return;

    final p = phoneNumberController.text.trim();
    final e = emailController.text.trim();
    final usePhone = p.length == 10;

    try {
      setContinueLoading(true);
      final res = await _authRepo.loginWithOtp(
        phone: usePhone ? p : e,
        countryCode: usePhone ? selectedDialCode.value : '',
        isShowLoader: false,
      );
      if (!context.mounted) return;

      if (res == null) {
        AppToast.showError(context, 'Request failed. Please try again.');
        return;
      }

      final message = res.message.trim().isNotEmpty
          ? res.message.trim()
          : 'Something went wrong.';

      if (res.statusCode == 1) {
        _otpRecipient = usePhone ? p : e;
        AppToast.showSuccess(context, message);
        showOtpView();
      } else {
        AppToast.showError(context, message);
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, e.toString());
      }
    } finally {
      setContinueLoading(false);
    }
  }

  Future<void> _submitVerifyOtp(BuildContext context) async {
    if (!validateOtp(context)) return;

    try {
      setContinueLoading(true);
      final otpDigits = otpControllers.map((c) => c.text).join();
      final res = await _authRepo.verifyOtp(
        phone: _otpRecipient,
        otp: otpDigits,
        isShowLoader: false,
      );
      if (!context.mounted) return;

      if (res == null) {
        AppToast.showError(context, 'Request failed. Please try again.');
        return;
      }

      final message = res.message.trim().isNotEmpty
          ? res.message.trim()
          : 'Something went wrong.';

      if (res.statusCode == 1) {
        final data = res.data;
        if (data != null) {
          await _persistVerifiedSession(data);
        }
        ErrorHandlerUtils.resetSessionState();
        if (!context.mounted) return;
        AppToast.showSuccess(context, message);
        Get.offAllNamed(
          Routes.UPDATE_PROFILE,
          arguments: <String, dynamic>{
            'isComeFromOtpScreen': true,
          },
        );
      } else {
        AppToast.showError(context, message);
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, e.toString());
      }
    } finally {
      setContinueLoading(false);
    }
  }

  @override
  void onClose() {
    phoneNumberController.dispose();
    emailController.dispose();
    for (final otpController in otpControllers) {
      otpController.dispose();
    }
    for (final otpFocusNode in otpFocusNodes) {
      otpFocusNode.dispose();
    }
    super.onClose();
  }
}
