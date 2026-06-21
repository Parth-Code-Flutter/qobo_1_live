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
import 'package:qobo_one_live/repo/agency/agency_api_utils.dart';
import 'package:qobo_one_live/repo/agency/agency_repo.dart';
import 'package:qobo_one_live/services/agency_session_controller.dart';

import '../models/agency_host_interest.dart';
import '../models/agency_host_type.dart';
import '../widgets/agency_host_category_picker.dart';

class AgencyHostOnboardingController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final AgencyRepo _agencyRepo = AgencyRepo();

  final hostNameController = TextEditingController();
  final birthdayController = TextEditingController();
  final hostIdController = TextEditingController();
  final whatsAppController = TextEditingController();
  final gmailController = TextEditingController();
  final countryRegionController = TextEditingController();
  final stateController = TextEditingController();
  final addressController = TextEditingController();
  final agencyCodeController = TextEditingController();

  final selectedBirthday = Rxn<DateTime>();
  final selectedType = Rxn<AgencyHostType>();
  final selectedInterest = Rxn<AgencyHostInterest>();
  final hostPhoto = Rxn<File>();
  final docPhotoFront = Rxn<File>();
  final docPhotoBack = Rxn<File>();
  final isSubmitLoading = false.obs;
  final isAgencyCodeLocked = false.obs;
  final isAgencyCodePrefilling = false.obs;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    _prefillAgencyCode();
  }

  Future<void> _prefillAgencyCode() async {
    final args = Get.arguments;
    if (args is Map) {
      final code = args['agencyCode']?.toString().trim();
      if (code != null && code.isNotEmpty) {
        agencyCodeController.text = code;
        if (args['lockAgencyCode'] == true) {
          isAgencyCodeLocked.value = true;
        }
        return;
      }
    }

    isAgencyCodePrefilling.value = true;
    try {
      if (!Get.isRegistered<AgencySessionController>()) {
        Get.put(AgencySessionController(), permanent: true);
      }
      final session = Get.find<AgencySessionController>();
      await session.loadFromStorage();
      final code = await session.resolveApprovedAgencyCode();
      if (code != null && code.isNotEmpty) {
        agencyCodeController.text = code;
        isAgencyCodeLocked.value = true;
      }
    } finally {
      isAgencyCodePrefilling.value = false;
    }
  }

  @override
  void onClose() {
    hostNameController.dispose();
    birthdayController.dispose();
    hostIdController.dispose();
    whatsAppController.dispose();
    gmailController.dispose();
    countryRegionController.dispose();
    stateController.dispose();
    addressController.dispose();
    agencyCodeController.dispose();
    super.onClose();
  }

  Future<void> pickBirthday(BuildContext context) async {
    final now = DateTime.now();
    final initial =
        selectedBirthday.value ?? DateTime(now.year - 22, now.month, now.day);
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

  void selectType(AgencyHostType type) {
    selectedType.value = type;
  }

  Future<void> pickCategory(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final picked = await showAgencyHostCategoryPicker(
      context,
      selected: selectedInterest.value,
    );
    if (picked != null) {
      selectInterest(picked);
    }
  }

  void selectInterest(AgencyHostInterest? interest) {
    selectedInterest.value = interest;
  }

  Future<void> onHostPhotoTap(BuildContext context) async {
    final file = await _pickImage(context);
    if (file != null) hostPhoto.value = file;
  }

  Future<void> onDocPhotoFrontTap(BuildContext context) async {
    final file = await _pickImage(context);
    if (file != null) docPhotoFront.value = file;
  }

  Future<void> onDocPhotoBackTap(BuildContext context) async {
    final file = await _pickImage(context);
    if (file != null) docPhotoBack.value = file;
  }

  Future<File?> _pickImage(BuildContext context) async {
    final source = await CommonMediaPicker.show(context);
    if (source == null) return null;
    final file = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (file == null) return null;
    return File(file.path);
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

  String? validateRequiredField(String? value, String label) {
    if ((value ?? '').trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  String? validateCountryRegion(String? value) {
    return validateRequiredField(value, 'Country');
  }

  String? validateState(String? value) {
    return validateRequiredField(value, 'State');
  }

  String? validateAddress(String? value) {
    return validateRequiredField(value, 'Address');
  }

  String? validateAgencyCode(BuildContext context, String? value) {
    final code = (value ?? '').trim();
    if (code.isEmpty) return 'Agency code is required';
    return null;
  }

  String? validateType() {
    if (selectedType.value == null) {
      return 'Please select a type (Audio or Video)';
    }
    return null;
  }

  String? validateInterest() {
    if (selectedInterest.value == null) {
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

  String? validateDocPhotos() {
    if (docPhotoFront.value == null) {
      return 'Government document front photo is required';
    }
    if (docPhotoBack.value == null) {
      return 'Government document back photo is required';
    }
    return null;
  }

  Future<void> onSubmitPressed(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final isFormValid = formKey.currentState?.validate() ?? false;
    final typeError = validateType();
    final interestError = validateInterest();
    final photoError = validatePhoto();
    final docPhotoError = validateDocPhotos();

    if (!isFormValid ||
        typeError != null ||
        interestError != null ||
        photoError != null ||
        docPhotoError != null) {
      if (typeError != null) {
        AppToast.showError(context, typeError);
      } else if (interestError != null) {
        AppToast.showError(context, interestError);
      } else if (photoError != null) {
        AppToast.showError(context, photoError);
      } else if (docPhotoError != null) {
        AppToast.showError(context, docPhotoError);
      }
      return;
    }

    final birthday = selectedBirthday.value;
    if (birthday == null) {
      AppToast.showError(context, 'Birthday is required');
      return;
    }

    isSubmitLoading.value = true;
    final whatsapp = whatsAppController.text.trim();
    final response = await _agencyRepo.hostOnboarding(
      agencyCode: agencyCodeController.text.trim(),
      hostName: hostNameController.text.trim(),
      gmail: gmailController.text.trim(),
      whatsapp: whatsapp,
      type: selectedType.value!.apiValue,
      category: selectedInterest.value!.apiValue,
      countryRegion: countryRegionController.text.trim(),
      state: stateController.text.trim(),
      address: addressController.text.trim(),
      hostRealPhoto: hostPhoto.value!,
      docPhotoFront: docPhotoFront.value!,
      docPhotoBack: docPhotoBack.value!,
      dob: formatAgencyHostDob(birthday),
      idNo: hostIdController.text.trim(),
      isShowLoader: false,
    );
    isSubmitLoading.value = false;

    if (!context.mounted) return;

    if (isAgencyApiSuccess(response)) {
      final appData = response?['data'];
      final appId = appData is Map<String, dynamic>
          ? parseHostApplicationId(appData)
          : appData is Map
          ? parseHostApplicationId(Map<String, dynamic>.from(appData))
          : null;
      if (appId == null) {
        AppToast.showError(
          context,
          'Application submitted but no application ID was returned.',
        );
        return;
      }
      await CommonGiffyDialog.showSuccess(
        context,
        title: 'Application Submitted',
        subtitle:
            agencyApiMessage(response) ??
            'Your host application has been submitted successfully!',
        buttonText: 'Check Status',
        gifAssetPath: kGifCongratulation,
        onPressed: () {
          Get.back<void>();
          Get.offNamed(
            Routes.AGENCY_HOST_STATUS,
            arguments: {'application_id': appId, 'phone': whatsapp},
          );
        },
      );
    } else {
      final msg =
          agencyApiMessage(response) ??
          'Failed to submit host onboarding application';
      AppToast.showError(context, msg);
    }
  }
}
