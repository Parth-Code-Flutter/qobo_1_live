import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/generated/locales.g.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/new_password_controller.dart';

/// Figma: light grey back pill, centered “New Password” + subtitle, two matching
/// bordered fields (lock + visibility), full-width **Confirm**, footer **Sign In**.
class NewPasswordView extends GetView<NewPasswordController> {
  const NewPasswordView({super.key});

  static const Color _kBackPillFill = Color(0xFFE8E8E8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Form(
            key: controller.formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _figmaBackPill(context),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Spacing.v8,
                        BoldText(
                          text: LocaleKeys.newPasswordTitle.tr,
                          fontSize: TextStyles.k20FontSize,
                          color: kColorText,
                          align: TextAlign.center,
                        ),
                        Spacing.v8,
                        AppText(
                          text: LocaleKeys.newPasswordSubtitle.tr,
                          fontSize: TextStyles.k14FontSize,
                          color: kColorTextGrey,
                          align: TextAlign.center,
                        ),
                        Spacing.v28,
                        _passwordFields(context),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    16 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Obx(
                        () => appButton(
                          onPressed: () =>
                              controller.onConfirmPressed(context),
                          buttonText: controller.isSubmitLoading.value
                              ? ''
                              : LocaleKeys.newPasswordConfirmCta.tr,
                          isGradient: false,
                          buttonColor: kColorPrimary,
                          buttonIcon: controller.isSubmitLoading.value
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
                      _signInFooter(context),
                      Spacing.v8,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _figmaBackPill(BuildContext context) {
    return Material(
      color: _kBackPillFill,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => Get.back(),
        borderRadius: BorderRadius.circular(10),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.arrow_back_ios_new,
            size: 16,
            color: kColorText,
          ),
        ),
      ),
    );
  }

  Widget _passwordPrefixIcon(String assetPath) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 12),
      child: SvgPicture.asset(
        assetPath,
        width: 20,
        height: 20,
        fit: BoxFit.contain,
        colorFilter: const ColorFilter.mode(
          kColorHint,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  Widget _passwordFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(
          () => AppTextField(
            controller: controller.newPasswordController,
            onChanged: (_) => controller.formKey.currentState?.validate(),
            validator: (v) => controller.validateNewPassword(context, v),
            hintText: LocaleKeys.newPasswordFieldHint.tr,
            borderColor: kColorTextFieldBorder,
            hintStyle: TextStyles.kRegularPoppins(
              fontSize: TextStyles.k14FontSize,
              colors: kColorHint,
            ),
            obscureText: controller.isNewPasswordHidden.value,
            textInputType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.none,
            prefix: _passwordPrefixIcon(kIconLock),
            suffix: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: GestureDetector(
                onTap: controller.toggleNewPasswordVisibility,
                child: Icon(
                  controller.isNewPasswordHidden.value
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: kColorHint,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        Spacing.v10,
        Obx(
          () => AppTextField(
            controller: controller.confirmPasswordController,
            onChanged: (_) => controller.formKey.currentState?.validate(),
            validator: (v) =>
                controller.validateConfirmPassword(context, v),
            hintText: LocaleKeys.retypePasswordHint.tr,
            borderColor: kColorTextFieldBorder,
            hintStyle: TextStyles.kRegularPoppins(
              fontSize: TextStyles.k14FontSize,
              colors: kColorHint,
            ),
            obscureText: controller.isConfirmPasswordHidden.value,
            textInputType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.none,
            prefix: _passwordPrefixIcon(kIconLock),
            suffix: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: GestureDetector(
                onTap: controller.toggleConfirmPasswordVisibility,
                child: Icon(
                  controller.isConfirmPasswordHidden.value
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: kColorHint,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _signInFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppText(
          text: LocaleKeys.haveAccount.tr,
          fontSize: TextStyles.k14FontSize,
          color: kColorTextGrey,
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: controller.onSignInTap,
          child: SemiBoldText(
            text: LocaleKeys.signIn.tr,
            fontSize: TextStyles.k14FontSize,
            color: kColorPrimary,
          ),
        ),
      ],
    );
  }
}
