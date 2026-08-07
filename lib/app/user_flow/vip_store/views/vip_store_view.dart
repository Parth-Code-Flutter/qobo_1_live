import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/wallet/bindings/wallet_binding.dart';
import 'package:qobo_one_live/app/user_flow/wallet/views/wallet_view.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/admin_agency_chrome.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/network_svga_widget.dart';
import 'package:qobo_one_live/utils/app_widgets/profile_background_media.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/vip_store_controller.dart';

/// VIP Frames shop — dark glass theme aligned with Family / Discover chrome.
class VipStoreView extends GetView<VipStoreController> {
  const VipStoreView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(kImgBG),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _header(context),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value &&
                      controller.vipFrames.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: kColorWhite),
                    );
                  }

                  return RefreshIndicator(
                    color: AdminAgencyUi.gold,
                    backgroundColor: const Color(0xFF1A0B2E),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          AdminAgencyUi.glassIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            accent: AdminAgencyUi.sky,
            onTap: () => Get.back(),
            size: 40,
            iconSize: 16,
          ),
          const Expanded(
            child: SemiBoldText(
              text: 'VIP Frames',
              fontSize: TextStyles.k18FontSize,
              color: kColorWhite,
              align: TextAlign.center,
            ),
          ),
          // Balance + Recharge already cover wallet — no backpack shortcut.
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _balanceCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6A1B9A), Color(0xFFC2185B)],
        ),
        border: Border.all(
          color: AdminAgencyUi.gold.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: AdminAgencyUi.pink.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AdminAgencyUi.glowIcon(
                icon: Icons.monetization_on_rounded,
                accent: AdminAgencyUi.goldDeep,
                accentEnd: AdminAgencyUi.gold,
                size: 40,
                iconSize: 22,
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
              Spacing.h8,
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
                      gradient: AdminAgencyUi.goldButtonGradient,
                    ),
                    child: const Center(
                      child: SemiBoldText(
                        text: 'Recharge',
                        fontSize: TextStyles.k12FontSize,
                        color: AdminAgencyUi.ctaInk,
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
              color: Colors.black.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: kColorWhite.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              children: [
                AdminAgencyUi.glowIcon(
                  icon: Icons.auto_awesome_rounded,
                  accent: AdminAgencyUi.goldDeep,
                  accentEnd: AdminAgencyUi.gold,
                  size: 28,
                  iconSize: 14,
                ),
                Spacing.h8,
                Expanded(
                  child: AppText(
                    text:
                        'VIP frames auto-equip on purchase and play as your room entrance.',
                    fontSize: TextStyles.k10FontSize,
                    color: kColorWhite.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          AdminAgencyUi.glowIcon(
            icon: Icons.workspace_premium_rounded,
            accent: AdminAgencyUi.violet,
            accentEnd: AdminAgencyUi.pink,
            size: 28,
            iconSize: 14,
          ),
          Spacing.h8,
          const SemiBoldText(
            text: 'AVAILABLE FRAMES',
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite,
          ),
          const Spacer(),
          // Only show count when there is inventory (avoid unused "0 items").
          Obx(() {
            final count = controller.vipFrames.length;
            if (count <= 0) return const SizedBox.shrink();
            return AppText(
              text: '$count items',
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite.withValues(alpha: 0.65),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AdminAgencyUi.glowIcon(
              icon: Icons.workspace_premium_rounded,
              accent: AdminAgencyUi.goldDeep,
              accentEnd: AdminAgencyUi.gold,
              size: 64,
              iconSize: 32,
            ),
            Spacing.v16,
            const SemiBoldText(
              text: 'No VIP frames yet',
              fontSize: TextStyles.k16FontSize,
              color: kColorWhite,
            ),
            Spacing.v8,
            AppText(
              text:
                  'When admin adds Avatar Frames with category VIP, they will appear here.',
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite.withValues(alpha: 0.65),
              align: TextAlign.center,
            ),
          ],
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
            AdminAgencyUi.glowIcon(
              icon: Icons.wifi_off_rounded,
              accent: AdminAgencyUi.rose,
              size: 56,
              iconSize: 28,
            ),
            Spacing.v16,
            const SemiBoldText(
              text: 'Could not load VIP frames',
              fontSize: TextStyles.k16FontSize,
              color: kColorWhite,
            ),
            Spacing.v8,
            Obx(
              () => AppText(
                text: controller.loadError.value,
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite.withValues(alpha: 0.65),
                align: TextAlign.center,
              ),
            ),
            Spacing.v20,
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: controller.loadStore,
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  height: 44,
                  width: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: AdminAgencyUi.primaryButtonGradient,
                  ),
                  child: const Center(
                    child: SemiBoldText(
                      text: 'Retry',
                      fontSize: TextStyles.k14FontSize,
                      color: kColorWhite,
                    ),
                  ),
                ),
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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3D2068), Color(0xFF25143F)],
        ),
        border: Border.all(
          color: isEquipped
              ? AdminAgencyUi.gold
              : kColorWhite.withValues(alpha: 0.12),
          width: isEquipped ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AdminAgencyUi.violet.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
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
                      color: Colors.black.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AdminAgencyUi.gold.withValues(alpha: 0.2),
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
                          : AdminAgencyUi.goldButtonGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: AppText(
                      text: isEquipped ? 'ACTIVE' : 'VIP',
                      fontSize: 9,
                      color: isEquipped ? kColorWhite : AdminAgencyUi.ctaInk,
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
                  color: kColorWhite,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Spacing.v4,
                AppText(
                  text: isEquipped
                      ? 'Auto-equipped'
                      : (duration.isEmpty ? 'Limited time' : duration),
                  fontSize: TextStyles.k10FontSize,
                  color: isEquipped
                      ? AdminAgencyUi.mint
                      : kColorWhite.withValues(alpha: 0.65),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Spacing.v10,
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isBusy || isOwned ? null : onBuy,
                    borderRadius: BorderRadius.circular(12),
                    child: Ink(
                      height: 36,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: isOwned
                            ? LinearGradient(
                                colors: [
                                  AdminAgencyUi.gold.withValues(alpha: 0.35),
                                  AdminAgencyUi.goldDeep.withValues(
                                    alpha: 0.2,
                                  ),
                                ],
                              )
                            : AdminAgencyUi.primaryButtonGradient,
                      ),
                      child: Center(
                        child: SemiBoldText(
                          text: isOwned
                              ? (isEquipped ? 'Equipped' : 'Owned')
                              : _formatPrice(price),
                          fontSize: TextStyles.k12FontSize,
                          color: isOwned ? AdminAgencyUi.gold : kColorWhite,
                        ),
                      ),
                    ),
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
      return AdminAgencyUi.glowIcon(
        icon: Icons.workspace_premium_rounded,
        accent: AdminAgencyUi.goldDeep,
        accentEnd: AdminAgencyUi.gold,
        size: 44,
        iconSize: 22,
      );
    }

    final fallback = imageUrl.isNotEmpty
        ? Image.network(
            imageUrl,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => AdminAgencyUi.glowIcon(
              icon: Icons.workspace_premium_rounded,
              accent: AdminAgencyUi.goldDeep,
              accentEnd: AdminAgencyUi.gold,
              size: 44,
              iconSize: 22,
            ),
          )
        : AdminAgencyUi.glowIcon(
            icon: Icons.workspace_premium_rounded,
            accent: AdminAgencyUi.goldDeep,
            accentEnd: AdminAgencyUi.gold,
            size: 44,
            iconSize: 22,
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
