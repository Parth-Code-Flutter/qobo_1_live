import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/social_user_card.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/app_widgets/live_session_badge.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/discover_tab_controller.dart';
import '../models/discover_feed_layout.dart';
import 'discover_user_call_dialog.dart';

/// Discover tab — photo grid or single-profile feed (`GET /api/discover`).
///
/// Pass [users] to render an alternate list (e.g. search results) with the
/// same card UI as the main Discover feed.
class DiscoverUsersFeed extends StatelessWidget {
  const DiscoverUsersFeed({
    super.key,
    required this.controller,
    this.users,
    this.isLoading,
    this.emptyMessage = 'New matches will appear here',
    this.enablePullToRefresh = true,
  });

  final DiscoverTabController controller;

  /// When set, shown instead of [DiscoverTabController.discoverUsers].
  final List<SocialUserCard>? users;

  /// Overrides discover loading spinner (used for search).
  final bool? isLoading;

  final String emptyMessage;
  final bool enablePullToRefresh;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = isLoading ?? controller.isDiscoverUsersLoading.value;
      if (loading) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(kColorPrimary),
          ),
        );
      }

      final feedUsers = users ?? controller.discoverUsers.toList();
      if (feedUsers.isEmpty) {
        return Center(
          child: AppText(
            text: emptyMessage,
            fontSize: TextStyles.k14FontSize,
            color: AppLightUi.subtitle,
            align: TextAlign.center,
          ),
        );
      }

      // Read layout inside Obx so grid ↔ single swaps without refetching users.
      final isSingle = controller.feedLayout.value == DiscoverFeedLayout.single;
      final body = isSingle
          ? _singleProfileList(context, feedUsers)
          : _gridList(context, feedUsers);

      if (!enablePullToRefresh) return body;

      return RefreshIndicator(
        color: kColorPrimary,
        backgroundColor: AppLightUi.card,
        onRefresh: controller.fetchDiscoverUsers,
        child: body,
      );
    });
  }

  Widget _gridList(BuildContext context, List<SocialUserCard> users) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 112),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        // Slightly taller so bottom identity + Follow fit without overflow.
        childAspectRatio: 0.56,
      ),
      itemCount: users.length,
      itemBuilder: (context, index) =>
          _userCard(context, users[index], compact: true),
    );
  }

  /// One tall card per viewport; vertical page snap reveals the next profile.
  Widget _singleProfileList(BuildContext context, List<SocialUserCard> users) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pageHeight = constraints.maxHeight;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 112),
          physics: const PageScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
          ),
          itemExtent: pageHeight > 0 ? pageHeight : null,
          itemCount: users.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _userCard(context, users[index], compact: false),
            );
          },
        );
      },
    );
  }

  Widget _userCard(
    BuildContext context,
    SocialUserCard user, {
    required bool compact,
  }) {
    return _DiscoverUserCard(
      user: user,
      compact: compact,
      isFavouriteLoading: controller.processingFavouriteId.value == user.id,
      isFollowLoading: controller.processingFollowId.value == user.id,
      onTap: () => showDiscoverUserCallDialog(context, controller, user),
      onFavouriteTap: () => controller.toggleFavourite(context, user),
      onFollowTap: () => controller.toggleFollowUser(context, user),
    );
  }
}

class _DiscoverUserCard extends StatelessWidget {
  const _DiscoverUserCard({
    required this.user,
    required this.compact,
    required this.onTap,
    required this.onFavouriteTap,
    required this.onFollowTap,
    this.isFavouriteLoading = false,
    this.isFollowLoading = false,
  });

  static const _radius = 20.0;

  final SocialUserCard user;
  final bool compact;
  final VoidCallback onTap;
  final VoidCallback onFavouriteTap;
  final VoidCallback onFollowTap;
  final bool isFavouriteLoading;
  final bool isFollowLoading;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = resolveUserAvatarUrl(user.displayPicture);
    // Tighter fade — identity + Follow only (no stats strip).
    final bottomFadeHeight = compact ? 108.0 : 132.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: AppLightUi.borderStrong, width: 1),
          boxShadow: AppLightUi.cardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_radius - 1),
                    child: avatarUrl != null
                        ? Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            errorBuilder: (_, __, ___) => _photoFallback(),
                          )
                        : _photoFallback(),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: bottomFadeHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(_radius - 1),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF1A0B2E).withValues(alpha: 0.22),
                          const Color(0xFF12081F).withValues(alpha: 0.78),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
                // Top-left — live / VIP / level badges.
                Positioned(
                  top: 10,
                  left: 10,
                  right: compact ? 46 : 52,
                  child: _TopBadgesRow(user: user),
                ),
                // Heart — top-right most.
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: isFavouriteLoading ? null : onFavouriteTap,
                    behavior: HitTestBehavior.opaque,
                    child: _FavouriteButton(
                      isFavourite: user.isFavourite,
                      isLoading: isFavouriteLoading,
                    ),
                  ),
                ),
                // Bottom — identity left + Follow replacing former stats strip.
                Positioned(
                  left: compact ? 10 : 14,
                  right: compact ? 10 : 14,
                  bottom: compact ? 10 : 14,
                  child: _CardBottomOverlay(
                    user: user,
                    compact: compact,
                    isFollowLoading: isFollowLoading,
                    onFollowTap: onFollowTap,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _photoFallback() {
    return ColoredBox(
      color: AppLightUi.cardSoft,
      child: Center(
        child: AppUserAvatar(
          name: user.name,
          size: 72,
          fontSize: TextStyles.k24FontSize,
          backgroundColor: AppLightUi.pink.withValues(alpha: 0.12),
          textColor: AppLightUi.title,
        ),
      ),
    );
  }
}

/// Bottom identity + Follow CTA (replaces former followers/following/coins strip).
class _CardBottomOverlay extends StatelessWidget {
  const _CardBottomOverlay({
    required this.user,
    required this.compact,
    required this.isFollowLoading,
    required this.onFollowTap,
  });

  final SocialUserCard user;
  final bool compact;
  final bool isFollowLoading;
  final VoidCallback onFollowTap;

  @override
  Widget build(BuildContext context) {
    final location = _locationLine(user);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FramedUserAvatar(
              name: user.name,
              imageUrl: user.displayPicture,
              frameUrl: user.avatarFrameUrl,
              frameSeed: user.id,
              size: compact ? 30.0 : 38.0,
              fontSize:
                  compact ? TextStyles.k10FontSize : TextStyles.k12FontSize,
            ),
            SizedBox(width: compact ? 7 : 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: SemiBoldText(
                          text: user.name,
                          fontSize: compact
                              ? TextStyles.k12FontSize
                              : TextStyles.k16FontSize,
                          color: kColorWhite,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.gender.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Icon(
                          _genderIcon(user.gender),
                          size: compact ? 12 : 15,
                          color: kColorWhite.withValues(alpha: 0.88),
                        ),
                      ],
                    ],
                  ),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    AppText(
                      text: location,
                      fontSize: compact
                          ? TextStyles.k10FontSize
                          : TextStyles.k12FontSize,
                      color: kColorWhite.withValues(alpha: 0.78),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (!compact && user.bio.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          AppText(
            text: user.bio.trim(),
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite.withValues(alpha: 0.70),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        SizedBox(height: compact ? 6 : 8),
        // Opaque detector so Follow taps never open the profile dialog.
        GestureDetector(
          onTap: isFollowLoading ? null : onFollowTap,
          behavior: HitTestBehavior.opaque,
          child: _CardFollowButton(
            isFollowing: user.isFollowing,
            isLoading: isFollowLoading,
            compact: compact,
            onTap: onFollowTap,
          ),
        ),
      ],
    );
  }

  static IconData _genderIcon(String gender) {
    final g = gender.toLowerCase();
    if (g.contains('female') || g == 'f') {
      return Icons.female_rounded;
    }
    if (g.contains('male') || g == 'm') {
      return Icons.male_rounded;
    }
    return Icons.person_outline_rounded;
  }

  static String _locationLine(SocialUserCard user) {
    return user.country.trim();
  }
}

class _CardFollowButton extends StatelessWidget {
  const _CardFollowButton({
    required this.isFollowing,
    required this.isLoading,
    required this.compact,
    required this.onTap,
  });

  final bool isFollowing;
  final bool isLoading;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final height = compact ? 28.0 : 34.0;
    final padH = compact ? 10.0 : 14.0;

    // GestureDetector wins the tap arena so the parent card InkWell
    // does not open the profile dialog when following.
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: height,
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: padH),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: isFollowing ? null : AppLightUi.familyCtaGradient,
          color: isFollowing ? kColorBlack.withValues(alpha: 0.42) : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isFollowing
                ? kColorWhite.withValues(alpha: 0.40)
                : kColorWhite.withValues(alpha: 0.50),
            width: 1.2,
          ),
          boxShadow: isFollowing
              ? null
              : [
                  BoxShadow(
                    color: AppLightUi.title.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: isLoading
            ? SizedBox(
                width: compact ? 14 : 16,
                height: compact ? 14 : 16,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(kColorWhite),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isFollowing
                        ? Icons.check_rounded
                        : Icons.person_add_alt_1_rounded,
                    size: compact ? 13 : 15,
                    color: kColorWhite,
                  ),
                  SizedBox(width: compact ? 3 : 5),
                  SemiBoldText(
                    text: isFollowing ? 'Following' : 'Follow',
                    fontSize: compact
                        ? TextStyles.k10FontSize
                        : TextStyles.k12FontSize,
                    color: kColorWhite,
                  ),
                ],
              ),
      ),
    );
  }
}

class _TopBadgesRow extends StatelessWidget {
  const _TopBadgesRow({required this.user});

  final SocialUserCard user;

  @override
  Widget build(BuildContext context) {
    final showLive = user.isLiveNow;
    if (!showLive && !user.isVip && user.level <= 0) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (showLive)
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                child: LiveSessionBadge.fromSession(
                  user.activeSession,
                  compact: true,
                ),
              ),
            if (user.isVip) const _VipBadgeChip(),
            if (user.level > 0) _LevelBadgeChip(level: user.level),
          ],
        );
      },
    );
  }
}

/// Glossy level chip — gradient fill, gloss ring, soft neutral glow.
class _LevelBadgeChip extends StatelessWidget {
  const _LevelBadgeChip({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(1.4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        gradient: AppLightUi.glossRingGradient,
        boxShadow: [
          BoxShadow(
            color: AppLightUi.title.withValues(alpha: 0.14),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9.5),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppLightUi.violet.withValues(alpha: 0.95),
              const Color(0xFF7B5CFF),
              AppLightUi.pink.withValues(alpha: 0.88),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 10,
                color: kColorWhite.withValues(alpha: 0.95),
              ),
              const SizedBox(width: 3),
              SemiBoldText(
                text: 'Lv $level',
                fontSize: TextStyles.k10FontSize,
                color: kColorWhite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Light polish for VIP so it sits next to the level chip cleanly.
class _VipBadgeChip extends StatelessWidget {
  const _VipBadgeChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kColorWalletAmount.withValues(alpha: 0.95),
            const Color(0xFFFFD56A),
            kColorWalletAmount,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppLightUi.title.withValues(alpha: 0.10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9.5),
          color: kColorWalletAmount,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                size: 10,
                color: kColorBlack.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 3),
              SemiBoldText(
                text: 'VIP',
                fontSize: TextStyles.k10FontSize,
                color: kColorBlack,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavouriteButton extends StatelessWidget {
  const _FavouriteButton({required this.isFavourite, required this.isLoading});

  final bool isFavourite;
  final bool isLoading;

  static const _size = 30.0;
  static const _ring = 1.5;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      padding: const EdgeInsets.all(_ring),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppLightUi.glossRingGradient,
        boxShadow: [
          BoxShadow(
            color: AppLightUi.title.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isFavourite ? AppLightUi.familyCtaGradient : null,
          color: isFavourite ? null : kColorWhite.withValues(alpha: 0.96),
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isFavourite ? kColorWhite : AppLightUi.pink,
                    ),
                  ),
                )
              : isFavourite
                  ? const Icon(
                      Icons.favorite_rounded,
                      size: 15,
                      color: kColorWhite,
                    )
                  : ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) =>
                          AppLightUi.familyCtaGradient.createShader(bounds),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        size: 15,
                        color: kColorWhite,
                      ),
                    ),
        ),
      ),
    );
  }
}
