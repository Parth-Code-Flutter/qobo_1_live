import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

import '../models/social_user_card.dart';

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
