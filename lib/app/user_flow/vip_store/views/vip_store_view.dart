import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/wallet/bindings/wallet_binding.dart';
import 'package:qobo_one_live/app/user_flow/wallet/views/wallet_view.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/app_widgets/glossy_dating_card.dart';
import 'package:qobo_one_live/utils/app_widgets/network_svga_widget.dart';
import 'package:qobo_one_live/utils/app_widgets/profile_background_media.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/vip_store_controller.dart';

/// VIP Frames shop — light dating canvas + glossy cards.
class VipStoreView extends GetView<VipStoreController> {
  const VipStoreView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppLightUi.bg,
      appBar: const CommonAppBarWidget(title: 'VIP Frames'),
      body: Obx(() {
        if (controller.isLoading.value && controller.vipFrames.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppLightUi.pink),
          );
        }

        return RefreshIndicator(
          color: AppLightUi.pink,
          backgroundColor: AppLightUi.card,
          onRefresh: controller.loadStore,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: _balanceCard()),
              SliverToBoxAdapter(child: _sectionHeader()),
              if (controller.loadError.value.isNotEmpty &&
                  controller.vipFrames.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _errorState(),
                )
              else if (controller.vipFrames.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _emptyState(),
                )
              else
                _framesGrid(),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
            ],
          ),
        );
      }),
    );
  }

  Widget _balanceCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: AppLightUi.familyCtaGradient,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppText(
              text: 'Your Balance',
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite.withValues(alpha: 0.85),
            ),
            Spacing.v10,
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: kColorWhite.withValues(alpha: 0.18),
                    border: Border.all(
                      color: kColorWhite.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Icon(
                    Icons.monetization_on_rounded,
                    color: Color(0xFFFFD84E),
                    size: 24,
                  ),
                ),
                Spacing.h10,
                Expanded(
                  child: Obx(
                    () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BoldText(
                          text: controller.formattedCoins,
                          fontSize: TextStyles.k22FontSize,
                          color: kColorWhite,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        AppText(
                          text: 'Coins',
                          fontSize: TextStyles.k12FontSize,
                          color: kColorWhite.withValues(alpha: 0.85),
                        ),
                      ],
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Get.to(
                      () => const WalletView(),
                      binding: WalletBinding(),
                    ),
                    borderRadius: BorderRadius.circular(18),
                    child: Ink(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: kColorWhite,
                      ),
                      child: const Center(
                        child: SemiBoldText(
                          text: 'Recharge',
                          fontSize: TextStyles.k12FontSize,
                          color: AppLightUi.title,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Spacing.v12,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: kColorWhite.withValues(alpha: 0.16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: const Color(0xFFFFD84E).withValues(alpha: 0.95),
                  ),
                  Spacing.h8,
                  Expanded(
                    child: AppText(
                      text:
                          'VIP frames auto-equip on purchase and play as your room entrance.',
                      fontSize: TextStyles.k10FontSize,
                      color: kColorWhite.withValues(alpha: 0.92),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: AppLightUi.iconTileDecoration(AppLightUi.pink),
            child: const Icon(
              Icons.workspace_premium_rounded,
              size: 14,
              color: AppLightUi.pink,
            ),
          ),
          Spacing.h8,
          const SemiBoldText(
            text: 'AVAILABLE FRAMES',
            fontSize: TextStyles.k12FontSize,
            color: AppLightUi.title,
          ),
          const Spacer(),
          Obx(() {
            final count = controller.vipFrames.length;
            if (count <= 0) return const SizedBox.shrink();
            return AppText(
              text: '$count items',
              fontSize: TextStyles.k12FontSize,
              color: AppLightUi.subtitle,
            );
          }),
        ],
      ),
    );
  }

  Widget _framesGrid() {
    return Obx(() {
      final list = controller.vipFrames;
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _VipFrameCard(
              item: list[index],
              onBuy: () => controller.purchaseFrame(list[index]),
              isBusy: controller.isPurchasing.value,
            ),
            childCount: list.length,
          ),
        ),
      );
    });
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: GlossyDatingCard(
          radius: 24,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: AppLightUi.iconTileDecoration(
                  AppLightUi.gold,
                  radius: 18,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppLightUi.gold,
                  size: 32,
                ),
              ),
              Spacing.v16,
              const SemiBoldText(
                text: 'No VIP frames yet',
                fontSize: TextStyles.k16FontSize,
                color: AppLightUi.title,
              ),
              Spacing.v8,
              const AppText(
                text:
                    'When admin adds Avatar Frames with category VIP, they will appear here.',
                fontSize: TextStyles.k12FontSize,
                color: AppLightUi.subtitle,
                align: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: AppLightUi.iconTileDecoration(AppLightUi.rose),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: AppLightUi.rose,
                size: 28,
              ),
            ),
            Spacing.v16,
            const SemiBoldText(
              text: 'Could not load VIP frames',
              fontSize: TextStyles.k16FontSize,
              color: AppLightUi.title,
            ),
            Spacing.v8,
            Obx(
              () => AppText(
                text: controller.loadError.value,
                fontSize: TextStyles.k12FontSize,
                color: AppLightUi.subtitle,
                align: TextAlign.center,
              ),
            ),
            Spacing.v20,
            SizedBox(
              width: 140,
              child: appButton(
                onPressed: controller.loadStore,
                buttonText: 'Retry',
                buttonHeight: 44,
                borderRadius: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VipFrameCard extends StatelessWidget {
  const _VipFrameCard({
    required this.item,
    required this.onBuy,
    required this.isBusy,
  });

  final Map<String, dynamic> item;
  final VoidCallback onBuy;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final isOwned = item['isOwned'] == true;
    final isEquipped = item['isEquipped'] == true;
    final price = item['price'] as int? ?? 0;
    final name = item['name']?.toString() ?? 'VIP Frame';
    final duration = item['duration']?.toString() ?? '';

    return GlossyDatingCard(
      radius: 18,
      padding: EdgeInsets.zero,
      emphasized: isEquipped,
      borderGradient: isEquipped ? AppLightUi.familyCtaGradient : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppLightUi.cardSoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppLightUi.borderStrong.withValues(alpha: 0.7),
                      ),
                    ),
                    child: Center(child: _preview(size: 96)),
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      gradient: isEquipped
                          ? const LinearGradient(
                              colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
                            )
                          : AppLightUi.familyCtaGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: AppText(
                      text: isEquipped ? 'ACTIVE' : 'VIP',
                      fontSize: 9,
                      color: kColorWhite,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: name,
                  fontSize: TextStyles.k14FontSize,
                  color: AppLightUi.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Spacing.v4,
                AppText(
                  text: isEquipped
                      ? 'Auto-equipped'
                      : (duration.isEmpty ? 'Limited time' : duration),
                  fontSize: TextStyles.k10FontSize,
                  color: isEquipped ? const Color(0xFF22C55E) : AppLightUi.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Spacing.v10,
                SizedBox(
                  height: 36,
                  width: double.infinity,
                  child: appButton(
                    onPressed: isBusy || isOwned ? () {} : onBuy,
                    buttonText: isOwned
                        ? (isEquipped ? 'Equipped' : 'Owned')
                        : _formatPrice(price),
                    buttonHeight: 36,
                    borderRadius: 12,
                    isGradient: !isOwned,
                    buttonColor: isOwned
                        ? AppLightUi.gold.withValues(alpha: 0.25)
                        : null,
                    textColor: isOwned ? AppLightUi.gold : kColorWhite,
                    gradientColors: AppLightUi.familyCtaColors,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _preview({required double size}) {
    final svgaUrl = item['svgaUrl']?.toString().trim() ?? '';
    final imageUrl = item['imageUrl']?.toString().trim() ?? '';
    final source = svgaUrl.isNotEmpty ? svgaUrl : imageUrl;

    if (source.isEmpty) {
      return Icon(
        Icons.workspace_premium_rounded,
        size: 44,
        color: AppLightUi.gold.withValues(alpha: 0.85),
      );
    }

    final fallback = imageUrl.isNotEmpty
        ? Image.network(
            imageUrl,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.workspace_premium_rounded,
              size: 44,
              color: AppLightUi.gold.withValues(alpha: 0.85),
            ),
          )
        : Icon(
            Icons.workspace_premium_rounded,
            size: 44,
            color: AppLightUi.gold.withValues(alpha: 0.85),
          );

    if (ProfileBackgroundMedia.isSvgaUrl(source) || svgaUrl.isNotEmpty) {
      return NetworkSvgaWidget(
        url: source,
        width: size,
        height: size,
        fit: BoxFit.contain,
        showLoadingIndicator: false,
        fallback: fallback,
      );
    }

    return Image.network(
      source,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  String _formatPrice(int price) {
    final digits = price.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final reverseIndex = digits.length - i;
      buffer.write(digits[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) buffer.write(',');
    }
    return '${buffer.toString()} Coins';
  }
}
