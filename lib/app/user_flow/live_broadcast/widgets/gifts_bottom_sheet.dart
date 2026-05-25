import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import '../controllers/live_broadcast_controller.dart';

class GiftsBottomSheet extends StatefulWidget {
  const GiftsBottomSheet({super.key});

  @override
  State<GiftsBottomSheet> createState() => _GiftsBottomSheetState();
}

class _GiftsBottomSheetState extends State<GiftsBottomSheet> {
  int _selectedTabIndex = 0;
  int _selectedGiftIndex = -1;

  final _tabs = ['Popular', 'Exclusive', 'Events', 'Backpack'];

  final _gifts = [
    {'name': 'Rose', 'price': '10', 'icon': '🌹'},
    {'name': 'Diamond', 'price': '99', 'icon': '💎'},
    {'name': 'Ring', 'price': '299', 'icon': '💍'},
    {'name': 'Crown', 'price': '999', 'icon': '👑'},
    {'name': 'Castle', 'price': '5000', 'icon': '🏰'},
    {'name': 'Rocket', 'price': '10000', 'icon': '🚀'},
    {'name': 'Unicorn', 'price': '2500', 'icon': '🦄'},
    {'name': 'Fireworks', 'price': '500', 'icon': '🎆'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.48,
      decoration: const BoxDecoration(
        color: Color(0xFF161622),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Spacing.v12,
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Spacing.v16,
          _buildTabBar(),
          Spacing.v12,
          Expanded(
            child: _buildGiftsGrid(),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.pinkAccent.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.pinkAccent : Colors.transparent,
                ),
              ),
              child: SemiBoldText(
                text: _tabs[index],
                fontSize: TextStyles.k14FontSize,
                color: isSelected ? kColorWhite : kColorHint,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGiftsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: _gifts.length,
      itemBuilder: (context, index) {
        final gift = _gifts[index];
        final isSelected = _selectedGiftIndex == index;
        return GestureDetector(
          onTap: () => setState(() => _selectedGiftIndex = index),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.pinkAccent.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.pinkAccent : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(gift['icon']!, style: const TextStyle(fontSize: 32)),
                Spacing.v4,
                AppText(
                  text: gift['name']!,
                  fontSize: TextStyles.k10FontSize,
                  color: kColorWhite,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Spacing.v2,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.diamond_outlined, color: Colors.orange, size: 10),
                    Spacing.h4,
                    AppText(
                      text: gift['price']!,
                      fontSize: 10,
                      color: kColorHint,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    final controller = Get.find<LiveBroadcastController>();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2D),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          Row(
            children: [
              const Icon(Icons.diamond_outlined, color: Colors.orange, size: 16),
              Spacing.h6,
              Obx(() => SemiBoldText(
                    text: controller.coinsBalance.value.toString(),
                    fontSize: TextStyles.k14FontSize,
                    color: kColorWhite,
                  )),
              const Icon(Icons.chevron_right_rounded, color: kColorHint, size: 16),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 100,
            height: 38,
            child: appButton(
              onPressed: () {
                if (_selectedGiftIndex == -1) return;
                controller.sendGift(_gifts[_selectedGiftIndex]);
              },
              buttonText: 'Send',
              buttonColor: _selectedGiftIndex != -1 ? Colors.pinkAccent : kColorHint,
              borderRadius: 20,
            ),
          ),
        ],
      ),
    );
  }
}
