import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/wallet/bindings/wallet_binding.dart';
import 'package:qobo_one_live/app/user_flow/wallet/views/wallet_view.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/app_widgets/network_svga_widget.dart';
import 'package:qobo_one_live/utils/app_widgets/profile_background_media.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/vip_store_controller.dart';

class VipStoreView extends GetView<VipStoreController> {
  const VipStoreView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorAppBackground,
      appBar: CommonAppBarWidget(
        title: 'VIP Frames',
        useMaterialAppBar: true,
        actions: [
          IconButton(
            tooltip: 'My Backpack',
            onPressed: controller.openBackpack,
            icon: const Icon(Icons.style_outlined, color: kColorText),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.vipFrames.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(kColorPrimary),
            ),
          );
        }

        return RefreshIndicator(
          color: kColorPrimary,
          onRefresh: controller.loadStore,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _balanceCard(context)),
              SliverToBoxAdapter(child: _sectionHeader()),
              if (controller.loadError.value.isNotEmpty &&
                  controller.vipFrames.isEmpty)
                SliverFillRemaining(hasScrollBody: false, child: _errorState())
              else if (controller.vipFrames.isEmpty)
                SliverFillRemaining(hasScrollBody: false, child: _emptyState())
              else
                _framesGrid(),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
            ],
          ),
        );
      }),
    );
  }

  Widget _balanceCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF761B65), Color(0xFFC04B9F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kColorPrimary.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppText(
            text: 'Your Balance',
            fontSize: 12,
            color: Color(0xCCFFFFFF),
          ),
          Spacing.v8,
          Row(
            children: [
              const Icon(
                Icons.monetization_on_rounded,
                color: Color(0xFFFFD700),
                size: 26,
              ),
              Spacing.h8,
              Expanded(
                child: Obx(
                  () => BoldText(
                    text: '${controller.formattedCoins} Coins',
                    fontSize: TextStyles.k20FontSize,
                    color: kColorWhite,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Spacing.h8,
              SizedBox(
                height: 34,
                width: 96,
                child: appButton(
                  onPressed: () => Get.to(
                    () => const WalletView(),
                    binding: WalletBinding(),
                  ),
                  buttonText: 'Recharge',
                  buttonColor: kColorWhite,
                  borderRadius: 17,
                  buttonWidth: 96,
                  textStyle: TextStyles.kBoldPoppins(
                    fontSize: TextStyles.k12FontSize,
                    colors: kColorPrimary,
                  ),
                ),
              ),
            ],
          ),
          Spacing.v12,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: kColorWhite.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: AppText(
                    text:
                        'VIP frames auto-equip on purchase and play as your room entrance.',
                    fontSize: 11,
                    color: Color(0xEEFFFFFF),
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
          const SemiBoldText(
            text: 'Available Frames',
            fontSize: TextStyles.k16FontSize,
            color: kColorText,
          ),
          const Spacer(),
          Obx(
            () => AppText(
              text: '${controller.vipFrames.length} items',
              fontSize: 12,
              color: kColorHint,
            ),
          ),
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
            Icon(
              Icons.workspace_premium_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            Spacing.v16,
            const SemiBoldText(
              text: 'No VIP frames yet',
              fontSize: 16,
              color: kColorText,
            ),
            Spacing.v8,
            const AppText(
              text:
                  'When admin adds Avatar Frames with category VIP, they will appear here.',
              fontSize: 12,
              color: kColorHint,
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
            const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.redAccent),
            Spacing.v16,
            const SemiBoldText(
              text: 'Could not load VIP frames',
              fontSize: 16,
              color: kColorText,
            ),
            Spacing.v8,
            Obx(
              () => AppText(
                text: controller.loadError.value,
                fontSize: 12,
                color: kColorHint,
                align: TextAlign.center,
              ),
            ),
            Spacing.v20,
            SizedBox(
              width: 140,
              height: 40,
              child: appButton(
                onPressed: controller.loadStore,
                buttonText: 'Retry',
                isGradient: true,
                borderRadius: 12,
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
        color: kColorWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isEquipped
              ? const Color(0xFFFFD700)
              : kColorPrimary.withValues(alpha: 0.08),
          width: isEquipped ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: kColorBlack.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                      color: const Color(0xFFF7F0F6),
                      borderRadius: BorderRadius.circular(14),
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
                      color: isEquipped
                          ? Colors.green
                          : const Color(0xFFFFD700),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: AppText(
                      text: isEquipped ? 'ACTIVE' : 'VIP',
                      fontSize: 9,
                      color: isEquipped ? kColorWhite : kColorText,
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
                  color: kColorText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Spacing.v4,
                AppText(
                  text: isEquipped
                      ? 'Auto-equipped'
                      : (duration.isEmpty ? 'Limited time' : duration),
                  fontSize: 11,
                  color: isEquipped ? Colors.green : kColorHint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Spacing.v10,
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: appButton(
                    onPressed: isBusy || isOwned ? () {} : onBuy,
                    buttonText: isOwned
                        ? (isEquipped ? 'Equipped' : 'Owned')
                        : _formatPrice(price),
                    buttonColor: isOwned
                        ? const Color(0xFFF1E6B8)
                        : kColorPrimary,
                    textColor: isOwned ? kColorText : kColorWhite,
                    borderRadius: 12,
                    textStyle: TextStyles.kSemiBoldPoppins(
                      fontSize: TextStyles.k12FontSize,
                      colors: isOwned ? kColorText : kColorWhite,
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
      return Icon(
        Icons.workspace_premium_rounded,
        color: kColorPrimary.withValues(alpha: 0.7),
        size: 40,
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
              color: kColorPrimary.withValues(alpha: 0.7),
              size: 40,
            ),
          )
        : Icon(
            Icons.workspace_premium_rounded,
            color: kColorPrimary.withValues(alpha: 0.7),
            size: 40,
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
