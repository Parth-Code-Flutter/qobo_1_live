import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/live_broadcast_controller.dart';

class LiveViewersSheet extends GetView<LiveBroadcastController> {
  const LiveViewersSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.55,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF161622),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Spacing.v12,
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Spacing.v16,
          Obx(
            () => SemiBoldText(
              text:
                  '${controller.viewerCount.value} ${controller.viewerCount.value == 1 ? 'Viewer' : 'Viewers'}',
              fontSize: TextStyles.k16FontSize,
              color: kColorWhite,
            ),
          ),
          Spacing.v12,
          Flexible(
            child: Obx(() {
              final viewers = controller.liveViewers;
              if (viewers.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: AppText(
                    text: 'No viewers in the room yet.',
                    fontSize: TextStyles.k14FontSize,
                    color: kColorHint,
                    align: TextAlign.center,
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: viewers.length,
                separatorBuilder: (_, __) => Spacing.v8,
                itemBuilder: (_, index) {
                  final viewer = viewers[index];
                  final name = viewer['name']?.toString() ?? 'Viewer';
                  final isHost = viewer['isHost'] == true;
                  final isCurrentUser = viewer['isCurrentUser'] == true;
                  return _ViewerListTile(
                    name: name,
                    avatarUrl: viewer['avatarUrl']?.toString(),
                    isHost: isHost,
                    isCurrentUser: isCurrentUser,
                    onTap: isCurrentUser
                        ? null
                        : () => controller.openChatWithViewer(context, viewer),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ViewerListTile extends StatelessWidget {
  const _ViewerListTile({
    required this.name,
    required this.avatarUrl,
    required this.isHost,
    required this.isCurrentUser,
    required this.onTap,
  });

  final String name;
  final String? avatarUrl;
  final bool isHost;
  final bool isCurrentUser;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2D),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          AppUserAvatar(
            name: name,
            imageUrl: avatarUrl,
            size: 40,
          ),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: isCurrentUser ? '$name (You)' : name,
                  fontSize: TextStyles.k14FontSize,
                  color: isCurrentUser
                      ? kColorWhite.withValues(alpha: 0.55)
                      : kColorWhite,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isHost)
                  const AppText(
                    text: 'Host',
                    fontSize: TextStyles.k10FontSize,
                    color: Color(0xFFFF79B4),
                  ),
              ],
            ),
          ),
          if (!isCurrentUser)
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 18,
              color: kColorWhite.withValues(alpha: 0.45),
            ),
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: content,
      ),
    );
  }
}
