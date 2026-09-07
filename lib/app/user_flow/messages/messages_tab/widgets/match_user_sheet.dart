import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/app_widgets/profile_background_media.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

import '../models/social_user_card.dart';

class OwnUserSheetData {
  const OwnUserSheetData({
    required this.user,
    required this.levelLabel,
    required this.roleLabel,
    required this.visitors,
    required this.friends,
    required this.following,
    required this.followers,
    required this.details,
  });

  final SocialUserCard user;
  final String levelLabel;
  final String roleLabel;
  final String visitors;
  final String friends;
  final String following;
  final String followers;
  final Map<String, String> details;
}

/// Follow / profile / message actions for the match user bottom sheet.
class MatchUserSheetActions {
  MatchUserSheetActions({
    required this.processingFollowId,
    required this.userById,
    required this.fetchPublicProfile,
    required this.toggleFollow,
    required this.openChat,
  });

  final RxString processingFollowId;
  final SocialUserCard? Function(String id) userById;
  final Future<SocialUserCard?> Function(String id) fetchPublicProfile;
  final Future<void> Function(BuildContext context, SocialUserCard user)
  toggleFollow;
  final Future<void> Function(BuildContext context, SocialUserCard user)
  openChat;
}

/// Bottom sheet when tapping a New Match avatar.
Future<void> showMatchUserSheet(
  BuildContext context,
  MatchUserSheetActions actions,
  SocialUserCard user,
) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  final loadingEntry = OverlayEntry(
    builder: (_) => const _ProfileLoadingOverlay(),
  );
  overlay.insert(loadingEntry);

  SocialUserCard profile = user;
  try {
    final refreshed = await actions.fetchPublicProfile(user.id);
    if (refreshed != null) profile = refreshed;
  } finally {
    loadingEntry.remove();
  }

  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) {
      return Obx(() {
        final cached = actions.userById(profile.id);
        final live = cached == null
            ? profile
            : profile.copyWith(
                isFollowing: cached.isFollowing,
                isFollower: cached.isFollower,
                isMutual: cached.isMutual,
                canMessage: cached.canMessage,
                followersCount: cached.followersCount > 0
                    ? cached.followersCount
                    : profile.followersCount,
                followingCount: cached.followingCount > 0
                    ? cached.followingCount
                    : profile.followingCount,
              );
        final isProcessing = actions.processingFollowId.value == live.id;

        return _sheetPadding(
          ctx,
          _MatchUserSheetBody(
            user: live,
            isProcessing: isProcessing,
            onFollowTap: () => actions.toggleFollow(ctx, live),
            onMessageTap: () => _onMessagePressed(
              sheetContext: ctx,
              hostContext: context,
              actions: actions,
              user: live,
            ),
          ),
        );
      });
    },
  );
}

/// Shows the signed-in user's information with the same presentation used for
/// message-list profiles, without actions that do not apply to oneself.
Future<void> showOwnUserSheet(
  BuildContext context, {
  required Future<OwnUserSheetData?> Function() loadProfile,
}) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  final loadingEntry = OverlayEntry(
    builder: (_) => const _ProfileLoadingOverlay(),
  );
  overlay.insert(loadingEntry);

  OwnUserSheetData? profile;
  try {
    profile = await loadProfile();
  } finally {
    loadingEntry.remove();
  }

  if (!context.mounted || profile == null) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    constraints: const BoxConstraints(maxWidth: double.infinity),
    builder: (ctx) => SizedBox(
      width: double.infinity,
      height: MediaQuery.sizeOf(ctx).height * 0.75,
      child: SafeArea(top: false, child: _OwnUserSheetBody(data: profile!)),
    ),
  );
}

class _OwnUserSheetBody extends StatelessWidget {
  const _OwnUserSheetBody({required this.data});

  final OwnUserSheetData data;

  @override
  Widget build(BuildContext context) {
    final user = data.user;
    return SizedBox.expand(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFF150B29)),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _hero(context, user),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                  child: Column(
                    children: [
                      _identity(user),
                      Spacing.v16,
                      _stats(),
                      if (user.bio.trim().isNotEmpty) ...[
                        Spacing.v16,
                        _section(
                          title: 'About me',
                          icon: Icons.auto_awesome_rounded,
                          child: AppText(
                            text: user.bio.trim(),
                            fontSize: TextStyles.k12FontSize,
                            color: kColorWhite.withValues(alpha: 0.78),
                            maxLines: 5,
                          ),
                        ),
                      ],
                      if (data.details.isNotEmpty) ...[
                        Spacing.v16,
                        _section(
                          title: 'Profile details',
                          icon: Icons.person_outline_rounded,
                          child: Column(
                            children: data.details.entries
                                .toList()
                                .asMap()
                                .entries
                                .map((entry) {
                                  final detail = entry.value;
                                  return Column(
                                    children: [
                                      _detailRow(detail.key, detail.value),
                                      if (entry.key < data.details.length - 1)
                                        Divider(
                                          height: 1,
                                          color: kColorWhite.withValues(
                                            alpha: 0.08,
                                          ),
                                        ),
                                    ],
                                  );
                                })
                                .toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero(BuildContext context, SocialUserCard user) {
    final background = user.profileBackgroundUrl?.trim() ?? '';
    return SizedBox(
      height: 150,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (background.isNotEmpty)
            ProfileBackgroundMedia(
              url: background,
              fit: BoxFit.cover,
              showLoadingIndicator: false,
            )
          else
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF743AE7), Color(0xFFE92B85)],
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.10),
                  const Color(0xFF150B29).withValues(alpha: 0.88),
                ],
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: kColorWhite.withValues(alpha: 0.48),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 14,
            child: Material(
              color: Colors.black.withValues(alpha: 0.28),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: Navigator.of(context).pop,
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 38,
                  height: 38,
                  child: Icon(
                    Icons.close_rounded,
                    color: kColorWhite,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: FramedUserAvatar(
                name: user.name,
                imageUrl: user.displayPicture,
                frameUrl: user.avatarFrameUrl,
                frameSeed: user.id,
                size: 88,
                fontSize: TextStyles.k20FontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _identity(SocialUserCard user) {
    return Column(
      children: [
        BoldText(
          text: user.name,
          fontSize: TextStyles.k20FontSize,
          color: kColorWhite,
          align: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Spacing.v8,
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _identityChip(
              data.levelLabel,
              Icons.military_tech_rounded,
              const Color(0xFF9E77FF),
            ),
            if (data.roleLabel.isNotEmpty)
              _identityChip(
                data.roleLabel,
                Icons.workspace_premium_rounded,
                const Color(0xFFFFC44D),
              ),
            _identityChip(
              'My profile',
              Icons.verified_user_rounded,
              kColorProfileChipPinkStart,
            ),
          ],
        ),
      ],
    );
  }

  Widget _identityChip(String label, IconData icon, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.48)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: accent),
          Spacing.h4,
          SemiBoldText(
            text: label,
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite,
          ),
        ],
      ),
    );
  }

  Widget _stats() {
    final values = [
      (
        data.visitors,
        'Visitors',
        Icons.visibility_outlined,
        const Color(0xFF54D8FF),
      ),
      (
        data.friends,
        'Friends',
        Icons.favorite_outline_rounded,
        const Color(0xFFFF4F9A),
      ),
      (
        data.following,
        'Following',
        Icons.person_add_alt_rounded,
        const Color(0xFF9E77FF),
      ),
      (
        data.followers,
        'Followers',
        Icons.groups_2_outlined,
        const Color(0xFF42D989),
      ),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: values
            .map(
              (item) => Expanded(
                child: Column(
                  children: [
                    Icon(item.$3, color: item.$4, size: 17),
                    Spacing.v4,
                    SemiBoldText(
                      text: item.$1,
                      fontSize: TextStyles.k14FontSize,
                      color: kColorWhite,
                    ),
                    AppText(
                      text: item.$2,
                      fontSize: TextStyles.k8FontSize,
                      color: kColorWhite.withValues(alpha: 0.54),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.09)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: kColorProfileChipPinkStart),
              Spacing.h8,
              SemiBoldText(
                text: title,
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite,
              ),
            ],
          ),
          Spacing.v10,
          child,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    final accent = _detailColor(label);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(_detailIcon(label), size: 15, color: accent),
          ),
          Spacing.h10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: label,
                  fontSize: TextStyles.k8FontSize,
                  color: kColorWhite.withValues(alpha: 0.48),
                ),
                Spacing.v2,
                AppText(
                  text: value,
                  fontSize: 11,
                  color: kColorWhite.withValues(alpha: 0.88),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _detailIcon(String label) {
    switch (label) {
      case 'User ID':
        return Icons.badge_outlined;
      case 'Email':
        return Icons.alternate_email_rounded;
      case 'Phone':
        return Icons.phone_outlined;
      case 'Birthday':
        return Icons.cake_outlined;
      case 'Age':
        return Icons.calendar_today_outlined;
      case 'Location':
        return Icons.location_on_outlined;
      case 'Coins':
        return Icons.monetization_on_outlined;
      case 'Diamonds':
        return Icons.diamond_outlined;
      case 'Agency code':
        return Icons.apartment_rounded;
      case 'Call rate':
        return Icons.monetization_on_outlined;
      case 'Status':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _detailColor(String label) {
    switch (label) {
      case 'User ID':
        return const Color(0xFFFF4F9A);
      case 'Email':
        return const Color(0xFF54D8FF);
      case 'Phone':
        return const Color(0xFF42D989);
      case 'Gender':
        return const Color(0xFFFF6F91);
      case 'Birthday':
      case 'Age':
        return const Color(0xFFFFB84D);
      case 'Location':
        return const Color(0xFF72D7C8);
      case 'Coins':
        return const Color(0xFFFFD84D);
      case 'Diamonds':
        return const Color(0xFF45C7FF);
      case 'Agency code':
        return const Color(0xFFB185FF);
      case 'Call rate':
        return const Color(0xFFFF9D4D);
      case 'Status':
        return const Color(0xFF42D989);
      default:
        return kColorProfileChipPinkStart;
    }
  }
}

class _ProfileLoadingOverlay extends StatelessWidget {
  const _ProfileLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const ModalBarrier(dismissible: false, color: Color(0x73000000)),
        Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 126,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2A1248), Color(0xFF17102B)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: kColorWhite.withValues(alpha: 0.14)),
                boxShadow: [
                  BoxShadow(
                    color: kColorPrimary.withValues(alpha: 0.24),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      color: kColorProfileChipPinkStart,
                      strokeWidth: 2.5,
                    ),
                  ),
                  Spacing.v10,
                  AppText(
                    text: 'Loading profile',
                    fontSize: TextStyles.k10FontSize,
                    color: kColorWhite.withValues(alpha: 0.78),
                    align: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Widget _sheetPadding(BuildContext context, Widget child) {
  return Padding(
    padding: EdgeInsets.only(
      left: 12,
      right: 12,
      bottom: MediaQuery.paddingOf(context).bottom + 12,
    ),
    child: child,
  );
}

Future<void> _onMessagePressed({
  required BuildContext sheetContext,
  required BuildContext hostContext,
  required MatchUserSheetActions actions,
  required SocialUserCard user,
}) async {
  if (!user.canMessage) {
    AppToast.showError(
      sheetContext,
      user.isFollowing
          ? 'Waiting for them to follow you back'
          : 'Follow to connect — message when either follows',
    );
    return;
  }

  Navigator.of(sheetContext).pop();
  await Future<void>.delayed(Duration.zero);
  if (!hostContext.mounted) return;
  await actions.openChat(hostContext, user);
}

class _MatchUserSheetBody extends StatelessWidget {
  const _MatchUserSheetBody({
    required this.user,
    required this.isProcessing,
    required this.onFollowTap,
    required this.onMessageTap,
  });

  final SocialUserCard user;
  final bool isProcessing;
  final VoidCallback onFollowTap;
  final VoidCallback onMessageTap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.86,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: kColorPrimary.withValues(alpha: 0.35),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF2A1248),
                        const Color(0xFF1A0E32),
                        const Color(0xFF120822),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -40,
                right: -20,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        kColorProfileChipPinkStart.withValues(alpha: 0.22),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _dragHandle(),
                      Spacing.v16,
                      _avatarSection(),
                      Spacing.v12,
                      SemiBoldText(
                        text: user.name,
                        fontSize: TextStyles.k20FontSize,
                        color: kColorWhite,
                        align: TextAlign.center,
                      ),
                      Spacing.v8,
                      _statusRow(),
                      if (user.bio.isNotEmpty) ...[Spacing.v12, _bioCard()],
                      Spacing.v12,
                      _statsRow(),
                      Spacing.v12,
                      _profileDetails(),
                      if (user.activeSession != null) ...[
                        Spacing.v12,
                        _liveSessionCard(),
                      ],
                      Spacing.v20,
                      _actionRow(),
                      Spacing.v12,
                      _connectionHint(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dragHandle() {
    return Container(
      width: 44,
      height: 4,
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }

  Widget _avatarSection() {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          FramedUserAvatar(
            name: user.name,
            imageUrl: user.displayPicture,
            frameUrl: user.avatarFrameUrl,
            frameSeed: user.id,
            size: 78,
            fontSize: TextStyles.k20FontSize,
          ),
          if (user.isVip)
            Positioned(
              bottom: 0,
              right: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kColorWhite, width: 1),
                ),
                child: const SemiBoldText(
                  text: 'VIP',
                  fontSize: TextStyles.k8FontSize,
                  color: kColorBlack,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusRow() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        if (user.level > 0)
          _chip('LV.${user.level}', Icons.military_tech_rounded),
        if (user.isMutual)
          _chip('Mutual', Icons.favorite_rounded, accent: true)
        else if (user.isFollowing)
          _chip('Following', Icons.person_add_alt_1_rounded)
        else if (user.isFollower)
          _chip('Follows you', Icons.arrow_downward_rounded),
        if (user.canMessage)
          _chip('Can message', Icons.chat_bubble_rounded, accent: true),
      ],
    );
  }

  Widget _chip(String label, IconData icon, {bool accent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent
            ? kColorPrimary.withValues(alpha: 0.35)
            : kColorWhite.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent
              ? kColorProfileChipPinkStart.withValues(alpha: 0.45)
              : kColorWhite.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: accent
                ? kColorProfileChipPinkStart
                : kColorWhite.withValues(alpha: 0.75),
          ),
          Spacing.h4,
          SemiBoldText(
            text: label,
            fontSize: TextStyles.k10FontSize,
            color: accent ? kColorWhite : kColorWhite.withValues(alpha: 0.82),
          ),
        ],
      ),
    );
  }

  Widget _bioCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.08)),
      ),
      child: AppText(
        text: user.bio,
        fontSize: TextStyles.k12FontSize,
        color: kColorWhite.withValues(alpha: 0.78),
        align: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        Expanded(child: _statTile('Followers', '${user.followersCount}')),
        Container(
          width: 1,
          height: 34,
          color: kColorWhite.withValues(alpha: 0.12),
        ),
        Expanded(child: _statTile('Following', '${user.followingCount}')),
        Container(
          width: 1,
          height: 34,
          color: kColorWhite.withValues(alpha: 0.12),
        ),
        Expanded(child: _statTile('Coins', _compactNumber(user.coins))),
      ],
    );
  }

  Widget _profileDetails() {
    final details = <(IconData, String, String)>[
      (Icons.badge_outlined, 'User ID', user.id),
      if (user.country.trim().isNotEmpty)
        (Icons.public_rounded, 'Country', user.country.trim()),
      if (user.gender.trim().isNotEmpty)
        (Icons.person_outline_rounded, 'Gender', user.gender.trim()),
      if (user.coinsPerSecond > 0)
        (
          Icons.timer_outlined,
          'Call rate',
          '${_compactNumber(user.coinsPerSecond)} coins/sec',
        ),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.09)),
      ),
      child: Column(
        children: [
          for (var index = 0; index < details.length; index++) ...[
            _detailRow(details[index].$1, details[index].$2, details[index].$3),
            if (index < details.length - 1)
              Divider(height: 1, color: kColorWhite.withValues(alpha: 0.08)),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(icon, color: kColorProfileChipPinkStart, size: 17),
          Spacing.h8,
          AppText(
            text: label,
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite.withValues(alpha: 0.52),
          ),
          Spacing.h10,
          Expanded(
            child: SemiBoldText(
              text: value,
              fontSize: 11,
              color: kColorWhite.withValues(alpha: 0.88),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              align: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveSessionCard() {
    final session = user.activeSession!;
    final isLive = session.isLive;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kColorProfileChipPinkStart.withValues(alpha: 0.20),
            kColorProfileChipPurpleStart.withValues(alpha: 0.16),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: kColorProfileChipPinkStart.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: kColorProfileChipPinkStart.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              session.normalizedRoomType == 'AUDIO'
                  ? Icons.graphic_eq_rounded
                  : Icons.videocam_rounded,
              color: kColorWhite,
              size: 20,
            ),
          ),
          Spacing.h10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: isLive ? session.liveBadgeLabel : 'Last session',
                  fontSize: TextStyles.k12FontSize,
                  color: isLive ? kColorProfileChipPinkStart : kColorWhite,
                ),
                if ((session.title ?? '').trim().isNotEmpty)
                  AppText(
                    text: session.title!.trim(),
                    fontSize: TextStyles.k10FontSize,
                    color: kColorWhite.withValues(alpha: 0.65),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (session.viewerCount > 0)
            AppText(
              text: '${session.viewerCount} watching',
              fontSize: TextStyles.k10FontSize,
              color: kColorWhite.withValues(alpha: 0.62),
            ),
        ],
      ),
    );
  }

  String _compactNumber(num value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  Widget _statTile(String label, String value) {
    return Column(
      children: [
        SemiBoldText(
          text: value,
          fontSize: TextStyles.k16FontSize,
          color: kColorWhite,
        ),
        Spacing.v2,
        AppText(
          text: label,
          fontSize: TextStyles.k10FontSize,
          color: kColorWhite.withValues(alpha: 0.55),
        ),
      ],
    );
  }

  Widget _actionRow() {
    return Row(
      children: [
        Expanded(
          child: _FollowButton(
            isFollowing: user.isFollowing,
            isProcessing: isProcessing,
            onTap: onFollowTap,
          ),
        ),
        Spacing.h12,
        Expanded(
          child: _MessageButton(enabled: user.canMessage, onTap: onMessageTap),
        ),
      ],
    );
  }

  Widget _connectionHint() {
    final String text;
    final IconData icon;

    if (user.canMessage) {
      text = 'You can start a conversation now';
      icon = Icons.check_circle_outline_rounded;
    } else if (user.isFollowing) {
      text = 'Waiting for them to follow you back';
      icon = Icons.hourglass_top_rounded;
    } else {
      text = 'Follow to connect — message when either follows';
      icon = Icons.info_outline_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: kColorWhite.withValues(alpha: 0.5)),
          Spacing.h8,
          Expanded(
            child: AppText(
              text: text,
              fontSize: TextStyles.k10FontSize,
              color: kColorWhite.withValues(alpha: 0.58),
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({
    required this.isFollowing,
    required this.isProcessing,
    required this.onTap,
  });

  final bool isFollowing;
  final bool isProcessing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isProcessing ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isFollowing
                ? null
                : const LinearGradient(
                    colors: [
                      kColorProfileActionPinkStart,
                      kColorProfileActionPinkEnd,
                    ],
                  ),
            color: isFollowing ? kColorWhite.withValues(alpha: 0.08) : null,
            border: isFollowing
                ? Border.all(color: kColorWhite.withValues(alpha: 0.22))
                : null,
            boxShadow: isFollowing
                ? null
                : [
                    BoxShadow(
                      color: kColorProfileActionPinkStart.withValues(
                        alpha: 0.35,
                      ),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: isProcessing
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: isFollowing
                          ? kColorWhite.withValues(alpha: 0.7)
                          : kColorWhite,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isFollowing
                            ? Icons.check_rounded
                            : Icons.person_add_alt_1_rounded,
                        size: 18,
                        color: kColorWhite,
                      ),
                      Spacing.h6,
                      SemiBoldText(
                        text: isFollowing ? 'Following' : 'Follow',
                        fontSize: TextStyles.k14FontSize,
                        color: kColorWhite,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _MessageButton extends StatelessWidget {
  const _MessageButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: enabled
                ? LinearGradient(
                    colors: [
                      kColorBottomNavHeart,
                      kColorBottomNavHeart.withValues(alpha: 0.82),
                    ],
                  )
                : null,
            color: enabled ? null : kColorWhite.withValues(alpha: 0.06),
            border: enabled
                ? null
                : Border.all(color: kColorWhite.withValues(alpha: 0.1)),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 17,
                  color: enabled
                      ? kColorWhite
                      : kColorWhite.withValues(alpha: 0.35),
                ),
                Spacing.h6,
                SemiBoldText(
                  text: 'Message',
                  fontSize: TextStyles.k14FontSize,
                  color: enabled
                      ? kColorWhite
                      : kColorWhite.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
