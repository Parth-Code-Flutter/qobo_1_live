import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_dialogs/common_giffy_dialog.dart';
import 'package:qobo_one_live/utils/app_widgets/common_media_picker.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';
import 'package:qobo_one_live/utils/validations/text_field_validations.dart';
import 'package:qobo_one_live/routes/app_pages.dart';

class AgencyOwnerRegisterController extends GetxController {
  final formKey = GlobalKey<FormState>();

  final agencyNameController = TextEditingController();
  final ownerNameController = TextEditingController();
  final whatsappController = TextEditingController();

  final agencyLogo = Rxn<File>();
  final isSubmitLoading = false.obs;
  
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void onClose() {
    agencyNameController.dispose();
    ownerNameController.dispose();
    whatsappController.dispose();
    super.onClose();
  }

  Future<void> onLogoTap(BuildContext context) async {
    final source = await CommonMediaPicker.show(context);
    if (source == null) return;
    
    final file = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (file == null) return;
    agencyLogo.value = File(file.path);
  }

  String? validateAgencyName(BuildContext context, String? value) {
    if ((value ?? '').trim().isEmpty) return 'Agency name is required';
    return null;
  }

  String? validateOwnerName(BuildContext context, String? value) {
    return Validate.nameValidation(context, value ?? '');
  }

  String? validateWhatsApp(BuildContext context, String? value) {
    return Validate.phone10DigitValidation(context, value ?? '');
  }

  Future<void> onSubmitPressed(BuildContext context) async {
    FocusScope.of(context).unfocus();
    
    final isFormValid = formKey.currentState?.validate() ?? false;
    if (agencyLogo.value == null) {
      AppToast.showError(context, 'Agency logo is required');
      return;
    }

    if (!isFormValid) return;

    isSubmitLoading.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 600));
    isSubmitLoading.value = false;

    if (!context.mounted) return;
    
    await CommonGiffyDialog.showSuccess(
      context,
      title: 'Agency Registered',
      subtitle: 'Your agency has been successfully registered locally.',
      buttonText: 'Get Recruit Link',
      gifAssetPath: kGifCongratulation,
      onPressed: () {
        Get.back<void>(); // close dialog
        Get.offNamed(Routes.AGENCY_RECRUIT_LINK);
      },
    );
  }
}
