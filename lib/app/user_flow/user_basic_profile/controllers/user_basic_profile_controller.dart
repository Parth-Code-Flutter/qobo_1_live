import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/generated/locales.g.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/app_widgets/common_media_picker.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';
import 'package:qobo_one_live/utils/validations/text_field_validations.dart';

/// Basic profile capture (photo + core fields). Wire `/api` here when ready.
class UserBasicProfileController extends GetxController {
  UserBasicProfileController();

  UserSessionController? get _userSession =>
      Get.isRegistered<UserSessionController>()
      ? Get.find<UserSessionController>()
      : null;

  final formKey = GlobalKey<FormState>();
  final userNameController = TextEditingController();
  final birthdateController = TextEditingController();

  final selectedGender = ''.obs;
  final selectedAge = Rxn<int>();
  final selectedBirthdate = Rxn<DateTime>();
  final selectedProfileMedia = Rxn<File>();
  final isSubmitLoading = false.obs;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    _prefillFromSession();
  }

  /// Light prefill when session already has name / gender / age hints.
  Future<void> _prefillFromSession() async {
    final session = _userSession;
    if (session == null) return;
    await session.loadFromStorage();
    final data = session.profileData;
    if (data == null || data.isEmpty) return;

    final name = (data['name'] ?? '').toString().trim();
    if (name.isNotEmpty) userNameController.text = name;

    final genderRaw = (data['gender'] ?? '').toString().trim().toLowerCase();
    if (genderRaw.isNotEmpty) {
      selectedGender.value = genderRaw == 'female' ? 'Female' : 'Male';
    }

    final dobRaw = (data['dob'] ?? '').toString().trim();
    if (dobRaw.isNotEmpty) {
      final parsed = DateTime.tryParse(dobRaw);
      if (parsed != null) {
        selectedBirthdate.value = parsed;
        final age = _ageFromDob(parsed);
        selectedAge.value = age;
        birthdateController.text = age.toString();
        return;
      }
    }

    final ageRaw = (data['age'] ?? '').toString().trim();
    final age = int.tryParse(ageRaw);
    if (age != null && age > 0) _applySelectedAge(age);
  }

  int _ageFromDob(DateTime dob) {
    final now = DateTime.now();
    var years = now.year - dob.year;
    final hadBirthday =
        (now.month > dob.month) ||
        (now.month == dob.month && now.day >= dob.day);
    if (!hadBirthday) years -= 1;
    return years.clamp(0, 150);
  }

  void _applySelectedAge(int age) {
    selectedAge.value = age;
    birthdateController.text = age.toString();
    selectedBirthdate.value = _dobFromAge(age);
  }

  DateTime _dobFromAge(int age) {
    final now = DateTime.now();
    return DateTime(now.year - age, now.month, now.day);
  }

  /// Same UX as [UpdateProfileController.pickAge] (wheel picker).
  Future<void> pickAge(BuildContext context) async {
    const int minAge = 13;
    const int maxAge = 100;
    final ageValues = List<int>.generate(
      maxAge - minAge + 1,
      (index) => minAge + index,
    );
    final initialAge = (selectedAge.value ?? 18).clamp(minAge, maxAge);
    var temporaryAge = initialAge;
    final scrollController = FixedExtentScrollController(
      initialItem: ageValues.indexOf(initialAge),
    );

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: kColorWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: 300,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          LocaleKeys.selectAgeTitle.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: kColorText,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _applySelectedAge(temporaryAge);
                          Navigator.of(sheetContext).pop();
                        },
                        child: Text(LocaleKeys.doneText.tr),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: CupertinoPicker(
                    scrollController: scrollController,
                    itemExtent: 42,
                    useMagnifier: true,
                    magnification: 1.08,
                    onSelectedItemChanged: (index) {
                      temporaryAge = ageValues[index];
                    },
                    children: ageValues
                        .map(
                          (age) => Center(
                            child: Text(
                              '$age',
                              style: const TextStyle(
                                fontSize: 20,
                                color: kColorText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String? validateBirthdate(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return LocaleKeys.ageRequiredError.tr;
    }
    return null;
  }

  String? validateUserName(BuildContext context, String? value) {
    return Validate.nameValidation(context, value?.trim() ?? '');
  }

  /// Opens gallery/camera via shared picker (same as update profile).
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
        AppToast.showError(context, e.message ?? 'Unable to access media.');
      }
    } catch (_) {
      if (context.mounted) {
        AppToast.showError(context, 'Unable to access media.');
      }
    }
  }

  /// Validates form + gender; extend with API/repo call later.
  Future<void> onSavePressed(BuildContext context) async {
    if (isSubmitLoading.value) return;
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (selectedGender.value.trim().isEmpty) {
      AppToast.showError(context, 'Please select gender');
      return;
    }

    try {
      isSubmitLoading.value = true;
      // TODO(user_basic_profile): POST payload via repo when endpoint exists.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!context.mounted) return;
      AppToast.showSuccess(context, 'Basic profile saved.');
    } finally {
      isSubmitLoading.value = false;
    }
  }

  @override
  void onClose() {
    userNameController.dispose();
    birthdateController.dispose();
    super.onClose();
  }
}
