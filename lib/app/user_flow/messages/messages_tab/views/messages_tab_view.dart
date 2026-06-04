import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/theme/app_theme_colors.dart';
import 'package:qobo_one_live/theme/theme_context.dart';
import 'package:qobo_one_live/utils/app_widgets/app_screen_background.dart';
import 'package:qobo_one_live/utils/app_widgets/app_search_field.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/messages_tab_controller.dart';
import '../widgets/messages_common_widgets.dart';

class MessagesTabView extends StatelessWidget {
  const MessagesTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final userSession = _resolveUserSession();
    final messagesController = _resolveController();
    const messages = <MessageListItemModel>[];

    return GetBuilder<MessagesTabController>(
      init: messagesController,
      builder: (messagesController) {
        final colors = context.appColors;
        return AppScreenBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _topHeader(colors, userSession),
                  Spacing.v16,
                  SemiBoldText(
                    text: 'New Match',
                    fontSize: TextStyles.k18FontSize,
                    color: colors.onHeroPrimary,
                  ),
                  Spacing.v12,
                  Obx(() => _newMatchRow(context, colors, messagesController)),
                  Spacing.v20,
                  SemiBoldText(
                    text: 'Message',
                    fontSize: TextStyles.k18FontSize,
                    color: colors.onHeroPrimary,
                  ),
                  Spacing.v8,
                  Expanded(
                    child: messages.isEmpty
                        ? const _MessagesEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: messages.length,
                            itemBuilder: (_, index) =>
                                MessageListTileItem(item: messages[index]),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _newMatchRow(
    BuildContext context,
    AppThemeColors colors,
    MessagesTabController messagesController,
  ) {
    if (messagesController.isNewMatchesLoading.value) {
      return SizedBox(
        height: 86,
        child: Center(
          child: CircularProgressIndicator(
            color: colors.chipSelected,
            strokeWidth: 2,
          ),
        ),
      );
    }

    final matches = messagesController.newMatches;
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
        itemBuilder: (_, index) => MessageMatchAvatarItem(user: matches[index]),
      ),
    );
  }

  Widget _topHeader(AppThemeColors colors, UserSessionController userSession) {
    return GetBuilder<UserSessionController>(
      init: userSession,
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
                border: Border.all(color: colors.onHeroPrimary, width: 1),
              ),
              child: ClipOval(
                child: avatarUrl == null
                    ? _initialsAvatar(session.initials)
                    : Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _initialsAvatar(session.initials),
                      ),
              ),
            ),
            Spacing.h10,
            Expanded(child: const AppSearchField()),
          ],
        );
      },
    );
  }

  Widget _initialsAvatar(String initials) {
    return ColoredBox(
      color: kColorAvatarFallbackBg,
      child: Center(
        child: SemiBoldText(
          text: initials,
          fontSize: TextStyles.k12FontSize,
          color: kColorWhite,
        ),
      ),
    );
  }

  UserSessionController _resolveUserSession() {
    if (Get.isRegistered<UserSessionController>()) {
      return Get.find<UserSessionController>();
    }
    return Get.put(UserSessionController(), permanent: true);
  }

  MessagesTabController _resolveController() {
    if (Get.isRegistered<MessagesTabController>()) {
      return Get.find<MessagesTabController>();
    }
    return Get.put(MessagesTabController());
  }
}

class _InlineEmptyState extends StatelessWidget {
  const _InlineEmptyState({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.isDark
            ? kColorWhite.withValues(alpha: 0.08)
            : colors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.isDark
              ? kColorWhite.withValues(alpha: 0.08)
              : colors.border,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: colors.onHeroMuted, size: 18),
          Spacing.h8,
          SemiBoldText(
            text: text,
            fontSize: TextStyles.k12FontSize,
            color: colors.onHeroSecondary,
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
    final colors = context.appColors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            color: colors.onHeroMuted,
            size: 54,
          ),
          Spacing.v12,
          SemiBoldText(
            text: 'No data found',
            fontSize: TextStyles.k16FontSize,
            color: colors.onHeroPrimary,
            align: TextAlign.center,
          ),
          Spacing.v6,
          AppText(
            text: 'Messages will appear here when available.',
            fontSize: TextStyles.k12FontSize,
            color: colors.onHeroMuted,
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
