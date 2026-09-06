import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_shell_background.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/agency_host_onboarding_controller.dart';
import '../models/agency_host_interest.dart';
import '../models/agency_host_type.dart';
import '../widgets/agency_host_category_picker.dart';
import 'package:qobo_one_live/utils/app_widgets/country_state_picker_sheet.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

/// Agency host onboarding form — `POST /api/agency/host-onboarding`.
class AgencyHostOnboardingView extends GetView<AgencyHostOnboardingController> {
  const AgencyHostOnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: AppShellBackground(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _topBar(context),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    child: ColoredBox(
                      color: kColorWhite,
                      child: Form(
                        key: controller.formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                20,
                                20,
                                20,
                                24 + MediaQuery.of(context).viewInsets.bottom,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight - 40,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _formHeader(),
                                    Spacing.v20,
                                    Center(child: _hostPhotoPicker(context)),
                                    Spacing.v24,
                                    _hostNameField(context),
                                    Spacing.v10,
                                    _birthdayField(context),
                                    Spacing.v10,
                                    _hostIdField(context),
                                    Spacing.v10,
                                    _whatsAppField(context),
                                    Spacing.v10,
                                    _gmailField(context),
                                    Spacing.v10,
                                    _countryField(context),
                                    Spacing.v10,
                                    _stateField(context),
                                    Spacing.v10,
                                    _cityField(context),
                                    Spacing.v10,
                                    _addressField(context),
                                    Spacing.v10,
                                    _agencyCodeField(context),
                                    Spacing.v16,
                                    _typeSection(),
                                    Spacing.v16,
                                    _categoryDropdown(context),
                                    Spacing.v20,
                                    _governmentDocsSection(context),
                                    Spacing.v28,
                                    Obx(
                                      () => appButton(
                                        onPressed: () {
                                          if (!controller
                                              .isSubmitLoading
                                              .value) {
                                            controller.onSubmitPressed(context);
                                          }
                                        },
                                        buttonText:
                                            controller.isSubmitLoading.value
                                            ? ''
                                            : 'Submit',
                                        buttonIcon:
                                            controller.isSubmitLoading.value
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(kColorWhite),
                                                ),
                                              )
                                            : null,
                                      ),
                                    ),
                                    Spacing.v16,
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 14, 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Get.back<void>(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: kColorWhite,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: kColorWhite,
                size: 20,
              ),
            ),
          ),
          Obx(
            () => SemiBoldText(
              text: controller.isFromAgencyOwner.value
                  ? 'Add Host'
                  : 'Agency Host',
              fontSize: TextStyles.k18FontSize,
              color: kColorWhite,
              align: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _formHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BoldText(
          text: 'Host Registration',
          fontSize: TextStyles.k22FontSize,
          color: kColorText,
        ),
        Spacing.v6,
        const AppText(
          text: 'Apply to join as an agency host. All fields are required.',
          fontSize: TextStyles.k12FontSize,
          color: kColorHint,
        ),
      ],
    );
  }

  Widget _hostPhotoPicker(BuildContext context) {
    return Obx(() {
      final file = controller.hostPhoto.value;
      return GestureDetector(
        onTap: () => controller.onHostPhotoTap(context),
        child: Column(
          children: [
            Container(
              width: 124,
              height: 124,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kColorAvatarFallbackBg.withValues(alpha: 0.15),
                border: Border.all(color: kColorHint.withValues(alpha: 0.4)),
              ),
              child: ClipOval(
                child: file != null
                    ? Image.file(file, fit: BoxFit.cover)
                    : Center(
                        child: Icon(
                          Icons.add_a_photo_outlined,
                          size: 36,
                          color: kColorHint.withValues(alpha: 0.8),
                        ),
                      ),
              ),
            ),
            Spacing.v8,
            const AppText(
              text: 'Host real photo',
              fontSize: TextStyles.k12FontSize,
              color: kColorHint,
            ),
          ],
        ),
      );
    });
  }

  Widget _hostNameField(BuildContext context) {
    return _labeledField(
      label: 'Host name',
      child: AppTextField(
        controller: controller.hostNameController,
        validator: (v) => controller.validateHostName(context, v),
        hintText: 'Enter host name',
        borderColor: kColorHint,
        textInputAction: TextInputAction.next,
        textCapitalization: TextCapitalization.words,
        prefix: _fieldIcon(Icons.person_outline_rounded),
      ),
    );
  }

  Widget _birthdayField(BuildContext context) {
    return _labeledField(
      label: 'Birthday date',
      child: AppTextField(
        controller: controller.birthdayController,
        validator: controller.validateBirthday,
        hintText: 'DD/MM/YYYY',
        readOnly: true,
        onTap: () => controller.pickBirthday(context),
        borderColor: kColorHint,
        prefix: Padding(
          padding: const EdgeInsets.only(left: 14, right: 12),
          child: SvgPicture.asset(
            kIconCalendar,
            colorFilter: const ColorFilter.mode(kColorHint, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }

  Widget _hostIdField(BuildContext context) {
    return _labeledField(
      label: 'Host ID number',
      child: AppTextField(
        controller: controller.hostIdController,
        validator: (v) => controller.validateHostId(context, v),
        hintText: 'Enter host ID',
        borderColor: kColorHint,
        textInputAction: TextInputAction.next,
        prefix: _fieldIcon(Icons.badge_outlined),
      ),
    );
  }

  Widget _whatsAppField(BuildContext context) {
    return _labeledField(
      label: 'WhatsApp number',
      child: AppTextField(
        controller: controller.whatsAppController,
        validator: (v) => controller.validateWhatsApp(context, v),
        hintText: '10-digit mobile number',
        borderColor: kColorHint,
        textInputType: TextInputType.number,
        textInputAction: TextInputAction.next,
        maxLength: 10,
        showCounter: false,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        prefix: _fieldIcon(Icons.phone_android_outlined),
      ),
    );
  }

  Widget _gmailField(BuildContext context) {
    return _labeledField(
      label: 'Gmail ID',
      child: AppTextField(
        controller: controller.gmailController,
        validator: (v) => controller.validateGmail(context, v),
        hintText: 'name@gmail.com',
        borderColor: kColorHint,
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
    );
  }

  Widget _countryField(BuildContext context) {
    return Obx(
      () => CountryStatePickerField(
        label: 'Country',
        value: controller.selectedCountry.value?.name,
        hint: 'Select country',
        isLoading: controller.isCountriesLoading.value,
        onTap: () => _pickCountry(context),
      ),
    );
  }

  Widget _stateField(BuildContext context) {
    return Obx(
      () => CountryStatePickerField(
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

  Widget _cityField(BuildContext context) {
    return _labeledField(
      label: 'City',
      child: AppTextField(
        controller: controller.cityController,
        validator: controller.validateCity,
        hintText: 'Enter city',
        borderColor: kColorHint,
        textInputAction: TextInputAction.next,
        textCapitalization: TextCapitalization.words,
        prefix: _fieldIcon(Icons.location_city_outlined),
      ),
    );
  }

  Widget _addressField(BuildContext context) {
    return _labeledField(
      label: 'Address',
      child: AppTextField(
        controller: controller.addressController,
        validator: controller.validateAddress,
        hintText: 'Enter full address',
        borderColor: kColorHint,
        textInputAction: TextInputAction.next,
        textCapitalization: TextCapitalization.sentences,
        maxLines: 2,
        minLines: 2,
        prefix: _fieldIcon(Icons.home_outlined),
      ),
    );
  }

  Widget _agencyCodeField(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labeledField(
            label: 'Agency code',
            child: AppTextField(
              controller: controller.agencyCodeController,
              validator: (v) => controller.validateAgencyCode(context, v),
              hintText: controller.isAgencyCodePrefilling.value
                  ? 'Loading your agency code…'
                  : 'Enter agency code',
              borderColor: kColorHint,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.characters,
              readOnly:
                  controller.isAgencyCodeLocked.value ||
                  controller.isAgencyCodePrefilling.value,
              prefix: _fieldIcon(Icons.vpn_key_outlined),
            ),
          ),
          if (controller.isAgencyCodeLocked.value) ...[
            Spacing.v6,
            AppText(
              text: 'Using your approved agency code',
              fontSize: TextStyles.k12FontSize,
              color: kColorPrimary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _typeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          text: 'Type',
          fontSize: TextStyles.k14FontSize,
          color: kColorText,
        ),
        Spacing.v10,
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AgencyHostType.values
                .map(
                  (type) => _typeChip(
                    type: type,
                    selected: controller.selectedType.value == type,
                    onTap: () => controller.selectType(type),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _typeChip({
    required AgencyHostType type,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kColorPrimary : kColorWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? kColorPrimary : kColorHint.withValues(alpha: 0.5),
          ),
        ),
        child: SemiBoldText(
          text: type.label,
          fontSize: TextStyles.k12FontSize,
          color: selected ? kColorWhite : kColorText,
        ),
      ),
    );
  }

  Widget _governmentDocsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          text: 'Upload government document photos',
          fontSize: TextStyles.k14FontSize,
          color: kColorText,
        ),
        Spacing.v6,
        const AppText(
          text: 'Upload clear photos of your ID document (front and back).',
          fontSize: TextStyles.k12FontSize,
          color: kColorHint,
        ),
        Spacing.v10,
        Row(
          children: [
            Expanded(
              child: _docPhotoTile(
                context,
                label: 'Front photo',
                file: controller.docPhotoFront,
                onTap: () => controller.onDocPhotoFrontTap(context),
              ),
            ),
            Spacing.h10,
            Expanded(
              child: _docPhotoTile(
                context,
                label: 'Back photo',
                file: controller.docPhotoBack,
                onTap: () => controller.onDocPhotoBackTap(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _docPhotoTile(
    BuildContext context, {
    required String label,
    required Rxn<File> file,
    required VoidCallback onTap,
  }) {
    return Obx(() {
      final picked = file.value;
      return GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1.35,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: kColorAvatarFallbackBg.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kColorHint.withValues(alpha: 0.35)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: picked != null
                      ? Image.file(picked, fit: BoxFit.cover)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.upload_file_outlined,
                              size: 28,
                              color: kColorHint.withValues(alpha: 0.85),
                            ),
                            Spacing.v6,
                            AppText(
                              text: 'Tap to upload',
                              fontSize: TextStyles.k10FontSize,
                              color: kColorHint.withValues(alpha: 0.9),
                              align: TextAlign.center,
                            ),
                          ],
                        ),
                ),
              ),
            ),
            Spacing.v6,
            AppText(
              text: label,
              fontSize: TextStyles.k12FontSize,
              color: kColorHint,
              align: TextAlign.center,
            ),
          ],
        ),
      );
    });
  }

  Widget _categoryDropdown(BuildContext context) {
    return FormField<AgencyHostInterest>(
      validator: (_) => controller.validateInterest(),
      builder: (field) {
        return Obx(
          () => _labeledField(
            label: 'Category',
            child: AgencyHostCategoryField(
              selected: controller.selectedInterest.value,
              errorText: field.errorText,
              onTap: () async {
                await controller.pickCategory(context);
                field.didChange(controller.selectedInterest.value);
                field.validate();
              },
            ),
          ),
        );
      },
    );
  }

  Widget _labeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          text: label,
          fontSize: TextStyles.k12FontSize,
          color: kColorText,
        ),
        Spacing.v6,
        child,
      ],
    );
  }

  Widget _fieldIcon(IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 12),
      child: Icon(icon, size: 20, color: kColorHint),
    );
  }
}
