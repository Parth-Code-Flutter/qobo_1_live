import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/messages_tab_controller.dart';
import '../widgets/match_user_sheet.dart';
import '../widgets/message_inbox_tile_widget.dart';
import '../widgets/messages_common_widgets.dart';

class MessagesTabView extends GetView<MessagesTabController> {
  const MessagesTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(kImgBG),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topHeader(),
              Spacing.v16,
              Obx(() {
                if (controller.isSearchMode.value) {
                  return Expanded(child: _searchResults(context));
                }
                return Expanded(
                  child: RefreshIndicator(
                    color: kColorPrimary,
                    backgroundColor: kColorWhite,
                    onRefresh: controller.refreshAll,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      children: [
                        const SemiBoldText(
                          text: 'New Match',
                          fontSize: TextStyles.k18FontSize,
                          color: kColorWhite,
                        ),
                        Spacing.v12,
                        _newMatchRow(context),
                        Spacing.v20,
                        const SemiBoldText(
                          text: 'Message',
                          fontSize: TextStyles.k18FontSize,
                          color: kColorWhite,
                        ),
                        Spacing.v8,
                        _inboxSection(context),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topHeader() {
    return GetBuilder<UserSessionController>(
      builder: (session) {
        final avatarUrl = session.displayPictureUrl;
        return Row(
          children: [
            Container(
              width: 34,
              height: 34,
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: kColorWhite, width: 1),
              ),
            child: ClipOval(
              child: AppUserAvatar(
                name: session.displayName,
                imageUrl: avatarUrl,
                size: 34,
                fontSize: TextStyles.k10FontSize,
                backgroundColor: kColorAvatarFallbackBg,
              ),
            ),
            ),
            Spacing.h10,
            Expanded(child: _searchBar()),
          ],
        );
      },
    );
  }

  Widget _searchBar() {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: kColorDiscoverSearchBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller.searchController,
        textInputAction: TextInputAction.search,
        style: TextStyles.kRegularPoppins(
          fontSize: TextStyles.k12FontSize,
          colors: kColorText,
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: 'Search users',
          hintStyle: TextStyles.kRegularPoppins(
            fontSize: TextStyles.k12FontSize,
            colors: kColorHint,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Icon(
              Icons.search_rounded,
              size: 16,
              color: kColorHint,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 34),
          contentPadding: const EdgeInsets.only(top: 10, right: 10),
        ),
      ),
    );
  }

  Widget _newMatchRow(BuildContext context) {
    if (controller.isNewMatchesLoading.value) {
      return const SizedBox(
        height: 86,
        child: Center(
          child: CircularProgressIndicator(
            color: kColorWhite,
            strokeWidth: 2,
          ),
        ),
      );
    }

    final matches = controller.newMatches;
    if (matches.isEmpty) {
      return const SizedBox(
        height: 86,
        child: _InlineEmptyState(
          icon: Icons.favorite_border_rounded,
          text: 'New matches will appear here',
        ),
      );
    }

    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: matches.length,
        separatorBuilder: (_, __) => Spacing.h10,
        itemBuilder: (_, index) {
          final user = matches[index];
          return MessageMatchAvatarItem(
            user: user,
            onTap: () => showMatchUserSheet(
              context,
              controller.matchSheetActions,
              user,
            ),
          );
        },
      ),
    );
  }

  Widget _searchResults(BuildContext context) {
    if (controller.isSearchLoading.value) {
      return const Center(
        child: CircularProgressIndicator(color: kColorWhite, strokeWidth: 2),
      );
    }

    if (controller.searchResults.isEmpty) {
      return Center(
        child: AppText(
          text: controller.searchQuery.value.isEmpty
              ? 'Type to search users'
              : 'No users found for "${controller.searchQuery.value}"',
          fontSize: TextStyles.k14FontSize,
          color: kColorWhite.withValues(alpha: 0.75),
          align: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      itemCount: controller.searchResults.length,
      separatorBuilder: (_, __) =>
          Divider(color: kColorWhite.withValues(alpha: 0.12), height: 1),
      itemBuilder: (_, index) {
        final user = controller.searchResults[index];
        return MessageSearchUserTile(
          user: user,
          isProcessing: controller.processingFollowId.value == user.id,
          onFollowTap: () => controller.toggleFollow(context, user),
          onAvatarTap: () => showMatchUserSheet(
            context,
            controller.matchSheetActions,
            user,
          ),
        );
      },
    );
  }

  Widget _inboxSection(BuildContext context) {
    if (controller.isInboxLoading.value) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(color: kColorWhite, strokeWidth: 2),
        ),
      );
    }

    if (controller.inboxThreads.isEmpty) {
      return const SizedBox(
        height: 160,
        child: _MessagesEmptyState(),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.inboxThreads.length,
      separatorBuilder: (_, __) => Spacing.v8,
      itemBuilder: (_, index) {
        final thread = controller.inboxThreads[index];
        return MessageInboxTileWidget(
          item: thread,
          onTap: () => controller.openChatFromInbox(context, thread),
        );
      },
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  const _InlineEmptyState({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: kColorWhite.withValues(alpha: 0.74), size: 18),
          Spacing.h8,
          SemiBoldText(
            text: text,
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite,
          ),
        ],
      ),
    );
  }
}

class _MessagesEmptyState extends StatelessWidget {
  const _MessagesEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            color: kColorWhite.withValues(alpha: 0.7),
            size: 54,
          ),
          Spacing.v12,
          const SemiBoldText(
            text: 'No conversations yet',
            fontSize: TextStyles.k16FontSize,
            color: kColorWhite,
            align: TextAlign.center,
          ),
          Spacing.v6,
          AppText(
            text: 'Follow someone from New Match to start chatting.',
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite.withValues(alpha: 0.72),
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
