import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/auth/auth_route_arguments.dart';
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
  bool isComeFromForgotPassword = false;

  /// Phone or email string last used with OTP APIs (must match `verify-otp`).
  String _otpRecipient = '';
  String _otpPhone = '';
  String _otpEmail = '';
  bool _otpSentToPhone = true;
  String? _referralCode;
  static const int _otpResendSeconds = 120;
  final otpResendRemainingSeconds = 0.obs;
  Timer? _otpResendTimer;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      if (args[AuthVerifyAccountArgs.isComeFromForgotPassword] == true) {
        isComeFromForgotPassword = true;
      }
      final ref = args[AuthVerifyAccountArgs.referralCode]?.toString().trim();
      if (ref != null && ref.isNotEmpty) {
        _referralCode = ref.toUpperCase();
      }
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
    _otpPhone = '';
    _otpEmail = '';
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

  void onOtpChanged({required int index, required String value}) {
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
    // Email OTP contact path temporarily disabled — phone only.
    // final e = emailController.text.trim();
    final phoneOk = p.length == 10;
    // final emailOk =
    //     e.isNotEmpty && Validate.emailValidation(context, e) == null;
    // return phoneOk || emailOk;
    return phoneOk;
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

    if (isComeFromForgotPassword) {
      if (!_validateForgotPasswordContact(context)) return;
      await _submitForgotPasswordSend(context);
      return;
    }

    if (!validateContactStep(context)) return;

    // Both channels valid: user must pick phone vs email before we hit the API.
    // Email field is temporarily hidden — skip destination picker.
    // if (_hasBothPhoneAndEmailFilled(context)) {
    //   _showOtpDestinationDialog(context);
    //   return;
    // }

    await _submitLoginPhoneOtp(context);
  }

  /// True when the user entered a full 10-digit phone **and** a syntactically valid email.
  // ignore: unused_element - kept while email OTP contact UI is commented out
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
  // ignore: unused_element - kept while email OTP contact UI is commented out
  Future<void> _showOtpDestinationDialog(BuildContext context) {
    return CommonAppDialog.show(
      context,
      title: LocaleKeys.verifyOtpChoiceTitle.tr,
      actions: [
        CommonAppDialogAction(
          label: LocaleKeys.sendOtpOnPhone.tr,
          isPrimary: true,
          onPressed: () =>
              _scheduleOtpSubmitAfterDialogClosed(context, sendToPhone: true),
        ),
        CommonAppDialogAction(
          label: LocaleKeys.sendOtpOnMail.tr,
          isPrimary: true,
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

  /// Forgot-password flow: API only accepts a 10-digit local [phone] in the body.
  bool _validateForgotPasswordContact(BuildContext context) {
    final state = formKey.currentState;
    if (state == null || !state.validate()) return false;
    final p = phoneNumberController.text.trim();
    if (!RegExp(r'^\d{10}$').hasMatch(p)) {
      AppToast.showError(context, LocaleKeys.forgotPasswordPhoneRequired.tr);
      return false;
    }
    return true;
  }

  Future<void> _submitForgotPasswordSend(BuildContext context) async {
    final p = phoneNumberController.text.trim();

    try {
      setContinueLoading(true);
      final res = await _authRepo.forgotPasswordSendOtp(
        phone: p,
        isShowLoader: false,
      );
      if (!context.mounted) return;

      if (res == null) {
        AppToast.showError(context, 'Request failed. Please try again.');
        return;
      }

      if (res.isSuccess) {
        _otpRecipient = p;
        _otpPhone = p;
        _otpEmail = '';
        _otpSentToPhone = true;
        AppToast.showSuccess(context, res.message);
        showOtpView();
      } else {
        AppToast.showError(context, res.message);
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, e.toString());
      }
    } finally {
      setContinueLoading(false);
    }
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
        phone: usePhone ? p : '',
        countryCode: usePhone ? selectedDialCode.value : '',
        email: usePhone ? '' : e,
        isShowLoader: false,
      );
      if (!context.mounted) return;

      if (res == null) {
        AppToast.showError(context, 'Request failed. Please try again.');
        return;
      }

      var message = res.message.trim().isNotEmpty
          ? res.message.trim()
          : 'Something went wrong.';

      if (res.statusCode == 1) {
        _otpRecipient = usePhone ? p : e;
        _otpPhone = usePhone ? p : '';
        _otpEmail = usePhone ? '' : e;
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

      if (isComeFromForgotPassword) {
        final res = await _authRepo.forgotPasswordSendOtp(
          phone: _otpRecipient,
          isShowLoader: false,
        );
        if (!context.mounted) return;

        if (res == null) {
          AppToast.showError(context, 'Request failed. Please try again.');
          return;
        }

        if (res.isSuccess) {
          _clearOtpFields();
          _startOtpResendTimer();
          AppToast.showSuccess(context, res.message);
        } else {
          AppToast.showError(context, res.message);
        }
        return;
      }

      final res = await _authRepo.loginWithOtp(
        phone: _otpPhone,
        countryCode: _otpSentToPhone ? selectedDialCode.value : '',
        email: _otpEmail,
        isShowLoader: false,
      );
      if (!context.mounted) return;

      if (res == null) {
        AppToast.showError(context, 'Request failed. Please try again.');
        return;
      }

      var message = res.message.trim().isNotEmpty
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

    final otpDigits = otpControllers.map((c) => c.text).join();

    try {
      setContinueLoading(true);
      var res = await _authRepo.verifyOtp(
        phone: _otpPhone,
        email: _otpEmail,
        otp: otpDigits,
        referralCode: _referralCode,
        isShowLoader: false,
      );
      if (!context.mounted) return;

      if (res == null) {
        AppToast.showError(context, 'Request failed. Please try again.');
        return;
      }

      var message = res.message.trim().isNotEmpty
          ? res.message.trim()
          : 'Something went wrong.';

      if (!isComeFromForgotPassword && res.statusCode == 2) {
        final confirmed = await CommonAppDialog.confirm(
          context: context,
          title: 'Already Logged In',
          message: message,
          icon: Icons.phonelink_lock_rounded,
          iconAccent: const Color(0xFFFFA53D),
          cancelLabel: 'Cancel',
          confirmLabel: 'Log In Here',
          barrierDismissible: false,
        );
        if (!context.mounted || confirmed != true) return;
        res = await _authRepo.verifyOtp(
          phone: _otpPhone,
          email: _otpEmail,
          otp: otpDigits,
          referralCode: _referralCode,
          isShowLoader: false,
          forceLogin: true,
        );
        if (!context.mounted) return;
        if (res == null) {
          AppToast.showError(context, 'Request failed. Please try again.');
          return;
        }
        message = res.message.trim().isNotEmpty
            ? res.message.trim()
            : 'Something went wrong.';
      }

      if (res.statusCode == 1) {
        final data = res.data;
        if (data == null) {
          AppToast.showError(context, message);
          return;
        }

        // Forgot password: same `verify-otp` as other flows; do not persist session.
        // Pass [otpDigits] to the reset screen for `POST /api/auth/reset-password`.
        if (isComeFromForgotPassword) {
          if (!context.mounted) return;
          AppToast.showSuccess(context, message);
          Get.offNamed(
            Routes.AUTH_NEW_PASSWORD,
            arguments: <String, dynamic>{
              AuthNewPasswordArgs.phone: _otpRecipient,
              AuthNewPasswordArgs.otp: otpDigits,
            },
          );
          return;
        }

        await _persistVerifiedSession(data);
        ErrorHandlerUtils.resetSessionState();
        if (!context.mounted) return;

        Get.toNamed(
          Routes.UPDATE_PROFILE,
          arguments: <String, dynamic>{
            'isComeFromOtpScreen': true,
            if (!_otpSentToPhone && _otpRecipient.trim().isNotEmpty)
              'email': _otpRecipient.trim(),
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
