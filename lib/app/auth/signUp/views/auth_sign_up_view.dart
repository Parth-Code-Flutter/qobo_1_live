import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/generated/locales.g.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/app_widgets/glossy_auth_field_border.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/validations/text_field_validations.dart';

import '../controllers/auth_sign_up_controller.dart';

class AuthSignUpView extends GetView<AuthSignUpController> {
  const AuthSignUpView({super.key});

  static const _fieldRadius = BorderRadius.all(Radius.circular(18));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppLightUi.bg,
      resizeToAvoidBottomInset: true,
      appBar: const CommonAppBarWidget(
        title: '',
        showBackButton: true,
        useGradientStyle: false,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: controller.formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: LayoutBuilder(
            builder: (_, constraints) => SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Spacing.v12,
                    signUpHeader(),
                    Spacing.v16,
                    emailUsernamePasswordTextFields(context),
                    Spacing.v10,
                    _referralCodeSection(context),
                    Spacing.v20,
                    Obx(
                      () => Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppLightUi.pink.withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: appButton(
                          onPressed: () =>
                              controller.onSignUpPressed(context),
                          buttonText: controller.isSignUpLoading.value
                              ? ''
                              : LocaleKeys.signUp.tr,
                          isGradient: true,
                          gradientColors: AppLightUi.familyCtaColors,
                          borderRadius: 18,
                          buttonIcon: controller.isSignUpLoading.value
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
                    ),
                    Spacing.v16,
                    orLoginWithDividerWidget(),
                    Spacing.v12,
                    socialMediaLogin(context),
                    Spacing.v12,
                    signInFooterWidget(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget signUpHeader() {
    return Column(
      children: [
        BoldText(
          text: LocaleKeys.signUp.tr,
          fontSize: TextStyles.k20FontSize,
          color: AppLightUi.title,
        ),
        Spacing.v4,
        AppText(
          text: LocaleKeys.loginSubTitle.tr,
          fontSize: TextStyles.k12FontSize,
          color: AppLightUi.subtitle,
        ),
      ],
    );
  }

  Widget emailUsernamePasswordTextFields(BuildContext context) {
    return Column(
      children: [
        GlossyAuthFieldBorder(
          child: AppTextField(
            controller: controller.usernameController,
            validator: (value) =>
                Validate.nameValidation(context, value?.trim() ?? ''),
            hintText: LocaleKeys.signUpUsernameHint.tr,
            borderColor: Colors.transparent,
            fillColor: Colors.transparent,
            inputBorderRadius: _fieldRadius,
            hintStyle: TextStyles.kRegularPoppins(
              fontSize: TextStyles.k14FontSize,
              colors: AppLightUi.hint,
            ),
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.none,
            prefix: Padding(
              padding: const EdgeInsets.only(left: 14, right: 12),
              child: SvgPicture.asset(
                kIconUser,
                colorFilter: ColorFilter.mode(
                  AppLightUi.violet.withValues(alpha: 0.85),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
        Spacing.v10,
        Obx(
          () => GlossyAuthFieldBorder(
            child: AppTextField(
              controller: controller.passwordController,
              validator: (value) =>
                  Validate.passwordValidation(context, value?.trim() ?? ''),
              hintText: LocaleKeys.loginPasswordHint.tr,
              borderColor: Colors.transparent,
              fillColor: Colors.transparent,
              inputBorderRadius: _fieldRadius,
              hintStyle: TextStyles.kRegularPoppins(
                fontSize: TextStyles.k14FontSize,
                colors: AppLightUi.hint,
              ),
              obscureText: controller.isPasswordHidden.value,
              textInputType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.none,
              prefix: Padding(
                padding: const EdgeInsets.only(left: 14, right: 12),
                child: SvgPicture.asset(
                  kIconPassword,
                  colorFilter: ColorFilter.mode(
                    AppLightUi.violet.withValues(alpha: 0.85),
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
                    color: AppLightUi.muted,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _referralCodeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText(
          text: 'Have a referral code? (optional)',
          fontSize: TextStyles.k12FontSize,
          color: AppLightUi.subtitle,
        ),
        Spacing.v8,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GlossyAuthFieldBorder(
                child: AppTextField(
                  controller: controller.referralCodeController,
                  hintText: 'Enter code e.g. QOBO8X9A',
                  borderColor: Colors.transparent,
                  fillColor: Colors.transparent,
                  inputBorderRadius: _fieldRadius,
                  hintStyle: TextStyles.kRegularPoppins(
                    fontSize: TextStyles.k14FontSize,
                    colors: AppLightUi.hint,
                  ),
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 8,
                  prefix: Padding(
                    padding: const EdgeInsets.only(left: 14, right: 10),
                    child: Icon(
                      Icons.card_giftcard_outlined,
                      color: AppLightUi.violet.withValues(alpha: 0.85),
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
            Spacing.h8,
            Obx(
              () => SizedBox(
                height: 52,
                child: TextButton(
                  onPressed: controller.isReferralVerifying.value
                      ? null
                      : () => controller.verifyReferralCode(context),
                  style: TextButton.styleFrom(
                    backgroundColor: controller.isReferralVerified.value
                        ? const Color(0xFF12B845)
                        : kColorPrimary,
                    foregroundColor: kColorWhite,
                    disabledBackgroundColor:
                        AppLightUi.hint.withValues(alpha: 0.35),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: controller.isReferralVerifying.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: kColorWhite,
                          ),
                        )
                      : SemiBoldText(
                          text: controller.isReferralVerified.value
                              ? 'Verified'
                              : 'Verify',
                          fontSize: TextStyles.k12FontSize,
                          color: kColorWhite,
                        ),
                ),
              ),
            ),
          ],
        ),
        Obx(() {
          final message = controller.referralStatusMessage.value;
          if (message == null || message.trim().isEmpty) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: AppText(
              text: message,
              fontSize: TextStyles.k12FontSize,
              color: controller.isReferralVerified.value
                  ? const Color(0xFF12B845)
                  : AppLightUi.subtitle,
            ),
          );
        }),
      ],
    );
  }

  Widget orLoginWithDividerWidget() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            thickness: 1,
            color: AppLightUi.borderStrong.withValues(alpha: 0.7),
          ),
        ),
        Spacing.h8,
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppLightUi.border),
          ),
          child: AppText(
            text: LocaleKeys.orLoginWith.tr,
            fontSize: TextStyles.k10FontSize,
            color: AppLightUi.subtitle,
          ),
        ),
        Spacing.h8,
        Expanded(
          child: Divider(
            thickness: 1,
            color: AppLightUi.borderStrong.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget socialMediaLogin(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(
          () => _socialOutlinedButton(
            iconPath: kIconFB,
            onTap: () => controller.onFacebookSignUpPressed(context),
            iconHeight: 24,
            iconWidth: 24,
            title: LocaleKeys.loginWithFacebookFull.tr,
            isLoading: controller.isFacebookLoginLoading.value,
          ),
        ),
        Spacing.v8,
        Obx(
          () => _socialOutlinedButton(
            iconPath: kIconGoogle,
            onTap: () => controller.onGoogleSignUpPressed(context),
            iconHeight: 22,
            iconWidth: 22,
            title: LocaleKeys.loginWithGoogleFull.tr,
            isLoading: controller.isGoogleLoginLoading.value,
          ),
        ),
      ],
    );
  }

  Widget _socialOutlinedButton({
    required String iconPath,
    required String title,
    required VoidCallback onTap,
    double iconHeight = 24,
    double iconWidth = 24,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppLightUi.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: iconWidth,
                  height: iconHeight,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(kColorPrimary),
                  ),
                )
              else
                SvgPicture.asset(
                  iconPath,
                  fit: BoxFit.contain,
                  height: iconHeight,
                  width: iconWidth,
                ),
              Spacing.h10,
              SemiBoldText(
                text: isLoading ? '' : title,
                fontSize: TextStyles.k12FontSize,
                color: AppLightUi.title,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget signInFooterWidget() {
    return GestureDetector(
      onTap: Get.back,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText(
              text: LocaleKeys.haveAccount.tr,
              fontSize: TextStyles.k12FontSize,
              color: AppLightUi.subtitle,
            ),
            Spacing.h4,
            SemiBoldText(
              text: LocaleKeys.signIn.tr,
              fontSize: TextStyles.k12FontSize,
              color: kColorPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
