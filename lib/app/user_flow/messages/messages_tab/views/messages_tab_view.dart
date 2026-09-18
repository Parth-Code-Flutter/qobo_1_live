import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/bottom_nav/controllers/bottom_nav_controller.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/app_widgets/dating_empty_hero.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/messages_tab_controller.dart';
import '../widgets/match_user_sheet.dart';
import '../widgets/message_inbox_tile_widget.dart';
import '../widgets/messages_common_widgets.dart';

/// Local dating polish accents for the light Messages tab.
abstract final class _MessagesUi {
  static const pink = AppLightUi.pink;
  static const pinkSoft = AppLightUi.pinkSoft;
  static const violet = AppLightUi.violet;
  static const cyan = AppLightUi.cyan;
}

class MessagesTabView extends GetView<MessagesTabController> {
  const MessagesTabView({super.key, this.showBackButton = false});

  /// When opened from a live/audio room, show back so the user returns to the room.
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppLightUi.bg,
      child: Stack(
        children: [
          // Soft romantic ambience — keep orbs subtle on lavender.
          Positioned(
            top: -40,
            right: -30,
            child: _GlowOrb(
              size: 180,
              color: _MessagesUi.pink.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            top: 180,
            left: -60,
            child: _GlowOrb(
              size: 160,
              color: _MessagesUi.violet.withValues(alpha: 0.07),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _topHeader(context),
                  Spacing.v16,
                  Obx(() {
                    if (controller.isSearchMode.value) {
                      return Expanded(child: _searchResults(context));
                    }
                    return Expanded(
                      child: RefreshIndicator(
                        color: AppLightUi.pink,
                        backgroundColor: AppLightUi.cardElevated,
                        onRefresh: controller.refreshAll,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          children: [
                            _sectionHeader(
                              icon: Icons.favorite_rounded,
                              title: 'New sparks',
                              subtitle: 'People waiting for your hello',
                              count: controller.newMatches.length,
                              accent: _MessagesUi.pink,
                            ),
                            Spacing.v12,
                            _newMatchRow(context),
                            Spacing.v20,
                            _sectionHeader(
                              icon: Icons.forum_rounded,
                              title: 'Your chats',
                              subtitle: 'Keep the vibe going',
                              count: controller.inboxThreads.length,
                              accent: _MessagesUi.cyan,
                            ),
                            Spacing.v12,
                            _inboxSection(context),
                            const SizedBox(height: 112),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topHeader(BuildContext context) {
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
                      color: AppLightUi.title,
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
                GestureDetector(
                  onTap: () {
                    if (!Get.isRegistered<BottomNavController>()) return;
                    Get.find<BottomNavController>().openOwnProfileSheet(
                      context,
                    );
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          _MessagesUi.pink.withValues(alpha: 0.95),
                          _MessagesUi.violet.withValues(alpha: 0.9),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _MessagesUi.pink.withValues(alpha: 0.22),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: FramedUserAvatar(
                      name: session.displayName,
                      imageUrl: avatarUrl,
                      frameUrl: session.profileFrameUrl,
                      frameSeed: session.userId,
                      size: 42,
                      fontSize: TextStyles.k12FontSize,
                    ),
                  ),
                ),
                Spacing.h12,
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SemiBoldText(
                        text: 'Messages',
                        fontSize: TextStyles.k20FontSize,
                        color: AppLightUi.title,
                      ),
                      SizedBox(height: 2),
                      AppText(
                        text: 'Good connections start with hello.',
                        fontSize: TextStyles.k10FontSize,
                        color: AppLightUi.subtitle,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppLightUi.familyCtaGradient,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: kColorWhite.withValues(alpha: 0.40),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppLightUi.title.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    size: 22,
                    color: kColorWhite,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _searchBar(),
          ],
        );
      },
    );
  }

  Widget _searchBar() {
    return Obx(
      () => ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 50,
            decoration: AppLightUi.searchDecoration(),
            child: TextField(
              controller: controller.searchController,
              textInputAction: TextInputAction.search,
              style: TextStyles.kRegularPoppins(
                fontSize: TextStyles.k12FontSize,
                colors: AppLightUi.body,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Find your next hello',
                hintStyle: TextStyles.kRegularPoppins(
                  fontSize: TextStyles.k12FontSize,
                  colors: AppLightUi.hint,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: _MessagesUi.pinkSoft.withValues(alpha: 0.95),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 44),
                suffixIcon: controller.searchQuery.value.isEmpty
                    ? null
                    : IconButton(
                        onPressed: controller.searchController.clear,
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppLightUi.muted,
                        ),
                      ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required int count,
    required Color accent,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: AppLightUi.iconTileDecoration(accent),
          child: Icon(icon, size: 17, color: accent),
        ),
        Spacing.h10,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SemiBoldText(
                text: title,
                fontSize: TextStyles.k16FontSize,
                color: AppLightUi.title,
              ),
              AppText(
                text: subtitle,
                fontSize: TextStyles.k10FontSize,
                color: AppLightUi.subtitle,
              ),
            ],
          ),
        ),
        if (count > 0)
          Container(
            constraints: const BoxConstraints(minWidth: 30),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.22),
                  accent.withValues(alpha: 0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: accent.withValues(alpha: 0.32)),
            ),
            child: AppText(
              text: '$count',
              fontSize: TextStyles.k10FontSize,
              color: AppLightUi.title,
              align: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _newMatchRow(BuildContext context) {
    if (controller.isNewMatchesLoading.value) {
      return const SizedBox(
        height: 176,
        child: Center(
          child: CircularProgressIndicator(
            color: AppLightUi.pink,
            strokeWidth: 2,
          ),
        ),
      );
    }

    final matches = controller.newMatches;
    if (matches.isEmpty) {
      return const SizedBox(
        height: 176,
        child: _InlineEmptyState(
          text: 'Your next spark could be one hello away.',
        ),
      );
    }

    return SizedBox(
      height: 176,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: matches.length,
        separatorBuilder: (_, __) => Spacing.h12,
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
        child: CircularProgressIndicator(
          color: AppLightUi.pink,
          strokeWidth: 2,
        ),
      );
    }

    if (controller.searchResults.isEmpty) {
      return Center(
        child: AppText(
          text: controller.searchQuery.value.isEmpty
              ? 'Type to search users'
              : 'No users found for "${controller.searchQuery.value}"',
          fontSize: TextStyles.k14FontSize,
          color: AppLightUi.subtitle,
          align: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      itemCount: controller.searchResults.length,
      separatorBuilder: (_, __) =>
          Divider(color: AppLightUi.border.withValues(alpha: 0.8), height: 1),
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
          child: CircularProgressIndicator(
            color: AppLightUi.pink,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (controller.inboxThreads.isEmpty) {
      return const SizedBox(height: 168, child: _MessagesEmptyState());
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.inboxThreads.length,
      separatorBuilder: (_, __) => Spacing.v6,
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

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  const _InlineEmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: AppLightUi.cardDecoration(radius: 22),
      child: Row(
        children: [
          const DatingEmptyHero(
            style: DatingEmptyHeroStyle.sparks,
            size: 88,
            accentColors: [AppLightUi.pink, AppLightUi.violet],
          ),
          Spacing.h10,
          Expanded(
            child: SemiBoldText(
              text: text,
              fontSize: TextStyles.k12FontSize,
              color: AppLightUi.body,
            ),
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
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: AppLightUi.cardDecoration(radius: 22),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DatingEmptyHero(
              style: DatingEmptyHeroStyle.messages,
              size: 72,
              accentColors: [AppLightUi.pink, AppLightUi.violet],
            ),
            SizedBox(height: 8),
            SemiBoldText(
              text: 'No chats yet',
              fontSize: TextStyles.k14FontSize,
              color: AppLightUi.title,
              align: TextAlign.center,
            ),
            SizedBox(height: 4),
            AppText(
              text: 'Say hello to a spark above and start something fun.',
              fontSize: TextStyles.k12FontSize,
              color: AppLightUi.subtitle,
              align: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
