import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/repo/agency/agency_api_utils.dart';
import 'package:qobo_one_live/repo/agency/agency_repo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/agency_session_controller.dart';
import 'package:qobo_one_live/utils/app_dialogs/common_giffy_dialog.dart';
import 'package:qobo_one_live/utils/app_widgets/common_media_picker.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';
import 'package:qobo_one_live/utils/validations/text_field_validations.dart';

class AgencyOwnerRegisterController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final AgencyRepo _agencyRepo = AgencyRepo();

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
    if (!isFormValid) return;

    final agencyName = agencyNameController.text.trim();
    final ownerName = ownerNameController.text.trim();
    final phone = whatsappController.text.trim();

    isSubmitLoading.value = true;

    if (!Get.isRegistered<AgencySessionController>()) {
      Get.put(AgencySessionController(), permanent: true);
    }
    final session = Get.find<AgencySessionController>();

    try {
      final response = await _agencyRepo.registerAgency(
        agencyName: agencyName,
        ownerName: ownerName,
        ownerWhatsapp: phone,
        isShowLoader: false,
      );

      final data = response?['data'];
      if (isAgencyApiSuccess(response) && data is Map) {
        final map = Map<String, dynamic>.from(data);
        session.appliedAgencyName.value = agencyName;
        session.appliedOwnerName.value = ownerName;
        session.appliedPhone.value = phone;
        await session.applyRegisterResponse(map);
        isSubmitLoading.value = false;
        if (!context.mounted) return;

        final status = map['status']?.toString() ?? '';
        final isPending = isAgencyStatusPending(status);

        await CommonGiffyDialog.showSuccess(
          context,
          title: isPending ? 'Application Submitted' : 'Agency Registered',
          subtitle: isPending
              ? (response?['message']?.toString() ??
                    'Your agency "$agencyName" is pending approval. Check the dashboard for status updates.')
              : (response?['message']?.toString() ??
                    'Your agency "$agencyName" is active. Open the dashboard to manage hosts and revenue.'),
          buttonText: 'Open Dashboard',
          gifAssetPath: kGifCongratulation,
          onPressed: () {
            Get.back<void>();
            Get.offNamed(Routes.AGENCY_OWNER);
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
}
