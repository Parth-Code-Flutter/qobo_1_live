import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/generated/locales.g.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/user_basic_profile_controller.dart';

/// Basic profile on the same full-screen background as Live Room, with
/// Update Profile–style photo picker, nickname, age wheel, and gender chips.
class UserBasicProfileView extends GetView<UserBasicProfileController> {
  const UserBasicProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
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
                                20,
                                20,
                                20,
                                24 + MediaQuery.of(context).viewInsets.bottom,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight - 40,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(child: _profileImagePicker(context)),
                                    Spacing.v28,
                                    _userNameField(context),
                                    Spacing.v10,
                                    _ageField(context),
                                    Spacing.v10,
                                    _genderField(),
                                    Spacing.v24,
                                    _profileExtrasCard(context),
                                    Spacing.v16,
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

  /// Circular confirm control (replaces Save). Grey fill when form has unsaved edits.
  Widget _confirmProfileIconButton(
    BuildContext context, {
    bool forHeader = false,
  }) {
    final diameter = forHeader ? 28.0 : 28.0;
    final iconSize = forHeader ? 12.0 : 12.0;
    final stroke = forHeader ? 2.0 : 2.5;

    return Obx(() {
      final dirty = controller.isProfileDirty.value;
      final loading = controller.isSubmitLoading.value;
      final bg = dirty
          ? kColorProfileConfirmIconBgDirty
          : kColorProfileConfirmIconBgIdle;
      final iconColor = dirty ? kColorWhite : kColorPrimary;

      return Material(
        color: bg,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: loading ? null : () => controller.onSavePressed(context),
          child: SizedBox(
            width: diameter,
            height: diameter,
            child: Center(
              child: loading
                  ? SizedBox(
                      width: iconSize,
                      height: iconSize,
                      child: CircularProgressIndicator(
                        strokeWidth: stroke,
                        color: iconColor,
                      ),
                    )
                  : SvgPicture.asset(
                      kIconRight,
                      width: iconSize,
                      height: iconSize,
                      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                    ),
            ),
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
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 2),
              child: _confirmProfileIconButton(context, forHeader: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileImagePicker(BuildContext context) {
    final userSession = _resolveUserSession();

    return Obx(() {
      final File? selectedMedia = controller.selectedProfileMedia.value;

      return GetBuilder<UserSessionController>(
        init: userSession,
        builder: (session) {
          return GestureDetector(
            onTap: () => controller.onProfileMediaTap(context),
            child: SizedBox(
              width: 124,
              height: 124,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F5F5),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: _avatarInner(selectedMedia, session),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => controller.onProfileMediaTap(context),
                      child: SizedBox(
                        width: 34,
                        height: 34,
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
