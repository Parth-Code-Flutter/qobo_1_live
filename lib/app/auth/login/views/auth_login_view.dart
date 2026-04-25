import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/generated/locales.g.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import 'package:get/get.dart';

import '../controllers/auth_login_controller.dart';

class AuthLoginView extends GetView<AuthLoginController> {
  const AuthLoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorWhite,
      // appBar: CommonAppBarWidget(title: '', showBackButton: false),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            welcomeTextHeader(),
            Spacing.v24,
            emailPasswordTextFields(),
            Spacing.v28,
            appButton(
              onPressed: () {},
              buttonText: LocaleKeys.loginButtonText.tr,
            ),
            Spacing.v20,
            orLoginWithDividerWidget(),
            Spacing.v20,
            socialMediaLogin(),
            Spacing.v28,
            signUpFooterWidget(),
          ],
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

  Widget emailPasswordTextFields() {
    return Column(
      children: [
        AppTextField(
          controller: controller.emailController,
          hintText: LocaleKeys.loginEmailHint.tr,
          borderColor: kColorHint,
          hintStyle: TextStyles.kRegularPoppins(
            fontSize: TextStyles.k14FontSize,
            colors: kColorHint,
          ),
          textInputType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.none,
          prefix: Padding(
            padding: const EdgeInsets.only(left: 14, right: 12),
            child: SvgPicture.asset(
              kIconMail,
              colorFilter: const ColorFilter.mode(kColorHint, BlendMode.srcIn),
            ),
          ),
        ),
        Spacing.v10,
        Obx(
          () => AppTextField(
            controller: controller.passwordController,
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
      children: [
        _socialLoginButton(
          iconPath: kIconFB,
          title: LocaleKeys.loginWithApple.tr,
          onTap: () {},
        ),
        Spacing.v10,
        _socialLoginButton(
          iconPath: kIconGoogle,
          title: LocaleKeys.loginWithGoogle.tr,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _socialLoginButton({
    required String iconPath,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          color: kColorWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kColorTextFieldBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(iconPath, width: 24, height: 24),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppText(
          text: LocaleKeys.dontHaveAccount.tr,
          fontSize: TextStyles.k14FontSize,
          color: kColorTextGrey,
        ),
        Spacing.h4,
        SemiBoldText(
          text: LocaleKeys.signUp.tr,
          fontSize: TextStyles.k14FontSize,
          color: kColorPrimary,
        ),
      ],
    );
  }
}
