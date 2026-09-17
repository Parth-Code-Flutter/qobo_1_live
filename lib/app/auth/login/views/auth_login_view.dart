import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/auth/auth_route_arguments.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
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
import 'package:qobo_one_live/utils/validations/text_field_validations.dart';

import '../controllers/auth_login_controller.dart';

class AuthLoginView extends StatefulWidget {
  const AuthLoginView({super.key});

  @override
  State<AuthLoginView> createState() => _AuthLoginViewState();
}

class _AuthLoginViewState extends State<AuthLoginView> {
  // Navigation transitions can keep two login pages alive at once. Each page
  // must own its form key and text controllers until that page is disposed.
  final controller = AuthLoginController();

  static const _fieldRadius = BorderRadius.all(Radius.circular(18));

  @override
  void dispose() {
    controller.onClose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppLightUi.bg,
      resizeToAvoidBottomInset: true,
      appBar: const CommonAppBarWidget(
        title: '',
        showBackButton: false,
        useGradientStyle: false,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            _ambientBackdrop(),
            Form(
              key: controller.formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: LayoutBuilder(
                builder: (_, constraints) => SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        welcomeTextHeader(),
                        Spacing.v12,
                        emailPasswordTextFields(context),
                        Spacing.v12,
                        _loginCta(context),
                        Spacing.v12,
                        orLoginWithDividerWidget(),
                        Spacing.v12,
                        socialMediaLogin(context),
                        Spacing.v12,
                        signUpFooterWidget(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ambientBackdrop() {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            bottom: 80,
            left: -70,
            child: _glowBlob(
              size: 160,
              color: AppLightUi.violet.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            bottom: 20,
            right: -50,
            child: _glowBlob(
              size: 140,
              color: AppLightUi.pink.withValues(alpha: 0.07),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowBlob({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }

  Widget welcomeTextHeader() {
    return Column(
      children: [
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: AppLightUi.border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppLightUi.title.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Image.asset(
            kIconApp,
            width: 50,
            height: 50,
            fit: BoxFit.contain,
          ),
        ),
        Spacing.v10,
        BoldText(
          text: LocaleKeys.loginWelcomeTitle.tr,
          fontSize: TextStyles.k18FontSize,
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

  Widget emailPasswordTextFields(BuildContext context) {
    return Column(
      children: [
        Obx(
          () => AppTextField(
            controller: controller.emailController,
            onChanged: controller.onUsernameChanged,
            validator: (value) => controller.validateUsername(context, value),
            hintText: LocaleKeys.loginEmailOrPhoneHint.tr,
            glossyBorder: true,
            fillColor: Colors.transparent,
            inputBorderRadius: _fieldRadius,
            hintStyle: TextStyles.kRegularPoppins(
              fontSize: TextStyles.k14FontSize,
              colors: AppLightUi.hint,
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
              child: Icon(
                Icons.phone_iphone_rounded,
                color: AppLightUi.violet.withValues(alpha: 0.85),
                size: 20,
              ),
            ),
          ),
        ),
        Spacing.v10,
        Obx(
          () => AppTextField(
            controller: controller.passwordController,
            validator: (value) =>
                Validate.passwordValidation(context, value?.trim() ?? ''),
            hintText: LocaleKeys.loginPasswordHint.tr,
            glossyBorder: true,
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
                  size: 18,
                ),
              ),
            ),
          ),
        ),
        Spacing.v8,
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => Get.toNamed(
              Routes.AUTH_VERIFY_ACCOUNT,
              arguments: <String, dynamic>{
                AuthVerifyAccountArgs.isComeFromForgotPassword: true,
              },
            ),
            child: SemiBoldText(
              text: LocaleKeys.forgotPassword.tr,
              fontSize: TextStyles.k12FontSize,
              color: kColorPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _loginCta(BuildContext context) {
    return Obx(
      () => appButton(
        onPressed: () => controller.onLoginPressed(context),
        buttonText: controller.isLoginLoading.value
            ? ''
            : LocaleKeys.loginButtonText.tr,
        borderRadius: 18,
        buttonIcon: controller.isLoginLoading.value
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(kColorWhite),
                ),
              )
            : null,
      ),
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
            onTap: () => controller.onFacebookLoginPressed(context),
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
            onTap: () => controller.onGoogleLoginPressed(context),
            iconHeight: 22,
            iconWidth: 22,
            title: LocaleKeys.loginWithGoogleFull.tr,
            isLoading: controller.isGoogleLoginLoading.value,
          ),
        ),
        Spacing.v8,
        _socialOutlinedButton(
          iconPath: kIconLock,
          onTap: () => Get.toNamed(
            Routes.AUTH_VERIFY_ACCOUNT,
            arguments: <String, dynamic>{
              AuthVerifyAccountArgs.isFromLoginWithOtp: true,
            },
          ),
          iconHeight: 22,
          iconWidth: 22,
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
    double iconHeight = 24,
    double iconWidth = 24,
    bool tintIcon = false,
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
            boxShadow: [
              BoxShadow(
                color: AppLightUi.title.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
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
                  colorFilter: tintIcon
                      ? ColorFilter.mode(
                          AppLightUi.violet.withValues(alpha: 0.9),
                          BlendMode.srcIn,
                        )
                      : null,
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

  Widget signUpFooterWidget() {
    return GestureDetector(
      onTap: () => Get.toNamed(Routes.AUTH_SIGN_UP),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            AppText(
              text: LocaleKeys.dontHaveAccount.tr,
              fontSize: TextStyles.k12FontSize,
              color: AppLightUi.subtitle,
            ),
            SemiBoldText(
              text: LocaleKeys.signUp.tr,
              fontSize: TextStyles.k12FontSize,
              color: kColorPrimary,
            ),
          ],
        ),
      ),
    );
  }
}