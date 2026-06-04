import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/wallet/bindings/wallet_binding.dart';
import 'package:qobo_one_live/app/user_flow/wallet/views/wallet_view.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/vip_store_controller.dart';

class VipStoreView extends GetView<VipStoreController> {
  const VipStoreView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBarWidget(
        title: 'VIP Store',
        useMaterialAppBar: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(kColorPrimary),
            ),
          );
        }

        return Column(
          children: [
            _buildBalanceHeader(),
            _buildCategorySelector(),
            Expanded(
              child: _buildItemsList(),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildBalanceHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kColorPrimary, Color(0xFFC04B9F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kColorPrimary.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                text: 'Your Balance',
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite.withOpacity(0.8),
              ),
              Spacing.v4,
              Row(
                children: [
                  const Icon(
                    Icons.monetization_on_rounded,
                    color: Color(0xFFFFD700),
                    size: 24,
                  ),
                  Spacing.h6,
                  BoldText(
                    text: '${controller.userCoins.value} Coins',
                    fontSize: 22,
                    color: kColorWhite,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(
            height: 34,
            width: 90,
            child: appButton(
              onPressed: () => Get.to(() => const WalletView(), binding: WalletBinding()),
              buttonText: 'Recharge',
              buttonColor: kColorWhite,
              borderRadius: 18,
              buttonWidth: 90,
              textStyle: TextStyles.kBoldPoppins(
                fontSize: TextStyles.k12FontSize,
                colors: kColorPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    final categories = ['Entrances', 'Avatar Rings', 'Chat Bubbles'];
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => Spacing.h10,
        itemBuilder: (context, index) {
          final isSelected = controller.selectedCategory.value == index;
          return GestureDetector(
            onTap: () => controller.selectedCategory.value = index,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? kColorPrimary : kColorWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.transparent : kColorPrimary.withOpacity(0.3),
                ),
              ),
              child: SemiBoldText(
                text: categories[index],
                fontSize: TextStyles.k14FontSize,
                color: isSelected ? kColorWhite : kColorPrimary,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemsList() {
    List<Map<String, dynamic>> list;
    if (controller.selectedCategory.value == 0) {
      list = controller.entranceEffects;
    } else if (controller.selectedCategory.value == 1) {
      list = controller.avatarRings;
    } else {
      list = controller.chatBubbles;
    }

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_rounded, color: Colors.grey.shade400, size: 64),
            Spacing.v16,
            const SemiBoldText(text: 'Category is Empty', fontSize: 16, color: kColorText),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => Spacing.v12,
      itemBuilder: (context, index) {
        final item = list[index];
        final bool isOwned = item['isOwned'] ?? false;
        final int price = item['price'] ?? 0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kColorWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kColorBlack.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Styled Icon Preview
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: kColorPrimary.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: kColorPrimary.withOpacity(0.2), width: 1.5),
                ),
                child: Icon(
                  _getItemIcon(item['icon'] ?? ''),
                  color: kColorPrimary,
                  size: 28,
                ),
              ),
              Spacing.h16,
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: SemiBoldText(
                            text: item['title'] ?? '',
                            fontSize: TextStyles.k16FontSize,
                            color: kColorText,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Spacing.h8,
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getTagColor(item['tag'] ?? '').withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: AppText(
                            text: item['tag'] ?? '',
                            fontSize: 9,
                            color: _getTagColor(item['tag'] ?? ''),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    Spacing.v4,
                    AppText(
                      text: item['desc'] ?? '',
                      fontSize: TextStyles.k12FontSize,
                      color: kColorHint,
                    ),
                    Spacing.v8,
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, color: Colors.grey.shade400, size: 12),
                        Spacing.h4,
                        AppText(
                          text: 'Validity: ${item['duration']}',
                          fontSize: 11,
                          color: kColorHint,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Spacing.h12,
              // Buy Action Button
              SizedBox(
                height: 36,
                width: 90,
                child: appButton(
                  onPressed: () => controller.purchaseItem(index),
                  buttonText: isOwned ? 'Owned' : '$price Coins',
                  buttonColor: isOwned ? Colors.grey.shade200 : kColorPrimary,
                  buttonBorderColor: isOwned ? Colors.grey.shade300 : Colors.transparent,
                  borderRadius: 18,
                  buttonWidth: 90,
                  textStyle: TextStyles.kBoldPoppins(
                    fontSize: 11,
                    colors: isOwned ? Colors.grey.shade600 : kColorWhite,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getItemIcon(String name) {
    switch (name) {
      case 'sports_car_rounded':
        return Icons.directions_car_rounded;
      case 'wb_sunny_rounded':
        return Icons.wb_sunny_rounded;
      case 'electric_bolt_rounded':
        return Icons.bolt_rounded;
      case 'brightness_high_rounded':
        return Icons.brightness_high_rounded;
      case 'change_circle_rounded':
        return Icons.autorenew_rounded;
      case 'filter_vintage_rounded':
        return Icons.filter_vintage_rounded;
      case 'chat_bubble_rounded':
        return Icons.chat_bubble_rounded;
      case 'favorite_rounded':
        return Icons.favorite_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  Color _getTagColor(String tag) {
    switch (tag.toLowerCase()) {
      case 'mythic':
        return const Color(0xFFFF4E00);
      case 'legendary':
        return const Color(0xFFFFD700);
      case 'epic':
        return const Color(0xFF9C27B0);
      case 'rare':
        return const Color(0xFF00bcd4);
      default:
        return Colors.blue;
    }
  }
}
