import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/user_basic_profile_controller.dart';

/// Edit-cover picker: owned profile backgrounds + shop purchases.
class ProfileCoverBackgroundSheet
    extends GetView<UserBasicProfileController> {
  const ProfileCoverBackgroundSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.72;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Color(0xFF161022),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
          const SemiBoldText(
            text: 'Edit cover',
            fontSize: TextStyles.k18FontSize,
            color: kColorWhite,
          ),
          Spacing.v4,
          AppText(
            text: 'Use a purchased background or buy a new one',
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite.withValues(alpha: 0.62),
          ),
          Spacing.v16,
          _tabs(),
          Spacing.v12,
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _tabs() {
    return Obx(() {
      final tab = controller.coverBackgroundTab.value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: _tabChip(
                label: 'Purchased',
                selected: tab == 0,
                onTap: () => controller.coverBackgroundTab.value = 0,
              ),
            ),
            Spacing.h10,
            Expanded(
              child: _tabChip(
                label: 'Shop',
                selected: tab == 1,
                onTap: () => controller.coverBackgroundTab.value = 1,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _tabChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? kColorPrimary : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? kColorPrimary
                  : Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: SemiBoldText(
            text: label,
            fontSize: TextStyles.k14FontSize,
            color: kColorWhite,
          ),
        ),
      ),
    );
  }

  Widget _body() {
    return Obx(() {
      if (controller.isLoadingCoverBackgrounds.value &&
          controller.purchasedCoverBackgrounds.isEmpty &&
          controller.shopCoverBackgrounds.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: kColorPrimary),
        );
      }

      final isPurchasedTab = controller.coverBackgroundTab.value == 0;
      final items = isPurchasedTab
          ? controller.purchasedCoverBackgrounds
          : controller.shopCoverBackgrounds;

      if (items.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: AppText(
              text: isPurchasedTab
                  ? 'No purchased backgrounds yet. Open Shop to buy one.'
                  : 'No backgrounds available in the shop right now.',
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite.withValues(alpha: 0.7),
              align: TextAlign.center,
            ),
          ),
        );
      }

      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _CoverBackgroundCard(
            item: item,
            isShop: !isPurchasedTab,
            busy: controller.isApplyingCoverBackground.value,
            onTap: () {
              if (controller.isApplyingCoverBackground.value) return;
              if (isPurchasedTab) {
                controller.applyPurchasedCoverBackground(item);
              } else {
                controller.purchaseCoverBackground(item);
              }
            },
          );
        },
      );
    });
  }
}

class _CoverBackgroundCard extends StatelessWidget {
  const _CoverBackgroundCard({
    required this.item,
    required this.isShop,
    required this.busy,
    required this.onTap,
  });

  final Map<String, dynamic> item;
  final bool isShop;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = item['name']?.toString() ?? 'Background';
    final imageUrl = item['imageUrl']?.toString() ?? '';
    final meta = item['duration']?.toString() ?? '';
    final category = item['category']?.toString() ?? '';
    final isEquipped = item['isEquipped'] == true;
    final price = item['price'] is int
        ? item['price'] as int
        : int.tryParse(item['price']?.toString() ?? '') ?? 0;

    final cta = isShop
        ? (price > 0 ? '$price Coins' : 'Buy')
        : (isEquipped ? 'Equipped' : 'Use cover');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF221833),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isEquipped
                  ? kColorPrimary
                  : Colors.white.withValues(alpha: 0.08),
              width: isEquipped ? 1.6 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: imageUrl.isEmpty
                    ? ColoredBox(
                        color: kColorPrimary.withValues(alpha: 0.2),
                        child: const Icon(
                          Icons.image_outlined,
                          color: kColorWhite,
                        ),
                      )
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => ColoredBox(
                          color: kColorPrimary.withValues(alpha: 0.2),
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: kColorWhite,
                          ),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemiBoldText(
                      text: name,
                      fontSize: TextStyles.k12FontSize,
                      color: kColorWhite,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (category.isNotEmpty || meta.isNotEmpty) ...[
                      Spacing.v4,
                      AppText(
                        text: [
                          if (category.isNotEmpty) category,
                          if (meta.isNotEmpty) meta,
                        ].join(' · '),
                        fontSize: TextStyles.k10FontSize,
                        color: kColorWhite.withValues(alpha: 0.62),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    Spacing.v10,
                    Container(
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isEquipped
                            ? kColorPrimary
                            : isShop
                            ? Colors.white.withValues(alpha: 0.08)
                            : kColorPrimary.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12),
                        border: isShop && !isEquipped
                            ? Border.all(
                                color: kColorPrimary.withValues(alpha: 0.55),
                              )
                            : null,
                      ),
                      child: SemiBoldText(
                        text: cta,
                        fontSize: TextStyles.k12FontSize,
                        color: kColorWhite,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
