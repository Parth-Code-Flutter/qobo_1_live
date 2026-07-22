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
import 'package:qobo_one_live/utils/app_widgets/country_state_picker_sheet.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';
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
                    Obx(
                      () => !controller.isComeFromOtpScreen.value
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _adsBannerSection(context),
                                Spacing.v20,
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                    _userNameField(context),
                    Obx(
                      () => controller.isComeFromOtpScreen.value
                          ? Column(
                              children: [
                                Spacing.v10,
                                _emailField(context),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                    Spacing.v10,
                    _ageField(context),
                    Spacing.v10,
                    _passwordField(context),
                    Spacing.v10,
                    _confirmPasswordField(context),
                    Spacing.v10,
                    _genderField(),
                    Spacing.v10,
                    Obx(() => _countryStateFields(context)),
                    Spacing.v10,
                    _cityField(context),
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

  Widget _adsBannerSection(BuildContext context) {
    return Obx(() {
      final banners = controller.adBanners.toList();
      final loading = controller.isLoadingAdBanners.value;
      final applying = controller.isApplyingBanner.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SemiBoldText(
            text: 'Cover banner',
            fontSize: TextStyles.k14FontSize,
            color: kColorText,
          ),
          Spacing.v6,
          AppText(
            text: 'Pick a banner from the ads catalog for your profile cover',
            fontSize: TextStyles.k12FontSize,
            color: kColorHint,
          ),
          Spacing.v12,
          if (loading && banners.isEmpty)
            const SizedBox(
              height: 96,
              child: Center(
                child: CircularProgressIndicator(color: kColorPrimary),
              ),
            )
          else if (banners.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7FB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE6E6EE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.image_outlined, color: kColorHint, size: 22),
                  Spacing.h10,
                  const Expanded(
                    child: AppText(
                      text: 'No banners available right now.',
                      fontSize: TextStyles.k12FontSize,
                      color: kColorHint,
                    ),
                  ),
                  GestureDetector(
                    onTap: controller.loadAdBanners,
                    child: const SemiBoldText(
                      text: 'Retry',
                      fontSize: TextStyles.k12FontSize,
                      color: kColorPrimary,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: banners.length,
                separatorBuilder: (_, __) => Spacing.h10,
                itemBuilder: (context, index) {
                  final banner = banners[index];
                  final selected =
                      controller.selectedAdBannerId.value == banner.id ||
                      controller.selectedPosterUrl.value == banner.imageUrl;
                  return GestureDetector(
                    onTap: applying
                        ? null
                        : () => controller.selectAdBanner(context, banner),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 168,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? kColorPrimary
                              : const Color(0xFFE6E6EE),
                          width: selected ? 2 : 1,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: kColorPrimary.withValues(alpha: 0.18),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            banner.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => ColoredBox(
                              color: const Color(0xFFF0F0F5),
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: kColorHint.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Color(0xCC101018),
                                  ],
                                ),
                              ),
                              child: SemiBoldText(
                                text: banner.title,
                                fontSize: TextStyles.k10FontSize,
                                color: kColorWhite,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (selected)
                            const Positioned(
                              top: 6,
                              right: 6,
                              child: Icon(
                                Icons.check_circle_rounded,
                                color: kColorPrimary,
                                size: 20,
                              ),
                            ),
                          if (applying && selected)
                            ColoredBox(
                              color: Colors.black.withValues(alpha: 0.35),
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: kColorWhite,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      );
    });
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

  Widget _emailField(BuildContext context) {
    return AppTextField(
      controller: controller.emailController,
      validator: (value) => controller.validateEmail(context, value),
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

  Widget _cityField(BuildContext context) {
    return AppTextField(
      controller: controller.cityController,
      validator: controller.validateCity,
      hintText: 'Enter city',
      borderColor: kColorHint,
      hintStyle: TextStyles.kRegularPoppins(
        fontSize: TextStyles.k14FontSize,
        colors: kColorHint,
      ),
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      prefix: Padding(
        padding: const EdgeInsets.only(left: 14, right: 12),
        child: Icon(Icons.location_city_outlined, size: 20, color: kColorHint),
      ),
    );
  }

  Widget _countryStateFields(BuildContext context) {
    return Column(
      children: [
        CountryStatePickerField(
          label: 'Country',
          value: controller.selectedCountry.value?.name,
          hint: 'Select country',
          isLoading: controller.isCountriesLoading.value,
          onTap: () => _pickCountry(context),
        ),
        Spacing.v10,
        CountryStatePickerField(
          label: 'State',
          value: controller.selectedState.value?.name,
          hint: controller.selectedCountry.value == null
              ? 'Select country first'
              : 'Select state',
          isLoading: controller.isStatesLoading.value,
          onTap: controller.selectedCountry.value == null
              ? () {
                  AppToast.showError(context, 'Please select country first');
                }
              : () => _pickState(context),
        ),
      ],
    );
  }

  Future<void> _pickCountry(BuildContext context) async {
    FocusScope.of(context).unfocus();
    await controller.ensureCountriesLoaded(forceRefresh: true);
    if (!context.mounted) return;
    final picked = await showCountryPickerSheet(
      context,
      countries: controller.countries.toList(),
      selected: controller.selectedCountry.value,
    );
    if (picked != null) await controller.selectCountry(picked);
  }

  Future<void> _pickState(BuildContext context) async {
    final country = controller.selectedCountry.value;
    if (country == null) return;
    FocusScope.of(context).unfocus();
    await controller.loadStatesForCountry(country.id, forceRefresh: true);
    if (!context.mounted) return;
    final picked = await showStatePickerSheet(
      context,
      states: controller.states.toList(),
      selected: controller.selectedState.value,
    );
    if (picked != null) controller.selectState(picked);
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
