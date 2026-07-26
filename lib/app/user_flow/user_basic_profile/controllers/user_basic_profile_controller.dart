import 'dart:async';
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
import 'package:qobo_one_live/repo/background/background_repo.dart';
import 'package:qobo_one_live/repo/user/user_repo.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:qobo_one_live/utils/app_widgets/country_state_picker_sheet.dart';
import 'package:qobo_one_live/utils/app_dialogs/common_radio_choice_dialog.dart';
import 'package:qobo_one_live/utils/app_widgets/common_media_picker.dart';
import 'package:qobo_one_live/utils/app_widgets/profile_background_media.dart';
import 'package:qobo_one_live/utils/geo/country_state_selection_mixin.dart';
import 'package:qobo_one_live/utils/profile/stored_profile_map.dart';
import 'package:qobo_one_live/utils/profile/update_profile_api_helper.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';
import 'package:qobo_one_live/utils/validations/text_field_validations.dart';
import 'package:qobo_one_live/utils/svga_network_loader.dart';

import '../widgets/profile_cover_background_sheet.dart';

/// Basic profile capture (photo + core fields). Wire `/api` here when ready.
class UserBasicProfileController extends GetxController
    with CountryStateSelectionMixin {
  UserBasicProfileController({
    AuthRepo? authRepo,
    UserRepo? userRepo,
    BackgroundRepo? backgroundRepo,
  })  : _authRepo = authRepo ?? AuthRepo(),
        _userRepo = userRepo ?? UserRepo(),
        _backgroundRepo = backgroundRepo ?? BackgroundRepo();

  final AuthRepo _authRepo;
  final UserRepo _userRepo;
  final BackgroundRepo _backgroundRepo;

  UserSessionController _ensureSession() {
    if (Get.isRegistered<UserSessionController>()) {
      return Get.find<UserSessionController>();
    }
    return Get.put(UserSessionController(), permanent: true);
  }

  final formKey = GlobalKey<FormState>();
  final userNameController = TextEditingController();
  final birthdateController = TextEditingController();
  final coinsPerSecondController = TextEditingController();

  final selectedGender = ''.obs;
  final selectedAge = Rxn<int>();
  final selectedBirthdate = Rxn<DateTime>();
  final selectedProfileMedia = Rxn<File>();
  final selectedPosterMedia = Rxn<File>();
  final posterUrl = ''.obs;
  final isPosterUploading = false.obs;
  final isSubmitLoading = false.obs;

  /// Edit-cover sheet: 0 = purchased backpack, 1 = shop.
  final coverBackgroundTab = 0.obs;
  final purchasedCoverBackgrounds = <Map<String, dynamic>>[].obs;
  final shopCoverBackgrounds = <Map<String, dynamic>>[].obs;
  final isLoadingCoverBackgrounds = false.obs;
  final isApplyingCoverBackground = false.obs;

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
  String _baselineCoinsPerSecond = '';
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
    coinsPerSecondController.addListener(_refreshProfileDirty);
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
    _baselineCoinsPerSecond = coinsPerSecondController.text.trim();
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
        coinsPerSecondController.text.trim() != _baselineCoinsPerSecond ||
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

  /// Country + state picker for profile location.
  Future<void> openCurrentLocationDialog(BuildContext context) async {
    lastSelectedProfileExtraIndex.value = 2;
    await ensureCountriesLoaded(forceRefresh: true);
    if (!context.mounted) return;

    final country = await showCountryPickerSheet(
      context,
      countries: countries.toList(),
      selected: selectedCountry.value,
    );
    if (!context.mounted || country == null) return;
    await selectCountry(country);
    if (!context.mounted) return;

    await loadStatesForCountry(country.id, forceRefresh: true);
    if (!context.mounted) return;

    final state = await showStatePickerSheet(
      context,
      states: states.toList(),
      selected: selectedState.value,
    );
    if (!context.mounted || state == null) return;
    selectState(state);
    currentLocationsLine.value = '${country.name}, ${state.name}';
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
    await _hydrateCoinsPerSecondIfMissing(session.userId);
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
    final equippedBg = ApiImageUtils.normalize(
      _firstProfileText(data, const [
        'profileBackgroundUrl',
        'profile_background_url',
        'profileBackground.image',
        'profile_background.image',
        'backgroundUrl',
        'background_url',
      ]),
    );
    // Prefer equipped mall profile background for the cover preview.
    if (equippedBg != null && equippedBg.isNotEmpty) {
      posterUrl.value = equippedBg;
    } else {
      final sessionBg = _ensureSession().profileBackgroundUrl.trim();
      if (sessionBg.isNotEmpty) posterUrl.value = sessionBg;
    }

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

    final cps = coinsPerSecondFromProfileMap(data);
    if (cps != null) {
      _setCoinsPerSecondField(cps);
    }

    _populateProfileExtrasFromMap(data);
  }

  void _setCoinsPerSecondField(double value) {
    coinsPerSecondController.text = coinsPerSecondLabel(value);
  }

  /// Profile GET may omit rate — public profile / discover card often includes it.
  Future<void> _hydrateCoinsPerSecondIfMissing(String userId) async {
    if (coinsPerSecondController.text.trim().isNotEmpty) return;
    final id = userId.trim();
    if (id.isEmpty) return;

    try {
      final response = await _userRepo.getPublicProfile(
        userId: id,
        isShowLoader: false,
      );
      final data = response?['data'];
      if (data is! Map) return;
      final cps = coinsPerSecondFromProfileMap(
        coalesceStoredProfileMap(Map<String, dynamic>.from(data)),
      );
      if (cps != null) {
        _setCoinsPerSecondField(cps);
      }
    } catch (_) {
      // Keep field empty when fallback fails.
    }
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

  String? validateCoinsPerSecond(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null || parsed < 0) {
      return 'Enter a valid coins per second value';
    }
    return null;
  }

  double? _parseCoinsPerSecondForApi() {
    final text = coinsPerSecondController.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
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
        country: selectedCountry.value?.name,
        countryId: selectedCountry.value?.id,
        state: selectedState.value?.name,
        stateId: selectedState.value?.id,
        coinsPerSecond: _parseCoinsPerSecondForApi(),
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

  /// Edit cover → purchased / shop profile backgrounds bottom sheet.
  Future<void> openCoverBackgroundSheet(BuildContext context) async {
    coverBackgroundTab.value = 0;
    unawaited(loadCoverBackgrounds());
    await Get.bottomSheet(
      const ProfileCoverBackgroundSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      ignoreSafeArea: false,
    );
  }

  Future<void> loadCoverBackgrounds() async {
    if (isLoadingCoverBackgrounds.value) return;
    isLoadingCoverBackgrounds.value = true;
    try {
      final shopResponse = await _backgroundRepo.getShopBackgrounds(
        isShowLoader: false,
      );
      final backpackResponse = await _backgroundRepo.getMyBackpack(
        isShowLoader: false,
      );

      final backpackItems = _extractList(backpackResponse?['data']);
      final purchasedById = _purchasedBackgroundsByBackgroundId(backpackItems);

      purchasedCoverBackgrounds.assignAll(
        _mapPurchasedCoverBackgrounds(backpackItems),
      );
      shopCoverBackgrounds.assignAll(
        _mapShopCoverBackgrounds(
          _extractList(shopResponse?['data']),
          purchasedById,
        ),
      );
      // Keep Profile tab + Basic Profile in sync with the equipped backpack item
      // (API often returns both `.svga` and image URLs in the same `image` field).
      _syncEquippedCoverFromPurchased();
      _prefetchCoverSvga(purchasedCoverBackgrounds);
      _prefetchCoverSvga(shopCoverBackgrounds);
      // Warm bundled fallback so 404 CDN covers still animate immediately.
      unawaited(
        SvgaNetworkLoader.prefetchAsset(
          ProfileBackgroundMedia.kProfileSvgaFallbackAsset,
        ),
      );
    } finally {
      isLoadingCoverBackgrounds.value = false;
    }
  }

  void _syncEquippedCoverFromPurchased() {
    for (final item in purchasedCoverBackgrounds) {
      if (item['isEquipped'] != true) continue;
      final url = item['imageUrl']?.toString().trim() ?? '';
      if (url.isEmpty) return;
      _syncCoverPreview(url);
      return;
    }
  }

  /// Warm SVGA disk cache while the picker is open so equip feels instant.
  void _prefetchCoverSvga(List<Map<String, dynamic>> items) {
    for (final item in items) {
      final url =
          ApiImageUtils.normalize(item['imageUrl']?.toString())?.trim() ?? '';
      if (!ProfileBackgroundMedia.isSvgaUrl(url)) continue;
      // Safe prefetch — never caches 404 HTML like decodeFromURL can.
      unawaited(SvgaNetworkLoader.prefetch(url));
    }
  }

  Future<void> applyPurchasedCoverBackground(Map<String, dynamic> item) async {
    final backpackItemId = item['id']?.toString().trim() ?? '';
    final name = item['name']?.toString() ?? 'Profile Background';
    final imageUrl = item['imageUrl']?.toString() ?? '';
    if (backpackItemId.isEmpty) {
      _coverToast('This background is missing an id.', isError: true);
      return;
    }
    if (item['isExpired'] == true) {
      _coverToast('This background has expired.', isError: true);
      return;
    }
    if (item['isEquipped'] == true) {
      _syncCoverPreview(imageUrl);
      if (Get.isBottomSheetOpen == true) Get.back();
      _coverToast('"$name" is already your cover.');
      return;
    }

    // Instant cover update — do not wait for equip/refresh APIs.
    _syncCoverPreview(imageUrl);
    if (Get.isBottomSheetOpen == true) Get.back();

    isApplyingCoverBackground.value = true;
    try {
      final response = await _backgroundRepo.equipBackground(
        backpackItemId: backpackItemId,
        equip: true,
        isShowLoader: false,
      );
      if (!_isBackgroundApiSuccess(response)) {
        _coverToast(
          response?['message']?.toString() ?? 'Could not apply this background.',
          isError: true,
        );
        return;
      }

      // Sync session / purchased list in the background; preview already shows.
      unawaited(_refreshCoverAfterBackgroundChange(previewUrl: imageUrl));
      _coverToast('Cover updated to "$name".');
    } finally {
      isApplyingCoverBackground.value = false;
    }
  }

  Future<void> purchaseCoverBackground(Map<String, dynamic> item) async {
    final backgroundId = item['id']?.toString().trim() ?? '';
    final name = item['name']?.toString() ?? 'Profile Background';
    if (backgroundId.isEmpty || item['isPlaceholder'] == true) return;
    if (item['isOwned'] == true) {
      coverBackgroundTab.value = 0;
      await loadCoverBackgrounds();
      final owned = _findPurchasedByBackgroundId(backgroundId);
      if (owned != null) {
        await applyPurchasedCoverBackground(owned);
      }
      return;
    }

    isApplyingCoverBackground.value = true;
    try {
      final response = await _backgroundRepo.buyBackground(
        backgroundId: backgroundId,
        isShowLoader: true,
      );
      if (!_isBackgroundApiSuccess(response)) {
        _coverToast(
          response?['message']?.toString() ?? 'Could not purchase "$name".',
          isError: true,
        );
        return;
      }

      await loadCoverBackgrounds();
      final owned = _findPurchasedByBackgroundId(backgroundId);
      if (owned != null) {
        // Buy succeeded — equip so Basic Profile cover updates immediately.
        isApplyingCoverBackground.value = false;
        await applyPurchasedCoverBackground(owned);
        return;
      }

      await _ensureSession().refreshProfileFromApi();
      _coverToast('"$name" added to Purchased. Select it to use as cover.');
      coverBackgroundTab.value = 0;
    } finally {
      isApplyingCoverBackground.value = false;
    }
  }

  Future<void> _refreshCoverAfterBackgroundChange({
    required String previewUrl,
  }) async {
    selectedPosterMedia.value = null;
    final normalizedPreview =
        ApiImageUtils.normalize(previewUrl)?.trim() ?? '';
    await _ensureSession().refreshProfileFromApi();
    final sessionBg = _ensureSession().profileBackgroundUrl.trim();
    final normalizedSession =
        ApiImageUtils.normalize(sessionBg)?.trim() ?? '';
    // Prefer session URL when present. If getProfile drops the field, keep the
    // optimistic cover so Profile tab does not go blank after equip.
    final next = normalizedSession.isNotEmpty
        ? normalizedSession
        : normalizedPreview;
    if (next.isNotEmpty) {
      _syncCoverPreview(next);
    }
    await loadCoverBackgrounds();
  }

  void _syncCoverPreview(String url) {
    final normalized = ApiImageUtils.normalize(url)?.trim() ?? '';
    if (normalized.isEmpty) return;
    posterUrl.value = normalized;
    final session = _ensureSession();
    final updated = Map<String, dynamic>.from(session.profileData ?? {});
    updated['profileBackgroundUrl'] = normalized;
    updated['poster'] = normalized;
    unawaited(session.saveProfile(updated));
  }

  List<Map<String, dynamic>> _mapPurchasedCoverBackgrounds(List items) {
    final rows = <Map<String, dynamic>>[];
    for (final raw in items.whereType<Map>()) {
      final item = Map<String, dynamic>.from(raw);
      final itemType = item['itemType']?.toString().toUpperCase() ?? '';
      if (itemType.isNotEmpty &&
          itemType != 'PROFILE_BACKGROUND' &&
          itemType != 'BACKGROUND') {
        continue;
      }

      final backgroundDetails =
          item['backgroundDetails'] ?? item['background_details'];
      final background = backgroundDetails is Map
          ? Map<String, dynamic>.from(backgroundDetails)
          : const <String, dynamic>{};
      final itemId = item['id']?.toString() ?? '';
      if (itemId.isEmpty) continue;

      final expiresAt = item['expiresAt']?.toString() ?? '';
      final isExpired = _isExpired(expiresAt);
      final isEquipped = item['isEquipped'] == true && !isExpired;
      final imageUrl =
          ApiImageUtils.normalize(
            _firstText([
              background['animationUrl'],
              background['svgaUrl'],
              background['svga'],
              background['image'],
              background['imageUrl'],
              background['previewUrl'],
              item['animationUrl'],
              item['image'],
              item['imageUrl'],
            ]),
          ) ??
          '';

      rows.add({
        'id': itemId,
        'backgroundId':
            background['id']?.toString() ??
            item['itemId']?.toString() ??
            item['item_id']?.toString() ??
            '',
        'name': background['name']?.toString() ?? 'Profile Background',
        'imageUrl': imageUrl,
        'category': background['category']?.toString() ?? '',
        'duration': isExpired ? 'Expired' : _expiryLabel(expiresAt),
        'isEquipped': isEquipped,
        'isExpired': isExpired,
        'expiresAt': expiresAt,
      });
    }
    return rows;
  }

  List<Map<String, dynamic>> _mapShopCoverBackgrounds(
    List items,
    Map<String, Map<String, dynamic>> purchasedById,
  ) {
    final rows = <Map<String, dynamic>>[];
    for (final raw in items.whereType<Map>()) {
      final backgroundId = raw['id']?.toString() ?? '';
      if (backgroundId.isEmpty) continue;

      final status = raw['status']?.toString().toLowerCase() ?? 'active';
      if (status.isNotEmpty && status != 'active') continue;

      final purchased = purchasedById[backgroundId];
      final expiresAt = purchased?['expiresAt']?.toString() ?? '';
      final isExpired = _isExpired(expiresAt);
      final isOwned = purchased != null && !isExpired;
      // Shop tab only lists items still available to buy.
      if (isOwned) continue;

      final durationDays = _toInt(raw['durationDays'] ?? raw['duration_days']);
      rows.add({
        'id': backgroundId,
        'name': raw['name']?.toString() ?? 'Profile Background',
        'imageUrl':
            ApiImageUtils.normalize(
              _firstText([
                raw['animationUrl'],
                raw['svgaUrl'],
                raw['svga'],
                raw['image'],
                raw['imageUrl'],
                raw['previewUrl'],
              ]),
            ) ??
            '',
        'price': _toInt(raw['price']),
        'duration': durationDays > 0 ? '$durationDays days' : 'Limited time',
        'category': raw['category']?.toString() ?? 'Premium',
        'isOwned': false,
        'isEquipped': false,
      });
    }
    return rows;
  }

  Map<String, dynamic>? _findPurchasedByBackgroundId(String backgroundId) {
    for (final row in purchasedCoverBackgrounds) {
      if (row['backgroundId']?.toString() == backgroundId) return row;
    }
    return null;
  }

  Map<String, Map<String, dynamic>> _purchasedBackgroundsByBackgroundId(
    List items,
  ) {
    final result = <String, Map<String, dynamic>>{};
    for (final raw in items.whereType<Map>()) {
      final item = Map<String, dynamic>.from(raw);
      final itemType = item['itemType']?.toString().toUpperCase() ?? '';
      if (itemType.isNotEmpty &&
          itemType != 'PROFILE_BACKGROUND' &&
          itemType != 'BACKGROUND') {
        continue;
      }
      final backgroundDetails =
          item['backgroundDetails'] ?? item['background_details'];
      final backgroundId =
          item['itemId']?.toString() ??
          item['item_id']?.toString() ??
          (backgroundDetails is Map
              ? backgroundDetails['id']?.toString()
              : null);
      if (backgroundId != null && backgroundId.isNotEmpty) {
        result[backgroundId] = item;
      }
    }
    return result;
  }

  List _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      final nested =
          raw['items'] ?? raw['list'] ?? raw['backgrounds'] ?? raw['data'];
      if (nested is List) return nested;
    }
    return const [];
  }

  String? _firstText(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty && text != 'null') return text;
    }
    return null;
  }

  String? _firstProfileText(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      if (key.contains('.')) {
        final parts = key.split('.');
        dynamic cursor = data;
        var ok = true;
        for (final part in parts) {
          if (cursor is Map && cursor.containsKey(part)) {
            cursor = cursor[part];
          } else {
            ok = false;
            break;
          }
        }
        if (!ok) continue;
        final text = cursor?.toString().trim();
        if (text != null && text.isNotEmpty && text != 'null') return text;
        continue;
      }
      final text = data[key]?.toString().trim();
      if (text != null && text.isNotEmpty && text != 'null') return text;
    }
    return null;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _isExpired(String raw) {
    final text = raw.trim();
    if (text.isEmpty || text == 'null') return false;
    final date = DateTime.tryParse(text);
    if (date == null) return false;
    return date.toUtc().isBefore(DateTime.now().toUtc());
  }

  String _expiryLabel(String raw) {
    final text = raw.trim();
    if (text.isEmpty || text == 'null') return 'Owned';
    final date = DateTime.tryParse(text);
    if (date == null) return 'Owned';
    final local = date.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return 'Expires $y-$m-$d';
  }

  bool _isBackgroundApiSuccess(Map<String, dynamic>? response) {
    if (response == null) return false;
    final code = response['statusCode'];
    return code == 1 || code == 200 || code == 201 || code == true;
  }

  void _coverToast(String message, {bool isError = false}) {
    final context = Get.overlayContext ?? Get.context;
    if (context == null) return;
    if (isError) {
      AppToast.showError(context, message);
    } else {
      AppToast.showSuccess(context, message);
    }
  }

  @override
  void onClose() {
    userNameController.removeListener(_refreshProfileDirty);
    birthdateController.removeListener(_refreshProfileDirty);
    coinsPerSecondController.removeListener(_refreshProfileDirty);
    userNameController.dispose();
    birthdateController.dispose();
    coinsPerSecondController.dispose();
    super.onClose();
  }
}
