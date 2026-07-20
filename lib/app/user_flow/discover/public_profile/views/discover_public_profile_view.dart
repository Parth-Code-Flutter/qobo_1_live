import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/social_user_card.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/discover_public_profile_controller.dart';

/// Dating-style full profile for a Discover user (`GET /api/user/public/:id`).
class DiscoverPublicProfileView
    extends GetView<DiscoverPublicProfileController> {
  const DiscoverPublicProfileView({super.key});

  static const _hiddenKeys = {
    'password',
    'otp',
    'token',
    'fcm_token',
    'fcmToken',
    'refreshToken',
    'refresh_token',
    'accessToken',
    'access_token',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage(kImgBG), fit: BoxFit.cover),
        ),
        child: SafeArea(
          child: Obx(() {
            final user = controller.profile.value;
            if (user == null && controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: kColorWhite),
              );
            }
            if (user == null) return _emptyState();

            return Column(
              children: [
                _topBar(user),
                Expanded(
                  child: RefreshIndicator(
                    color: kColorPrimary,
                    onRefresh: controller.loadProfile,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                      children: [
                        _heroCard(user),
                        Spacing.v16,
                        _actionButtons(context, user),
                        Spacing.v12,
                        _connectionBanner(user),
                        if (user.bio.trim().isNotEmpty) ...[
                          Spacing.v12,
                          _aboutCard(user.bio.trim()),
                        ],
                        Spacing.v12,
                        _highlightsCard(user),
                        if (_extraRows(user).isNotEmpty) ...[
                          Spacing.v12,
                          _sectionCard(
                            title: 'More details',
                            icon: Icons.auto_awesome_rounded,
                            child: Column(children: _extraRows(user)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            text: 'Profile unavailable',
            fontSize: TextStyles.k16FontSize,
            color: kColorWhite.withValues(alpha: 0.8),
          ),
          Spacing.v16,
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Go back', style: TextStyle(color: kColorWhite)),
          ),
        ],
      ),
    );
  }

  Widget _topBar(SocialUserCard user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Row(
        children: [
          _glassIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Get.back(),
          ),
          Spacing.h10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: user.name,
                  fontSize: TextStyles.k18FontSize,
                  color: kColorWhite,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                AppText(
                  text: _subtitle(user),
                  fontSize: TextStyles.k10FontSize,
                  color: kColorWhite.withValues(alpha: 0.62),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (controller.isLoading.value)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: kColorWhite,
              ),
            )
          else
            _glassIconButton(
              icon: Icons.refresh_rounded,
              onTap: controller.loadProfile,
            ),
        ],
      ),
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: kColorWhite.withValues(alpha: 0.10),
            border: Border.all(color: kColorWhite.withValues(alpha: 0.16)),
          ),
          child: Icon(icon, size: 18, color: kColorWhite),
        ),
      ),
    );
  }

  Widget _heroCard(SocialUserCard user) {
    final photo = resolveUserAvatarUrl(user.displayPicture);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF2D7B).withValues(alpha: 0.30),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: const Color(0xFF5B6CFF).withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF4DC4),
              Color(0xFF7B5CFF),
              Color(0xFF2ED3FF),
            ],
          ),
        ),
        padding: const EdgeInsets.all(2.5),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: SizedBox(
            height: 440,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (photo != null)
                  Image.network(
                    photo,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (_, __, ___) => _heroFallback(user),
                  )
                else
                  _heroFallback(user),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x66000000),
                        Color(0x00000000),
                        Color(0x99120822),
                        Color(0xF2160822),
                      ],
                      stops: [0, 0.32, 0.7, 1],
                    ),
                  ),
                ),
                Positioned(
                  top: -40,
                  right: -20,
                  child: _glowBlob(
                    const Color(0xFFFF4DC4),
                    size: 160,
                    alpha: 0.34,
                  ),
                ),
                Positioned(
                  left: -28,
                  bottom: 70,
                  child: _glowBlob(
                    const Color(0xFF2ED3FF),
                    size: 130,
                    alpha: 0.22,
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: Row(
                    children: [
                      if (user.isVip) ...[
                        _chip(
                          'VIP',
                          Icons.workspace_premium_rounded,
                          accent: true,
                        ),
                        Spacing.h8,
                      ],
                      if (user.isFavourite)
                        _chip(
                          'Favourite',
                          Icons.favorite_rounded,
                          accent: true,
                        ),
                    ],
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF4DC4), Color(0xFFFF9A3D)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFFF4DC4,
                          ).withValues(alpha: 0.45),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: FramedUserAvatar(
                      name: user.name,
                      imageUrl: user.displayPicture,
                      frameUrl: user.avatarFrameUrl,
                      frameSeed: user.id,
                      size: 52,
                      fontSize: TextStyles.k12FontSize,
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: SemiBoldText(
                              text: user.name,
                              fontSize: TextStyles.k28FontSize,
                              color: kColorWhite,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _genderBadge(user.gender),
                        ],
                      ),
                      Spacing.v10,
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (user.level > 0)
                            _chip(
                              'Lv ${user.level}',
                              Icons.military_tech_rounded,
                            ),
                          if (user.country.isNotEmpty)
                            _chip(user.country, Icons.public_rounded),
                          if (user.isMutual)
                            _chip(
                              'Mutual',
                              Icons.favorite_rounded,
                              accent: true,
                            )
                          else if (user.isFollowing)
                            _chip(
                              'Following',
                              Icons.person_add_alt_1_rounded,
                            )
                          else if (user.isFollower)
                            _chip(
                              'Follows you',
                              Icons.arrow_downward_rounded,
                            ),
                          if (user.canMessage)
                            _chip(
                              'Can message',
                              Icons.chat_bubble_rounded,
                              accent: true,
                            ),
                        ],
                      ),
                      Spacing.v12,
                      Row(
                        children: [
                          Expanded(
                            child: _statPill(
                              '${user.followersCount}',
                              'Followers',
                              Icons.people_alt_rounded,
                            ),
                          ),
                          Spacing.h8,
                          Expanded(
                            child: _statPill(
                              '${user.followingCount}',
                              'Following',
                              Icons.person_outline_rounded,
                            ),
                          ),
                          if (user.coinsPerSecond > 0) ...[
                            Spacing.h8,
                            Expanded(
                              child: _statPill(
                                '${user.coinsPerSecond.toStringAsFixed(0)}/s',
                                'Coins',
                                Icons.monetization_on_rounded,
                              ),
                            ),
                          ],
                        ],
                      ),
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

  Widget _heroFallback(SocialUserCard user) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A1658), Color(0xFF1A0E32), Color(0xFF0E1A3A)],
        ),
      ),
      child: Center(
        child: FramedUserAvatar(
          name: user.name,
          imageUrl: user.displayPicture,
          frameUrl: user.avatarFrameUrl,
          frameSeed: user.id,
          size: 120,
          fontSize: TextStyles.k32FontSize,
        ),
      ),
    );
  }

  Widget _actionButtons(BuildContext context, SocialUserCard user) {
    return Row(
      children: [
        Expanded(
          child: _GradientActionButton(
            label: user.isFollowing ? 'Following' : 'Follow',
            icon: user.isFollowing
                ? Icons.check_rounded
                : Icons.person_add_alt_1_rounded,
            gradient: user.isFollowing
                ? LinearGradient(
                    colors: [
                      kColorWhite.withValues(alpha: 0.16),
                      kColorWhite.withValues(alpha: 0.08),
                    ],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFF4DC4),
                      Color(0xFFFF2D7B),
                      Color(0xFFFF6A3D),
                    ],
                  ),
            glow: const Color(0xFFFF2D7B),
            border: user.isFollowing
                ? Border.all(
                    color: kColorProfileChipPinkStart.withValues(alpha: 0.55),
                  )
                : null,
            loading: controller.isFollowProcessing.value,
            onTap: () => controller.toggleFollow(context),
          ),
        ),
        Spacing.h10,
        Expanded(
          child: _GradientActionButton(
            label: 'Message',
            icon: Icons.chat_bubble_rounded,
            gradient: user.canMessage
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF7B5CFF),
                      Color(0xFF4F7CFF),
                      Color(0xFF2ED3FF),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF7B5CFF).withValues(alpha: 0.42),
                      const Color(0xFF2ED3FF).withValues(alpha: 0.28),
                    ],
                  ),
            glow: const Color(0xFF5B6CFF),
            border: user.canMessage
                ? null
                : Border.all(
                    color: const Color(0xFF8FA8FF).withValues(alpha: 0.45),
                  ),
            textAlpha: user.canMessage ? 1 : 0.78,
            onTap: () => controller.openChat(context),
          ),
        ),
      ],
    );
  }

  Widget _connectionBanner(SocialUserCard user) {
    final String text;
    final IconData icon;
    final List<Color> colors;

    if (user.canMessage) {
      text = 'You’re connected — say hi anytime';
      icon = Icons.favorite_rounded;
      colors = const [Color(0xFFFF4DC4), Color(0xFFFF6A3D)];
    } else if (user.isFollowing) {
      text = 'Waiting for them to follow you back';
      icon = Icons.hourglass_top_rounded;
      colors = const [Color(0xFF7B5CFF), Color(0xFF4F7CFF)];
    } else if (user.isFollower) {
      text = 'They follow you — follow back to chat';
      icon = Icons.waving_hand_rounded;
      colors = const [Color(0xFFFF9A3D), Color(0xFFFF5E7A)];
    } else {
      text = 'Follow to connect — message when either follows';
      icon = Icons.bolt_rounded;
      colors = const [Color(0xFF7B5CFF), Color(0xFF2ED3FF)];
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            colors.first.withValues(alpha: 0.22),
            colors.last.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(color: colors.first.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: colors),
            ),
            child: Icon(icon, size: 16, color: kColorWhite),
          ),
          Spacing.h10,
          Expanded(
            child: AppText(
              text: text,
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aboutCard(String bio) {
    return _sectionCard(
      title: 'About',
      icon: Icons.format_quote_rounded,
      child: AppText(
        text: bio,
        fontSize: TextStyles.k14FontSize,
        color: kColorWhite.withValues(alpha: 0.9),
      ),
    );
  }

  Widget _highlightsCard(SocialUserCard user) {
    final tiles = <_HighlightTile>[
      _HighlightTile(
        icon: Icons.wc_rounded,
        label: 'Gender',
        value: _prettyGender(user.gender),
        colors: const [Color(0xFFFF4DC4), Color(0xFFFF6A3D)],
      ),
      _HighlightTile(
        icon: Icons.military_tech_rounded,
        label: 'Level',
        value: user.level > 0 ? '${user.level}' : '—',
        colors: const [Color(0xFFFF9A3D), Color(0xFFFF5E7A)],
      ),
      _HighlightTile(
        icon: Icons.public_rounded,
        label: 'Country',
        value: user.country.trim().isEmpty ? '—' : user.country.trim(),
        colors: const [Color(0xFF7B5CFF), Color(0xFF4F7CFF)],
      ),
      _HighlightTile(
        icon: Icons.workspace_premium_rounded,
        label: 'VIP',
        value: user.isVip ? 'Yes' : 'No',
        colors: const [Color(0xFFFFD54F), Color(0xFFFF8F00)],
      ),
      _HighlightTile(
        icon: Icons.favorite_rounded,
        label: 'Connection',
        value: _connectionLabel(user),
        colors: const [Color(0xFFFF4DC4), Color(0xFF7B5CFF)],
      ),
      _HighlightTile(
        icon: Icons.chat_bubble_rounded,
        label: 'Messaging',
        value: user.canMessage ? 'Open' : 'Locked',
        colors: const [Color(0xFF4F7CFF), Color(0xFF2ED3FF)],
      ),
    ];

    return _sectionCard(
      title: 'Highlights',
      icon: Icons.auto_awesome_rounded,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tiles.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.55,
        ),
        itemBuilder: (_, index) => _highlightTile(tiles[index]),
      ),
    );
  }

  Widget _highlightTile(_HighlightTile tile) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tile.colors.first.withValues(alpha: 0.22),
            tile.colors.last.withValues(alpha: 0.10),
          ],
        ),
        border: Border.all(color: tile.colors.first.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: tile.colors),
            ),
            child: Icon(tile.icon, size: 15, color: kColorWhite),
          ),
          const Spacer(),
          AppText(
            text: tile.label,
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite.withValues(alpha: 0.62),
          ),
          Spacing.v2,
          SemiBoldText(
            text: tile.value,
            fontSize: TextStyles.k14FontSize,
            color: kColorWhite,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kColorWhite.withValues(alpha: 0.12),
            kColorWhite.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF4DC4), Color(0xFF7B5CFF)],
                  ),
                ),
                child: Icon(icon, size: 14, color: kColorWhite),
              ),
              Spacing.h8,
              SemiBoldText(
                text: title,
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite,
              ),
            ],
          ),
          Spacing.v12,
          child,
        ],
      ),
    );
  }

  List<Widget> _extraRows(SocialUserCard user) {
    final known = {
      'id',
      'name',
      'displayPicture',
      'avatarFrame',
      'avatarFrameUrl',
      'avatar_frame_url',
      'profileFrameUrl',
      'profile_frame_url',
      'gender',
      'country',
      'level',
      'bio',
      'isFollowing',
      'isFollower',
      'isMutual',
      'canMessage',
      'isVip',
      'isFavourite',
      'isFavorite',
      'coins',
      'coinsPerSecond',
      'followersCount',
      'followingCount',
    };

    final extras = <MapEntry<String, String>>[];
    for (final entry in controller.rawData.entries) {
      final key = entry.key.toString();
      if (known.contains(key) || _hiddenKeys.contains(key)) continue;
      final value = _stringify(entry.value);
      if (value == null) continue;
      extras.add(MapEntry(_labelize(key), value));
    }

    // Keep User ID as a soft footer detail when extras exist or alone.
    if (user.id.isNotEmpty) {
      extras.add(MapEntry('User ID', user.id));
    }

    return [
      for (var i = 0; i < extras.length; i++) ...[
        _detailRow(extras[i].key, extras[i].value),
        if (i != extras.length - 1) Spacing.v10,
      ],
    ];
  }

  Widget _detailRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: AppText(
              text: label,
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite.withValues(alpha: 0.55),
            ),
          ),
          Expanded(
            child: AppText(
              text: value,
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, IconData icon, {bool accent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: accent
            ? const LinearGradient(
                colors: [Color(0xFFFF4DC4), Color(0xFFFF6A3D)],
              )
            : null,
        color: accent ? null : kColorWhite.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: accent
            ? null
            : Border.all(color: kColorWhite.withValues(alpha: 0.18)),
        boxShadow: accent
            ? [
                BoxShadow(
                  color: const Color(0xFFFF2D7B).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: kColorWhite),
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

  Widget _statPill(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFFFF9AD5)),
          Spacing.h6,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: value,
                  fontSize: TextStyles.k12FontSize,
                  color: kColorWhite,
                ),
                AppText(
                  text: label,
                  fontSize: TextStyles.k8FontSize,
                  color: kColorWhite.withValues(alpha: 0.68),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _genderBadge(String gender) {
    if (gender.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: kColorWhite.withValues(alpha: 0.16),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.28)),
      ),
      child: Icon(_genderIcon(gender), size: 18, color: kColorWhite),
    );
  }

  Widget _glowBlob(Color color, {required double size, required double alpha}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: alpha), Colors.transparent],
        ),
      ),
    );
  }

  String _subtitle(SocialUserCard user) {
    final parts = <String>[];
    if (user.level > 0) parts.add('Lv ${user.level}');
    if (user.country.trim().isNotEmpty) parts.add(user.country.trim());
    if (user.isMutual) {
      parts.add('Mutual');
    } else if (user.isFollowing) {
      parts.add('Following');
    }
    return parts.isEmpty ? 'Discover profile' : parts.join(' · ');
  }

  String _connectionLabel(SocialUserCard user) {
    if (user.isMutual) return 'Mutual';
    if (user.isFollowing) return 'Following';
    if (user.isFollower) return 'Follower';
    return 'None';
  }

  String _prettyGender(String gender) {
    final raw = gender.trim();
    if (raw.isEmpty || raw == 'null') return '—';
    if (raw.toLowerCase() == 'not_specified') return 'Not specified';
    return raw
        .replaceAll('_', ' ')
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  IconData _genderIcon(String gender) {
    final g = gender.toLowerCase();
    if (g.contains('female') || g == 'f') return Icons.female_rounded;
    if (g.contains('male') || g == 'm') return Icons.male_rounded;
    return Icons.person_outline_rounded;
  }

  String _labelize(String key) {
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[1]}')
        .replaceAll('_', ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String? _stringify(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value ? 'Yes' : 'No';
    if (value is num) return value.toString();
    if (value is String) {
      final t = value.trim();
      if (t.isEmpty || t == 'null') return null;
      if (t.startsWith('http') &&
          (t.contains('cloudinary') || t.contains('image'))) {
        return null;
      }
      return t;
    }
    if (value is Map) {
      final nested = value['name'] ?? value['image'] ?? value['title'];
      return _stringify(nested);
    }
    if (value is List) {
      if (value.isEmpty) return null;
      return value.map(_stringify).whereType<String>().join(', ');
    }
    return value.toString();
  }
}

class _HighlightTile {
  const _HighlightTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final String value;
  final List<Color> colors;
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.glow,
    required this.onTap,
    this.border,
    this.textAlpha = 1,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final Gradient gradient;
  final Color glow;
  final VoidCallback onTap;
  final Border? border;
  final double textAlpha;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final textColor = kColorWhite.withValues(alpha: textAlpha);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: gradient,
            border: border,
            boxShadow: [
              BoxShadow(
                color: glow.withValues(alpha: 0.42),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Center(
            child: loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: textColor,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 18, color: textColor),
                      Spacing.h8,
                      SemiBoldText(
                        text: label,
                        fontSize: TextStyles.k14FontSize,
                        color: textColor,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
