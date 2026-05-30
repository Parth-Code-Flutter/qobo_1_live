import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:get/get.dart';

import '../widgets/messages_common_widgets.dart';

class MessagesTabView extends StatelessWidget {
  const MessagesTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final userSession = _resolveUserSession();
    const matches = <MessageMatchUser>[];
    const messages = <MessageListItemModel>[];

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage(kImgBG), fit: BoxFit.cover),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topHeader(userSession),
              Spacing.v16,
              const SemiBoldText(
                text: 'New Match',
                fontSize: TextStyles.k18FontSize,
                color: kColorWhite,
              ),
              Spacing.v12,
              SizedBox(
                height: 86,
                child: matches.isEmpty
                    ? const _InlineEmptyState(
                        icon: Icons.favorite_border_rounded,
                        text: 'No data found',
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: matches.length,
                        separatorBuilder: (_, __) => Spacing.h10,
                        itemBuilder: (_, index) =>
                            MessageMatchAvatarItem(user: matches[index]),
                      ),
              ),
              Spacing.v20,
              const SemiBoldText(
                text: 'Message',
                fontSize: TextStyles.k18FontSize,
                color: kColorWhite,
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
  }

  /// Top row with profile image (left) and search field below, matching target UI.
  Widget _topHeader(UserSessionController userSession) {
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
                border: Border.all(color: kColorWhite, width: 1),
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
            Expanded(child: _searchBar()),
          ],
        );
      },
    );
  }

  /// Light search container with icon + placeholder.
  Widget _searchBar() {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: kColorDiscoverSearchBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        textInputAction: TextInputAction.search,
        style: TextStyles.kRegularPoppins(
          fontSize: TextStyles.k12FontSize,
          colors: kColorText,
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: 'Search',
          hintStyle: TextStyles.kRegularPoppins(
            fontSize: TextStyles.k12FontSize,
            colors: kColorHint,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: const Icon(
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
            text: 'No data found',
            fontSize: TextStyles.k16FontSize,
            color: kColorWhite,
            align: TextAlign.center,
          ),
          Spacing.v6,
          AppText(
            text: 'Messages will appear here when available.',
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite.withValues(alpha: 0.72),
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
