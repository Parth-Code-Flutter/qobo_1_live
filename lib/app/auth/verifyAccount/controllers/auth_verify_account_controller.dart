import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/local_storage_constants.dart';
import 'package:qobo_one_live/generated/locales.g.dart';
import 'package:qobo_one_live/repo/auth/auth_repo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/utils/error_handler_utils.dart';
import 'package:qobo_one_live/utils/local_storage/controllers/local_storage_controller.dart';
import 'package:qobo_one_live/utils/app_dialogs/common_app_dialog.dart';
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
  final isResendLoading = false.obs;
  final otpError = RxnString();
  final otpControllers = List.generate(4, (_) => TextEditingController());
  final otpFocusNodes = List.generate(4, (_) => FocusNode());
  bool isFromLoginWithOtp = false;

  /// Phone or email string last used with `login-phone` (must match `verify-otp`).
  String _otpRecipient = '';
  bool _otpSentToPhone = true;
  static const int _otpResendSeconds = 120;
  final otpResendRemainingSeconds = 0.obs;
  Timer? _otpResendTimer;

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
    _startOtpResendTimer();
  }

  void showPhoneNumberView() {
    isOtpView.value = false;
    _otpRecipient = '';
    _otpSentToPhone = true;
    _cancelOtpResendTimer();
  }

  bool get canResendOtp =>
      otpResendRemainingSeconds.value == 0 && !isResendLoading.value;

  String get otpResendRemainingLabel {
    final mins = otpResendRemainingSeconds.value ~/ 60;
    final secs = otpResendRemainingSeconds.value % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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

    if (!validateContactStep(context)) return;

    // Both channels valid: user must pick phone vs email before we hit the API.
    if (_hasBothPhoneAndEmailFilled(context)) {
      _showOtpDestinationDialog(context);
      return;
    }

    await _submitLoginPhoneOtp(context);
  }

  /// True when the user entered a full 10-digit phone **and** a syntactically valid email.
  bool _hasBothPhoneAndEmailFilled(BuildContext context) {
    final p = phoneNumberController.text.trim();
    final e = emailController.text.trim();
    final phoneReady = p.length == 10;
    final emailReady =
        e.isNotEmpty && Validate.emailValidation(context, e) == null;
    return phoneReady && emailReady;
  }

  /// Shown only when both a 10-digit phone and a valid email are present.
  /// Uses [CommonAppDialog]; closes the route first, then runs the same OTP request as Continue.
  Future<void> _showOtpDestinationDialog(BuildContext context) {
    return CommonAppDialog.show(
      context,
      title: LocaleKeys.verifyOtpChoiceTitle.tr,
      actions: [
        CommonAppDialogAction(
          label: LocaleKeys.sendOtpOnPhone.tr,
          onPressed: () =>
              _scheduleOtpSubmitAfterDialogClosed(context, sendToPhone: true),
        ),
        CommonAppDialogAction(
          label: LocaleKeys.sendOtpOnMail.tr,
          onPressed: () =>
              _scheduleOtpSubmitAfterDialogClosed(context, sendToPhone: false),
        ),
      ],
    );
  }

  /// Runs after the dialog is popped so loading / toasts attach to the verify screen.
  void _scheduleOtpSubmitAfterDialogClosed(
    BuildContext context, {
    required bool sendToPhone,
  }) {
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      await _submitLoginPhoneOtp(context, sendOtpToPhone: sendToPhone);
    });
  }

  /// Sends OTP via `login-phone`. When [sendOtpToPhone] is null, phone is used if 10 digits exist, otherwise email.
  Future<void> _submitLoginPhoneOtp(
    BuildContext context, {
    bool? sendOtpToPhone,
  }) async {
    if (!validateContactStep(context)) return;

    final p = phoneNumberController.text.trim();
    final e = emailController.text.trim();
    final usePhone = sendOtpToPhone ?? (p.length == 10);

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
        _otpSentToPhone = usePhone;
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

  /// Resend OTP from OTP step using the same recipient/channel selected earlier.
  Future<void> onResendCodePressed(BuildContext context) async {
    if (!canResendOtp) return;
    if (_otpRecipient.trim().isEmpty) {
      AppToast.showError(context, LocaleKeys.resendUnavailableError.tr);
      return;
    }

    try {
      isResendLoading.value = true;
      final res = await _authRepo.loginWithOtp(
        phone: _otpRecipient,
        countryCode: _otpSentToPhone ? selectedDialCode.value : '',
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
        // New OTP has been issued; restart cooldown and clear old typed digits.
        _clearOtpFields();
        _startOtpResendTimer();
        AppToast.showSuccess(context, message);
      } else {
        AppToast.showError(context, message);
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, e.toString());
      }
    } finally {
      isResendLoading.value = false;
    }
  }

  /// Starts a fresh 2-minute countdown before resend is enabled.
  void _startOtpResendTimer() {
    _cancelOtpResendTimer();
    otpResendRemainingSeconds.value = _otpResendSeconds;
    _otpResendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = otpResendRemainingSeconds.value - 1;
      if (next <= 0) {
        otpResendRemainingSeconds.value = 0;
        timer.cancel();
      } else {
        otpResendRemainingSeconds.value = next;
      }
    });
  }

  void _cancelOtpResendTimer() {
    _otpResendTimer?.cancel();
    _otpResendTimer = null;
    otpResendRemainingSeconds.value = 0;
  }

  void _clearOtpFields() {
    for (final controller in otpControllers) {
      controller.clear();
    }
    otpError.value = null;
    if (otpFocusNodes.isNotEmpty) {
      otpFocusNodes.first.requestFocus();
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
        Get.toNamed(
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
    _cancelOtpResendTimer();
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
