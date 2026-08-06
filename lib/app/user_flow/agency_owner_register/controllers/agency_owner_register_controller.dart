import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qobo_one_live/app/super_admin/bottom_nav/controllers/super_admin_bottom_nav_controller.dart';
import 'package:qobo_one_live/app/super_admin/home/controllers/super_admin_home_controller.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/repo/agency/agency_api_utils.dart';
import 'package:qobo_one_live/repo/agency/agency_repo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/agency_session_controller.dart';
import 'package:qobo_one_live/utils/app_dialogs/common_giffy_dialog.dart';
import 'package:qobo_one_live/utils/app_widgets/common_media_picker.dart';
import 'package:qobo_one_live/utils/files_utils/file_utils.dart';
import 'package:qobo_one_live/utils/geo/country_state_selection_mixin.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';
import 'package:qobo_one_live/utils/validations/text_field_validations.dart';

class AgencyOwnerRegisterController extends GetxController
    with CountryStateSelectionMixin {
  final formKey = GlobalKey<FormState>();
  final AgencyRepo _agencyRepo = AgencyRepo();

  final agencyNameController = TextEditingController();
  final ownerNameController = TextEditingController();
  final whatsappController = TextEditingController();
  final emailController = TextEditingController();
  final countryCodeController = TextEditingController(text: '+91');
  final passwordController = TextEditingController();
  final cityController = TextEditingController();
  final addressController = TextEditingController();

  final agencyLogo = Rxn<File>();
  final docPhotoFront = Rxn<File>();
  final docPhotoBack = Rxn<File>();
  final isSubmitLoading = false.obs;
  final isPublicInvite = false.obs;
  final invitedBy = ''.obs;

  /// True when a super admin opened this form from the Agency tab FAB —
  /// success should return to the super admin shell, not the login screen.
  final isFromSuperAdmin = false.obs;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    final argInvitedBy = args is Map ? args['invitedBy']?.toString() : null;
    final paramInvitedBy =
        Get.parameters['invitedBy'] ?? Get.parameters['invited_by'];
    final value = (argInvitedBy ?? paramInvitedBy ?? '').trim();
    invitedBy.value = value;
    isPublicInvite.value = value.isNotEmpty;
    isFromSuperAdmin.value = args is Map && args['fromSuperAdmin'] == true;
  }

  @override
  void onClose() {
    agencyNameController.dispose();
    ownerNameController.dispose();
    whatsappController.dispose();
    emailController.dispose();
    countryCodeController.dispose();
    passwordController.dispose();
    cityController.dispose();
    addressController.dispose();
    super.onClose();
  }

  Future<void> onLogoTap(BuildContext context) async {
    final source = await CommonMediaPicker.show(context);
    if (source == null) return;

    final file = await _imagePicker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    agencyLogo.value = File(file.path);
  }

  Future<void> pickDocumentFront(BuildContext context) async {
    final file = await _pickSingleDocument(context);
    if (file != null) docPhotoFront.value = file;
  }

  Future<void> pickDocumentBack(BuildContext context) async {
    final file = await _pickSingleDocument(context);
    if (file != null) docPhotoBack.value = file;
  }

  Future<File?> _pickSingleDocument(BuildContext context) async {
    final paths = await FileUtils.pickFilePaths();
    if (paths.isEmpty) return null;
    return File(paths.first);
  }

  String? validateAgencyName(BuildContext context, String? value) {
    return Validate.agencyNameValidation(context, value ?? '');
  }

  String? validateOwnerName(BuildContext context, String? value) {
    return Validate.nameValidation(
      context,
      value ?? '',
      label: 'Owner name',
    );
  }

  String? validateWhatsApp(BuildContext context, String? value) {
    return Validate.phone10DigitValidation(context, value ?? '');
  }

  String? validateEmail(BuildContext context, String? value) {
    return Validate.emailValidation(context, value ?? '');
  }

  String? validatePassword(BuildContext context, String? value) {
    return Validate.passwordValidation(context, value ?? '', minLength: 6);
  }

  String? validateCountryCode(BuildContext context, String? value) {
    return Validate.countryCodeValidation(context, value ?? '');
  }

  String? validateRequired(String label, String? value) {
    if ((value ?? '').trim().isEmpty) return '$label is required';
    return null;
  }

  Future<void> onSubmitPressed(BuildContext context) async {
    FocusScope.of(context).unfocus();

    final isFormValid = formKey.currentState?.validate() ?? false;
    if (!isFormValid) return;

    if (isPublicInvite.value) {
      final countryError = validateCountrySelection();
      if (countryError != null) {
        AppToast.showError(context, countryError);
        return;
      }
      final stateError = validateStateSelection();
      if (stateError != null) {
        AppToast.showError(context, stateError);
        return;
      }
    }

    final agencyName = agencyNameController.text.trim();
    final ownerName = ownerNameController.text.trim();
    // Keep only digits for WhatsApp / mobile (enforced as 10 digits).
    final phone = whatsappController.text.trim().replaceAll(RegExp(r'\D'), '');
    whatsappController.text = phone;

    isSubmitLoading.value = true;

    if (!Get.isRegistered<AgencySessionController>()) {
      Get.put(AgencySessionController(), permanent: true);
    }
    final session = Get.find<AgencySessionController>();

    try {
      final response = isPublicInvite.value
          ? await _submitPublicAgencyRegistration(context)
          : await _agencyRepo.registerAgency(
              agencyName: agencyName,
              ownerName: ownerName,
              ownerWhatsapp: phone,
              isShowLoader: false,
            );

      final data = response?['data'];
      if (isAgencyApiSuccess(response) && data is Map) {
        final map = Map<String, dynamic>.from(data);
        final fromSuperAdmin = isFromSuperAdmin.value;

        // Super admin creates agencies for others — do not overwrite their session.
        if (!fromSuperAdmin) {
          session.appliedAgencyName.value = agencyName;
          session.appliedOwnerName.value = ownerName;
          session.appliedPhone.value = phone;
          await session.applyRegisterResponse(map);
        }

        isSubmitLoading.value = false;
        if (!context.mounted) return;

        final status = map['status']?.toString() ?? '';
        final isPending = isAgencyStatusPending(status);
        final publicInvite = isPublicInvite.value;

        await CommonGiffyDialog.showSuccess(
          context,
          title: publicInvite || isPending
              ? 'Application Submitted'
              : 'Agency Registered',
          subtitle: fromSuperAdmin
              ? (response?['message']?.toString() ??
                    'Agency "$agencyName" was created and is pending in the Agency tab. Approve it to activate the owner account.')
              : publicInvite
              ? (response?['message']?.toString() ??
                    'Your agency application is pending super admin approval. Please login after approval.')
              : isPending
              ? (response?['message']?.toString() ??
                    'Your agency "$agencyName" is pending approval. Check the dashboard for status updates.')
              : (response?['message']?.toString() ??
                    'Your agency "$agencyName" is active. Open the dashboard to manage hosts and revenue.'),
          buttonText: fromSuperAdmin
              ? 'Back to Agencies'
              : publicInvite
              ? 'Back to Login'
              : 'Open Dashboard',
          gifAssetPath: kGifCongratulation,
          onPressed: () {
            Get.back<void>();
            if (fromSuperAdmin) {
              _returnToSuperAdminAgencyListing();
              return;
            }
            Get.offNamed(
              publicInvite ? Routes.AUTH_LOGIN : Routes.AGENCY_OWNER,
            );
          },
        );
        return;
      }

      final message =
          agencyApiMessage(response) ??
          'Registration failed. Please try again.';
      isSubmitLoading.value = false;
      if (context.mounted) {
        AppToast.showError(context, message);
      }
    } catch (_) {
      isSubmitLoading.value = false;
      if (context.mounted) {
        AppToast.showError(context, 'Failed to register agency. Try again.');
      }
    }
  }

  Future<Map<String, dynamic>?> _submitPublicAgencyRegistration(
    BuildContext context,
  ) async {
    final front = docPhotoFront.value;
    final back = docPhotoBack.value;
    if (agencyLogo.value == null) {
      isSubmitLoading.value = false;
      AppToast.showError(context, 'Please upload agency logo.');
      return null;
    }
    if (front == null || back == null) {
      isSubmitLoading.value = false;
      AppToast.showError(context, 'Please upload both document photos.');
      return null;
    }

    return _agencyRepo.registerAgencyPublic(
      agencyName: agencyNameController.text,
      ownerName: ownerNameController.text,
      email: emailController.text,
      phone: whatsappController.text,
      countryCode: countryCodeController.text,
      password: passwordController.text,
      invitedBy: invitedBy.value,
      country: selectedCountry.value?.name ?? '',
      state: selectedState.value?.name ?? '',
      city: cityController.text,
      address: addressController.text,
      agencyLogo: agencyLogo.value,
      docPhotoFront: front,
      docPhotoBack: back,
      isShowLoader: false,
    );
  }

  /// Pop the register form and land on Super Admin → Agency listing.
  void _returnToSuperAdminAgencyListing() {
    Get.back<void>();

    if (Get.isRegistered<SuperAdminBottomNavController>()) {
      Get.find<SuperAdminBottomNavController>().onNavBarTabSelected(
        SuperAdminBottomNavController.agencyTabIndex,
      );
    }
    if (Get.isRegistered<SuperAdminHomeController>()) {
      Get.find<SuperAdminHomeController>().loadAgencies(showLoader: false);
      Get.find<SuperAdminHomeController>().loadDashboardStats(showLoader: false);
    }
  }
}
