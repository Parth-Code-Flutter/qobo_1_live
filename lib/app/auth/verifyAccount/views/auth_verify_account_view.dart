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

  /// OTP step — light dating canvas + [CommonAppBarWidget].
  Widget _buildOtpVerificationScaffold(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppLightUi.bg,
        resizeToAvoidBottomInset: true,
        appBar: CommonAppBarWidget(
          title: LocaleKeys.otpVerificationTitle.tr,
          showBackButton: true,
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

  /// Phone / email contact step — same light canvas as login & signup.
  Widget _buildPhoneEmailVerificationScaffold(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppLightUi.bg,
        resizeToAvoidBottomInset: true,
        appBar: CommonAppBarWidget(
          title: LocaleKeys.secureAccountTitle.tr,
          showBackButton: true,
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
                child: Form(
                  key: controller.formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Spacing.v16,
                      _secureAccountHeader(),
                      Spacing.v28,
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
                          buttonText: controller.isContinueLoading.value
                              ? ''
                              : LocaleKeys.continueButton.tr,
                          buttonIcon: controller.isContinueLoading.value
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
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
      ),
    );
  }

  Widget _secureAccountHeader() {
    return AppText(
      text: LocaleKeys.secureAccountSubtitle.tr,
      fontSize: TextStyles.k12FontSize,
      color: AppLightUi.subtitle,
      align: TextAlign.center,
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
          child: AppTextField(
            controller: controller.phoneNumberController,
            glossyBorder: true,
            validator: (value) {
              final p = value?.trim() ?? '';
              if (p.length == 10) return null;
              if (p.isEmpty) {
                return LocaleKeys.verifyEnterPhoneOrEmail.tr;
              }
              return Validate.phone10DigitValidation(context, p);
            },
            hintText: LocaleKeys.verifyPhoneHint.tr,
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
      ],
    );
  }

  Widget emailFieldWidget(BuildContext context) {
    return AppTextField(
      controller: controller.emailController,
      glossyBorder: true,
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
    );
  }

  Widget otpVerificationHeader() {
    return AppText(
      text: LocaleKeys.otpVerificationSubTitle.tr,
      fontSize: TextStyles.k12FontSize,
      color: AppLightUi.subtitle,
      align: TextAlign.center,
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
