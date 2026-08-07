import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/social_user_card.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/live_room_ui_colors.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
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
            color: kColorWhite.withValues(alpha: 0.65),
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
        backgroundColor: LiveRoomUiColors.screenGradientBottom,
        onRefresh: controller.fetchDiscoverUsers,
        child: body,
      );
    });
  }

  Widget _gridList(BuildContext context, List<SocialUserCard> users) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 16),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.62,
      ),
      itemCount: users.length,
      itemBuilder: (context, index) => _userCard(context, users[index]),
    );
  }

  /// One tall card per viewport; vertical page snap reveals the next profile.
  Widget _singleProfileList(BuildContext context, List<SocialUserCard> users) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pageHeight = constraints.maxHeight;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 16),
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
              child: _userCard(context, users[index]),
            );
          },
        );
      },
    );
  }

  Widget _userCard(BuildContext context, SocialUserCard user) {
    return _DiscoverUserCard(
      user: user,
      isFavouriteLoading: controller.processingFavouriteId.value == user.id,
      onTap: () => showDiscoverUserCallDialog(context, controller, user),
      onFavouriteTap: () => controller.toggleFavourite(context, user),
    );
  }
}

class _DiscoverUserCard extends StatelessWidget {
  const _DiscoverUserCard({
    required this.user,
    required this.onTap,
    required this.onFavouriteTap,
    this.isFavouriteLoading = false,
  });

  static const _radius = 20.0;

  final SocialUserCard user;
  final VoidCallback onTap;
  final VoidCallback onFavouriteTap;
  final bool isFavouriteLoading;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = resolveUserAvatarUrl(user.displayPicture);

    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: LiveRoomUiColors.cardSurface,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: avatarUrl != null
                    ? Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        errorBuilder: (_, __, ___) => _photoFallback(),
                      )
                    : _photoFallback(),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 108,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.5),
                        Colors.black.withValues(alpha: 0.82),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                right: 48,
                child: _TopBadgesRow(user: user),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FramedUserAvatar(
                          name: user.name,
                          imageUrl: user.displayPicture,
                          frameUrl: user.avatarFrameUrl,
                          frameSeed: user.id,
                          size: 38,
                          fontSize: TextStyles.k10FontSize,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SemiBoldText(
                            text: user.name,
                            fontSize: TextStyles.k14FontSize,
                            color: kColorWhite,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.gender.isNotEmpty) ...[
                          Icon(
                            _genderIcon(user.gender),
                            size: 14,
                            color: kColorWhite.withValues(alpha: 0.9),
                          ),
                        ],
                      ],
                    ),
                    if (_locationLine(user).isNotEmpty) ...[
                      const SizedBox(height: 3),
                      AppText(
                        text: _locationLine(user),
                        fontSize: TextStyles.k10FontSize,
                        color: kColorWhite.withValues(alpha: 0.82),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (user.bio.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      AppText(
                        text: user.bio.trim(),
                        fontSize: TextStyles.k10FontSize,
                        color: kColorWhite.withValues(alpha: 0.72),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (user.followersCount > 0) ...[
                          _MetaIcon(
                            icon: Icons.people_outline_rounded,
                            label: _compactCount(user.followersCount),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (user.coinsPerSecond > 0)
                          _MetaIcon(
                            icon: Icons.monetization_on_outlined,
                            label:
                                '${user.coinsPerSecond.toStringAsFixed(0)}/s',
                          )
                        else if (user.coins > 0)
                          _MetaIcon(
                            icon: Icons.monetization_on_outlined,
                            label: user.coins.toStringAsFixed(0),
                          ),
                        if (user.isFollowing) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: kColorPrimary.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const AppText(
                              text: 'Following',
                              fontSize: TextStyles.k8FontSize,
                              color: kColorWhite,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: isFavouriteLoading ? null : onFavouriteTap,
                  behavior: HitTestBehavior.opaque,
                  child: _FavouriteButton(
                    isFavourite: user.isFavourite,
                    isLoading: isFavouriteLoading,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoFallback() {
    return ColoredBox(
      color: LiveRoomUiColors.cardSurface,
      child: Center(
        child: AppUserAvatar(
          name: user.name,
          size: 72,
          fontSize: TextStyles.k24FontSize,
          backgroundColor: kColorWhite.withValues(alpha: 0.1),
          textColor: kColorWhite.withValues(alpha: 0.9),
        ),
      ),
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
    final country = user.country.trim();
    if (country.isEmpty) return '';
    return country;
  }

  static String _compactCount(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return '$value';
  }
}

class _TopBadgesRow extends StatelessWidget {
  const _TopBadgesRow({required this.user});

  final SocialUserCard user;

  @override
  Widget build(BuildContext context) {
    if (!user.isVip && user.level <= 0) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (user.isVip)
          const _BadgeChip(
            label: 'VIP',
            backgroundColor: kColorWalletAmount,
            textColor: kColorBlack,
          ),
        if (user.level > 0)
          _BadgeChip(
            label: 'Lv ${user.level}',
            backgroundColor: kColorPrimary,
            textColor: kColorWhite,
          ),
      ],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: kColorWhite.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SemiBoldText(
        text: label,
        fontSize: TextStyles.k10FontSize,
        color: textColor,
      ),
    );
  }
}

class _MetaIcon extends StatelessWidget {
  const _MetaIcon({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: kColorWalletAmount),
        const SizedBox(width: 3),
        AppText(
          text: label,
          fontSize: TextStyles.k10FontSize,
          color: kColorWhite.withValues(alpha: 0.88),
        ),
      ],
    );
  }
}

class _FavouriteButton extends StatelessWidget {
  const _FavouriteButton({required this.isFavourite, required this.isLoading});

  final bool isFavourite;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(kColorWhite),
              ),
            )
          : Icon(
              isFavourite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              size: 18,
              color: isFavourite ? kColorBottomNavHeart : kColorWhite,
            ),
    );
  }
}
