import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/theme/app_theme_colors.dart';
import 'package:qobo_one_live/theme/theme_context.dart';
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
    final colors = context.appColors;
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
                      color: colors.surface,
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
                                    _formHeader(colors),
                                    Spacing.v20,
                                    Center(child: _agencyLogoPicker(context, colors)),
                                    Spacing.v24,
                                    _fieldLabel(colors, 'Agency Name'),
                                    Spacing.v6,
                                    AppTextField(
                                      controller: controller.agencyNameController,
                                      validator: (v) => controller.validateAgencyName(context, v),
                                      hintText: 'Enter agency name',
                                      textInputAction: TextInputAction.next,
                                      prefix: _fieldIcon(colors, Icons.business_rounded),
                                    ),
                                    Spacing.v16,
                                    _fieldLabel(colors, 'Owner Name'),
                                    Spacing.v6,
                                    AppTextField(
                                      controller: controller.ownerNameController,
                                      validator: (v) => controller.validateOwnerName(context, v),
                                      hintText: 'Enter your name',
                                      textInputAction: TextInputAction.next,
                                      prefix: _fieldIcon(colors, Icons.person_outline_rounded),
                                    ),
                                    Spacing.v16,
                                    _fieldLabel(colors, 'WhatsApp Number'),
                                    Spacing.v6,
                                    AppTextField(
                                      controller: controller.whatsappController,
                                      validator: (v) => controller.validateWhatsApp(context, v),
                                      hintText: '10-digit mobile number',
                                      textInputType: TextInputType.phone,
                                      textInputAction: TextInputAction.done,
                                      prefix: _fieldIcon(colors, Icons.phone_android_outlined),
                                    ),
                                    Spacing.v32,
                                    Obx(
                                      () => appButton(
                                        onPressed: () {
                                          if (!controller.isSubmitLoading.value) {
                                            controller.onSubmitPressed(context);
                                          }
                                        },
                                        buttonText: controller.isSubmitLoading.value ? '' : 'Register Agency',
                                        buttonIcon: controller.isSubmitLoading.value
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
              icon: const Icon(Icons.arrow_back_ios_new, color: kColorWhite, size: 20),
            ),
          ),
          const SemiBoldText(
            text: 'Register Agency',
            fontSize: TextStyles.k18FontSize,
            color: kColorWhite,
          ),
        ],
      ),
    );
  }

  Widget _formHeader(AppThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BoldText(
          text: 'Become an Agency Owner',
          fontSize: TextStyles.k22FontSize,
          color: colors.textPrimary,
        ),
        Spacing.v4,
        AppText(
          text: 'Fill out this form to register your own agency and start recruiting hosts.',
          fontSize: TextStyles.k12FontSize,
          color: colors.textSecondary,
        ),
      ],
    );
  }

  Widget _agencyLogoPicker(BuildContext context, AppThemeColors colors) {
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
                color: colors.surfaceMuted,
                border: Border.all(color: colors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: file != null
                    ? Image.file(file, fit: BoxFit.cover)
                    : Center(
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 32,
                          color: colors.iconMuted,
                        ),
                      ),
              ),
            ),
            Spacing.v8,
            AppText(
              text: 'Upload Agency Logo',
              fontSize: TextStyles.k12FontSize,
              color: colors.textSecondary,
            ),
          ],
        ),
      );
    });
  }

  Widget _fieldLabel(AppThemeColors colors, String label) {
    return AppText(
      text: label,
      fontSize: TextStyles.k12FontSize,
      color: colors.textPrimary,
    );
  }

  Widget _fieldIcon(AppThemeColors colors, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 12),
      child: Icon(icon, size: 20, color: colors.iconMuted),
    );
  }
}
