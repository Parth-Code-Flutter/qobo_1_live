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
    final matches = _demoMatches;
    final messages = _demoMessages;

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
                child: ListView.separated(
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
                child: ListView.builder(
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

/// Static mock list for Figma-matching "new match" avatars.
const List<MessageMatchUser> _demoMatches = [
  MessageMatchUser(name: 'You', imagePath: kImgTemp2, hasStoryRing: true),
  MessageMatchUser(name: 'Emma', imagePath: kImgTemp3, hasStoryRing: true),
  MessageMatchUser(name: 'Ava', imagePath: kImgTemp4),
  MessageMatchUser(name: 'Sophia', imagePath: kImgTemp5),
  MessageMatchUser(name: 'Amelia', imagePath: kImgTemp1, hasStoryRing: true),
];

/// Static mock list for message preview rows.
const List<MessageListItemModel> _demoMessages = [
  MessageListItemModel(
    name: 'Afrin Sabila',
    message: 'Life is beautiful 👌',
    time: '23 min',
    imagePath: kImgTemp1,
    unreadCount: 1,
  ),
  MessageListItemModel(
    name: 'Adil Adnan',
    message: 'Be your own hero 💪',
    time: '27 min',
    imagePath: kImgTemp2,
    unreadCount: 2,
  ),
  MessageListItemModel(
    name: 'Bristy Haque',
    message: 'Keep working 💪',
    time: '50 min',
    imagePath: kImgTemp3,
  ),
  MessageListItemModel(
    name: 'John Borino',
    message: 'Make yourself proud 😍',
    time: '33 min',
    imagePath: kImgTemp4,
  ),
  MessageListItemModel(
    name: 'Borsha Akther',
    message: 'Flowers are beautiful 🌸',
    time: '33 min',
    imagePath: kImgTemp5,
  ),
  MessageListItemModel(
    name: 'sheik Sadi',
    message: 'Life is beautiful 👌',
    time: '33 min',
    imagePath: kImgTemp1,
  ),
  MessageListItemModel(
    name: 'Bristy Haque',
    message: 'Keep working 💪',
    time: '33 min',
    imagePath: kImgTemp3,
  ),
  MessageListItemModel(
    name: 'John Borino',
    message: 'Make yourself proud 😍',
    time: '33 min',
    imagePath: kImgTemp4,
  ),
];
