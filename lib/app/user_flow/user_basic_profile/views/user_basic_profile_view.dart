import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/generated/locales.g.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/app_widgets/profile_background_media.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/user_basic_profile_controller.dart';

/// Basic profile on the same full-screen background as Live Room, with
/// Update Profile–style photo picker, nickname, age wheel, and gender chips.
class UserBasicProfileView extends StatefulWidget {
  const UserBasicProfileView({super.key});

  @override
  State<UserBasicProfileView> createState() => _UserBasicProfileViewState();
}

class _UserBasicProfileViewState extends State<UserBasicProfileView> {
  UserBasicProfileController get controller =>
      Get.find<UserBasicProfileController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kDebugMode) {
        controller.debugPrintFullUserProfile('UserBasicProfileView entered');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      floatingActionButton: _floatingSaveButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage(kImgBG), fit: BoxFit.cover),
        ),
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _topBar(context),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    child: ColoredBox(
                      color: kColorWhite,
                      child: Form(
                        key: controller.formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                0,
                                0,
                                0,
                                88 + MediaQuery.of(context).viewInsets.bottom,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight - 40,
                                ),
                                child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _profileCoverHeader(context),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Spacing.v16,
                                        _userNameField(context),
                                        Spacing.v10,
                                        _ageField(context),
                                        Spacing.v10,
                                        _coinsPerSecondField(),
                                        Spacing.v10,
                                        _genderField(),
                                        Spacing.v24,
                                        _profileExtrasCard(context),
                                        Spacing.v16,
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Floating save control at the bottom of the screen.
  Widget _floatingSaveButton(BuildContext context) {
    return Obx(() {
      final dirty = controller.isProfileDirty.value;
      final loading = controller.isSubmitLoading.value;

      return IgnorePointer(
        ignoring: loading,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: appButton(
            onPressed: () => controller.onSavePressed(context),
            buttonText: 'Save',
            buttonHeight: 48,
            buttonWidth: MediaQuery.sizeOf(context).width - 48,
            isGradient: dirty,
            buttonColor: dirty ? kColorPrimary : kColorHint,
            buttonBorderColor: dirty ? kColorPrimary : kColorHint,
            textStyle: TextStyles.kSemiBoldPoppins(
              fontSize: TextStyles.k14FontSize,
              colors: kColorWhite,
            ),
            buttonIcon: loading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: kColorWhite.withValues(alpha: 0.9),
                    ),
                  )
                : null,
          ),
        ),
      );
    });
  }

  /// Extras: [CommonRadioChoiceDialog] per row; purple text when saved value exists;
  /// primary row background for whichever row was opened last.
  Widget _profileExtrasCard(BuildContext context) {
    const rows = <({String label, IconData icon})>[
      (label: 'Relationship status', icon: Icons.favorite_border_rounded),
      (label: 'Languages', icon: Icons.public_rounded),
      (label: 'Current locations', icon: Icons.location_on_outlined),
      (label: 'Interests', icon: Icons.favorite_border_rounded),
      (label: 'Voice Show', icon: Icons.mic_none_rounded),
      (label: 'Link Accounts', icon: Icons.verified_user_outlined),
    ];

    void openDialogForRow(int i) {
      switch (i) {
        case 0:
          controller.openRelationshipStatusDialog(context);
          break;
        case 1:
          controller.openLanguagesDialog(context);
          break;
        case 2:
          controller.openCurrentLocationDialog(context);
          break;
        case 3:
          controller.openInterestsDialog(context);
          break;
        case 4:
          controller.openVoiceShowDialog(context);
          break;
        case 5:
          controller.openLinkAccountsDialog(context);
          break;
        default:
          break;
      }
    }

    Widget rowContent(int i, List<bool> highlights, {required bool selected}) {
      final filled = highlights[i];
      final iconColor = selected
          ? kColorWhite
          : (filled ? kColorPrimary : kColorText);
      final textStyle = selected
          ? TextStyles.kSemiBoldPoppins(
              fontSize: TextStyles.k14FontSize,
              colors: kColorWhite,
            )
          : filled
          ? TextStyles.kSemiBoldPoppins(
              fontSize: TextStyles.k14FontSize,
              colors: kColorPrimary,
            )
          : TextStyles.kRegularPoppins(
              fontSize: TextStyles.k14FontSize,
              colors: kColorText,
            );
      return AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        color: selected ? kColorPrimary : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(rows[i].icon, size: 22, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: AppText(text: rows[i].label, style: textStyle),
            ),
          ],
        ),
      );
    }

    return Obx(() {
      final highlights = controller.profileExtrasRowHighlighted;
      final lastIx = controller.lastSelectedProfileExtraIndex.value;
      return Container(
        decoration: BoxDecoration(
          color: kColorProfileExtrasCardBg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: kColorBlack.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: kColorProfileExtrasDivider,
                ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => openDialogForRow(i),
                  child: rowContent(
                    i,
                    highlights,
                    selected: lastIx == i,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 14, 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: kColorWhite,
                size: 18,
              ),
            ),
          ),
          const BoldText(
            text: 'Basic profile',
            fontSize: TextStyles.k20FontSize,
            color: kColorWhite,
          ),
        ],
      ),
    );
  }

  /// Facebook-style cover banner with overlapping profile photo.
  Widget _profileCoverHeader(BuildContext context) {
    const bannerHeight = 150.0;
    const avatarSize = 108.0;
    const avatarOverhang = avatarSize / 2;

    return Obx(() {
      final File? localPoster = controller.selectedPosterMedia.value;
      final String netPoster = controller.posterUrl.value;
      final String posterPreview = controller.posterPreviewUrl.value;
      final bool isUploading = controller.isPosterUploading.value;
      final bool hasPoster =
          localPoster != null || netPoster.trim().isNotEmpty;

      return SizedBox(
        height: bannerHeight + avatarOverhang,
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: isUploading
                  ? null
                  : () => controller.openCoverBackgroundSheet(context),
              child: SizedBox(
                height: bannerHeight,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (localPoster != null)
                        Image.file(localPoster, fit: BoxFit.cover)
                      else if (netPoster.isNotEmpty)
                        ProfileBackgroundMedia(
                          url: netPoster,
                          showLoadingIndicator: true,
                          previewImageUrl: posterPreview,
                        )
                      else
                        _emptyCoverPlaceholder(),
                      if (!hasPoster)
                        Container(
                          color: kColorBlack.withValues(alpha: 0.04),
                        ),
                      Positioned(
                        right: 14,
                        bottom: 14,
                        child: _coverEditButton(),
                      ),
                      if (isUploading)
                        ColoredBox(
                          color: kColorBlack.withValues(alpha: 0.35),
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation(kColorPrimary),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: bannerHeight - avatarOverhang,
              left: 0,
              right: 0,
              child: Center(
                child: _profileAvatarPicker(context, size: avatarSize),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _emptyCoverPlaceholder() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kColorPrimary.withValues(alpha: 0.35),
            const Color(0xFFDFE3EA),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: kColorWhite.withValues(alpha: 0.9),
              size: 34,
            ),
            Spacing.v6,
            AppText(
              text: 'Choose a cover background',
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite.withValues(alpha: 0.92),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coverEditButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: kColorBlack.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.35)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wallpaper_rounded, color: kColorWhite, size: 14),
          SizedBox(width: 6),
          AppText(
            text: 'Edit cover',
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite,
          ),
        ],
      ),
    );
  }

  Widget _profileAvatarPicker(BuildContext context, {required double size}) {
    final userSession = _resolveUserSession();

    return Obx(() {
      final File? selectedMedia = controller.selectedProfileMedia.value;

      return GetBuilder<UserSessionController>(
        init: userSession,
        builder: (session) {
          return GestureDetector(
            onTap: () => controller.onProfileMediaTap(context),
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kColorWhite,
                      border: Border.all(color: kColorWhite, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: kColorBlack.withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _avatarInner(selectedMedia, session),
                    ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => controller.onProfileMediaTap(context),
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: SvgPicture.asset(
                          kIconEditBG,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  /// Matches Live Room: local pick wins; else network avatar from session; else initials.
  Widget _avatarInner(File? selectedMedia, UserSessionController session) {
    if (selectedMedia != null) {
      return Image.file(selectedMedia, fit: BoxFit.cover);
    }
    final avatarUrl = session.displayPictureUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return Image.network(
        avatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _initialsAvatar(session.initials),
      );
    }
    return _initialsAvatar(session.initials);
  }

  Widget _initialsAvatar(String initials) {
    return ColoredBox(
      color: const Color(0xFF2A2A2A),
      child: Center(
        child: SemiBoldText(
          text: initials,
          fontSize: TextStyles.k14FontSize,
          color: kColorWhite,
        ),
      ),
    );
  }

  UserSessionController _resolveUserSession() {
    if (Get.isRegistered<UserSessionController>()) {
      return Get.find<UserSessionController>();
    }
    return Get.put(UserSessionController(), permanent: true);
  }

  Widget _userNameField(BuildContext context) {
    return AppTextField(
      controller: controller.userNameController,
      validator: (value) => controller.validateUserName(context, value),
      hintText: LocaleKeys.nickNameHint.tr,
      borderColor: kColorHint,
      hintStyle: TextStyles.kRegularPoppins(
        fontSize: TextStyles.k14FontSize,
        colors: kColorHint,
      ),
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.none,
      prefix: Padding(
        padding: const EdgeInsets.only(left: 14, right: 12),
        child: SvgPicture.asset(
          kIconUser,
          colorFilter: const ColorFilter.mode(kColorHint, BlendMode.srcIn),
        ),
      ),
    );
  }

  Widget _ageField(BuildContext context) {
    return AppTextField(
      controller: controller.birthdateController,
      validator: controller.validateBirthdate,
      hintText: LocaleKeys.ageHint.tr,
      readOnly: true,
      onTap: () => controller.pickAge(context),
      borderColor: kColorHint,
      hintStyle: TextStyles.kRegularPoppins(
        fontSize: TextStyles.k14FontSize,
        colors: kColorHint,
      ),
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.none,
      prefix: Padding(
        padding: const EdgeInsets.only(left: 14, right: 12),
        child: SvgPicture.asset(kIconCalendar),
      ),
    );
  }

  Widget _coinsPerSecondField() {
    return AppTextField(
      controller: controller.coinsPerSecondController,
      validator: controller.validateCoinsPerSecond,
      hintText: 'Coins per second',
      borderColor: kColorHint,
      hintStyle: TextStyles.kRegularPoppins(
        fontSize: TextStyles.k14FontSize,
        colors: kColorHint,
      ),
      textInputAction: TextInputAction.next,
      textInputType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      prefix: const Padding(
        padding: EdgeInsets.only(left: 14, right: 12),
        child: Icon(
          Icons.monetization_on_outlined,
          size: 20,
          color: kColorHint,
        ),
      ),
      suffix: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: AppText(
            text: 'coins per second',
            fontSize: TextStyles.k10FontSize,
            color: kColorHint,
            maxLines: 1,
          ),
        ),
      ),
    );
  }

  Widget _genderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          text: 'Select Gender',
          fontSize: TextStyles.k14FontSize,
          color: kColorText,
        ),
        Spacing.v12,
        Obx(
          () => Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _genderCircleOption(
                label: 'Male',
                value: 'Male',
                iconAsset: kIconMale,
                isSelected: controller.selectedGender.value == 'Male',
              ),
              const SizedBox(width: 16),
              _genderCircleOption(
                label: 'Female',
                value: 'Female',
                iconAsset: kIconFemale,
                isSelected: controller.selectedGender.value == 'Female',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _genderCircleOption({
    required String label,
    required String value,
    required String iconAsset,
    required bool isSelected,
  }) {
    const double kGenderCircleSize = 90;

    return GestureDetector(
      onTap: () => controller.selectedGender.value = value,
      child: SizedBox(
        width: kGenderCircleSize,
        height: kGenderCircleSize,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isSelected ? kColorPrimary : kColorWhite,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? kColorPrimary : kColorTextFieldBorder,
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                iconAsset,
                height: 32,
                width: 32,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(
                  isSelected ? kColorWhite : kColorHint,
                  BlendMode.srcIn,
                ),
              ),
              Spacing.v2,
              if (isSelected)
                SemiBoldText(
                  text: label,
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite,
                )
              else
                AppText(
                  text: label,
                  fontSize: TextStyles.k14FontSize,
                  color: kColorHint,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
