import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/status_code_constants.dart';
import 'package:qobo_one_live/generated/locales.g.dart';
import 'package:qobo_one_live/repo/auth/auth_repo.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/app_widgets/common_media_picker.dart';
import 'package:qobo_one_live/utils/profile/stored_profile_map.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';
import 'package:qobo_one_live/utils/validations/text_field_validations.dart';

/// Basic profile capture (photo + core fields). Wire `/api` here when ready.
class UserBasicProfileController extends GetxController {
  UserBasicProfileController({AuthRepo? authRepo})
    : _authRepo = authRepo ?? AuthRepo();

  final AuthRepo _authRepo;

  UserSessionController _ensureSession() {
    if (Get.isRegistered<UserSessionController>()) {
      return Get.find<UserSessionController>();
    }
    return Get.put(UserSessionController(), permanent: true);
  }

  final formKey = GlobalKey<FormState>();
  final userNameController = TextEditingController();
  final birthdateController = TextEditingController();

  final selectedGender = ''.obs;
  final selectedAge = Rxn<int>();
  final selectedBirthdate = Rxn<DateTime>();
  final selectedProfileMedia = Rxn<File>();
  final isSubmitLoading = false.obs;

  /// True when name, age, gender, or profile image differs from last baseline.
  final isProfileDirty = false.obs;

  /// Selected row in profile extras card (0–5). Default: Languages (Figma).
  final selectedProfileExtraIndex = 1.obs;

  final ImagePicker _imagePicker = ImagePicker();

  String _baselineName = '';
  String _baselineAgeText = '';
  String _baselineGender = '';
  bool _baselineHadNewImage = false;

  static const int _profileExtraRowCount = 6;

  void selectProfileExtraRow(int index) {
    if (index < 0 || index >= _profileExtraRowCount) return;
    selectedProfileExtraIndex.value = index;
  }

  @override
  void onInit() {
    super.onInit();
    userNameController.addListener(_refreshProfileDirty);
    birthdateController.addListener(_refreshProfileDirty);
    ever<String>(selectedGender, (_) => _refreshProfileDirty());
    ever<File?>(selectedProfileMedia, (_) => _refreshProfileDirty());
  }

  /// Call after loading/saving so “dirty” compares to the latest server snapshot.
  void captureFormBaseline() {
    _baselineName = userNameController.text.trim();
    _baselineAgeText = birthdateController.text.trim();
    _baselineGender = selectedGender.value;
    _baselineHadNewImage = selectedProfileMedia.value != null;
    _refreshProfileDirty();
  }

  void _refreshProfileDirty() {
    final hasNewImage = selectedProfileMedia.value != null;
    final dirty =
        userNameController.text.trim() != _baselineName ||
        birthdateController.text.trim() != _baselineAgeText ||
        selectedGender.value != _baselineGender ||
        hasNewImage != _baselineHadNewImage;
    isProfileDirty.value = dirty;
  }

  @override
  void onReady() {
    super.onReady();
    fetchProfileAndPopulateForm();
  }

  /// Primary entry: GET `/api/user/profile`, persist, then bind fields.
  ///
  /// Falls back to disk/session snapshot only when the request fails or the
  /// envelope has no user row.
  Future<void> fetchProfileAndPopulateForm() async {
    final session = _ensureSession();
    await session.loadFromStorage();

    Map<String, dynamic>? apiRow;
    try {
      final envelope = await _authRepo.getProfile(isShowLoader: true);
      apiRow = _extractProfileUserMap(envelope);
      if (apiRow != null) {
        await session.saveProfile(apiRow);
      }
    } catch (_) {
      // Use cached profile below.
    }

    final root =
        apiRow ??
        (session.profileData != null && session.profileData!.isNotEmpty
            ? Map<String, dynamic>.from(session.profileData!)
            : null);

    if (root != null && root.isNotEmpty) {
      _populateFormFromProfile(coalesceStoredProfileMap(root));
    }
    captureFormBaseline();
    update();
  }

  /// Accepts legacy body `statusCode: 1` and standard `201`.
  Map<String, dynamic>? _extractProfileUserMap(Map<String, dynamic>? envelope) {
    if (envelope == null) return null;
    final rawCode = envelope['statusCode'];
    final code = rawCode is int
        ? rawCode
        : int.tryParse(rawCode?.toString() ?? '') ?? 0;
    if (code != 1 && code != StatusCodeConstants.success) return null;

    final raw = envelope['data'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  void _populateFormFromProfile(Map<String, dynamic> data) {
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
    } else {
      final agePresent = firstPresent(data, const ['age', 'userAge']);
      final age = agePresent is int
          ? agePresent
          : int.tryParse(agePresent?.toString().trim() ?? '');
      if (age != null && age > 0) _applySelectedAge(age);
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
      selectedProfileMedia.value = null;
      captureFormBaseline();
    } finally {
      isSubmitLoading.value = false;
    }
  }

  @override
  void onClose() {
    userNameController.removeListener(_refreshProfileDirty);
    birthdateController.removeListener(_refreshProfileDirty);
    userNameController.dispose();
    birthdateController.dispose();
    super.onClose();
  }
}
