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
  const MessagesTabView({super.key, this.showBackButton = false});

  /// When opened from a live/audio room, show back so the user returns to the room.
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage(kImgBG),
          fit: BoxFit.cover,
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF6D197E).withValues(alpha: 0.18),
            const Color(0xFF09071B).withValues(alpha: 0.22),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
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
                        _sectionHeader(
                          icon: Icons.auto_awesome_rounded,
                          title: 'New Matches',
                          count: controller.newMatches.length,
                          accent: kColorProfileChipPinkStart,
                        ),
                        Spacing.v12,
                        _newMatchRow(context),
                        Spacing.v24,
                        _sectionHeader(
                          icon: Icons.forum_rounded,
                          title: 'Conversations',
                          count: controller.inboxThreads.length,
                          accent: const Color(0xFF54D8FF),
                        ),
                        Spacing.v12,
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
        return Column(
          children: [
            Row(
              children: [
                if (showBackButton) ...[
                  IconButton(
                    onPressed: Get.back,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: kColorWhite,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 40,
                    ),
                  ),
                  Spacing.h6,
                ],
                FramedUserAvatar(
                  name: session.displayName,
                  imageUrl: avatarUrl,
                  frameUrl: session.profileFrameUrl,
                  frameSeed: session.userId,
                  size: 42,
                  fontSize: TextStyles.k12FontSize,
                ),
                Spacing.h10,
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SemiBoldText(
                        text: 'Messages',
                        fontSize: TextStyles.k20FontSize,
                        color: kColorWhite,
                      ),
                      AppText(
                        text: 'Your matches and conversations',
                        fontSize: TextStyles.k10FontSize,
                        color: Color(0xBFFFFFFF),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        kColorProfileChipPinkStart,
                        kColorProfileChipPurpleStart,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: kColorProfileChipPinkStart.withValues(
                          alpha: 0.28,
                        ),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    size: 20,
                    color: kColorWhite,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _searchBar(),
          ],
        );
      },
    );
  }

  Widget _searchBar() {
    return Obx(
      () => Container(
        height: 48,
        decoration: BoxDecoration(
          color: kColorWhite.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.13)),
        ),
        child: TextField(
          controller: controller.searchController,
          textInputAction: TextInputAction.search,
          style: TextStyles.kRegularPoppins(
            fontSize: TextStyles.k12FontSize,
            colors: kColorWhite,
          ),
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            hintText: 'Search users',
            hintStyle: TextStyles.kRegularPoppins(
              fontSize: TextStyles.k12FontSize,
              colors: kColorWhite.withValues(alpha: 0.50),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 20,
              color: kColorWhite.withValues(alpha: 0.68),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 44),
            suffixIcon: controller.searchQuery.value.isEmpty
                ? null
                : IconButton(
                    onPressed: controller.searchController.clear,
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: kColorWhite.withValues(alpha: 0.68),
                    ),
                  ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required int count,
    required Color accent,
  }) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: accent),
        ),
        Spacing.h8,
        Expanded(
          child: SemiBoldText(
            text: title,
            fontSize: TextStyles.k16FontSize,
            color: kColorWhite,
          ),
        ),
        if (count > 0)
          Container(
            constraints: const BoxConstraints(minWidth: 26),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: kColorWhite.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: AppText(
              text: '$count',
              fontSize: TextStyles.k10FontSize,
              color: kColorWhite.withValues(alpha: 0.72),
              align: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _newMatchRow(BuildContext context) {
    if (controller.isNewMatchesLoading.value) {
      return const SizedBox(
        height: 112,
        child: Center(
          child: CircularProgressIndicator(color: kColorWhite, strokeWidth: 2),
        ),
      );
    }

    final matches = controller.newMatches;
    if (matches.isEmpty) {
      return const SizedBox(
        height: 112,
        child: _InlineEmptyState(
          icon: Icons.favorite_border_rounded,
          text: 'New matches will appear here',
        ),
      );
    }

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: matches.length,
        separatorBuilder: (_, __) => Spacing.h10,
        itemBuilder: (_, index) {
          final user = matches[index];
          return MessageMatchAvatarItem(
            user: user,
            onTap: () =>
                showMatchUserSheet(context, controller.matchSheetActions, user),
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
          onAvatarTap: () =>
              showMatchUserSheet(context, controller.matchSheetActions, user),
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
      return const SizedBox(height: 160, child: _MessagesEmptyState());
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
