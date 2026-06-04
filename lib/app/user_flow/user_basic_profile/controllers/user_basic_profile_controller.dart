import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/status_code_constants.dart';
import 'package:qobo_one_live/generated/locales.g.dart';
import 'package:qobo_one_live/repo/auth/auth_repo.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/app_dialogs/common_radio_choice_dialog.dart';
import 'package:qobo_one_live/utils/app_widgets/common_media_picker.dart';
import 'package:qobo_one_live/utils/profile/stored_profile_map.dart';
import 'package:qobo_one_live/utils/profile/update_profile_api_helper.dart';
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
  final selectedPosterMedia = Rxn<File>();
  final posterUrl = ''.obs;
  final isPosterUploading = false.obs;
  final isSubmitLoading = false.obs;

  /// True when name, age, gender, or profile image differs from last baseline.
  final isProfileDirty = false.obs;

  /// Profile extras rows — empty until user/API fills them; purple row only when non-empty.
  final relationshipStatus = ''.obs;
  final languagesLine = ''.obs;
  final currentLocationsLine = ''.obs;
  final interestsLine = ''.obs;
  final voiceShowLine = ''.obs;
  final linkAccountsLine = ''.obs;

  /// Last extras row the user opened (primary background in the list).
  final lastSelectedProfileExtraIndex = Rxn<int>();

  final ImagePicker _imagePicker = ImagePicker();

  String _baselineName = '';
  String _baselineAgeText = '';
  String _baselineGender = '';
  String _baselineRelationship = '';
  String _baselineLanguages = '';
  String _baselineLocations = '';
  String _baselineInterests = '';
  String _baselineVoiceShow = '';
  String _baselineLinkAccounts = '';
  bool _baselineHadNewImage = false;

  /// Read inside [Obx] so all `.obs` fields are tracked for list repaint.
  List<bool> get profileExtrasRowHighlighted => [
    relationshipStatus.value.trim().isNotEmpty,
    languagesLine.value.trim().isNotEmpty,
    currentLocationsLine.value.trim().isNotEmpty,
    interestsLine.value.trim().isNotEmpty,
    voiceShowLine.value.trim().isNotEmpty,
    linkAccountsLine.value.trim().isNotEmpty,
  ];

  @override
  void onInit() {
    super.onInit();
    userNameController.addListener(_refreshProfileDirty);
    birthdateController.addListener(_refreshProfileDirty);
    ever<String>(selectedGender, (_) => _refreshProfileDirty());
    ever<File?>(selectedProfileMedia, (_) => _refreshProfileDirty());
    ever<String>(relationshipStatus, (_) => _refreshProfileDirty());
    ever<String>(languagesLine, (_) => _refreshProfileDirty());
    ever<String>(currentLocationsLine, (_) => _refreshProfileDirty());
    ever<String>(interestsLine, (_) => _refreshProfileDirty());
    ever<String>(voiceShowLine, (_) => _refreshProfileDirty());
    ever<String>(linkAccountsLine, (_) => _refreshProfileDirty());
  }

  /// Call after loading/saving so “dirty” compares to the latest server snapshot.
  void captureFormBaseline() {
    _baselineName = userNameController.text.trim();
    _baselineAgeText = birthdateController.text.trim();
    _baselineGender = selectedGender.value;
    _baselineRelationship = relationshipStatus.value;
    _baselineLanguages = languagesLine.value;
    _baselineLocations = currentLocationsLine.value;
    _baselineInterests = interestsLine.value;
    _baselineVoiceShow = voiceShowLine.value;
    _baselineLinkAccounts = linkAccountsLine.value;
    _baselineHadNewImage = selectedProfileMedia.value != null;
    _refreshProfileDirty();
  }

  void _refreshProfileDirty() {
    final hasNewImage = selectedProfileMedia.value != null;
    final dirty =
        userNameController.text.trim() != _baselineName ||
        birthdateController.text.trim() != _baselineAgeText ||
        selectedGender.value != _baselineGender ||
        relationshipStatus.value != _baselineRelationship ||
        languagesLine.value != _baselineLanguages ||
        currentLocationsLine.value != _baselineLocations ||
        interestsLine.value != _baselineInterests ||
        voiceShowLine.value != _baselineVoiceShow ||
        linkAccountsLine.value != _baselineLinkAccounts ||
        hasNewImage != _baselineHadNewImage;
    isProfileDirty.value = dirty;
  }

  /// Opens shared [CommonRadioChoiceDialog] for relationship (tile title = dialog title).
  Future<void> openRelationshipStatusDialog(BuildContext context) async {
    lastSelectedProfileExtraIndex.value = 0;
    final result = await CommonRadioChoiceDialog.show(
      context,
      title: 'Relationship status',
      options: const ['Single', 'In Relationship', 'Married', 'Privacy'],
      initialSelected: relationshipStatus.value.isEmpty
          ? null
          : relationshipStatus.value,
    );
    if (!context.mounted) return;
    if (result != null && result.isNotEmpty) {
      relationshipStatus.value = result;
    }
  }

  Future<void> openLanguagesDialog(BuildContext context) async {
    lastSelectedProfileExtraIndex.value = 1;
    const options = ['English', 'Hindi'];
    final cur = languagesLine.value.trim();
    final result = await CommonRadioChoiceDialog.show(
      context,
      title: 'Languages',
      options: options,
      initialSelected: cur.isEmpty || !options.contains(cur) ? null : cur,
    );
    if (!context.mounted) return;
    if (result != null && result.isNotEmpty) {
      languagesLine.value = result;
    }
  }

  /// Placeholder: only India until full location picker exists.
  Future<void> openCurrentLocationDialog(BuildContext context) async {
    lastSelectedProfileExtraIndex.value = 2;
    const options = ['India'];
    final cur = currentLocationsLine.value.trim();
    final result = await CommonRadioChoiceDialog.show(
      context,
      title: 'Current locations',
      options: options,
      initialSelected: cur.isEmpty || !options.contains(cur) ? null : cur,
    );
    if (!context.mounted) return;
    if (result != null && result.isNotEmpty) {
      currentLocationsLine.value = result;
    }
  }

  Future<void> openInterestsDialog(BuildContext context) async {
    lastSelectedProfileExtraIndex.value = 3;
    const options = ['Travel', 'Music'];
    final cur = interestsLine.value.trim();
    final result = await CommonRadioChoiceDialog.show(
      context,
      title: 'Interests',
      options: options,
      initialSelected: cur.isEmpty || !options.contains(cur) ? null : cur,
    );
    if (!context.mounted) return;
    if (result != null && result.isNotEmpty) {
      interestsLine.value = result;
    }
  }

  Future<void> openVoiceShowDialog(BuildContext context) async {
    lastSelectedProfileExtraIndex.value = 4;
    const options = ['Public', 'Private'];
    final cur = voiceShowLine.value.trim();
    final result = await CommonRadioChoiceDialog.show(
      context,
      title: 'Voice Show',
      options: options,
      initialSelected: cur.isEmpty || !options.contains(cur) ? null : cur,
    );
    if (!context.mounted) return;
    if (result != null && result.isNotEmpty) {
      voiceShowLine.value = result;
    }
  }

  Future<void> openLinkAccountsDialog(BuildContext context) async {
    lastSelectedProfileExtraIndex.value = 5;
    const options = ['Google', 'Apple'];
    final cur = linkAccountsLine.value.trim();
    final result = await CommonRadioChoiceDialog.show(
      context,
      title: 'Link Accounts',
      options: options,
      initialSelected: cur.isEmpty || !options.contains(cur) ? null : cur,
    );
    if (!context.mounted) return;
    if (result != null && result.isNotEmpty) {
      linkAccountsLine.value = result;
    }
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
    debugPrintFullUserProfile('after fetchProfileAndPopulateForm');
  }

  /// Debug: full [UserSessionController.profileData] (API + cached). No-op in release.
  void debugPrintFullUserProfile(String reason) {
    if (!kDebugMode) return;
    final session = _ensureSession();
    final raw = session.profileData;
    const tag = '[UserBasicProfile]';
    debugPrint('$tag full user profile — $reason');
    if (raw == null || raw.isEmpty) {
      debugPrint('$tag profileData is null or empty');
      return;
    }
    try {
      debugPrint(const JsonEncoder.withIndent('  ').convert(raw));
    } catch (e, st) {
      debugPrint('$tag JSON encode failed: $e');
      debugPrint('$tag raw toString: $raw');
      debugPrint('$st');
    }
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

    posterUrl.value = data['poster']?.toString() ?? '';

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

    _populateProfileExtrasFromMap(data);
  }

  void _populateProfileExtrasFromMap(Map<String, dynamic> data) {
    void setIfPresent(List<String> keys, void Function(String v) set) {
      for (final k in keys) {
        final raw = data[k];
        if (raw == null) continue;
        final line = profileListFieldToLine(raw);
        if (line.isNotEmpty) {
          set(line);
          return;
        }
      }
    }

    setIfPresent(
      ['relationshipStatus', 'relationship', 'relationship_status'],
      (v) => relationshipStatus.value = v,
    );
    setIfPresent(
      ['languages', 'languagesSpoken', 'language'],
      (v) => languagesLine.value = v,
    );
    setIfPresent(
      ['currentLocation', 'current_location', 'location', 'address'],
      (v) => currentLocationsLine.value = v,
    );
    setIfPresent(['interests', 'interest'], (v) => interestsLine.value = v);
    setIfPresent(['voiceShow', 'voice_show', 'voiceBio'], (v) {
      voiceShowLine.value = v;
    });
    setIfPresent(
      ['linkedAccounts', 'link_accounts', 'linked_accounts'],
      (v) => linkAccountsLine.value = v,
    );
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

  /// Saves via `PUT /api/user/update` (multipart).
  Future<void> onSavePressed(BuildContext context) async {
    if (isSubmitLoading.value) return;
    if (!isProfileDirty.value) return;
    if (!(formKey.currentState?.validate() ?? false)) return;
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
        relationshipStatus: relationshipStatus.value,
        languages: languagesLine.value,
        interests: interestsLine.value,
        currentLocation: currentLocationsLine.value,
      );
      if (!request.hasAnyField) {
        AppToast.showError(context, 'Nothing to update.');
        return;
      }

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
        final successMessage = message.isNotEmpty
            ? message
            : 'Profile updated successfully';
        Get.back<void>();
        final overlay = Get.overlayContext;
        if (overlay != null && overlay.mounted) {
          AppToast.showSuccess(overlay, successMessage);
        }
        return;
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

  /// Opens gallery/camera to upload poster background
  Future<void> pickPosterMedia(BuildContext context) async {
    try {
      final source = await CommonMediaPicker.show(context);
      if (source == null) return;

      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      selectedPosterMedia.value = file;
      
      // Upload poster instantly
      isPosterUploading.value = true;
      final response = await _authRepo.uploadPoster(posterFile: file);
      if (response != null && response['statusCode'] == 1) {
        final newUrl = response['data']['posterUrl']?.toString() ?? '';
        if (newUrl.isNotEmpty) {
          posterUrl.value = newUrl;
          final session = _ensureSession();
          final updatedData = Map<String, dynamic>.from(session.profileData ?? {});
          updatedData['poster'] = newUrl;
          await session.saveProfile(updatedData);
          if (context.mounted) {
            AppToast.showSuccess(context, 'Poster background uploaded successfully!');
          }
        }
      } else {
        if (context.mounted) {
          AppToast.showError(context, 'Failed to upload poster background.');
        }
      }
    } on MissingPluginException {
      if (context.mounted) {
        AppToast.showError(context, 'Media picker is not ready.');
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, 'Error uploading poster: $e');
      }
    } finally {
      isPosterUploading.value = false;
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
