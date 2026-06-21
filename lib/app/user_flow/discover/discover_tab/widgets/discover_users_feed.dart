import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/social_user_card.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/live_room_ui_colors.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/discover_tab_controller.dart';
import 'discover_user_call_dialog.dart';

/// Discover tab — photo grid with name overlay (`GET /api/user/discover`).
class DiscoverUsersFeed extends StatelessWidget {
  const DiscoverUsersFeed({super.key, required this.controller});

  final DiscoverTabController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isDiscoverUsersLoading.value) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(kColorPrimary),
          ),
        );
      }

      final users = controller.discoverUsers;
      if (users.isEmpty) {
        return Center(
          child: AppText(
            text: 'New matches will appear here',
            fontSize: TextStyles.k14FontSize,
            color: kColorWhite.withValues(alpha: 0.65),
            align: TextAlign.center,
          ),
        );
      }

      return RefreshIndicator(
        color: kColorPrimary,
        backgroundColor: LiveRoomUiColors.screenGradientBottom,
        onRefresh: controller.fetchDiscoverUsers,
        child: ColoredBox(
          color: LiveRoomUiColors.screenGradientBottom,
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.68,
            ),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ColoredBox(
                color: LiveRoomUiColors.screenGradientBottom,
                child: _DiscoverUserCard(
                  user: user,
                  onTap: () =>
                      showDiscoverUserCallDialog(context, controller, user),
                ),
              );
            },
          ),
        ),
      );
    });
  }
}

class _DiscoverUserCard extends StatelessWidget {
  const _DiscoverUserCard({
    required this.user,
    required this.onTap,
  });

  static const _radius = 20.0;

  final SocialUserCard user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = resolveUserAvatarUrl(user.displayPicture);

    return ColoredBox(
      color: LiveRoomUiColors.screenGradientBottom,
      child: ClipRRect(
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
                  height: 72,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.45),
                          Colors.black.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: SemiBoldText(
                    text: user.name,
                    fontSize: TextStyles.k16FontSize,
                    color: kColorWhite,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
}
