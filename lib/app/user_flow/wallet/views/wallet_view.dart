import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import 'package:qobo_one_live/routes/app_pages.dart';
import '../controllers/wallet_controller.dart';

class WalletView extends StatefulWidget {
  const WalletView({super.key});

  @override
  State<WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends State<WalletView> {
  final WalletController controller = Get.find<WalletController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage(kImgBG), fit: BoxFit.cover),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
            child: Column(
              children: [
                _walletHeader(),
                Spacing.v20,
                Row(
                  children: [
                    Expanded(
                      child: Obx(
                        () => _balanceCard(
                          title: 'Coin',
                          amount: controller.coinBalance.value,
                          icon: kIconCoin2,
                        ),
                      ),
                    ),
                    Spacing.h12,
                    Expanded(
                      child: Obx(
                        () => _balanceCard(
                          title: 'Diamonds',
                          amount: controller.diamondBalance.value,
                          iconData: Icons.diamond_rounded,
                        ),
                      ),
                    ),
                  ],
                ),
                Spacing.v12,
                Obx(() => _withdrawalLimitCard()),
                Spacing.v12,
                // VIP Store Promo Banner
                GestureDetector(
                  onTap: () => Get.toNamed(Routes.VIP_STORE),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.storefront_rounded, color: kColorWhite, size: 24),
                        Spacing.h12,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SemiBoldText(
                                text: 'VIP Decoration Store',
                                fontSize: TextStyles.k14FontSize,
                                color: kColorWhite,
                              ),
                              Spacing.v2,
                              AppText(
                                text: 'Get elite entrances, avatars, & chat bubbles!',
                                fontSize: 11,
                                color: kColorWhite.withValues(alpha: 0.8),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: kColorWhite, size: 22),
                      ],
                    ),
                  ),
                ),
                Spacing.v10,
                // Coin Seller Center Promo Banner
                GestureDetector(
                  onTap: () => Get.toNamed(Routes.COIN_SELLER),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.monetization_on_rounded, color: kColorWhite, size: 24),
                        Spacing.h12,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SemiBoldText(
                                text: 'Official Coin Seller Center',
                                fontSize: TextStyles.k14FontSize,
                                color: kColorWhite,
                              ),
                              Spacing.v2,
                              AppText(
                                text: 'Manage transfers, buyer requests, & transaction ledger!',
                                fontSize: 11,
                                color: kColorWhite.withValues(alpha: 0.8),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: kColorWhite, size: 22),
                      ],
                    ),
                  ),
                ),
                Spacing.v16,
                const Align(
                  alignment: Alignment.centerLeft,
                  child: SemiBoldText(
                    text: 'Buy Coin',
                    fontSize: TextStyles.k20FontSize,
                    color: kColorWhite,
                  ),
                ),
                Spacing.v12,
                Expanded(child: _coinPackagesPanel()),
                Spacing.v20,
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: appButton(
                    onPressed: () {
                      if (controller.packages.isEmpty) {
                        Get.snackbar(
                          'Wallet',
                          'No coin package available right now.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.black87,
                          colorText: kColorWhite,
                        );
                        return;
                      }
                      _openCheckoutBottomSheet(
                        controller.packages[controller.selectedPlanIndex.value],
                      );
                    },
                    buttonText: 'Buy Now',
                    isGradient: false,
                    buttonColor: kColorPrimary,
                    borderRadius: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _coinPackagesPanel() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: kColorWalletCardBorder.withValues(alpha: 0.6),
          width: 1,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kColorWalletCardBgTop, kColorWalletCardBgBottom],
        ),
      ),
      child: Obx(() {
        if (controller.isLoadingPackages.value) {
          return const Center(
            child: CircularProgressIndicator(color: kColorPrimary),
          );
        }
        if (controller.packages.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                controller.packageError.value.isNotEmpty
                    ? controller.packageError.value
                    : 'No coin packages found.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: kColorHint,
                ),
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          itemCount: controller.packages.length,
          separatorBuilder: (_, __) => Divider(
            color: kColorWhite.withValues(alpha: 0.12),
            height: 10,
          ),
          itemBuilder: (_, index) {
            final plan = controller.packages[index];
            return GestureDetector(
              onTap: () => controller.selectedPlanIndex.value = index,
              child: Obx(
                () => _coinPlanRow(
                  coins: plan.coinsLabel,
                  price: plan.priceLabel,
                  hasExtra: false,
                  isSelected: controller.selectedPlanIndex.value == index,
                ),
              ),
            );
          },
        );
      }),
    );
  }

  void _openCheckoutBottomSheet(CoinPackage plan) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E2D),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Spacing.v16,
            const Center(
              child: SemiBoldText(
                text: 'Select Payment Method',
                fontSize: 16,
                color: kColorWhite,
              ),
            ),
            Spacing.v12,
            Center(
              child: AppText(
                text: 'Total Amount: ${plan.priceLabel} (${plan.coinsLabel})',
                fontSize: 13,
                color: Colors.amber,
              ),
            ),
            Spacing.v24,
            _paymentMethodTile(
              logoIcon: Icons.account_balance_wallet_rounded,
              title: 'Google Pay',
              color: Colors.blue,
              onTap: () => _submitPayment('Google Pay', plan),
            ),
            const Divider(color: Colors.white10, height: 16),
            _paymentMethodTile(
              logoIcon: Icons.payment_rounded,
              title: 'PayPal Gateway',
              color: Colors.indigo,
              onTap: () => _submitPayment('PayPal', plan),
            ),
            const Divider(color: Colors.white10, height: 16),
            _paymentMethodTile(
              logoIcon: Icons.credit_card_rounded,
              title: 'Razorpay Instant',
              color: Colors.deepOrange,
              onTap: () => _submitPayment('Razorpay', plan),
            ),
            const Divider(color: Colors.white10, height: 16),
            _paymentMethodTile(
              logoIcon: Icons.monetization_on_outlined,
              title: 'Buy via Coin Seller',
              color: Colors.amber,
              onTap: () {
                Get.back();
                Get.snackbar(
                  'Order Request Submitted',
                  'Purchase request sent to official coin sellers! They will contact you shortly.',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.green,
                  colorText: kColorWhite,
                );
              },
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  Widget _paymentMethodTile({
    required IconData logoIcon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(logoIcon, color: color, size: 20),
      ),
      title: SemiBoldText(text: title, fontSize: 13, color: kColorWhite),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
      onTap: onTap,
    );
  }

  void _submitPayment(String method, CoinPackage plan) async {
    Get.back(); // close payment methods
    final ok = await controller.buySelectedPackage(method.toLowerCase());
    if (ok) {
      Get.dialog(
        Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: const Color(0xFF1E1E2D),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Payment Successful',
                  style: TextStyle(color: kColorWhite, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),
                Text(
                  'Added ${plan.coinsLabel} to your account via $method.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kColorPrimary,
                      foregroundColor: kColorWhite,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Get.back(),
                    child: const Text('Dismiss'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      Get.snackbar(
        'Payment Failed',
        controller.packageError.value.isNotEmpty
            ? controller.packageError.value
            : 'Unable to complete this purchase.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: kColorWhite,
      );
    }
  }

  Widget _walletHeader() {
    return Row(
      children: [
        _headerBackButton(onTap: Get.back),
        const Expanded(
          child: Center(
            child: SemiBoldText(
              text: 'Wallet',
              fontSize: TextStyles.k20FontSize,
              color: kColorWhite,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => Get.toNamed(Routes.TRANSACTION_HISTORY),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: kColorWalletCardBgTop.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 16,
              color: kColorWhite,
            ),
          ),
        ),
      ],
    );
  }

  Widget _headerBackButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: kColorWalletCardBgTop.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 14,
          color: kColorWhite,
        ),
      ),
    );
  }

  Widget _withdrawalLimitCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: kColorWalletCardBorder.withValues(alpha: 0.6),
        ),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            kColorWalletCardBgTop.withValues(alpha: 0.95),
            kColorWalletCardBgBottom.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kColorWalletAmount.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.savings_outlined,
              size: 20,
              color: kColorWalletAmount,
            ),
          ),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SemiBoldText(
                  text: 'Withdrawal limit',
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite,
                ),
                Spacing.v2,
                AppText(
                  text: 'Minimum diamonds required to withdraw',
                  fontSize: TextStyles.k10FontSize,
                  color: kColorWhite.withValues(alpha: 0.65),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.diamond_rounded,
                size: 16,
                color: kColorWalletAmount,
              ),
              Spacing.h6,
              SemiBoldText(
                text: controller.withdrawalLimit.value,
                fontSize: TextStyles.k18FontSize,
                color: kColorWalletAmount,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balanceCard({
    required String title,
    required String amount,
    String? icon,
    IconData? iconData,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: kColorWalletCardBorder.withValues(alpha: 0.6),
          width: 1,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kColorWalletCardBgTop, kColorWalletCardBgBottom],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null)
                SvgPicture.asset(icon, width: 16, height: 16)
              else
                Icon(iconData, size: 16, color: kColorWalletAmount),
              Spacing.h8,
              SemiBoldText(
                text: title,
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite,
              ),
            ],
          ),
          Spacing.v6,
          Row(
            children: [
              if (title == 'Coin')
                SvgPicture.asset(kIconCoin3, width: 14, height: 14)
              else
                const Icon(
                  Icons.diamond_rounded,
                  size: 14,
                  color: kColorWalletAmount,
                ),
              Spacing.h8,
              SemiBoldText(
                text: amount,
                fontSize: TextStyles.k20FontSize,
                color: kColorWalletAmount,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _coinPlanRow({
    required String coins,
    required String price,
    required bool hasExtra,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? kColorPrimary.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: kColorPrimary, width: 1.5) : Border.all(color: Colors.transparent),
      ),
      child: Row(
        children: [
          SvgPicture.asset(kIconCoin4, width: 22, height: 22),
          Spacing.h10,
          AppText(
            text: coins,
            fontSize: TextStyles.k16FontSize,
            color: kColorWhite,
          ),
          const Spacer(),
          SemiBoldText(
            text: price,
            fontSize: TextStyles.k16FontSize,
            color: kColorWhite,
          ),
          if (hasExtra) ...[
            Spacing.h8,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: kColorWalletExtraBadge,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const SemiBoldText(
                text: '10 extra',
                fontSize: TextStyles.k10FontSize,
                color: kColorWhite,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
