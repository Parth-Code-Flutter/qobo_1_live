import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:get/get.dart';

/// Reusable model for "new match" horizontal list.
class MessageMatchUser {
  const MessageMatchUser({
    required this.name,
    required this.imagePath,
    this.imageUrl,
    this.hasStoryRing = false,
  });

  final String name;
  final String imagePath;
  final String? imageUrl;
  final bool hasStoryRing;
}

/// Reusable model for message listing rows.
class MessageListItemModel {
  const MessageListItemModel({
    required this.name,
    required this.message,
    required this.time,
    required this.imagePath,
    this.unreadCount = 0,
  });

  final String name;
  final String message;
  final String time;
  final String imagePath;
  final int unreadCount;
}

/// Common reusable avatar tile for the "New Match" horizontal list.
class MessageMatchAvatarItem extends StatelessWidget {
  const MessageMatchAvatarItem({super.key, required this.user});

  final MessageMatchUser user;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 66,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            padding: EdgeInsets.all(user.hasStoryRing ? 2 : 0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: user.hasStoryRing
                  ? Border.all(color: kColorWhite, width: 1.2)
                  : null,
            ),
            child: ClipOval(
              child: _matchAvatar(user),
            ),
          ),
          Spacing.v6,
          AppText(
            text: user.name,
            color: kColorWhite,
            fontSize: TextStyles.k12FontSize,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _matchAvatar(MessageMatchUser user) {
    final url = user.imageUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Image.asset(user.imagePath, fit: BoxFit.cover),
      );
    }
    return Image.asset(user.imagePath, fit: BoxFit.cover);
  }
}

/// Common reusable message row tile used by the listing screen.
class MessageListTileItem extends StatelessWidget {
  const MessageListTileItem({super.key, required this.item});

  final MessageListItemModel item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.toNamed(
          '/chat-detail',
          arguments: {'name': item.name, 'image': item.imagePath},
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            ClipOval(
              child: Image.asset(
                item.imagePath,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
            Spacing.h12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SemiBoldText(
                    text: item.name,
                    color: kColorWhite,
                    fontSize: TextStyles.k14FontSize,
                  ),
                  Spacing.v2,
                  AppText(
                    text: item.message,
                    color: kColorWhite.withValues(alpha: 0.9),
                    fontSize: TextStyles.k10FontSize,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Spacing.h8,
            SizedBox(
              width: 42,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppText(
                    text: item.time,
                    color: kColorWhite,
                    fontSize: TextStyles.k10FontSize,
                  ),
                  Spacing.v6,
                  if (item.unreadCount > 0)
                    Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: kColorBottomNavHeart,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: AppText(
                        text: '${item.unreadCount}',
                        color: kColorWhite,
                        fontSize: TextStyles.k8FontSize,
                      ),
                    )
                  else
                    const SizedBox(height: 18),
                ],
              ),
            ),
            Spacing.h6,
            Icon(
              Icons.more_vert,
              size: 18,
              color: kColorWhite.withValues(alpha: 0.65),
            ),
          ],
        ),
      ),
    );
  }
}
