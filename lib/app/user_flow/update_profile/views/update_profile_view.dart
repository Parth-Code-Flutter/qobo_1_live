import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/generated/locales.g.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/update_profile_controller.dart';

class UpdateProfileView extends GetView<UpdateProfileController> {
  const UpdateProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: CommonAppBarWidget(title: '', showBackButton: true),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Spacing.v24,
                    _headerWidget(),
                    Spacing.v28,
                    Center(child: _profileImagePicker(context)),
                    Spacing.v28,
                    _userNameField(context),
                    Spacing.v10,
                    _ageField(context),
                    Spacing.v10,
                    _passwordField(context),
                    Spacing.v10,
                    _confirmPasswordField(context),
                    Spacing.v10,
                    _genderField(),
                    Spacing.v16,
                    _termsAndPrivacyText(),
                    Spacing.v28,
                    Obx(
                      () => appButton(
                        onPressed: () =>
                            controller.onPrimaryActionPressed(context),
                        buttonText: controller.isSubmitLoading.value
                            ? ''
                            : (controller.isComeFromOtpScreen.value
                                  ? 'Next'
                                  : 'Update Profile'),
                        buttonIcon: controller.isSubmitLoading.value
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
                    Spacing.v24,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerWidget() {
    return const Center(
      child: BoldText(
        text: 'Additional Information',
        fontSize: TextStyles.k22FontSize,
        color: kColorText,
      ),
    );
  }

  Widget _profileImagePicker(BuildContext context) {
    return Obx(() {
      final File? selectedMedia = controller.selectedProfileMedia.value;
      return GestureDetector(
        onTap: () => controller.onProfileMediaTap(context),
        child: SizedBox(
          width: 124,
          height: 124,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: selectedMedia == null
                        ? const Icon(
                            Icons.camera_alt_outlined,
                            color: kColorTextGrey,
                            size: 34,
                          )
                        : Image.file(selectedMedia, fit: BoxFit.cover),
                  ),
                ),
              ),
              // Bottom-right edit affordance as per Figma.
              Align(
                alignment: Alignment.bottomRight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => controller.onProfileMediaTap(context),
                  child: SizedBox(
                    width: 34,
                    height: 34,
                    child: SvgPicture.asset(kIconEditBG, fit: BoxFit.contain),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _userNameField(BuildContext context) {
    return AppTextField(
      controller: controller.userNameController,
      validator: (value) => controller.validateUserName(context, value),
      hintText: LocaleKeys.nickNameHint.tr,
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
    );
  }

  Widget _ageField(BuildContext context) {
    return AppTextField(
      controller: controller.birthdateController,
      validator: controller.validateBirthdate,
      hintText: LocaleKeys.ageHint.tr,
      readOnly: true,
      onTap: () => controller.pickAge(context),
      borderColor: kColorHint,
      hintStyle: TextStyles.kRegularPoppins(
        fontSize: TextStyles.k14FontSize,
        colors: kColorHint,
      ),
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.none,
      prefix:  Padding(
        padding: EdgeInsets.only(left: 14, right: 12),
        child: SvgPicture.asset(kIconCalendar),
      ),
    );
  }

  Widget _genderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          text: 'Select Gender',
          fontSize: TextStyles.k14FontSize,
          color: kColorText,
        ),
        Spacing.v12,
        Obx(
          () => Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _genderCircleOption(
                label: 'Male',
                value: 'Male',
                iconAsset: kIconMale,
                isSelected: controller.selectedGender.value == 'Male',
              ),
              const SizedBox(width: 16),
              _genderCircleOption(
                label: 'Female',
                value: 'Female',
                iconAsset: kIconFemale,
                isSelected: controller.selectedGender.value == 'Female',
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Consent copy shown below gender with clickable links.
  /// For now links only log taps; navigation can be added later.
  Widget _termsAndPrivacyText() {
    return Obx(
      () => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User can toggle consent from the circular indicator (tick / untick).
          GestureDetector(
            onTap: controller.toggleTermsAcceptance,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                controller.hasAcceptedTerms.value
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                size: 16,
                color: controller.hasAcceptedTerms.value
                    ? kColorPrimary
                    : kColorHint,
              ),
            ),
          ),
          Spacing.h6,
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                debugPrint('Privacy Policy clicked');
              },
              child: RichText(
                text: TextSpan(
                  style: TextStyles.kRegularPoppins(
                    fontSize: TextStyles.k12FontSize,
                    colors: kColorText,
                  ),
                  children: [
                    TextSpan(text: LocaleKeys.agreeToThe.tr),
                    TextSpan(
                      text: LocaleKeys.termsAndConditions.tr,
                      style: TextStyles.kSemiBoldPoppins(
                        fontSize: TextStyles.k12FontSize,
                        colors: kColorPrimary,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          debugPrint('Terms & Conditions clicked');
                        },
                    ),
                    const TextSpan(text: ' '),
                    TextSpan(text: LocaleKeys.andText.tr),
                    TextSpan(
                      text: LocaleKeys.privacyPolicy.tr,
                      style: TextStyles.kSemiBoldPoppins(
                        fontSize: TextStyles.k12FontSize,
                        colors: kColorPrimary,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          debugPrint('Privacy Policy clicked');
                        },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Figma-style circular chip: filled primary when selected, white + grey border when not.
  Widget _genderCircleOption({
    required String label,
    required String value,
    required String iconAsset,
    required bool isSelected,
  }) {
    const double kGenderCircleSize = 90;

    return GestureDetector(
      onTap: () => controller.selectedGender.value = value,
      child: SizedBox(
        width: kGenderCircleSize,
        height: kGenderCircleSize,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isSelected ? kColorPrimary : kColorWhite,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? kColorPrimary : kColorTextFieldBorder,
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                iconAsset,
                height: 32,
                width: 32,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(
                  isSelected ? kColorWhite : kColorHint,
                  BlendMode.srcIn,
                ),
              ),
              Spacing.v2,
              if (isSelected)
                SemiBoldText(
                  text: label,
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite,
                )
              else
                AppText(
                  text: label,
                  fontSize: TextStyles.k14FontSize,
                  color: kColorHint,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _passwordField(BuildContext context) {
    return Obx(
      () => AppTextField(
        controller: controller.passwordController,
        validator: (value) => controller.validatePassword(context, value),
        hintText: 'Enter password',
        obscureText: controller.isPasswordHidden.value,
        textInputType: TextInputType.visiblePassword,
        textInputAction: TextInputAction.next,
        textCapitalization: TextCapitalization.none,
        borderColor: kColorHint,
        hintStyle: TextStyles.kRegularPoppins(
          fontSize: TextStyles.k14FontSize,
          colors: kColorHint,
        ),
        prefix: Padding(
          padding: const EdgeInsets.only(left: 14, right: 12),
          child: SvgPicture.asset(
            kIconPassword,
            colorFilter: const ColorFilter.mode(kColorHint, BlendMode.srcIn),
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
    );
  }

  Widget _confirmPasswordField(BuildContext context) {
    return Obx(
      () => AppTextField(
        controller: controller.confirmPasswordController,
        validator: (value) =>
            controller.validateConfirmPassword(context, value),
        hintText: 'Re-enter password',
        obscureText: controller.isConfirmPasswordHidden.value,
        textInputType: TextInputType.visiblePassword,
        textInputAction: TextInputAction.done,
        textCapitalization: TextCapitalization.none,
        borderColor: kColorHint,
        hintStyle: TextStyles.kRegularPoppins(
          fontSize: TextStyles.k14FontSize,
          colors: kColorHint,
        ),
        prefix: Padding(
          padding: const EdgeInsets.only(left: 14, right: 12),
          child: SvgPicture.asset(
            kIconPassword,
            colorFilter: const ColorFilter.mode(kColorHint, BlendMode.srcIn),
          ),
        ),
        suffix: Padding(
          padding: const EdgeInsets.only(right: 14),
          child: GestureDetector(
            onTap: controller.toggleConfirmPasswordVisibility,
            child: Icon(
              controller.isConfirmPasswordHidden.value
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: kColorHint,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}
