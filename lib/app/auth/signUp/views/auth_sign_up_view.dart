import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/generated/locales.g.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/auth_sign_up_controller.dart';

class AuthSignUpView extends GetView<AuthSignUpController> {
  const AuthSignUpView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorWhite,
      appBar: CommonAppBarWidget(title: '', showBackButton: true),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Spacing.v24,
            signUpHeader(),
            Spacing.v24,
            emailUsernamePasswordTextFields(),
            Spacing.v28,
            appButton(
              onPressed: () => Get.toNamed(Routes.AUTH_VERIFY_ACCOUNT),
              buttonText: LocaleKeys.signUp.tr,
            ),
            Spacing.v20,
            orLoginWithDividerWidget(),
            Spacing.v16,
            socialMediaLogin(),
            Spacer(),
            signInFooterWidget(),
            Spacing.v28,
          ],
        ),
      ),
    );
  }

  Widget signUpHeader() {
    return Column(
      children: [
        BoldText(
          text: LocaleKeys.signUp.tr,
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

  Widget emailUsernamePasswordTextFields() {
    return Column(
      children: [
        AppTextField(
          controller: controller.usernameController,
          hintText: LocaleKeys.signUpUsernameHint.tr,
          borderColor: kColorHint,
          hintStyle: TextStyles.kRegularPoppins(
            fontSize: TextStyles.k14FontSize,
            colors: kColorHint,
          ),
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.none,
          prefix: Padding(
            padding: const EdgeInsets.only(left: 14, right: 12),
            child: SvgPicture.asset(
              kIconUser,
              colorFilter: const ColorFilter.mode(kColorHint, BlendMode.srcIn),
            ),
          ),
        ),
        Spacing.v10,
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
          title: LocaleKeys.signUpWithApple.tr,
          onTap: () {},
        ),
        Spacing.v10,
        _socialLoginButton(
          iconPath: kIconGoogle,
          title: LocaleKeys.signUpWithGoogle.tr,
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
            Spacing.h4,
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

  Widget signInFooterWidget() {
    return GestureDetector(
      onTap: Get.back,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppText(
            text: LocaleKeys.haveAccount.tr,
            fontSize: TextStyles.k14FontSize,
            color: kColorTextGrey,
          ),
          Spacing.h4,
          SemiBoldText(
            text: LocaleKeys.signIn.tr,
            fontSize: TextStyles.k14FontSize,
            color: kColorPrimary,
          ),
        ],
      ),
    );
  }
}
