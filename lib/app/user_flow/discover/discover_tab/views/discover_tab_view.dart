import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/discover_tab_controller.dart';
import '../widgets/discover_country_filter_sheet.dart';
import '../widgets/discover_users_feed.dart';

class DiscoverTabView extends StatelessWidget {
  const DiscoverTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final discoverController = _resolveController();

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage(kImgBG), fit: BoxFit.cover),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topHeader(context, discoverController),
              Spacing.v12,
              Expanded(
                child: Obx(() {
                  if (discoverController.searchQuery.value.isNotEmpty) {
                    return _searchResultsList(context, discoverController);
                  }
                  return DiscoverUsersFeed(controller: discoverController);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topHeader(
    BuildContext context,
    DiscoverTabController discoverController,
  ) {
    final userSession = _resolveUserSession();
    return Obx(() {
      if (discoverController.isSearchExpanded.value) {
        return _expandedSearchBar(discoverController);
      }

      return GetBuilder<UserSessionController>(
        init: userSession,
        builder: (session) {
          final avatarUrl = session.displayPictureUrl;
          return SizedBox(
            height: 58,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 38,
                    height: 38,
                    padding: const EdgeInsets.all(1.4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kColorWhite.withValues(alpha: 0.10),
                      border: Border.all(
                        color: kColorWhite.withValues(alpha: 0.78),
                        width: 1.2,
                      ),
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
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SemiBoldText(
                      text: 'EXPLORE',
                      fontSize: TextStyles.k24FontSize,
                      color: kColorWhite,
                    ),
                    AppText(
                      text: session.displayName,
                      fontSize: TextStyles.k12FontSize,
                      color: kColorWhite.withValues(alpha: 0.72),
                      align: TextAlign.center,
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _headerIconButton(
                        onTap: discoverController.openSearch,
                        icon: const Icon(
                          Icons.search_rounded,
                          size: 21,
                          color: kColorPrimary,
                        ),
                      ),
                      Spacing.h6,
                      Obx(() {
                        final hasFilter =
                            discoverController.hasActiveDiscoverFilters;
                        return _headerIconButton(
                          onTap: () => _openCountryFilter(
                            context,
                            discoverController,
                          ),
                          icon: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              SvgPicture.asset(
                                kIconFilter,
                                width: 21,
                                height: 21,
                                colorFilter: const ColorFilter.mode(
                                  kColorPrimary,
                                  BlendMode.srcIn,
                                ),
                              ),
                              if (hasFilter)
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: kColorBottomNavHeart,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _headerIconButton({
    required VoidCallback onTap,
    required Widget icon,
  }) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: kColorWhite.withValues(alpha: 0.94),
            boxShadow: [
              BoxShadow(
                color: kColorPrimary.withValues(alpha: 0.20),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(child: icon),
        ),
      ),
    );
  }

  Widget _expandedSearchBar(DiscoverTabController discoverController) {
    return Row(
      children: [
        Material(
          color: kColorWhite.withValues(alpha: 0.14),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: discoverController.closeSearch,
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: kColorWhite,
                size: 18,
              ),
            ),
          ),
        ),
        Spacing.h10,
        Expanded(
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: kColorWhite.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: kColorWhite.withValues(alpha: 0.26)),
                boxShadow: [
                  BoxShadow(
                    color: kColorPrimary.withValues(alpha: 0.16),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 22,
                    color: kColorHint.withValues(alpha: 0.85),
                  ),
                  Spacing.h10,
                  Expanded(
                    child: TextField(
                      controller: discoverController.searchController,
                      focusNode: discoverController.searchFocusNode,
                      textInputAction: TextInputAction.search,
                      style: TextStyles.kRegularPoppins(
                        fontSize: TextStyles.k14FontSize,
                        colors: kColorText,
                      ),
                      cursorColor: kColorPrimary,
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Search people',
                        hintStyle: TextStyles.kRegularPoppins(
                          fontSize: TextStyles.k14FontSize,
                          colors: kColorHint,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  Obx(() {
                    if (discoverController.searchQuery.value.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return GestureDetector(
                      onTap: discoverController.searchController.clear,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: kColorHint.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: kColorHint,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openCountryFilter(
    BuildContext context,
    DiscoverTabController controller,
  ) async {
    final result = await showDiscoverFilterSheet(
      context: context,
      initial: controller.filters.value,
    );
    if (result == null) return;
    await controller.applyDiscoverFilters(result);
  }

  UserSessionController _resolveUserSession() {
    if (Get.isRegistered<UserSessionController>()) {
      return Get.find<UserSessionController>();
    }
    return Get.put(UserSessionController(), permanent: true);
  }

  DiscoverTabController _resolveController() {
    if (Get.isRegistered<DiscoverTabController>()) {
      return Get.find<DiscoverTabController>();
    }
    return Get.put(DiscoverTabController());
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

  Widget _searchResultsList(
    BuildContext context,
    DiscoverTabController controller,
  ) {
    if (controller.isSearchLoading.value) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(kColorPrimary),
        ),
      );
    }

    if (controller.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              color: kColorWhite.withValues(alpha: 0.5),
              size: 48,
            ),
            Spacing.v12,
            AppText(
              text: 'No users found matching "${controller.searchQuery.value}"',
              fontSize: TextStyles.k14FontSize,
              color: kColorWhite.withValues(alpha: 0.7),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24, top: 8),
      itemCount: controller.searchResults.length,
      separatorBuilder: (_, __) =>
          const Divider(color: kColorDiscoverSearchBg, height: 1),
      itemBuilder: (context, index) {
        final user = controller.searchResults[index];
        final String name = user['name']?.toString() ?? 'User';
        final String id = user['id']?.toString() ?? '';

        final isFollowing =
            user['isFollowing'] == true ||
            controller.followingUserIds.contains(id);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              AppUserAvatar(
                name: name,
                imageUrl: user['displayPicture']?.toString(),
                size: 44,
                border: Border.all(
                  color: kColorWhite.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              Spacing.h12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemiBoldText(
                      text: name,
                      fontSize: TextStyles.k16FontSize,
                      color: kColorWhite,
                    ),
                    Spacing.v2,
                    AppText(
                      text: 'ID: ${id.length > 8 ? id.substring(0, 8) : id}',
                      fontSize: TextStyles.k12FontSize,
                      color: kColorWhite.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => controller.toggleFollow(context, id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: isFollowing
                        ? null
                        : LinearGradient(
                            colors: [
                              kColorProfileActionPinkStart,
                              kColorProfileActionOrangeEnd,
                            ],
                          ),
                    color: isFollowing ? Colors.transparent : null,
                    borderRadius: BorderRadius.circular(20),
                    border: isFollowing
                        ? Border.all(
                            color: kColorWhite.withValues(alpha: 0.5),
                            width: 1,
                          )
                        : null,
                  ),
                  child: SemiBoldText(
                    text: isFollowing ? 'Following' : 'Follow',
                    fontSize: TextStyles.k12FontSize,
                    color: kColorWhite,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
