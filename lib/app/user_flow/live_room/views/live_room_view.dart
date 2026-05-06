import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/generated/locales.g.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/live_room_controller.dart';
import '../widgets/common_live_room_widget.dart';

class LiveRoomView extends GetView<LiveRoomController> {
  const LiveRoomView({super.key});

  @override
  Widget build(BuildContext context) {
    final rooms = <Map<String, dynamic>>[
      {
        'nameAge': 'Mariana, 25',
        'badge': 'Premier',
        'location': 'Roha',
        'points': '2105',
        'favorite': false,
        'image':
            'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=600',
      },
      {
        'nameAge': 'Mariana, 25',
        'badge': 'Premier',
        'location': 'Roha',
        'points': '2105',
        'favorite': true,
        'image':
            'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=600',
      },
      {
        'nameAge': 'Mariana, 25',
        'badge': 'Hourly',
        'location': 'Roha',
        'points': '2105',
        'favorite': false,
        'image':
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=600',
      },
      {
        'nameAge': 'Mariana, 25',
        'badge': 'Supreme',
        'location': 'Roha',
        'points': '2105',
        'favorite': false,
        'image':
            'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=600',
      },
    ];
    final categories = <String>[
      LocaleKeys.liveRoomTabSab.tr,
      LocaleKeys.liveRoomTabShresth.tr,
      LocaleKeys.liveRoomTabNaya.tr,
      LocaleKeys.liveRoomTabBangladesh.tr,
    ];

    return GetBuilder<LiveRoomController>(
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            image: DecorationImage(image: AssetImage(kImgBG), fit: BoxFit.cover),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Column(
                    children: [
                      _topHeader(),
                      Spacing.v12,
                      _filterAndCategoryRow(categories),
                      Spacing.v12,
                      _topBanner(),
                      Spacing.v12,
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 40),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: rooms.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.8,
                      ),
                      itemBuilder: (context, index) {
                        final room = rooms[index];
                        return CommonLiveRoomWidget(
                          imageUrl: room['image'] as String,
                          userNameAge: room['nameAge'] as String,
                          badgeText: room['badge'] as String,
                          locationText: room['location'] as String,
                          pointsText: room['points'] as String,
                          isFavorite: room['favorite'] as bool,
                        );
                      },
                    ),
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
  Widget _topBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 3.2,
        child: Image.network(
          'https://images.unsplash.com/photo-1513151233558-d860c5398176?w=1400',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0x66351B6C),
            alignment: Alignment.center,
            child: SemiBoldText(
              text: 'Celebration Banner',
              fontSize: TextStyles.k14FontSize,
              color: kColorWhite,
            ),
          ),
        ),
      ),
    );
  }

  Widget _topHeader() {
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
          child: const CircleAvatar(
            backgroundImage: NetworkImage(
              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
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
                text: LocaleKeys.liveRoomHostName.tr,
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite,
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
            child: SvgPicture.asset(
              kIconSearch,
              width: 18,
              height: 18,
              colorFilter: const ColorFilter.mode(kColorPrimary, BlendMode.srcIn),
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterAndCategoryRow(List<String> categories) {
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
                  padding: EdgeInsets.only(right: index == categories.length - 1 ? 0 : 10),
                  child: _categoryChip(
                    label: categories[index],
                    isSelected: controller.selectedCategoryIndex == index,
                    onTap: () {
                      // Keep this UI-only for now; filtering behavior can be added later.
                      controller.onCategorySelected(index);
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
}
