import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/generated/locales.g.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/safe_network_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/live_room_controller.dart';
import '../widgets/common_live_room_widget.dart';

class LiveRoomView extends StatelessWidget {
  const LiveRoomView({super.key});

  @override
  Widget build(BuildContext context) {
    final liveRoomController = _resolveController();
    final userSession = _resolveUserSession();
    final categories = <String>[
      LocaleKeys.liveRoomTabSab.tr,
      LocaleKeys.liveRoomTabShresth.tr,
      LocaleKeys.liveRoomTabNaya.tr,
      LocaleKeys.liveRoomTabBangladesh.tr,
    ];

    return GetBuilder<LiveRoomController>(
      init: liveRoomController,
      builder: (controller) {
        return Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(kImgBG),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Column(
                    children: [
                      _topHeader(userSession),
                      Spacing.v12,
                      _filterAndCategoryRow(categories),
                      Spacing.v12,
                      _topBanner(controller),
                      Spacing.v12,
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 40),
                    child: Obx(() {
                      if (controller.isLoading.value) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: kColorPrimary,
                          ),
                        );
                      }
                      if (controller.rooms.isEmpty) {
                        return const Center(
                          child: AppText(
                            text: 'No active rooms found',
                            color: kColorWhite,
                            fontSize: 16,
                          ),
                        );
                      }
                      return GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: controller.rooms.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.8,
                            ),
                        itemBuilder: (context, index) {
                          final room = controller.rooms[index];
                          return GestureDetector(
                            onTap: () {
                              Get.toNamed(
                                '/live-broadcast',
                                arguments: {
                                  'isHost': false,
                                  'roomType': room['roomType'] == 'AUDIO'
                                      ? 'AUDIO'
                                      : 'VIDEO',
                                  'roomData': room['roomData'],
                                },
                              );
                            },
                            child: CommonLiveRoomWidget(
                              imageUrl: room['image'] as String,
                              userNameAge: room['nameAge'] as String,
                              badgeText: room['badge'] as String,
                              locationText: room['location'] as String,
                              pointsText: room['points'] as String,
                              isFavorite: room['favorite'] as bool,
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Promo banner shown above the live-room listing.
  Widget _topBanner(LiveRoomController controller) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 3.2,
        child: Obx(() {
          final bannerUrl = controller.promoBannerImageUrl.value;
          if (bannerUrl != null && bannerUrl.isNotEmpty) {
            return Image.network(
              bannerUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _bannerFallback(),
            );
          }
          return Image.asset(
            kImgTemp1,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _bannerFallback(),
          );
        }),
      ),
    );
  }

  Widget _bannerFallback() {
    return Container(
      color: const Color(0x66351B6C),
      alignment: Alignment.center,
      child: const SemiBoldText(
        text: 'Celebration Banner',
        fontSize: TextStyles.k14FontSize,
        color: kColorWhite,
      ),
    );
  }

  Widget _topHeader(UserSessionController userSession) {
    return GetBuilder<UserSessionController>(
      init: userSession,
      builder: (session) {
        final avatarUrl = session.displayPictureUrl;
        return Row(
          children: [
            Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: kColorWhite,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xB3FFFFFF), width: 1),
              ),
              child: ClipOval(
                child: SafeNetworkAvatar(
                  url: avatarUrl,
                  size: 40,
                  fallback: _initialsAvatar(session.initials),
                ),
              ),
            ),
            Spacing.h10,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    text: LocaleKeys.liveRoomWelcome.tr,
                    fontSize: TextStyles.k14FontSize,
                    color: kColorWhite,
                  ),
                  SemiBoldText(
                    text: session.displayName,
                    fontSize: TextStyles.k14FontSize,
                    color: kColorWhite,
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: kColorWhite,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(22),
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: Center(
                        child: SvgPicture.asset(
                          kIconSearch,
                          width: 18,
                          height: 18,
                          colorFilter: const ColorFilter.mode(
                            kColorPrimary,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Spacing.h8,

                InkWell(
                  onTap: () => Get.toNamed(Routes.LEADER_BOARD),
                  borderRadius: BorderRadius.circular(22),
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: Center(
                      child: SvgPicture.asset(
                        kIconLeaderboard,
                        // width: 18,
                        // height: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _filterAndCategoryRow(List<String> categories) {
    final liveRoomController = _resolveController();
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: kColorWhite,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: SvgPicture.asset(
              kIconFilter,
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                kColorPrimary,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        Spacing.h10,
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(categories.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == categories.length - 1 ? 0 : 10,
                  ),
                  child: _categoryChip(
                    label: categories[index],
                    isSelected:
                        liveRoomController.selectedCategoryIndex == index,
                    onTap: () {
                      // Keep this UI-only for now; filtering behavior can be added later.
                      liveRoomController.onCategorySelected(index);
                    },
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _categoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    kColorLiveFilterChipGradientStart,
                    kColorLiveFilterChipGradientMid,
                    kColorLiveFilterChipGradientEnd,
                  ],
                )
              : null,
          border: Border.all(
            color: isSelected ? kColorLiveFilterChipBorder : Colors.transparent,
            width: 1,
          ),
        ),
        child: SemiBoldText(
          text: label,
          fontSize: TextStyles.k14FontSize,
          color: isSelected ? kColorWhite : kColorHint,
        ),
      ),
    );
  }

  LiveRoomController _resolveController() {
    if (Get.isRegistered<LiveRoomController>()) {
      return Get.find<LiveRoomController>();
    }
    // Defensive fallback: prevents intermittent null lookup crashes.
    return Get.put(LiveRoomController());
  }

  UserSessionController _resolveUserSession() {
    if (Get.isRegistered<UserSessionController>()) {
      return Get.find<UserSessionController>();
    }
    return Get.put(UserSessionController(), permanent: true);
  }

  Widget _initialsAvatar(String initials) {
    return ColoredBox(
      color: const Color(0xFF2A2A2A),
      child: Center(
        child: SemiBoldText(
          text: initials,
          fontSize: TextStyles.k14FontSize,
          color: kColorWhite,
        ),
      ),
    );
  }
}
