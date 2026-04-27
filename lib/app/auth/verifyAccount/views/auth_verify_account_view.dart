import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/generated/locales.g.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
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
      child: Scaffold(
        backgroundColor: kColorWhite,
        appBar: CommonAppBarWidget(
          title: '',
          showBackButton: true,
          onBackPressed: () {
            if (controller.handleBackAction()) {
              Get.back();
            }
          },
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: controller.formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Obx(
              () => Column(
                children: [
                  Spacing.v24,
                  controller.isOtpView.value
                      ? otpVerificationHeader()
                      : verifyAccountHeader(),
                  Spacing.v28,
                  controller.isOtpView.value
                      ? otpVerificationWidget()
                      : phoneNumberInputWidget(context),
                  Spacing.v28,
                  if (controller.isOtpView.value) ...[
                    SemiBoldText(
                      text: LocaleKeys.resendCode.tr,
                      fontSize: TextStyles.k14FontSize,
                      color: kColorPrimary,
                    ),
                    Spacing.v28,
                  ],
                  appButton(
                    onPressed: () {
                      if (controller.isOtpView.value) {
                        if (controller.validateOtp(context)) {}
                        return;
                      }
                      if (controller.validatePhoneForm()) {
                        controller.showOtpView();
                      }
                    },
                    buttonText: LocaleKeys.continueButton.tr,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget verifyAccountHeader() {
    return Column(
      children: [
        BoldText(
          text: LocaleKeys.verifyAccountTitle.tr,
          fontSize: TextStyles.k22FontSize,
          color: kColorText,
        ),
        Spacing.v2,
        AppText(
          text: LocaleKeys.verifyAccountSubTitle.tr,
          fontSize: TextStyles.k14FontSize,
          color: kColorTextGrey,
          align: TextAlign.center,
        ),
      ],
    );
  }

  Widget phoneNumberInputWidget(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 50,
          width: 88,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: kColorWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kColorTextFieldBorder),
          ),
          child: SizedBox(
            height: 56,
            child: Center(
              child: CountryCodePicker(
                initialSelection: 'IN',
                favorite: const ['+91', 'IN'],
                showCountryOnly: false,
                showOnlyCountryWhenClosed: false,
                showFlag: false,
                showDropDownButton: true,
                alignLeft: false,
                padding: EdgeInsets.zero,
                textStyle: TextStyles.kRegularPoppins(
                  fontSize: TextStyles.k14FontSize,
                  colors: kColorText,
                ),
                onChanged: (countryCode) {
                  controller.onCountryCodeChanged(countryCode.dialCode ?? '+91');
                },
              ),
            ),
          ),
        ),
        Spacing.h8,
        Expanded(
          child: AppTextField(
            controller: controller.phoneNumberController,
            validator: (value) =>
                Validate.phone10DigitValidation(context, value?.trim() ?? ''),
            hintText: LocaleKeys.verifyPhoneHint.tr,
            borderColor: kColorTextFieldBorder,
            hintStyle: TextStyles.kRegularPoppins(
              fontSize: TextStyles.k14FontSize,
              colors: kColorHint,
            ),
            textInputType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 10,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.none,
          ),
        ),
      ],
    );
  }

  Widget otpVerificationHeader() {
    return Column(
      children: [
        BoldText(
          text: LocaleKeys.otpVerificationTitle.tr,
          fontSize: TextStyles.k22FontSize,
          color: kColorText,
        ),
        Spacing.v2,
        AppText(
          text: LocaleKeys.otpVerificationSubTitle.tr,
          fontSize: TextStyles.k14FontSize,
          color: kColorTextGrey,
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
              child: SizedBox(
                width: 42,
                height: 42,
                child: TextField(
                  controller: controller.otpControllers[index],
                  focusNode: controller.otpFocusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyles.kSemiBoldPoppins(
                    fontSize: TextStyles.k24FontSize,
                    colors: kColorText,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 1,
                  onChanged: (value) {
                    controller.onOtpChanged(index: index, value: value);
                  },
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: kColorWhite,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: kColorTextFieldBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: kColorPrimary),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if ((controller.otpError.value ?? '').isNotEmpty) ...[
          Spacing.v8,
          Align(
            alignment: Alignment.centerLeft,
            child: AppText(
              text: controller.otpError.value ?? '',
              fontSize: TextStyles.k12FontSize,
              color: kColorRed,
            ),
          ),
        ],
      ],
    );
  }
}
