import 'dart:io';

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qobo_one_live/constants/local_storage_constants.dart';
import 'package:qobo_one_live/repo/auth/auth_repo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/utils/app_widgets/common_media_picker.dart';
import 'package:qobo_one_live/utils/local_storage/controllers/local_storage_controller.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';
import 'package:qobo_one_live/utils/validations/text_field_validations.dart';

/// Controller for update profile flow (wire API + state here).
class UpdateProfileController extends GetxController {
  UpdateProfileController({AuthRepo? authRepo}) : _authRepo = authRepo ?? AuthRepo();

  final AuthRepo _authRepo;

  /// `true` when opened right after OTP verification; otherwise `false`.
  final isComeFromOtpScreen = false.obs;
  final formKey = GlobalKey<FormState>();

  final userNameController = TextEditingController();
  final birthdateController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final selectedGender = ''.obs;
  final selectedBirthdate = Rxn<DateTime>();
  final selectedProfileMedia = Rxn<File>();
  final isPasswordHidden = true.obs;
  final isConfirmPasswordHidden = true.obs;
  final isSubmitLoading = false.obs;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['isComeFromOtpScreen'] == true) {
      isComeFromOtpScreen.value = true;
    }
  }

  Future<void> pickBirthdate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedBirthdate.value ?? DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked == null) return;

    selectedBirthdate.value = picked;
    final month = picked.month.toString().padLeft(2, '0');
    final day = picked.day.toString().padLeft(2, '0');
    birthdateController.text = '${picked.year}-$month-$day';
  }

  String? validateBirthdate(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Birthdate is required';
    }
    return null;
  }

  bool validateForm(BuildContext context) {
    final formValid = formKey.currentState?.validate() ?? false;
    return formValid;
  }

  Future<void> onPrimaryActionPressed(BuildContext context) async {
    if (isSubmitLoading.value) return;
    if (!validateForm(context)) return;

    try {
      isSubmitLoading.value = true;
      final response = await _authRepo.updateProfile(
        name: userNameController.text.trim(),
        gender: selectedGender.value.trim().toLowerCase(),
        dob: birthdateController.text.trim(),
        // Country can be changed once country selection UI is added.
        country: 'IN',
        password: passwordController.text.trim(),
        displayPicture: selectedProfileMedia.value,
        isShowLoader: false,
      );
      if (!context.mounted) return;

      if (response == null) {
        AppToast.showError(context, 'Request failed. Please try again.');
        return;
      }

      final message = response.message.trim().isNotEmpty
          ? response.message.trim()
          : 'Something went wrong.';
      if (response.statusCode == 1) {
        final storage = Get.isRegistered<LocalStorage>()
            ? Get.find<LocalStorage>()
            : Get.put(LocalStorage(), permanent: true);
        await storage.writeBoolStorage(kStorageIsLoggedIn, true);
        if (!context.mounted) return;
        AppToast.showSuccess(context, message);
        Get.offAllNamed(Routes.BOTTOM_NAV);
      } else {
        AppToast.showError(context, message);
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, e.toString());
      }
    } finally {
      isSubmitLoading.value = false;
    }
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordHidden.value = !isConfirmPasswordHidden.value;
  }

  /// Opens common source picker, then stores selected media file for preview/API.
  Future<void> onProfileMediaTap(BuildContext context) async {
    try {
      final source = await CommonMediaPicker.show(context);
      if (source == null) return;

      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (pickedFile == null) return;

      selectedProfileMedia.value = File(pickedFile.path);
    } on MissingPluginException {
      if (context.mounted) {
        AppToast.showError(
          context,
          'Media picker is not ready. Please restart the app once.',
        );
      }
    } on PlatformException catch (e) {
      if (context.mounted) {
        AppToast.showError(
          context,
          e.message ?? 'Unable to access media.',
        );
      }
    } catch (_) {
      if (context.mounted) {
        AppToast.showError(context, 'Unable to access media.');
      }
    }
  }

  String? validateUserName(BuildContext context, String? value) {
    return Validate.nameValidation(context, value?.trim() ?? '');
  }

  String? validatePassword(BuildContext context, String? value) {
    return Validate.passwordValidation(context, value?.trim() ?? '');
  }

  String? validateConfirmPassword(BuildContext context, String? value) {
    return Validate.confirmPasswordValidation(
      context,
      value?.trim() ?? '',
      passwordController.text.trim(),
    );
  }

  @override
  void onClose() {
    userNameController.dispose();
    birthdateController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
