import 'dart:io';

import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/generated/locales.g.dart';
import 'package:qobo_one_live/constants/local_storage_constants.dart';
import 'package:qobo_one_live/repo/auth/auth_repo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/app_dialogs/common_giffy_dialog.dart';
import 'package:qobo_one_live/utils/app_widgets/common_media_picker.dart';
import 'package:qobo_one_live/utils/local_storage/controllers/local_storage_controller.dart';
import 'package:qobo_one_live/utils/profile/stored_profile_map.dart';
import 'package:qobo_one_live/utils/profile/update_profile_api_helper.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';
import 'package:qobo_one_live/utils/validations/text_field_validations.dart';

/// Controller for update profile flow (wire API + state here).
class UpdateProfileController extends GetxController {
  UpdateProfileController({AuthRepo? authRepo})
    : _authRepo = authRepo ?? AuthRepo();

  final AuthRepo _authRepo;
  final UserSessionController _userSession =
      Get.isRegistered<UserSessionController>()
      ? Get.find<UserSessionController>()
      : Get.put(UserSessionController(), permanent: true);

  /// `true` when opened right after OTP verification; otherwise `false`.
  final isComeFromOtpScreen = false.obs;
  final formKey = GlobalKey<FormState>();

  final userNameController = TextEditingController();
  final birthdateController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final selectedGender = ''.obs;
  final selectedAge = RxnInt();
  final selectedBirthdate = Rxn<DateTime>();
  final selectedProfileMedia = Rxn<File>();
  final hasAcceptedTerms = false.obs;
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
    _prefillFromStoredProfile();
  }

  /// Prefills profile fields for edit flow (skips OTP onboarding flow).
  Future<void> _prefillFromStoredProfile() async {
    if (isComeFromOtpScreen.value) return;

    await _userSession.loadFromStorage();
    final root = _userSession.profileData;
    if (root == null || root.isEmpty) return;

    final data = coalesceStoredProfileMap(root);

    final nameRaw = firstPresent(data, const [
      'name',
      'username',
      'userName',
      'fullName',
    ]);
    final name = nameRaw?.toString().trim() ?? '';
    if (name.isNotEmpty) userNameController.text = name;

    final genderLabel = genderLabelFromStored(
      firstPresent(data, const ['gender', 'sex']),
    );
    if (genderLabel.isNotEmpty) selectedGender.value = genderLabel;

    _prefillAgeAndDob(data);
    hasAcceptedTerms.value = true;
  }

  void _prefillAgeAndDob(Map<String, dynamic> data) {
    final dobParsed = parseStoredDob(
      firstPresent(data, const [
        'dob',
        'dateOfBirth',
        'birthDate',
        'birthday',
        'date_of_birth',
      ]),
    );
    if (dobParsed != null) {
      selectedBirthdate.value = dobParsed;
      final age = _ageFromDob(dobParsed);
      selectedAge.value = age;
      birthdateController.text = age.toString();
      return;
    }

    final agePresent = firstPresent(data, const ['age', 'userAge']);
    final age = agePresent is int
        ? agePresent
        : int.tryParse(agePresent?.toString().trim() ?? '');
    if (age != null && age > 0) {
      _applySelectedAge(age);
    }
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

  /// Opens a bottom-sheet wheel picker for integer age values.
  /// We still derive/store DOB internally so API contract remains unchanged.
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

  bool validateForm(BuildContext context) {
    final formValid = formKey.currentState?.validate() ?? false;
    return formValid;
  }

  Future<void> onPrimaryActionPressed(BuildContext context) async {
    if (isSubmitLoading.value) return;
    if (!validateForm(context)) return;
    if (!hasAcceptedTerms.value) {
      AppToast.showError(context, LocaleKeys.termsRequiredError.tr);
      return;
    }
    if (selectedGender.value.trim().isEmpty) {
      AppToast.showError(context, 'Please select gender');
      return;
    }

    try {
      isSubmitLoading.value = true;
      final request = UpdateProfileApiHelper.buildRequest(
        name: userNameController.text.trim(),
        genderLabel: selectedGender.value,
        dob: selectedBirthdate.value,
        displayPicture: selectedProfileMedia.value,
      );
      final response = await _authRepo.updateProfile(
        request: request,
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
        await UpdateProfileApiHelper.persistUserToSession(response);
        final storage = Get.isRegistered<LocalStorage>()
            ? Get.find<LocalStorage>()
            : Get.put(LocalStorage(), permanent: true);
        await storage.writeBoolStorage(kStorageIsLoggedIn, true);
        if (!context.mounted) return;

        // For OTP onboarding flow, show a success dialog before leaving this screen.
        if (isComeFromOtpScreen.value) {
          await CommonGiffyDialog.showSuccess(
            context,
            subtitle: LocaleKeys.verifySuccessDialogSubtitle.tr,
            buttonText: LocaleKeys.verifySuccessDialogButton.tr,
            gifAssetPath: kGifCongratulation,
            onPressed: () {
              // Dialog closes first in CommonGiffyDialog, then navigation runs.
              Get.offAllNamed(Routes.BOTTOM_NAV);
            },
          );
          return;
        }

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

  void toggleTermsAcceptance() {
    hasAcceptedTerms.value = !hasAcceptedTerms.value;
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
        AppToast.showError(context, e.message ?? 'Unable to access media.');
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
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return Validate.passwordValidation(context, trimmed);
  }

  String? validateConfirmPassword(BuildContext context, String? value) {
    final trimmed = value?.trim() ?? '';
    if (passwordController.text.trim().isEmpty && trimmed.isEmpty) {
      return null;
    }
    return Validate.confirmPasswordValidation(
      context,
      trimmed,
      passwordController.text.trim(),
    );
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

  @override
  void onClose() {
    userNameController.dispose();
    birthdateController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
