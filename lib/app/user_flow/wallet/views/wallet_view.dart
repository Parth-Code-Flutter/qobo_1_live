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

class WalletView extends StatelessWidget {
  const WalletView({super.key});

  @override
  Widget build(BuildContext context) {
    const plans = <({String coins, String price, bool hasExtra})>[
      (coins: '100 Coins', price: 'PKR 120', hasExtra: false),
      (coins: '100 Coins', price: 'PKR 120', hasExtra: false),
      (coins: '100 Coins', price: 'PKR 950', hasExtra: true),
      (coins: '100 Coins', price: 'PKR 950', hasExtra: true),
      (coins: '100 Coins', price: 'PKR 120', hasExtra: false),
      (coins: '100 Coins', price: 'PKR 950', hasExtra: true),
      (coins: '100 Coins', price: 'PKR 950', hasExtra: true),
    ];

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
                      child: _balanceCard(
                        title: 'Coin',
                        amount: '12,450',
                        icon: kIconCoin2,
                      ),
                    ),
                    Spacing.h12,
                    Expanded(
                      child: _balanceCard(
                        title: 'Diamonds',
                        amount: '8,680',
                        iconData: Icons.diamond_rounded,
                      ),
                    ),
                  ],
                ),
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
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
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
                                color: kColorWhite.withOpacity(0.8),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: kColorWhite, size: 22),
                      ],
                    ),
                  ),
                ),
                Spacing.v20,
                const Align(
                  alignment: Alignment.centerLeft,
                  child: SemiBoldText(
                    text: 'Buy Coin',
                    fontSize: TextStyles.k20FontSize,
                    color: kColorWhite,
                  ),
                ),
                Spacing.v12,
                Expanded(
                  child: Container(
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
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      itemCount: plans.length,
                      separatorBuilder: (_, __) => Divider(
                        color: kColorWhite.withValues(alpha: 0.12),
                        height: 10,
                      ),
                      itemBuilder: (_, index) => _coinPlanRow(
                        coins: plans[index].coins,
                        price: plans[index].price,
                        hasExtra: plans[index].hasExtra,
                      ),
                    ),
                  ),
                ),
                Spacing.v20,
                appButton(
                  onPressed: () {},
                  buttonText: 'Buy Now',
                  isGradient: false,
                  buttonColor: kColorPrimary,
                  borderRadius: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Top bar follows Figma: compact back icon and centered title.
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
        // Navigate to Transaction History
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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
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
