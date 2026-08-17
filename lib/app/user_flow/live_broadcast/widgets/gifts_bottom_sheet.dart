import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/repo/economy/economy_api_utils.dart';
import 'package:qobo_one_live/utils/app_dialogs/common_app_dialog.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/live_broadcast_controller.dart';
import 'gift_icon_widget.dart';

class GiftsBottomSheet extends StatefulWidget {
  const GiftsBottomSheet({super.key});

  @override
  State<GiftsBottomSheet> createState() => _GiftsBottomSheetState();
}

class _GiftsBottomSheetState extends State<GiftsBottomSheet> {
  int _selectedTabIndex = 0;
  int _selectedGiftIndex = -1;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<LiveBroadcastController>();
    controller.loadGiftCatalog();
    controller.loadWalletBalance();
  }

  List<String> _tabs(LiveBroadcastController controller) {
    final categories = controller.giftCategories;
    return categories.isEmpty ? const ['Gifts'] : categories;
  }

  List<Map<String, String>> _visibleGifts(LiveBroadcastController controller) {
    final tabs = _tabs(controller);
    if (tabs.isEmpty) return const [];
    final tab = tabs[_selectedTabIndex.clamp(0, tabs.length - 1)];
    return controller.giftsForCategory(tab);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LiveBroadcastController>();

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
          Obx(() => _buildGiftScope(controller)),
          Spacing.v10,
          Obx(() => _buildTabBar(controller)),
          Spacing.v12,
          Expanded(
            child: Obx(() {
              if (controller.isLoadingGifts.value) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.pinkAccent),
                );
              }
              return _buildGiftsGrid(controller);
            }),
          ),
          Obx(() => _buildBottomBar(controller)),
        ],
      ),
    );
  }

  Widget _buildGiftScope(LiveBroadcastController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(
            controller.isRoomGiftMode.value
                ? Icons.groups_rounded
                : Icons.person_rounded,
            color: Colors.pinkAccent,
            size: 18,
          ),
          Spacing.h8,
          Expanded(
            child: AppText(
              text: controller.giftSheetDescription,
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(LiveBroadcastController controller) {
    final tabs = _tabs(controller);
    if (_selectedTabIndex >= tabs.length) {
      _selectedTabIndex = 0;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedTabIndex = index;
              _selectedGiftIndex = -1;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.pinkAccent.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.pinkAccent : Colors.transparent,
                ),
              ),
              child: SemiBoldText(
                text: tabs[index],
                fontSize: TextStyles.k14FontSize,
                color: isSelected ? kColorWhite : kColorHint,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGiftsGrid(LiveBroadcastController controller) {
    final gifts = _visibleGifts(controller);
    if (gifts.isEmpty) {
      return Center(
        child: AppText(
          text: controller.giftCatalog.isEmpty
              ? 'No gifts available right now.'
              : 'No gifts in this category.',
          fontSize: TextStyles.k14FontSize,
          color: kColorHint,
          align: TextAlign.center,
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemCount: gifts.length,
      itemBuilder: (context, index) {
        final gift = gifts[index];
        final isSelected = _selectedGiftIndex == index;
        final price = gift['price'] ?? '0';

        return GestureDetector(
          onTap: () => setState(() => _selectedGiftIndex = index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.pinkAccent.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.pinkAccent : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GiftIconWidget(icon: gift['icon']),
                const SizedBox(height: 4),
                AppText(
                  text: gift['name'] ?? 'Gift',
                  fontSize: TextStyles.k10FontSize,
                  color: kColorWhite,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  align: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.diamond_outlined,
                      color: Colors.orange,
                      size: 10,
                    ),
                    Spacing.h2,
                    Flexible(
                      child: AppText(
                        text: price,
                        fontSize: 10,
                        color: kColorHint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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

  Widget _buildBottomBar(LiveBroadcastController controller) {
    final gifts = _visibleGifts(controller);
    final canSend =
        _selectedGiftIndex >= 0 && _selectedGiftIndex < gifts.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2D),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.diamond_outlined, color: Colors.orange, size: 16),
          Spacing.h6,
          SemiBoldText(
            text: formatLedgerAmount(controller.coinsBalance.value),
            fontSize: TextStyles.k14FontSize,
            color: kColorWhite,
          ),
          const Icon(Icons.chevron_right_rounded, color: kColorHint, size: 16),
          const Spacer(),
          SizedBox(
            width: 100,
            height: 38,
            child: appButton(
              onPressed: () async {
                if (!canSend) return;
                final combo = await CommonAppDialog.giftCombo();
                if (!mounted || combo == null) return;
                await controller.sendGift(
                  gifts[_selectedGiftIndex],
                  comboCount: combo,
                );
              },
              buttonText: 'Send',
              buttonColor: canSend ? Colors.pinkAccent : kColorHint,
              borderRadius: 20,
            ),
          ),
        ],
      ),
    );
  }
}
