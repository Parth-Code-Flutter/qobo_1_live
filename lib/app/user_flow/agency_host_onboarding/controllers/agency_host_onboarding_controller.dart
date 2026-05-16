import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_dialogs/common_giffy_dialog.dart';
import 'package:qobo_one_live/utils/app_widgets/common_media_picker.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';
import 'package:qobo_one_live/utils/validations/text_field_validations.dart';
import 'package:qobo_one_live/routes/app_pages.dart';

import '../models/agency_host_category.dart';

/// Agency host onboarding — UI only; API wiring in a later pass.
class AgencyHostOnboardingController extends GetxController {
  final formKey = GlobalKey<FormState>();

  final hostNameController = TextEditingController();
  final birthdayController = TextEditingController();
  final hostIdController = TextEditingController();
  final whatsAppController = TextEditingController();
  final gmailController = TextEditingController();
  final agencyCodeController = TextEditingController();

  final selectedBirthday = Rxn<DateTime>();
  final selectedCategory = Rxn<AgencyHostCategory>();
  final hostPhoto = Rxn<File>();
  final isSubmitLoading = false.obs;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      final code = args['agencyCode']?.toString().trim();
      if (code != null && code.isNotEmpty) {
        agencyCodeController.text = code;
      }
    }
  }

  @override
  void onClose() {
    hostNameController.dispose();
    birthdayController.dispose();
    hostIdController.dispose();
    whatsAppController.dispose();
    gmailController.dispose();
    agencyCodeController.dispose();
    super.onClose();
  }

  Future<void> pickBirthday(BuildContext context) async {
    final now = DateTime.now();
    final initial = selectedBirthday.value ?? DateTime(now.year - 22, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: kColorPrimary),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null) return;
    selectedBirthday.value = picked;
    birthdayController.text =
        '${picked.day.toString().padLeft(2, '0')}/'
        '${picked.month.toString().padLeft(2, '0')}/'
        '${picked.year}';
  }

  void selectCategory(AgencyHostCategory category) {
    selectedCategory.value = category;
  }

  Future<void> onHostPhotoTap(BuildContext context) async {
    final source = await CommonMediaPicker.show(context);
    if (source == null) return;
    final file = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (file == null) return;
    hostPhoto.value = File(file.path);
  }

  String? validateHostName(BuildContext context, String? value) {
    return Validate.nameValidation(context, value ?? '');
  }

  String? validateBirthday(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Birthday is required';
    }
    return null;
  }

  String? validateHostId(BuildContext context, String? value) {
    final id = (value ?? '').trim();
    if (id.isEmpty) return 'Host ID number is required';
    return null;
  }

  String? validateWhatsApp(BuildContext context, String? value) {
    return Validate.phone10DigitValidation(context, value ?? '');
  }

  String? validateGmail(BuildContext context, String? value) {
    return Validate.emailValidation(context, value ?? '');
  }

  String? validateAgencyCode(BuildContext context, String? value) {
    final code = (value ?? '').trim();
    if (code.isEmpty) return 'Agency code is required';
    return null;
  }

  String? validateCategory() {
    if (selectedCategory.value == null) {
      return 'Please select a category';
    }
    return null;
  }

  String? validatePhoto() {
    if (hostPhoto.value == null) {
      return 'Host real photo is required';
    }
    return null;
  }

  Future<void> onSubmitPressed(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final isFormValid = formKey.currentState?.validate() ?? false;
    final categoryError = validateCategory();
    final photoError = validatePhoto();

    if (!isFormValid || categoryError != null || photoError != null) {
      if (categoryError != null) {
        AppToast.showError(context, categoryError);
      } else if (photoError != null) {
        AppToast.showError(context, photoError);
      }
      return;
    }

    isSubmitLoading.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    isSubmitLoading.value = false;

    if (!context.mounted) return;
    await CommonGiffyDialog.showSuccess(
      context,
      title: 'Application Submitted',
      subtitle:
          'Your host application has been saved locally.\nAPI integration coming next.',
      buttonText: 'Check Status',
      gifAssetPath: kGifCongratulation,
      onPressed: () {
        Get.back<void>(); // Dismiss dialog
        Get.offNamed(Routes.AGENCY_HOST_STATUS, arguments: {'application_id': 'APP-90210'});
      },
    );
  }
}
