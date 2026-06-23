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
import 'package:qobo_one_live/utils/ui_utils/app_ui_utils.dart';

import '../controllers/discover_tab_controller.dart';
import '../widgets/discover_country_filter_sheet.dart';
import '../widgets/discover_filters_bar.dart';
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
              Spacing.v16,
              _searchBar(discoverController),
              Spacing.v10,
              Obx(() {
                if (discoverController.searchQuery.value.isNotEmpty) {
                  return const SizedBox.shrink();
                }
                return DiscoverFiltersBar(controller: discoverController);
              }),
              Spacing.v8,
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

  /// Header row (real profile image/name + location) matching Figma.
  Widget _topHeader(
    BuildContext context,
    DiscoverTabController discoverController,
  ) {
    final userSession = _resolveUserSession();
    return GetBuilder<UserSessionController>(
      init: userSession,
      builder: (session) {
        final avatarUrl = session.displayPictureUrl;
        return Row(
          children: [
            Container(
              width: 30,
              height: 30,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SemiBoldText(
                    text: 'EXPLORE',
                    fontSize: TextStyles.k24FontSize - 2,
                    color: kColorWhite,
                  ),
                  AppText(
                    text: session.displayName,
                    fontSize: TextStyles.k10FontSize,
                    color: kColorWhite.withValues(alpha: 0.9),
                    align: TextAlign.center,
                  ),
                ],
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: kColorWhite,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Center(
                child: Obx(() {
                  final hasFilter = discoverController.hasActiveDiscoverFilters;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        onPressed: () => _openCountryFilter(
                          context,
                          discoverController,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 30,
                          minHeight: 30,
                        ),
                        icon: SvgPicture.asset(
                          kIconFilter,
                          width: 20,
                          height: 20,
                          colorFilter: const ColorFilter.mode(
                            kColorPrimary,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      if (hasFilter)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: kColorBottomNavHeart,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ],
        );
      },
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

  Widget _searchBar(DiscoverTabController discoverController) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: kColorDiscoverSearchBg,
        borderRadius: AppUIUtils.primaryBorderRadius,
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 16, color: kColorHint),
          Spacing.h6,
          Expanded(
            child: TextField(
              controller: discoverController.searchController,
              textInputAction: TextInputAction.search,
              style: TextStyles.kRegularPoppins(
                fontSize: TextStyles.k12FontSize,
                colors: kColorText,
              ),
              cursorColor: kColorPrimary,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search',
                hintStyle: TextStyles.kRegularPoppins(
                  fontSize: TextStyles.k12FontSize,
                  colors: kColorHint,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
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

        final isFollowing = user['isFollowing'] == true ||
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
