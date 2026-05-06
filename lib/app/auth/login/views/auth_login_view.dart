import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/generated/locales.g.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/app_widgets/common_country_code_picker.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/validations/text_field_validations.dart';

import 'package:get/get.dart';

import '../controllers/auth_login_controller.dart';

class AuthLoginView extends GetView<AuthLoginController> {
  const AuthLoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorWhite,
      resizeToAvoidBottomInset: true,
      appBar: CommonAppBarWidget(title: '', showBackButton: false),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: controller.formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    welcomeTextHeader(),
                    Spacing.v24,
                    emailPasswordTextFields(context),
                    Spacing.v20,
                    Obx(
                      () => appButton(
                        onPressed: () => controller.onLoginPressed(context),
                        buttonText: controller.isLoginLoading.value
                            ? ''
                            : LocaleKeys.loginButtonText.tr,
                        buttonIcon: controller.isLoginLoading.value
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
                    Spacing.v20,
                    orLoginWithDividerWidget(),
                    Spacing.v20,
                    socialMediaLogin(),
                    const SizedBox(height: 20),
                    signUpFooterWidget(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget welcomeTextHeader() {
    return Column(
      children: [
        Spacing.v12,
        Image.asset(kIconApp, width: 86, height: 86, fit: BoxFit.contain),
        Spacing.v20,
        BoldText(
          text: LocaleKeys.loginWelcomeTitle.tr,
          fontSize: TextStyles.k22FontSize,
          color: kColorText,
        ),
        Spacing.v2,
        AppText(
          text: LocaleKeys.loginSubTitle.tr,
          fontSize: TextStyles.k14FontSize,
          color: kColorTextGrey,
        ),
      ],
    );
  }

  Widget emailPasswordTextFields(BuildContext context) {
    return Column(
      children: [
        Obx(
          () => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (controller.isPhoneInput.value) ...[
                CommonCountryCodePicker(
                  borderColor: kColorHint,
                  onChanged: controller.onCountryCodeChanged,
                ),
                Spacing.h8,
              ],
              Expanded(
                child: AppTextField(
                  controller: controller.emailController,
                  onChanged: controller.onUsernameChanged,
                  validator: (value) => controller.validateUsername(context, value),
                  hintText: LocaleKeys.loginEmailOrPhoneHint.tr,
                  borderColor: kColorHint,
                  hintStyle: TextStyles.kRegularPoppins(
                    fontSize: TextStyles.k14FontSize,
                    colors: kColorHint,
                  ),
                  textInputType: controller.isPhoneInput.value
                      ? TextInputType.phone
                      : TextInputType.emailAddress,
                  inputFormatters: controller.isPhoneInput.value
                      ? [FilteringTextInputFormatter.digitsOnly]
                      : null,
                  maxLength: controller.isPhoneInput.value ? 10 : null,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.none,
                  prefix: Padding(
                    padding: const EdgeInsets.only(left: 14, right: 12),
                    child: SvgPicture.asset(
                      kIconMail,
                      colorFilter: const ColorFilter.mode(
                        kColorHint,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Spacing.v10,
        Obx(
          () => AppTextField(
            controller: controller.passwordController,
            validator: (value) =>
                Validate.passwordValidation(context, value?.trim() ?? ''),
            hintText: LocaleKeys.loginPasswordHint.tr,
            borderColor: kColorHint,
            hintStyle: TextStyles.kRegularPoppins(
              fontSize: TextStyles.k14FontSize,
              colors: kColorHint,
            ),
            obscureText: controller.isPasswordHidden.value,
            textInputType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.none,
            prefix: Padding(
              padding: const EdgeInsets.only(left: 14, right: 12),
              child: SvgPicture.asset(
                kIconPassword,

                colorFilter: const ColorFilter.mode(
                  kColorHint,
                  BlendMode.srcIn,
                ),
              ),
            ),
            suffix: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: GestureDetector(
                onTap: controller.togglePasswordVisibility,
                child: Icon(
                  controller.isPasswordHidden.value
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: kColorHint,
                  size: 16,
                ),
              ),
            ),
          ),
        ),
        Spacing.v8,
        Align(
          alignment: Alignment.centerRight,
          child: SemiBoldText(
            text: LocaleKeys.forgotPassword.tr,
            fontSize: TextStyles.k14FontSize,
            color: kColorPrimary,
          ),
        ),
      ],
    );
  }

  Widget orLoginWithDividerWidget() {
    return Row(
      children: [
        const Expanded(
          child: Divider(thickness: 1, color: kColorTextFieldBorder),
        ),
        Spacing.h4,
        AppText(
          text: LocaleKeys.orLoginWith.tr,
          fontSize: TextStyles.k14FontSize,
          color: kColorTextGrey,
        ),
        Spacing.h4,
        const Expanded(
          child: Divider(thickness: 1, color: kColorTextFieldBorder),
        ),
      ],
    );
  }

  Widget socialMediaLogin() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _socialOutlinedButton(
          iconPath: kIconFB,
          onTap: () {},
          iconHeight: 28,
          iconWidth: 28,
          title: LocaleKeys.loginWithFacebookFull.tr,
        ),
        Spacing.v12,
        _socialOutlinedButton(
          iconPath: kIconGoogle,
          onTap: () {},
          iconHeight: 25,
          iconWidth: 25,
          title: LocaleKeys.loginWithGoogleFull.tr,
        ),
        Spacing.v12,
        _socialOutlinedButton(
          iconPath: kIconLock,
          onTap: () => Get.toNamed(
            Routes.AUTH_VERIFY_ACCOUNT,
            arguments: {'isFromLoginWithOtp': true},
          ),
          iconHeight: 25,
          iconWidth: 25,
          tintIcon: true,
          title: LocaleKeys.loginWithOtp.tr,
        ),
      ],
    );
  }

  Widget _socialOutlinedButton({
    required String iconPath,
    required String title,
    required VoidCallback onTap,
    double iconHeight = 28,
    double iconWidth = 28,
    bool tintIcon = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: kColorWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kColorTextFieldBorder, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconPath,
              fit: BoxFit.contain,
              height: iconHeight,
              width: iconWidth,
            ),
            Spacing.h10,
            SemiBoldText(
              text: title,
              fontSize: TextStyles.k14FontSize,
              color: kColorText,
            ),
          ],
        ),
      ),
    );
  }

  Widget signUpFooterWidget() {
    return GestureDetector(
      onTap: () => Get.toNamed(Routes.AUTH_SIGN_UP),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppText(
            text: LocaleKeys.dontHaveAccount.tr,
            fontSize: TextStyles.k12FontSize,
            color: kColorTextGrey,
          ),
          Spacing.h4,
          SemiBoldText(
            text: LocaleKeys.signUp.tr,
            fontSize: TextStyles.k12FontSize,
            color: kColorPrimary,
          ),
        ],
      ),
    );
  }

}
