import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/bottom_nav/controllers/bottom_nav_controller.dart';
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

/// Local dating polish tokens — keep the same purple/dark Messages theme.
abstract final class _MessagesUi {
  static const pink = Color(0xFFFF5C9A);
  static const pinkSoft = Color(0xFFFF9AB8);
  static const violet = Color(0xFF9B6DFF);
  static const cyan = Color(0xFF54D8FF);
  static const glass = Color(0xFF1C1230);
}

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
      child: Stack(
        children: [
          // Soft romantic ambience — does not replace the purple bg theme.
          Positioned(
            top: -40,
            right: -30,
            child: _GlowOrb(
              size: 180,
              color: _MessagesUi.pink.withValues(alpha: 0.16),
            ),
          ),
          Positioned(
            top: 180,
            left: -60,
            child: _GlowOrb(
              size: 160,
              color: _MessagesUi.violet.withValues(alpha: 0.14),
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
                        color: kColorPrimary,
                        backgroundColor: kColorWhite,
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
                          color: _MessagesUi.pink.withValues(alpha: 0.35),
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
                        color: kColorWhite,
                      ),
                      SizedBox(height: 2),
                      AppText(
                        text: 'Good connections start with hello.',
                        fontSize: TextStyles.k10FontSize,
                        color: Color(0xCCFFFFFF),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        kColorProfileChipPinkStart,
                        kColorProfileChipPurpleStart,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: kColorWhite.withValues(alpha: 0.18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kColorProfileChipPinkStart.withValues(
                          alpha: 0.38,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    size: 20,
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
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kColorWhite.withValues(alpha: 0.14),
                  kColorWhite.withValues(alpha: 0.07),
                ],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: _MessagesUi.pinkSoft.withValues(alpha: 0.28),
              ),
              boxShadow: [
                BoxShadow(
                  color: _MessagesUi.pink.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
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
                hintText: 'Find your next hello',
                hintStyle: TextStyles.kRegularPoppins(
                  fontSize: TextStyles.k12FontSize,
                  colors: kColorWhite.withValues(alpha: 0.48),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: _MessagesUi.pinkSoft.withValues(alpha: 0.9),
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accent.withValues(alpha: 0.34),
                accent.withValues(alpha: 0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.28)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.22),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
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
                color: kColorWhite,
              ),
              AppText(
                text: subtitle,
                fontSize: TextStyles.k10FontSize,
                color: kColorWhite.withValues(alpha: 0.58),
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
                  accent.withValues(alpha: 0.30),
                  accent.withValues(alpha: 0.12),
                ],
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: AppText(
              text: '$count',
              fontSize: TextStyles.k10FontSize,
              color: kColorWhite.withValues(alpha: 0.92),
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
          child: CircularProgressIndicator(color: kColorWhite, strokeWidth: 2),
        ),
      );
    }

    final matches = controller.newMatches;
    if (matches.isEmpty) {
      return const SizedBox(
        height: 176,
        child: _InlineEmptyState(
          icon: Icons.favorite_border_rounded,
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
      return const SizedBox(height: 180, child: _MessagesEmptyState());
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
  const _InlineEmptyState({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kColorWhite.withValues(alpha: 0.10),
            kColorWhite.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _MessagesUi.pinkSoft.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _MessagesUi.pinkSoft, size: 18),
          Spacing.h8,
          Flexible(
            child: SemiBoldText(
              text: text,
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite,
              align: TextAlign.center,
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
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _MessagesUi.glass.withValues(alpha: 0.72),
              const Color(0xFF2A1740).withValues(alpha: 0.55),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.10)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    _MessagesUi.pink.withValues(alpha: 0.35),
                    _MessagesUi.violet.withValues(alpha: 0.22),
                  ],
                ),
                border: Border.all(
                  color: _MessagesUi.pinkSoft.withValues(alpha: 0.4),
                ),
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                color: kColorWhite,
                size: 30,
              ),
            ),
            Spacing.v12,
            const SemiBoldText(
              text: 'No chats yet',
              fontSize: TextStyles.k16FontSize,
              color: kColorWhite,
              align: TextAlign.center,
            ),
            Spacing.v6,
            AppText(
              text: 'Say hello to a spark above and start something fun.',
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite.withValues(alpha: 0.72),
              align: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
