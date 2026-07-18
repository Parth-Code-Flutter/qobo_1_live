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
class DiscoverPublicProfileView extends GetView<DiscoverPublicProfileController> {
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
            if (user == null) {
              return _emptyState(context);
            }
            return Column(
              children: [
                _topBar(context, user),
                Expanded(
                  child: RefreshIndicator(
                    color: kColorPrimary,
                    onRefresh: controller.loadProfile,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                      children: [
                        _heroCard(user),
                        Spacing.v16,
                        _actionButtons(context, user),
                        Spacing.v16,
                        if (user.bio.trim().isNotEmpty) ...[
                          _sectionCard(
                            title: 'About',
                            child: AppText(
                              text: user.bio.trim(),
                              fontSize: TextStyles.k14FontSize,
                              color: kColorWhite.withValues(alpha: 0.88),
                            ),
                          ),
                          Spacing.v12,
                        ],
                        _sectionCard(
                          title: 'Profile',
                          child: Column(
                            children: [
                              ..._profileRows(user),
                            ],
                          ),
                        ),
                        if (_extraRows().isNotEmpty) ...[
                          Spacing.v12,
                          _sectionCard(
                            title: 'More details',
                            child: Column(children: _extraRows()),
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

  Widget _emptyState(BuildContext context) {
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

  Widget _topBar(BuildContext context, SocialUserCard user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kColorWhite),
          ),
          Expanded(
            child: SemiBoldText(
              text: user.name,
              fontSize: TextStyles.k18FontSize,
              color: kColorWhite,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
            ),
        ],
      ),
    );
  }

  Widget _heroCard(SocialUserCard user) {
    final photo = resolveUserAvatarUrl(user.displayPicture);
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 420,
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
                    Color(0x33000000),
                    Color(0x00000000),
                    Color(0xCC120822),
                  ],
                  stops: [0, 0.45, 1],
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
                      if (user.gender.isNotEmpty)
                        Icon(
                          _genderIcon(user.gender),
                          color: kColorWhite.withValues(alpha: 0.9),
                        ),
                    ],
                  ),
                  Spacing.v8,
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (user.level > 0) _chip('Lv ${user.level}'),
                      if (user.isVip) _chip('VIP', accent: true),
                      if (user.country.isNotEmpty) _chip(user.country),
                      if (user.isMutual)
                        _chip('Mutual', accent: true)
                      else if (user.isFollowing)
                        _chip('Following')
                      else if (user.isFollower)
                        _chip('Follows you'),
                    ],
                  ),
                  Spacing.v12,
                  Row(
                    children: [
                      _statPill('${user.followersCount}', 'Followers'),
                      Spacing.h8,
                      _statPill('${user.followingCount}', 'Following'),
                      if (user.coinsPerSecond > 0) ...[
                        Spacing.h8,
                        _statPill(
                          '${user.coinsPerSecond.toStringAsFixed(0)}/s',
                          'Coins',
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 14,
              right: 14,
              child: FramedUserAvatar(
                name: user.name,
                imageUrl: user.displayPicture,
                frameUrl: user.avatarFrameUrl,
                frameSeed: user.id,
                size: 52,
                fontSize: TextStyles.k12FontSize,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroFallback(SocialUserCard user) {
    return ColoredBox(
      color: const Color(0xFF2A1248),
      child: Center(
        child: AppUserAvatar(
          name: user.name,
          size: 120,
          fontSize: TextStyles.k32FontSize,
          backgroundColor: kColorWhite.withValues(alpha: 0.12),
          textColor: kColorWhite,
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
            outlined: user.isFollowing,
            loading: controller.isFollowProcessing.value,
            onTap: () => controller.toggleFollow(context),
          ),
        ),
        Spacing.h10,
        Expanded(
          child: _GradientActionButton(
            label: 'Message',
            icon: Icons.chat_bubble_rounded,
            accent: true,
            onTap: () => controller.openChat(context),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SemiBoldText(
            text: title,
            fontSize: TextStyles.k14FontSize,
            color: kColorWhite,
          ),
          Spacing.v10,
          child,
        ],
      ),
    );
  }

  List<Widget> _profileRows(SocialUserCard user) {
    final rows = <MapEntry<String, String>>[
      if (user.gender.isNotEmpty) MapEntry('Gender', user.gender),
      if (user.country.isNotEmpty) MapEntry('Country', user.country),
      if (user.level > 0) MapEntry('Level', '${user.level}'),
      MapEntry('Followers', '${user.followersCount}'),
      MapEntry('Following', '${user.followingCount}'),
      if (user.coins > 0) MapEntry('Coins', user.coins.toStringAsFixed(0)),
      if (user.coinsPerSecond > 0)
        MapEntry('Coins / sec', user.coinsPerSecond.toStringAsFixed(0)),
      MapEntry('VIP', user.isVip ? 'Yes' : 'No'),
      MapEntry('Favourite', user.isFavourite ? 'Yes' : 'No'),
      MapEntry(
        'Connection',
        user.isMutual
            ? 'Mutual'
            : user.isFollowing
            ? 'Following'
            : user.isFollower
            ? 'Follows you'
            : 'None',
      ),
      MapEntry('Can message', user.canMessage ? 'Yes' : 'No'),
      if (user.id.isNotEmpty) MapEntry('User ID', user.id),
    ];

    return [
      for (var i = 0; i < rows.length; i++) ...[
        _detailRow(rows[i].key, rows[i].value),
        if (i != rows.length - 1) Spacing.v8,
      ],
    ];
  }

  List<Widget> _extraRows() {
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

    return [
      for (var i = 0; i < extras.length; i++) ...[
        _detailRow(extras[i].key, extras[i].value),
        if (i != extras.length - 1) Spacing.v8,
      ],
    ];
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 118,
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
    );
  }

  Widget _chip(String label, {bool accent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent
            ? kColorPrimary.withValues(alpha: 0.85)
            : kColorWhite.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: SemiBoldText(
        text: label,
        fontSize: TextStyles.k10FontSize,
        color: kColorWhite,
      ),
    );
  }

  Widget _statPill(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SemiBoldText(
            text: value,
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite,
          ),
          Spacing.h4,
          AppText(
            text: label,
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
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
      // Skip raw URLs already shown in the hero.
      if (t.startsWith('http') &&
          (t.contains('cloudinary') || t.contains('image'))) {
        return null;
      }
      return t;
    }
    if (value is Map) {
      final nested = value['name'] ?? value['image'] ?? value['title'];
      return _stringify(nested) ?? value.toString();
    }
    if (value is List) {
      if (value.isEmpty) return null;
      return value.map(_stringify).whereType<String>().join(', ');
    }
    return value.toString();
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.outlined = false,
    this.accent = false,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool outlined;
  final bool accent;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: outlined
                ? null
                : LinearGradient(
                    colors: accent
                        ? [
                            kColorBottomNavHeart,
                            kColorBottomNavHeart.withValues(alpha: 0.82),
                          ]
                        : const [
                            kColorProfileActionPinkStart,
                            kColorProfileActionPinkEnd,
                          ],
                  ),
            color: outlined ? kColorWhite.withValues(alpha: 0.08) : null,
            border: outlined
                ? Border.all(color: kColorWhite.withValues(alpha: 0.22))
                : null,
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: kColorWhite,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 18, color: kColorWhite),
                      Spacing.h8,
                      SemiBoldText(
                        text: label,
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
