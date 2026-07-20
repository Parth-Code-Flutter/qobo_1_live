import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/agency_owner_register_controller.dart';

class AgencyOwnerRegisterView extends GetView<AgencyOwnerRegisterController> {
  const AgencyOwnerRegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage(kImgBG), fit: BoxFit.cover),
        ),
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
                                    Center(child: _agencyLogoPicker(context)),
                                    Spacing.v24,
                                    _fieldLabel('Agency Name'),
                                    Spacing.v6,
                                    AppTextField(
                                      controller:
                                          controller.agencyNameController,
                                      validator: (v) => controller
                                          .validateAgencyName(context, v),
                                      hintText: 'Enter agency name',
                                      borderColor: kColorHint,
                                      textInputAction: TextInputAction.next,
                                      prefix: _fieldIcon(
                                        Icons.business_rounded,
                                      ),
                                    ),
                                    Spacing.v16,
                                    _fieldLabel('Owner Name'),
                                    Spacing.v6,
                                    AppTextField(
                                      controller:
                                          controller.ownerNameController,
                                      validator: (v) => controller
                                          .validateOwnerName(context, v),
                                      hintText: 'Enter your name',
                                      borderColor: kColorHint,
                                      textInputAction: TextInputAction.next,
                                      prefix: _fieldIcon(
                                        Icons.person_outline_rounded,
                                      ),
                                    ),
                                    Spacing.v16,
                                    _fieldLabel('WhatsApp Number'),
                                    Spacing.v6,
                                    AppTextField(
                                      controller: controller.whatsappController,
                                      validator: (v) => controller
                                          .validateWhatsApp(context, v),
                                      hintText: '10-digit mobile number',
                                      borderColor: kColorHint,
                                      textInputType: TextInputType.phone,
                                      textInputAction: TextInputAction.done,
                                      prefix: _fieldIcon(
                                        Icons.phone_android_outlined,
                                      ),
                                    ),
                                    Obx(
                                      () => controller.isPublicInvite.value
                                          ? _publicInviteFields(context)
                                          : const SizedBox.shrink(),
                                    ),
                                    Spacing.v32,
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
                                            : 'Submit Application',
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
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: kColorWhite,
                size: 20,
              ),
            ),
          ),
          const SemiBoldText(
            text: 'Apply for Agency',
            fontSize: TextStyles.k18FontSize,
            color: kColorWhite,
          ),
        ],
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
            text: isPublic
                ? 'Agency Invite Registration'
                : 'Become an Agency Owner',
            fontSize: TextStyles.k22FontSize,
            color: kColorText,
          ),
          Spacing.v4,
          AppText(
            text: isPublic
                ? 'Complete your agency profile and documents. A super admin will approve your agency before the dashboard opens.'
                : 'Submit your agency details for super admin review. You can open the owner dashboard only after approval.',
            fontSize: TextStyles.k12FontSize,
            color: kColorHint,
          ),
        ],
      );
    });
  }

  Widget _agencyLogoPicker(BuildContext context) {
    return Obx(() {
      final file = controller.agencyLogo.value;
      return GestureDetector(
        onTap: () => controller.onLogoTap(context),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(20),
                color: kColorAvatarFallbackBg.withValues(alpha: 0.15),
                border: Border.all(color: kColorHint.withValues(alpha: 0.4)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: file != null
                    ? Image.file(file, fit: BoxFit.cover)
                    : Center(
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 32,
                          color: kColorHint.withValues(alpha: 0.8),
                        ),
                      ),
              ),
            ),
            Spacing.v8,
            const AppText(
              text: 'Agency logo',
              fontSize: TextStyles.k12FontSize,
              color: kColorHint,
            ),
          ],
        ),
      );
    });
  }

  Widget _fieldLabel(String label) {
    return AppText(
      text: label,
      fontSize: TextStyles.k12FontSize,
      color: kColorText,
    );
  }

  Widget _publicInviteFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Spacing.v16,
        _fieldLabel('Email'),
        Spacing.v6,
        AppTextField(
          controller: controller.emailController,
          validator: (v) => controller.validateEmail(context, v),
          hintText: 'Enter owner email',
          borderColor: kColorHint,
          textInputType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.none,
          prefix: _fieldIcon(Icons.email_outlined),
        ),
        Spacing.v16,
        _fieldLabel('Country Code'),
        Spacing.v6,
        AppTextField(
          controller: controller.countryCodeController,
          validator: (v) => controller.validateRequired('Country code', v),
          hintText: '+91',
          borderColor: kColorHint,
          textInputType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          prefix: _fieldIcon(Icons.public_rounded),
        ),
        Spacing.v16,
        _fieldLabel('Password'),
        Spacing.v6,
        AppTextField(
          controller: controller.passwordController,
          validator: (v) => controller.validateRequired('Password', v),
          hintText: 'Create password',
          borderColor: kColorHint,
          obscureText: true,
          textInputAction: TextInputAction.next,
          prefix: _fieldIcon(Icons.lock_outline_rounded),
        ),
        Spacing.v16,
        Row(
          children: [
            Expanded(
              child: _compactField(
                context,
                label: 'Country',
                controller: controller.countryController,
                icon: Icons.flag_outlined,
              ),
            ),
            Spacing.h12,
            Expanded(
              child: _compactField(
                context,
                label: 'State',
                controller: controller.stateController,
                icon: Icons.map_outlined,
              ),
            ),
          ],
        ),
        Spacing.v16,
        _fieldLabel('City'),
        Spacing.v6,
        AppTextField(
          controller: controller.cityController,
          validator: (v) => controller.validateRequired('City', v),
          hintText: 'Enter city',
          borderColor: kColorHint,
          prefix: _fieldIcon(Icons.location_city_outlined),
        ),
        Spacing.v16,
        _fieldLabel('Address'),
        Spacing.v6,
        AppTextField(
          controller: controller.addressController,
          validator: (v) => controller.validateRequired('Address', v),
          hintText: 'Enter full address',
          borderColor: kColorHint,
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
    );
  }

  Widget _compactField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        Spacing.v6,
        AppTextField(
          controller: controller,
          validator: (v) => this.controller.validateRequired(label, v),
          hintText: label,
          borderColor: kColorHint,
          prefix: _fieldIcon(icon),
        ),
      ],
    );
  }

  Widget _documentPicker({
    required String label,
    required IconData icon,
    required String? fileName,
    required VoidCallback onTap,
  }) {
    final hasFile = fileName != null && fileName.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasFile
              ? kColorPrimary.withValues(alpha: 0.08)
              : kColorBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasFile
                ? kColorPrimary.withValues(alpha: 0.35)
                : kColorHint.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: hasFile ? kColorPrimary : kColorHint),
            Spacing.h12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SemiBoldText(
                    text: label,
                    fontSize: TextStyles.k14FontSize,
                    color: kColorText,
                  ),
                  Spacing.v2,
                  AppText(
                    text: hasFile ? fileName : 'Tap to upload',
                    fontSize: TextStyles.k12FontSize,
                    color: hasFile ? kColorPrimary : kColorHint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.upload_file_rounded, color: kColorPrimary),
          ],
        ),
      ),
    );
  }

  Widget _fieldIcon(IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 12),
      child: Icon(icon, size: 20, color: kColorHint),
    );
  }
}
