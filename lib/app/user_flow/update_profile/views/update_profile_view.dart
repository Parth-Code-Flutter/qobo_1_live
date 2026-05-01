import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
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
      backgroundColor: kColorWhite,
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
                    Spacing.v12,
                    _birthdateField(context),
                    Spacing.v12,
                    _genderField(),
                    Spacing.v12,
                    _passwordField(context),
                    Spacing.v12,
                    _confirmPasswordField(context),
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
        child: Container(
          width: 110,
          height: 110,
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
                : Image.file(
                    selectedMedia,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
      );
    });
  }

  Widget _userNameField(BuildContext context) {
    return AppTextField(
      controller: controller.userNameController,
      labelText: 'User Name',
      isRequired: true,
      validator: (value) => controller.validateUserName(context, value),
      hintText: 'Enter user name',
      borderColor: kColorTextFieldBorder,
      hintStyle: TextStyles.kRegularPoppins(
        fontSize: TextStyles.k14FontSize,
        colors: kColorHint,
      ),
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
    );
  }

  Widget _birthdateField(BuildContext context) {
    return AppTextField(
      controller: controller.birthdateController,
      labelText: 'Enter Birthdate',
      validator: controller.validateBirthdate,
      hintText: 'YYYY-MM-DD',
      readOnly: true,
      onTap: () => controller.pickBirthdate(context),
      borderColor: kColorTextFieldBorder,
      hintStyle: TextStyles.kRegularPoppins(
        fontSize: TextStyles.k14FontSize,
        colors: kColorHint,
      ),
      suffix: const Padding(
        padding: EdgeInsets.only(right: 14),
        child: Icon(Icons.calendar_today_outlined, color: kColorHint, size: 18),
      ),
    );
  }

  Widget _genderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          text: 'Gender',
          fontSize: TextStyles.k14FontSize,
          color: kColorText,
        ),
        Row(
          children: [
            Expanded(
              child: Obx(
                () => RadioListTile<String>(
                  value: 'Male',
                  groupValue: controller.selectedGender.value,
                  onChanged: (value) =>
                      controller.selectedGender.value = value ?? '',
                  title: const Text('Male'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: kColorPrimary,
                ),
              ),
            ),
            Expanded(
              child: Obx(
                () => RadioListTile<String>(
                  value: 'Female',
                  groupValue: controller.selectedGender.value,
                  onChanged: (value) =>
                      controller.selectedGender.value = value ?? '',
                  title: const Text('Female'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: kColorPrimary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _passwordField(BuildContext context) {
    return Obx(
      () => AppTextField(
        controller: controller.passwordController,
        labelText: 'Password',
        isRequired: true,
        validator: (value) => controller.validatePassword(context, value),
        hintText: 'Enter password',
        obscureText: controller.isPasswordHidden.value,
        textInputType: TextInputType.visiblePassword,
        borderColor: kColorTextFieldBorder,
        hintStyle: TextStyles.kRegularPoppins(
          fontSize: TextStyles.k14FontSize,
          colors: kColorHint,
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
        labelText: 'Confirm Password',
        isRequired: true,
        validator: (value) =>
            controller.validateConfirmPassword(context, value),
        hintText: 'Re-enter password',
        obscureText: controller.isConfirmPasswordHidden.value,
        textInputType: TextInputType.visiblePassword,
        textInputAction: TextInputAction.done,
        borderColor: kColorTextFieldBorder,
        hintStyle: TextStyles.kRegularPoppins(
          fontSize: TextStyles.k14FontSize,
          colors: kColorHint,
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
