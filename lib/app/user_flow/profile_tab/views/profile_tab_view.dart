import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/generated/locales.g.dart';
import 'package:qobo_one_live/repo/user/user_repo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/app/user_flow/wallet/bindings/wallet_binding.dart';
import 'package:qobo_one_live/app/user_flow/wallet/views/wallet_view.dart';
import 'package:qobo_one_live/utils/alert_message_utils/alert_message_utils.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:qobo_one_live/utils/app_dialogs/audio_room_feedback_dialog.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/files_utils/file_utils.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Profile tab view (temporary) with shared background art.
class ProfileTabView extends StatelessWidget {
  const ProfileTabView({super.key, required this.onLogoutPressed});

  final VoidCallback onLogoutPressed;

  @override
  Widget build(BuildContext context) {
    final userSession = _resolveUserSession();
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage(kImgBG), fit: BoxFit.cover),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _profileHero(userSession),
                _superAdminAction(userSession),
                Spacing.v12,
                _profileActionCards(userSession),
                Spacing.v12,
                _profileFeatureGrid(),
                Spacing.v20,
                _settingsRow(),
                Spacing.v12,
                appButton(
                  onPressed: onLogoutPressed,
                  buttonText: LocaleKeys.logoutButtonText.tr,
                  isGradient: false,
                  buttonColor: kColorPrimary,
                  borderRadius: 14,
                  buttonIcon: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: const Icon(
                      Icons.logout,
                      color: kColorWhite,
                      size: 18,
                    ),
                  ),
                ),
                Spacing.v20,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileHero(UserSessionController userSession) {
    return GetBuilder<UserSessionController>(
      init: userSession,
      builder: (session) {
        final imageUrl = session.displayPictureUrl;
        final profileBackgroundUrl =
            ApiImageUtils.normalize(session.profileBackgroundUrl) ?? '';
        return LayoutBuilder(
          builder: (_, constraints) {
            final isCompact = constraints.maxWidth < 360;
            final avatarSize = isCompact ? 74.0 : 88.0;
            final avatarFrameSize = avatarSize * 1.34;
            return _ProfileBackgroundShell(
              backgroundUrl: profileBackgroundUrl,
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: avatarFrameSize,
                        height: avatarFrameSize,
                        child: Center(
                          // Key remounts the avatar when the frame URL changes
                          // so the loader appears while the new asset loads.
                          child: FramedUserAvatar(
                            key: ValueKey(
                              'profile_frame_${session.profileFrameUrl}',
                            ),
                            name: session.displayName,
                            imageUrl: imageUrl,
                            size: avatarSize,
                            frameUrl: session.profileFrameUrl,
                            frameSeed: session.userId.isNotEmpty
                                ? session.userId
                                : session.displayName,
                            fontSize: isCompact
                                ? TextStyles.k14FontSize
                                : TextStyles.k18FontSize,
                          ),
                        ),
                      ),
                      Spacing.h12,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BoldText(
                              text: session.displayName,
                              fontSize: isCompact
                                  ? TextStyles.k18FontSize
                                  : TextStyles.k20FontSize,
                              color: kColorWhite,
                            ),
                            Spacing.v2,
                            AppText(
                              text:
                                  'Id : ${session.userId.isNotEmpty ? session.userId : '25656363'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              fontSize: TextStyles.k14FontSize,
                              color: kColorWhite,
                              style: TextStyles.kRegularPoppins(
                                fontSize: TextStyles.k14FontSize,
                                colors: kColorWhite,
                              ),
                            ),
                            Spacing.v10,
                            // Wrap prevents chip row overflow on narrow devices.
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _smallChip(
                                  text: session.levelBadge,
                                  start: kColorProfileChipPinkStart,
                                  end: kColorProfileChipPinkEnd,
                                ),
                                _smallChip(
                                  text: '00',
                                  start: kColorProfileChipPurpleStart,
                                  end: kColorProfileChipPurpleEnd,
                                ),
                                _smallChip(
                                  text: 'Lorium Ip',
                                  start: kColorProfileChipOrangeStart,
                                  end: kColorProfileChipOrangeEnd,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Get.toNamed(Routes.USER_BASIC_PROFILE),
                        child: const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            color: kColorWhite,
                            size: 34,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Spacing.v16,
                  // Counts come from GET /api/user/profile (formatted* / *Count).
                  Row(
                    children: [
                      _statBlock(
                        session.formattedVisitors,
                        'Visitors',
                        onTap: () => Get.toNamed(Routes.VISITORS),
                      ),
                      _statDivider(),
                      _statBlock(
                        session.formattedFriends,
                        'Friends',
                        onTap: () => Get.toNamed(
                          Routes.FOLLOW_LIST,
                          arguments: const {'initialTab': 0},
                        ),
                      ),
                      _statDivider(),
                      _statBlock(
                        session.formattedFollowing,
                        'Following',
                        onTap: () => Get.toNamed(
                          Routes.FOLLOW_LIST,
                          arguments: const {'initialTab': 1},
                        ),
                      ),
                      _statDivider(),
                      _statBlock(
                        session.formattedFollowers,
                        'Followers',
                        onTap: () => Get.toNamed(
                          Routes.FOLLOW_LIST,
                          arguments: const {'initialTab': 2},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _smallChip({
    required String text,
    required Color start,
    required Color end,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [start, end]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: SemiBoldText(
        text: text,
        fontSize: TextStyles.k12FontSize,
        color: kColorWhite,
      ),
    );
  }

  Widget _statBlock(String value, String label, {VoidCallback? onTap}) {
    final content = Column(
      children: [
        BoldText(
          text: value,
          fontSize: TextStyles.k20FontSize,
          color: kColorWhite,
        ),
        Spacing.v6,
        AppText(
          text: label,
          fontSize: TextStyles.k12FontSize,
          color: kColorWhite,
        ),
      ],
    );

    return Expanded(
      child: onTap == null
          ? content
          : GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: content,
            ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1.2,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: kColorWhite.withValues(alpha: 0.85),
    );
  }

  Widget _superAdminAction(UserSessionController userSession) {
    return GetBuilder<UserSessionController>(
      init: userSession,
      builder: (session) {
        if (session.isSuperAdmin || session.isAgency || session.isHost) {
          return const SizedBox.shrink();
        }

        return const Padding(
          padding: EdgeInsets.only(top: 10),
          child: _BecomeSuperAdminButton(),
        );
      },
    );
  }

  /// Quick action cards right below stats, matching Figma layout.
  Widget _profileActionCards(UserSessionController userSession) {
    return GetBuilder<UserSessionController>(
      init: userSession,
      builder: (session) {
        final actions = <Widget>[
          Expanded(
            child: _actionCard(
              title: 'Recharge\nCoins',
              icon: kIconRechargeCoins,
              start: kColorProfileActionOrangeStart,
              end: kColorProfileActionOrangeEnd,
              onTap: () {
                Get.to(() => const WalletView(), binding: WalletBinding());
              },
            ),
          ),
        ];

        if (session.isSuperAdmin || session.isAgency) {
          actions
            ..add(Spacing.h10)
            ..add(
              Expanded(
                child: _actionCard(
                  title: session.isSuperAdmin
                      ? 'Super Admin\nDashboard'
                      : 'Agency\nDashboard',
                  trailing: const Icon(
                    Icons.groups_rounded,
                    color: kColorWhite,
                    size: 24,
                  ),
                  start: kColorProfileActionPinkStart,
                  end: kColorProfileActionPinkEnd,
                  onTap: () => session.isSuperAdmin
                      ? Get.offAllNamed(Routes.SUPER_ADMIN_BOTTOM_NAV)
                      : Get.toNamed(Routes.AGENCY_OWNER),
                ),
              ),
            );
        }

        return Row(children: actions);
      },
    );
  }

  Widget _actionCard({
    required String title,
    String? icon,
    Widget? trailing,
    required Color start,
    required Color end,
    required VoidCallback onTap,
  }) {
    assert(
      icon != null || trailing != null,
      'Provide either icon asset or trailing widget',
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(colors: [start, end]),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: SemiBoldText(
                text: title,
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite,
              ),
            ),
            Spacing.h8,
            trailing ??
                SvgPicture.asset(
                  icon!,
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                ),
          ],
        ),
      ),
    );
  }

  Widget _profileFeatureGrid() {
    final features = <_ProfileFeatureItem>[
      _ProfileFeatureItem('Visitors', kIconVisitor, const [
        Color(0xFF1F74F2),
        Color(0xFF22B8F2),
      ], onTapRoute: Routes.VISITORS),
      _ProfileFeatureItem('User Level', kIconUserLevel, const [
        Color(0xFF8F37F2),
        Color(0xFFD23CF6),
      ], onTapRoute: Routes.USER_LEVEL),
      _ProfileFeatureItem('Backpack', kIconBackpack, const [
        Color(0xFFFF36B6),
        Color(0xFFFF5C9B),
      ], onTapRoute: Routes.BACKPACK),
      _ProfileFeatureItem('Family', kIconFamily, const [
        Color(0xFFFF8A1D),
        Color(0xFFFFD21E),
      ], onTapRoute: Routes.FAMILY),
      _ProfileFeatureItem('SVIP', kIconSVIP, const [
        Color(0xFF15BDE6),
        Color(0xFF17D7C4),
      ], onTapRoute: Routes.SVIP),
      _ProfileFeatureItem('Activity', kIconActivity, const [
        Color(0xFF43D40A),
        Color(0xFF80F20A),
      ], onTapRoute: Routes.ACTIVITY),
      _ProfileFeatureItem('Mall', kIconMall, const [
        Color(0xFFE5009E),
        Color(0xFFFF54C8),
      ], onTapRoute: Routes.MALL),
      _ProfileFeatureItem('Point Center', kIconPointerCenter, const [
        Color(0xFF00A8B8),
        Color(0xFF08D6C7),
      ], onTapRoute: Routes.POINT_CENTER),
      _ProfileFeatureItem('Award', kIconAward, const [
        Color(0xFFFF145C),
        Color(0xFFFFD83D),
      ], onTapRoute: Routes.AWARD),
      _ProfileFeatureItem('Call', kIconAward, const [
        Color(0xFFE5009E),
        Color(0xFFFF54C8),
      ], onTapRoute: Routes.CALL),
      _ProfileFeatureItem(
        'Customer\nservice',
        kIconCustomerService,
        const [Color(0xFFFFC51D), Color(0xFFFFFF35)],
        onTapRoute: Routes.CUSTOMER_SERVICE,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: kColorProfileFeatureBorder.withValues(alpha: 0.75),
          width: 1,
        ),
      ),
      child: GridView.builder(
        itemCount: features.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 18,
          crossAxisSpacing: 8,
          mainAxisExtent: 104,
        ),
        itemBuilder: (_, index) => _featureItem(features[index]),
      ),
    );
  }

  Widget _featureItem(_ProfileFeatureItem item) {
    return GestureDetector(
      onTap: () async {
        if (item.onTapRoute != null) {
          await Get.toNamed(item.onTapRoute!);
          // After Backpack equip/unequip, reload session so the hero frame updates.
          if (item.onTapRoute == Routes.BACKPACK) {
            await _resolveUserSession().refreshProfileFromApi(
              isShowLoader: false,
            );
          }
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: item.gradientColors,
              ),
              boxShadow: [
                BoxShadow(
                  color: item.gradientColors.first.withValues(alpha: 0.24),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              item.iconPath,
              width: 29,
              height: 29,
              fit: BoxFit.contain,
              colorFilter: const ColorFilter.mode(kColorWhite, BlendMode.srcIn),
            ),
          ),
          Spacing.v8,
          Center(
            child: AppText(
              text: item.label,
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite,
              align: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  UserSessionController _resolveUserSession() {
    if (Get.isRegistered<UserSessionController>()) {
      return Get.find<UserSessionController>();
    }
    return Get.put(UserSessionController(), permanent: true);
  }

  Widget _settingsRow() {
    return GestureDetector(
      onTap: () => Get.toNamed(Routes.SETTINGS),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: kColorWhite.withValues(alpha: 0.12),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.settings_rounded, color: kColorWhite, size: 22),
            Spacing.h12,
            const Expanded(
              child: SemiBoldText(
                text: 'Settings',
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite,
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: kColorWhite,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _BecomeSuperAdminButton extends StatefulWidget {
  const _BecomeSuperAdminButton();

  @override
  State<_BecomeSuperAdminButton> createState() =>
      _BecomeSuperAdminButtonState();
}

class _ProfileBackgroundShell extends StatelessWidget {
  const _ProfileBackgroundShell({
    required this.backgroundUrl,
    required this.child,
  });

  final String backgroundUrl;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final hasBackground = backgroundUrl.trim().isNotEmpty;

    // The equipped background sits behind profile details only. A dark overlay
    // keeps name, ID, chips, and stats readable on bright uploaded images.
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: hasBackground
            ? Border.all(color: kColorWhite.withValues(alpha: 0.16))
            : null,
        image: hasBackground
            ? DecorationImage(
                image: NetworkImage(backgroundUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: hasBackground
              ? LinearGradient(
                  colors: [
                    kColorBlack.withValues(alpha: 0.18),
                    kColorBlack.withValues(alpha: 0.52),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          child: child,
        ),
      ),
    );
  }
}

class _BecomeSuperAdminButtonState extends State<_BecomeSuperAdminButton> {
  final UserRepo _userRepo = UserRepo();
  bool _isLoading = false;
  final List<File> _documents = <File>[];
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (_isLoading) return;
    final shouldSubmit = await _showDocumentForm();
    if (shouldSubmit != true) return;

    if (_documents.isEmpty) {
      _showError('Please upload at least one verification document.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _userRepo.requestSuperAdmin(
        documents: List<File>.from(_documents),
        note: _noteController.text,
        isShowLoader: true,
      );
      if (response == null) {
        _showError('Could not send request. Please try again.');
        return;
      }

      final link = _findFirstLink(response);
      if (link != null) {
        await FileUtils.openFileOrLink(link);
        return;
      }

      // Prefer dialog over toast so API message / status are easy to read.
      _showResponseDialog(response);
    } catch (_) {
      _showError('Could not send request. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool?> _showDocumentForm() {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161622),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                18,
                20,
                MediaQuery.viewInsetsOf(context).bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: kColorWhite.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Spacing.v16,
                  const SemiBoldText(
                    text: 'Become Super Admin',
                    fontSize: TextStyles.k18FontSize,
                    color: kColorWhite,
                  ),
                  Spacing.v6,
                  const AppText(
                    text:
                        'Upload verification documents. Admin will review and approve or reject your request.',
                    fontSize: TextStyles.k12FontSize,
                    color: Colors.white70,
                  ),
                  Spacing.v16,
                  TextField(
                    controller: _noteController,
                    minLines: 2,
                    maxLines: 3,
                    style: TextStyles.kRegularPoppins(
                      fontSize: TextStyles.k14FontSize,
                      colors: kColorWhite,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add a short note (optional)',
                      hintStyle: TextStyles.kRegularPoppins(
                        fontSize: TextStyles.k12FontSize,
                        colors: Colors.white54,
                      ),
                      filled: true,
                      fillColor: kColorWhite.withValues(alpha: 0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: kColorWhite.withValues(alpha: 0.14),
                        ),
                      ),
                    ),
                  ),
                  Spacing.v12,
                  OutlinedButton.icon(
                    onPressed: () async {
                      final paths = await FileUtils.pickFilePaths();
                      if (paths.isEmpty) return;
                      setSheetState(() {
                        _documents
                          ..clear()
                          ..addAll(paths.map(File.new));
                      });
                    },
                    icon: const Icon(Icons.upload_file_rounded),
                    label: Text(
                      _documents.isEmpty
                          ? 'Upload documents'
                          : '${_documents.length} document(s) selected',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kColorWhite,
                      side: BorderSide(
                        color: kColorWhite.withValues(alpha: 0.25),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  if (_documents.isNotEmpty) ...[
                    Spacing.v10,
                    ..._documents
                        .take(3)
                        .map(
                          (file) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: AppText(
                              text: file.path.split('/').last,
                              fontSize: TextStyles.k10FontSize,
                              color: Colors.white60,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                  ],
                  Spacing.v16,
                  appButton(
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                    buttonText: 'Submit Request',
                    buttonColor: kColorPrimary,
                    borderRadius: 14,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String? _findFirstLink(Object? value) {
    if (value is String) {
      final trimmed = value.trim();
      final uri = Uri.tryParse(trimmed);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        return trimmed;
      }
    }

    if (value is Map) {
      for (final entry in value.entries) {
        final key = entry.key.toString().toLowerCase();
        if (key.contains('link') ||
            key.contains('url') ||
            key.contains('redirect')) {
          final directLink = _findFirstLink(entry.value);
          if (directLink != null) return directLink;
        }
      }
      for (final entry in value.entries) {
        final nestedLink = _findFirstLink(entry.value);
        if (nestedLink != null) return nestedLink;
      }
    }

    if (value is Iterable) {
      for (final item in value) {
        final nestedLink = _findFirstLink(item);
        if (nestedLink != null) return nestedLink;
      }
    }

    return null;
  }

  String? _readMessage(Map<String, dynamic>? response) {
    final message = response?['message']?.toString().trim();
    return message == null || message.isEmpty ? null : message;
  }

  /// Shows only the API message in the room-style feedback dialog.
  void _showResponseDialog(Map<String, dynamic> response) {
    if (!mounted) return;

    _documents.clear();
    _noteController.clear();

    AudioRoomFeedbackDialog.show(
      context,
      title: 'Super Admin Request',
      message: _readMessage(response) ?? 'Request processed successfully.',
      tone: AudioRoomFeedbackTone.info,
      barrierDismissible: false,
    );
  }

  void _showError(String message) {
    if (Get.isRegistered<AlertMessageUtils>()) {
      Get.find<AlertMessageUtils>().showErrorSnackBar(message);
    } else {
      Get.snackbar('Error', message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _submitRequest,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: _isLoading ? 0.68 : 1,
        child: Container(
          width: double.infinity,
          // Match `_actionCard` height so Super Admin and Recharge align.
          height: 74,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                kColorProfileActionPinkStart,
                kColorProfileChipPurpleEnd,
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kColorWhite.withValues(alpha: 0.16)),
            boxShadow: [
              BoxShadow(
                color: kColorProfileActionPinkStart.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: kColorWhite,
                  ),
                )
              else
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: kColorWhite,
                  size: 20,
                ),
              Spacing.h8,
              const SemiBoldText(
                text: 'Become Super Admin',
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileFeatureItem {
  const _ProfileFeatureItem(
    this.label,
    this.iconPath,
    this.gradientColors, {
    this.onTapRoute,
  });

  final String label;
  final String iconPath;
  final List<Color> gradientColors;
  final String? onTapRoute;
}
