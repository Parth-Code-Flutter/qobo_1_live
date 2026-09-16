import 'package:qobo_one_live/app/user_flow/role_application/role_application_view.dart';
import 'package:qobo_one_live/repo/agency/role_application_repo.dart';
import 'package:qobo_one_live/utils/roles/recruitment_code_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/app_widgets/country_state_picker_sheet.dart';
import 'package:qobo_one_live/utils/app_widgets/glossy_dating_card.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

import '../controllers/agency_owner_register_controller.dart';

class AgencyOwnerRegisterView extends GetView<AgencyOwnerRegisterController> {
  const AgencyOwnerRegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!controller.isFromSuperAdmin.value) {
      return RoleApplicationView(
        role: ApplicationRole.agency,
        initialCode: controller.superAdminCodeController.text,
      );
    }
    return Scaffold(
      backgroundColor: kColorLavenderBg,
      appBar: const CommonAppBarWidget(
        title: 'Apply for Agency',
        subtitle: 'Create & approve agency',
        trailingIcon: Icons.business_center_outlined,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: controller.formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  24 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlossyDatingCard(
                        radius: 22,
                        borderWidth: 1.4,
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                        child: _formHeader(),
                      ),
                      Spacing.v16,
                      Obx(
                        () => controller.isFromSuperAdmin.value
                            ? const SizedBox.shrink()
                            : Center(
                                child: _agencyLogoPicker(context),
                              ),
                      ),
                      GlossyDatingCard(
                        radius: 22,
                        borderWidth: 1.4,
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel('Agency Name'),
                            Spacing.v8,
                            AppTextField(
                              controller: controller.agencyNameController,
                              validator: (v) =>
                                  controller.validateAgencyName(context, v),
                              hintText: 'Enter agency name',
                              borderColor: AppLightUi.borderStrong,
                              maxLength: 80,
                              showCounter: false,
                              textInputAction: TextInputAction.next,
                              textCapitalization: TextCapitalization.words,
                              prefix: _fieldIcon(Icons.business_rounded),
                            ),
                            Spacing.v16,
                            _fieldLabel('Owner Name'),
                            Spacing.v8,
                            AppTextField(
                              controller: controller.ownerNameController,
                              validator: (v) =>
                                  controller.validateOwnerName(context, v),
                              hintText: 'Enter your name',
                              borderColor: AppLightUi.borderStrong,
                              maxLength: 60,
                              showCounter: false,
                              textInputAction: TextInputAction.next,
                              textCapitalization: TextCapitalization.words,
                              prefix: _fieldIcon(
                                Icons.person_outline_rounded,
                              ),
                            ),
                            Obx(() => _publicInviteFields(context)),
                          ],
                        ),
                      ),
                      Spacing.v24,
                      Obx(
                        () => appButton(
                          onPressed: () {
                            if (!controller.isSubmitLoading.value) {
                              controller.onSubmitPressed(context);
                            }
                          },
                          buttonText: controller.isSubmitLoading.value
                              ? ''
                              : controller.isFromSuperAdmin.value
                              ? 'Add Agency'
                              : 'Submit Application',
                          isGradient: true,
                          gradientColors: AppLightUi.familyCtaColors,
                          borderRadius: 16,
                          buttonHeight: 52,
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
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _formHeader() {
    return Obx(() {
      final isPublic = controller.isPublicInvite.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BoldText(
            text: isPublic ? 'Apply for Agency' : 'Become an Agency Owner',
            fontSize: TextStyles.k22FontSize,
            color: AppLightUi.title,
          ),
          Spacing.v6,
          AppText(
            text: isPublic
                ? 'Complete your agency profile and documents. A super admin will approve your agency before the dashboard opens.'
                : 'Add an approved agency under your Super Admin account.',
            fontSize: TextStyles.k12FontSize,
            color: AppLightUi.subtitle,
          ),
        ],
      );
    });
  }

  Widget _agencyLogoPicker(BuildContext context) {
    return Obx(() {
      final file = controller.agencyLogo.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: GestureDetector(
          onTap: () => controller.onLogoTap(context),
          child: Column(
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: AppLightUi.card,
                  border: Border.all(color: AppLightUi.borderStrong),
                  boxShadow: AppLightUi.cardShadow,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: file != null
                      ? Image.file(file, fit: BoxFit.cover)
                      : Center(
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: AppLightUi.iconTileDecoration(
                              AppLightUi.pink,
                              radius: 14,
                            ),
                            child: const Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 24,
                              color: AppLightUi.pink,
                            ),
                          ),
                        ),
                ),
              ),
              Spacing.v8,
              const AppText(
                text: 'Agency logo',
                fontSize: TextStyles.k12FontSize,
                color: AppLightUi.subtitle,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _fieldLabel(String label) {
    return AppText(
      text: label,
      fontSize: TextStyles.k12FontSize,
      color: AppLightUi.title,
    );
  }

  Widget _publicInviteFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Spacing.v16,
        if (!controller.isFromSuperAdmin.value) ...[
          RecruitmentCodeField(
            verification: controller.codeVerification,
            label: 'Enter code',
          ),
          Spacing.v16,
        ],
        // Email input temporarily hidden, including its form validator.
        // _fieldLabel('Email'),
        // Spacing.v6,
        // AppTextField(
        //   controller: controller.emailController,
        //   validator: (v) => controller.validateEmail(context, v),
        //   hintText: 'Enter owner email',
        //   borderColor: kColorHint,
        //   textInputType: TextInputType.emailAddress,
        //   textInputAction: TextInputAction.next,
        //   textCapitalization: TextCapitalization.none,
        //   prefix: _fieldIcon(Icons.email_outlined),
        // ),
        // Spacing.v16,
        if (controller.isFromSuperAdmin.value) ...[
          _fieldLabel('Commission (%)'),
          Spacing.v8,
          AppTextField(
            controller: controller.commissionController,
            textInputType: const TextInputType.numberWithOptions(decimal: true),
            borderColor: AppLightUi.borderStrong,
            validator: (value) {
              final rate = double.tryParse(value?.trim() ?? '');
              return rate == null || !rate.isFinite || rate < 0 || rate > 100
                  ? 'Enter a commission from 0 to 100'
                  : null;
            },
          ),
        ],
        if (!controller.isFromSuperAdmin.value) ...[
          _fieldLabel('Password'),
          Spacing.v6,
          AppTextField(
            controller: controller.passwordController,
            validator: (v) => controller.validatePassword(context, v),
            hintText: 'Min. 6 characters',
            borderColor: AppLightUi.borderStrong,
            obscureText: true,
            textInputAction: TextInputAction.next,
            maxLength: 32,
            showCounter: false,
            prefix: _fieldIcon(Icons.lock_outline_rounded),
          ),
          Spacing.v16,
          Obx(
            () => Column(
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
                          AppToast.showError(
                            context,
                            'Please select country first',
                          );
                        }
                      : () => _pickState(context),
                ),
              ],
            ),
          ),
          Spacing.v16,
          _fieldLabel('City'),
          Spacing.v6,
          AppTextField(
            controller: controller.cityController,
            validator: (v) => controller.validateRequired('City', v),
            hintText: 'Enter city',
            borderColor: AppLightUi.borderStrong,
            prefix: _fieldIcon(Icons.location_city_outlined),
          ),
          Spacing.v16,
          _fieldLabel('Address'),
          Spacing.v6,
          AppTextField(
            controller: controller.addressController,
            validator: (v) => controller.validateRequired('Address', v),
            hintText: 'Enter full address',
            borderColor: AppLightUi.borderStrong,
            maxLines: 3,
            textInputAction: TextInputAction.newline,
            prefix: _fieldIcon(Icons.home_outlined),
          ),
          Spacing.v16,
          _documentPicker(
            label: 'Document Front',
            icon: Icons.badge_outlined,
            fileName: controller.docPhotoFront.value?.path.split('/').last,
            onTap: () => controller.pickDocumentFront(context),
          ),
          Spacing.v12,
          _documentPicker(
            label: 'Document Back',
            icon: Icons.badge_rounded,
            fileName: controller.docPhotoBack.value?.path.split('/').last,
            onTap: () => controller.pickDocumentBack(context),
          ),
        ],
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

  Widget _documentPicker({
    required String label,
    required IconData icon,
    required String? fileName,
    required VoidCallback onTap,
  }) {
    final hasFile = fileName != null && fileName.isNotEmpty;
    final accent = hasFile ? AppLightUi.violet : AppLightUi.pink;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppLightUi.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: hasFile
                  ? AppLightUi.violet.withValues(alpha: 0.45)
                  : AppLightUi.borderStrong,
              width: 1.2,
            ),
            boxShadow: AppLightUi.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: AppLightUi.iconTileDecoration(accent, radius: 13),
                child: Icon(icon, size: 22, color: accent),
              ),
              Spacing.h12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemiBoldText(
                      text: label,
                      fontSize: TextStyles.k14FontSize,
                      color: AppLightUi.title,
                    ),
                    Spacing.v2,
                    AppText(
                      text: hasFile ? fileName : 'Tap to upload',
                      fontSize: TextStyles.k12FontSize,
                      color: hasFile ? AppLightUi.violet : AppLightUi.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.upload_file_rounded,
                color: accent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldIcon(IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 12),
      child: Icon(icon, size: 20, color: AppLightUi.muted),
    );
  }
}
