import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/generated/locales.g.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/common_country_code_picker.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/app_widgets/glossy_auth_field_border.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/validations/text_field_validations.dart';

import '../controllers/auth_verify_account_controller.dart';

class AuthVerifyAccountView extends GetView<AuthVerifyAccountController> {
  const AuthVerifyAccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => controller.handleBackAction(),
      child: Obx(
        () => controller.isOtpView.value
            ? _buildOtpVerificationScaffold(context)
            : _buildPhoneEmailVerificationScaffold(context),
      ),
    );
  }

  /// Original white layout + [CommonAppBarWidget] — OTP step only (unchanged UX).
  Widget _buildOtpVerificationScaffold(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: kColorLavenderBg,
        resizeToAvoidBottomInset: true,
        appBar: CommonAppBarWidget(
          title: '',
          showBackButton: true,
          useGradientStyle: false,
          onBackPressed: () {
            if (controller.handleBackAction()) {
              Get.back();
            }
          },
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    Spacing.v24,
                    otpVerificationHeader(),
                    Spacing.v28,
                    otpVerificationWidget(),
                    Spacing.v28,
                    Obx(
                      () => GestureDetector(
                        onTap: controller.canResendOtp
                            ? () => controller.onResendCodePressed(context)
                            : null,
                        child: SemiBoldText(
                          text: controller.canResendOtp
                              ? LocaleKeys.resendCode.tr
                              : '${LocaleKeys.resendCodeIn.tr} ${controller.otpResendRemainingLabel}',
                          fontSize: TextStyles.k14FontSize,
                          color: controller.canResendOtp
                              ? kColorPrimary
                              : kColorHint,
                        ),
                      ),
                    ),
                    Spacing.v28,
                    Obx(
                      () => appButton(
                        onPressed: () => controller.onContinuePressed(context),
                        buttonText: controller.isContinueLoading.value
                            ? ''
                            : LocaleKeys.continueButton.tr,
                        buttonIcon: controller.isContinueLoading.value
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    kColorWhite,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Figma “Secure your account” layout: purple header + white sheet (phone / email only).
  Widget _buildPhoneEmailVerificationScaffold(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: kColorPrimary,
        resizeToAvoidBottomInset: false,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _verifyPhoneEmailPurpleHeader(context),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: kColorWhite,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                        child: Form(
                          key: controller.formKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: SingleChildScrollView(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                phoneNumberInputWidget(context),
                                // Email OTP entry temporarily disabled — phone only.
                                // Spacing.v24,
                                // _orDividerWithLabel(),
                                // Spacing.v24,
                                // emailFieldWidget(context),
                                Spacing.v32,
                                Obx(
                                  () => appButton(
                                    onPressed: () =>
                                        controller.onContinuePressed(context),
                                    buttonText:
                                        controller.isContinueLoading.value
                                        ? ''
                                        : LocaleKeys.continueButton.tr,
                                    isGradient: false,
                                    buttonColor: kColorPrimary,
                                    buttonIcon:
                                        controller.isContinueLoading.value
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    kColorWhite,
                                                  ),
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _verifyPhoneEmailPurpleHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _verifyPhoneEmailBackPill(context),
          ),
          Spacing.v16,
          BoldText(
            text: LocaleKeys.secureAccountTitle.tr,
            fontSize: TextStyles.k22FontSize,
            color: kColorWhite,
            align: TextAlign.center,
          ),
          Spacing.v12,
          AppText(
            text: LocaleKeys.secureAccountSubtitle.tr,
            fontSize: TextStyles.k14FontSize,
            color: kColorWhite.withValues(alpha: 0.92),
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Dark rounded control + white chevron (Figma); only for phone/email step.
  Widget _verifyPhoneEmailBackPill(BuildContext context) {
    return Material(
      color: kColorBottomNav,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () {
          if (controller.handleBackAction()) {
            Get.back();
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.arrow_back_ios_new, size: 16, color: kColorWhite),
        ),
      ),
    );
  }

  // ignore: unused_element - kept while email OTP contact UI is commented out
  Widget _orDividerWithLabel() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            thickness: 1,
            height: 1,
            color: AppLightUi.borderStrong,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: AppText(
            text: LocaleKeys.verifyContactOr.tr,
            fontSize: TextStyles.k14FontSize,
            color: AppLightUi.subtitle,
          ),
        ),
        Expanded(
          child: Divider(
            thickness: 1,
            height: 1,
            color: AppLightUi.borderStrong,
          ),
        ),
      ],
    );
  }

  Widget phoneNumberInputWidget(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlossyAuthFieldBorder(
          radius: 14,
          child: CommonCountryCodePicker(
            borderColor: Colors.transparent,
            onChanged: controller.onCountryCodeChanged,
          ),
        ),
        Spacing.h8,
        Expanded(
          child: GlossyAuthFieldBorder(
            child: AppTextField(
              controller: controller.phoneNumberController,
              validator: (value) {
                final p = value?.trim() ?? '';
                if (p.length == 10) return null;
                if (p.isEmpty) {
                  return LocaleKeys.verifyEnterPhoneOrEmail.tr;
                }
                return Validate.phone10DigitValidation(context, p);
              },
              hintText: LocaleKeys.verifyPhoneHint.tr,
              borderColor: Colors.transparent,
              fillColor: Colors.transparent,
              hintStyle: TextStyles.kRegularPoppins(
                fontSize: TextStyles.k14FontSize,
                colors: AppLightUi.hint,
              ),
              textInputType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 10,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget emailFieldWidget(BuildContext context) {
    return GlossyAuthFieldBorder(
      child: AppTextField(
        controller: controller.emailController,
        validator: (value) {
          final p = controller.phoneNumberController.text.trim();
          final e = value?.trim() ?? '';
          if (p.length == 10) return null;
          final emailOk =
              e.isNotEmpty && Validate.emailValidation(context, e) == null;
          if (emailOk) return null;
          if (p.isEmpty && e.isEmpty) return null;
          return Validate.emailValidation(context, e);
        },
        hintText: LocaleKeys.loginEmailHint.tr,
        borderColor: Colors.transparent,
        fillColor: Colors.transparent,
        hintStyle: TextStyles.kRegularPoppins(
          fontSize: TextStyles.k14FontSize,
          colors: AppLightUi.hint,
        ),
        textInputType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        textCapitalization: TextCapitalization.none,
        prefix: Padding(
          padding: const EdgeInsets.only(left: 14, right: 12),
          child: SvgPicture.asset(
            kIconMail,
            colorFilter: ColorFilter.mode(
              AppLightUi.violet.withValues(alpha: 0.85),
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }

  Widget otpVerificationHeader() {
    return Column(
      children: [
        BoldText(
          text: LocaleKeys.otpVerificationTitle.tr,
          fontSize: TextStyles.k20FontSize,
          color: AppLightUi.title,
        ),
        Spacing.v4,
        AppText(
          text: LocaleKeys.otpVerificationSubTitle.tr,
          fontSize: TextStyles.k12FontSize,
          color: AppLightUi.subtitle,
          align: TextAlign.center,
        ),
      ],
    );
  }

  Widget otpVerificationWidget() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            4,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: GlossyAuthFieldBorder(
                radius: 12,
                borderWidth: 1.4,
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: TextField(
                    controller: controller.otpControllers[index],
                    focusNode: controller.otpFocusNodes[index],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: false,
                      signed: false,
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyles.kSemiBoldPoppins(
                      fontSize: TextStyles.k18FontSize,
                      colors: AppLightUi.title,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 1,
                    onChanged: (value) {
                      controller.onOtpChanged(index: index, value: value);
                    },
                    decoration: const InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if ((controller.otpError.value ?? '').isNotEmpty) ...[
          Spacing.v8,
          AppText(
            text: controller.otpError.value ?? '',
            fontSize: TextStyles.k12FontSize,
            color: kColorRed,
            align: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
