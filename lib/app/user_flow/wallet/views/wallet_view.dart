import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_coin_icon.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import 'package:qobo_one_live/routes/app_pages.dart';
import '../controllers/wallet_controller.dart';

class WalletView extends StatefulWidget {
  const WalletView({super.key, this.openWithdrawOnLoad = false});

  /// When true, opens the withdraw bottom sheet after the wallet loads.
  final bool openWithdrawOnLoad;

  @override
  State<WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends State<WalletView> {
  final WalletController controller = Get.find<WalletController>();
  final TextEditingController _withdrawUpiController = TextEditingController();
  final TextEditingController _withdrawAccountController =
      TextEditingController();
  final TextEditingController _withdrawIfscController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.openWithdrawOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openWithdrawBottomSheet();
      });
    }
  }

  @override
  void dispose() {
    _withdrawUpiController.dispose();
    _withdrawAccountController.dispose();
    _withdrawIfscController.dispose();
    super.dispose();
  }

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
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Obx(
                                () => _balanceCard(
                                  title: 'Diamonds',
                                  amount: controller.coinBalance.value,
                                  icon: kIconCoin2,
                                ),
                              ),
                            ),
                            // Spacing.h12,
                            // Expanded(
                            //   child: Obx(
                            //     () => _balanceCard(
                            //       title: 'Diamonds',
                            //       amount: controller.diamondBalance.value,
                            //       iconData: Icons.diamond_rounded,
                            //       subtitle: controller.dollarBalance.value,
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                        Spacing.v12,
                        Obx(() => _earnedDollarsCard()),
                        Spacing.v12,
                        Obx(() => _withdrawalLimitCard()),
                        Spacing.v12,
                        Obx(() => _withdrawActionCard()),
                        Spacing.v12,
                        GestureDetector(
                          onTap: () => Get.toNamed(Routes.VIP_STORE),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.storefront_rounded,
                                  color: kColorWhite,
                                  size: 24,
                                ),
                                Spacing.h12,
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SemiBoldText(
                                        text: 'VIP Decoration Store',
                                        fontSize: TextStyles.k14FontSize,
                                        color: kColorWhite,
                                      ),
                                      Spacing.v2,
                                      AppText(
                                        text:
                                            'Get elite entrances, avatars, & chat bubbles!',
                                        fontSize: 11,
                                        color: kColorWhite.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: kColorWhite,
                                  size: 22,
                                ),
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
                        _coinPackagesPanel(),
                      ],
                    ),
                  ),
                ),
                Spacing.v20,
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: Obx(() {
                    final buying = controller.isBuying.value;
                    return appButton(
                      onPressed: () {
                        if (buying) return;
                        final plan = controller.selectedPackage;
                        if (plan == null) {
                          Get.snackbar(
                            'Wallet',
                            controller.packageError.value.isNotEmpty
                                ? controller.packageError.value
                                : 'No coin package available right now.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.black87,
                            colorText: kColorWhite,
                          );
                          return;
                        }
                        _openCheckoutBottomSheet(plan);
                      },
                      buttonText: buying ? 'Processing…' : 'Buy Now',
                      isGradient: false,
                      buttonColor: kColorPrimary,
                      borderRadius: 12,
                    );
                  }),
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
          return const SizedBox(
            height: 140,
            child: Center(
              child: CircularProgressIndicator(color: kColorPrimary),
            ),
          );
        }
        if (controller.packages.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              controller.packageError.value.isNotEmpty
                  ? controller.packageError.value
                  : 'No coin packages found.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: kColorHint),
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          itemCount: controller.packages.length,
          separatorBuilder: (_, __) =>
              Divider(color: kColorWhite.withValues(alpha: 0.12), height: 10),
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
      Builder(
        builder: (context) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.86,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2A2438),
                  Color(0xFF1A1528),
                  Color(0xFF12101C),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.28),
                          ),
                        ),
                        child: AppText(
                          text:
                              'Total Amount: ${plan.priceLabel} (${plan.coinsLabel})',
                          fontSize: 13,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                    Spacing.v16,
                    _paymentMethodTile(
                      logoIcon: Icons.credit_card_rounded,
                      title: 'Razorpay',
                      subtitle: 'UPI · Cards · NetBanking · Wallets',
                      color: Colors.deepOrange,
                      onTap: () => _submitPayment('Razorpay', plan),
                    ),
                    const Divider(color: Colors.white10, height: 16),
                    _paymentMethodTile(
                      logoIcon: Icons.account_balance_wallet_rounded,
                      title: 'Google Pay',
                      subtitle: 'Coming soon',
                      color: Colors.blue,
                      onTap: () {
                        Get.back();
                        Get.snackbar(
                          'Coming soon',
                          'Use Razorpay for coin purchases right now.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.black87,
                          colorText: kColorWhite,
                        );
                      },
                    ),
                    const Divider(color: Colors.white10, height: 16),
                    _paymentMethodTile(
                      logoIcon: Icons.payment_rounded,
                      title: 'PayPal Gateway',
                      subtitle: 'Coming soon',
                      color: Colors.indigo,
                      onTap: () {
                        Get.back();
                        Get.snackbar(
                          'Coming soon',
                          'Use Razorpay for coin purchases right now.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.black87,
                          colorText: kColorWhite,
                        );
                      },
                    ),
                    const Divider(color: Colors.white10, height: 16),
                    _paymentMethodTile(
                      logo: AppCoinIcon(size: 20, color: Colors.amber),
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
            ),
          );
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _paymentMethodTile({
    IconData? logoIcon,
    Widget? logo,
    required String title,
    required Color color,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: logo ?? Icon(logoIcon, color: color, size: 20),
        ),
      ),
      title: SemiBoldText(text: title, fontSize: 13, color: kColorWhite),
      subtitle: subtitle == null
          ? null
          : AppText(
              text: subtitle,
              fontSize: 11,
              color: kColorWhite.withValues(alpha: 0.55),
            ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        color: Colors.white24,
        size: 14,
      ),
      onTap: onTap,
    );
  }

  void _submitPayment(String method, CoinPackage plan) async {
    Get.back(); // close payment methods
    final index = controller.packages.indexWhere((p) => p.id == plan.id);
    if (index >= 0) {
      controller.selectedPlanIndex.value = index;
    }

    final ok = method.toLowerCase().contains('razor')
        ? await controller.buyPackageWithRazorpay(package: plan)
        : await controller.buySelectedPackage(method.toLowerCase());

    if (ok) {
      Get.dialog(
        Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: const Color(0xFF1E1E2D),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Payment Successful',
                  style: TextStyle(
                    color: kColorWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
      final msg = controller.packageError.value;
      if (msg.toLowerCase().contains('cancel')) {
        Get.snackbar(
          'Payment cancelled',
          'No coins were charged.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black87,
          colorText: kColorWhite,
        );
        return;
      }
      Get.snackbar(
        'Payment Failed',
        msg.isNotEmpty ? msg : 'Unable to complete this purchase.',
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

  Widget _earnedDollarsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFC857).withValues(alpha: 0.45),
        ),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            const Color(0xFFFFC857).withValues(alpha: 0.22),
            kColorWalletCardBgBottom.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFC857).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: AppCoinIcon(size: 22, color: const Color(0xFFFFC857)),
          ),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SemiBoldText(
                  text: 'Earned dollars',
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite,
                ),
                Spacing.v2,
                AppText(
                  text: '1,000 diamonds = \$1.00 USD',
                  fontSize: TextStyles.k10FontSize,
                  color: kColorWhite.withValues(alpha: 0.65),
                ),
              ],
            ),
          ),
          SemiBoldText(
            text: controller.dollarBalance.value,
            fontSize: TextStyles.k18FontSize,
            color: const Color(0xFFFFC857),
          ),
        ],
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

  Widget _withdrawActionCard() {
    final isLoading = controller.isLoadingWithdrawConfig.value;
    final isEligible = controller.isEligibleForWithdrawThisWeek.value;
    final hasTiers = controller.allowedWithdrawTiers.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: kColorWalletCardBorder.withValues(alpha: 0.6),
        ),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF3F235C), Color(0xFF251A45)],
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
              Icons.account_balance_wallet_outlined,
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
                  text: 'Withdraw diamonds',
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite,
                ),
                Spacing.v2,
                AppText(
                  text:
                      'Available: ${controller.withdrawCurrencySymbol.value}${controller.withdrawableBalance.value}',
                  fontSize: TextStyles.k10FontSize,
                  color: kColorWhite.withValues(alpha: 0.65),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 34,
            child: TextButton(
              onPressed: isLoading || !hasTiers
                  ? null
                  : () => _openWithdrawBottomSheet(),
              style: TextButton.styleFrom(
                backgroundColor: isEligible
                    ? kColorWalletAmount
                    : kColorWhite.withValues(alpha: 0.12),
                foregroundColor: isEligible ? kColorBlack : kColorWhite,
                disabledBackgroundColor: kColorWhite.withValues(alpha: 0.08),
                disabledForegroundColor: kColorWhite.withValues(alpha: 0.35),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: SemiBoldText(
                text: isLoading ? 'Loading' : 'Withdraw',
                fontSize: TextStyles.k12FontSize,
                color: isEligible ? kColorBlack : kColorWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openWithdrawBottomSheet() {
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.86,
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E2D),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Obx(
                  () => Column(
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
                          text: 'Withdraw',
                          fontSize: TextStyles.k18FontSize,
                          color: kColorWhite,
                        ),
                      ),
                      Spacing.v12,
                      _withdrawSummaryRow(),
                      if (!controller.isEligibleForWithdrawThisWeek.value) ...[
                        Spacing.v12,
                        _withdrawInfoBanner(
                          icon: Icons.event_busy_rounded,
                          text:
                              'You have already requested a weekly withdrawal.',
                          color: Colors.orangeAccent,
                        ),
                      ],
                      Spacing.v20,
                      const SemiBoldText(
                        text: 'Select amount',
                        fontSize: TextStyles.k14FontSize,
                        color: kColorWhite,
                      ),
                      Spacing.v10,
                      _withdrawTierGrid(),
                      Spacing.v20,
                      const SemiBoldText(
                        text: 'Bank details',
                        fontSize: TextStyles.k14FontSize,
                        color: kColorWhite,
                      ),
                      Spacing.v6,
                      AppText(
                        text: 'Enter UPI ID or bank account number with IFSC.',
                        fontSize: TextStyles.k10FontSize,
                        color: kColorWhite.withValues(alpha: 0.58),
                      ),
                      Spacing.v10,
                      _withdrawTextField(
                        controller: _withdrawUpiController,
                        label: 'UPI ID',
                        hint: 'name@upi',
                        icon: Icons.alternate_email_rounded,
                      ),
                      Spacing.v10,
                      _withdrawTextField(
                        controller: _withdrawAccountController,
                        label: 'Bank account number',
                        hint: 'Optional if UPI is entered',
                        icon: Icons.account_balance_rounded,
                        keyboardType: TextInputType.number,
                      ),
                      Spacing.v10,
                      _withdrawTextField(
                        controller: _withdrawIfscController,
                        label: 'IFSC code',
                        hint: 'Optional if UPI is entered',
                        icon: Icons.confirmation_number_outlined,
                        textCapitalization: TextCapitalization.characters,
                      ),
                      Spacing.v20,
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: TextButton(
                          onPressed:
                              controller.isSubmittingWithdrawal.value ||
                                  !controller
                                      .isEligibleForWithdrawThisWeek
                                      .value
                              ? null
                              : _submitWithdrawRequest,
                          style: TextButton.styleFrom(
                            backgroundColor: kColorPrimary,
                            disabledBackgroundColor: kColorWhite.withValues(
                              alpha: 0.1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: controller.isSubmittingWithdrawal.value
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: kColorWhite,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const SemiBoldText(
                                  text: 'Submit Request',
                                  fontSize: TextStyles.k14FontSize,
                                  color: kColorWhite,
                                ),
                        ),
                      ),
                      Spacing.v20,
                      _withdrawHistoryPreview(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _withdrawSummaryRow() {
    return Row(
      children: [
        Expanded(
          child: _withdrawMiniStat(
            label: 'Available',
            value:
                '${controller.withdrawCurrencySymbol.value}${controller.withdrawableBalance.value}',
          ),
        ),
        Spacing.h10,
        Expanded(
          child: _withdrawMiniStat(
            label: 'Weekly limit',
            value:
                '${controller.withdrawCurrencySymbol.value}${controller.withdrawalLimit.value}',
          ),
        ),
      ],
    );
  }

  Widget _withdrawMiniStat({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            text: label,
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite.withValues(alpha: 0.62),
          ),
          Spacing.v4,
          SemiBoldText(
            text: value,
            fontSize: TextStyles.k14FontSize,
            color: kColorWalletAmount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _withdrawInfoBanner({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          Spacing.h8,
          Expanded(
            child: AppText(
              text: text,
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    );
  }

  Widget _withdrawTierGrid() {
    final tiers = controller.allowedWithdrawTiers.toList();
    if (tiers.isEmpty) {
      return AppText(
        text: 'No withdrawal amount is available right now.',
        fontSize: TextStyles.k12FontSize,
        color: kColorWhite.withValues(alpha: 0.65),
      );
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: tiers.map((tier) {
        final selected = controller.selectedWithdrawTier.value == tier;
        return GestureDetector(
          onTap: () => controller.selectWithdrawTier(tier),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 86,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? kColorWalletAmount
                  : kColorWhite.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? kColorWalletAmount
                    : kColorWhite.withValues(alpha: 0.1),
              ),
            ),
            child: SemiBoldText(
              text: controller.tierLabel(tier),
              fontSize: TextStyles.k14FontSize,
              color: selected ? kColorBlack : kColorWhite,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _withdrawTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: TextStyles.kRegularPoppins(
        fontSize: TextStyles.k12FontSize,
        colors: kColorWhite,
      ),
      cursorColor: kColorWalletAmount,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: kColorWhite.withValues(alpha: 0.7)),
        labelStyle: TextStyles.kRegularPoppins(
          fontSize: TextStyles.k12FontSize,
          colors: kColorWhite.withValues(alpha: 0.72),
        ),
        hintStyle: TextStyles.kRegularPoppins(
          fontSize: TextStyles.k12FontSize,
          colors: kColorWhite.withValues(alpha: 0.35),
        ),
        filled: true,
        fillColor: kColorWhite.withValues(alpha: 0.06),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: kColorWhite.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kColorWalletAmount),
        ),
      ),
    );
  }

  Widget _withdrawHistoryPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: SemiBoldText(
                text: 'Recent requests',
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite,
              ),
            ),
            if (controller.isLoadingWithdrawHistory.value)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  color: kColorWalletAmount,
                  strokeWidth: 2,
                ),
              ),
          ],
        ),
        Spacing.v10,
        if (controller.withdrawHistory.isEmpty)
          AppText(
            text: 'No withdrawal request yet.',
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite.withValues(alpha: 0.62),
          )
        else
          Column(
            children: controller.withdrawHistory
                .take(3)
                .map(
                  (item) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: kColorWhite.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SemiBoldText(
                                text:
                                    '${controller.withdrawCurrencySymbol.value}${item.amount % 1 == 0 ? item.amount.toInt() : item.amount}',
                                fontSize: TextStyles.k12FontSize,
                                color: kColorWhite,
                              ),
                              Spacing.v2,
                              AppText(
                                text: _withdrawHistorySubtitle(item),
                                fontSize: TextStyles.k10FontSize,
                                color: kColorWhite.withValues(alpha: 0.55),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        _withdrawStatusChip(item.status),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  String _withdrawHistorySubtitle(dynamic item) {
    final id = item.transactionId.toString();
    final requestedAt = item.requestedAt;
    final dateText = requestedAt == null
        ? ''
        : '${requestedAt.day.toString().padLeft(2, '0')}/${requestedAt.month.toString().padLeft(2, '0')}/${requestedAt.year}';
    if (id.isEmpty) return dateText;
    if (dateText.isEmpty) return id;
    return '$id • $dateText';
  }

  Widget _withdrawStatusChip(String status) {
    final normalized = status.toUpperCase();
    final color = normalized == 'APPROVED'
        ? Colors.green
        : normalized == 'REJECTED'
        ? Colors.redAccent
        : Colors.orangeAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SemiBoldText(
        text: normalized,
        fontSize: TextStyles.k10FontSize,
        color: color,
      ),
    );
  }

  Future<void> _submitWithdrawRequest() async {
    final hasUpi = _withdrawUpiController.text.trim().isNotEmpty;
    final hasBank =
        _withdrawAccountController.text.trim().isNotEmpty &&
        _withdrawIfscController.text.trim().isNotEmpty;
    if (controller.selectedWithdrawTier.value == null) {
      _showWithdrawErrorDialog('Please select a withdrawal amount.');
      return;
    }
    if (!controller.isEligibleForWithdrawThisWeek.value) {
      _showWithdrawErrorDialog(
        'You have already requested a weekly withdrawal.',
      );
      return;
    }
    if (!hasUpi && !hasBank) {
      controller.withdrawError.value =
          'Enter UPI ID or bank account and IFSC details.';
      _showWithdrawErrorDialog(controller.withdrawError.value);
      return;
    }

    final result = await controller.submitWithdrawalRequest(
      upiId: _withdrawUpiController.text,
      accountNumber: _withdrawAccountController.text,
      ifscCode: _withdrawIfscController.text,
    );
    if (result == null) {
      _showWithdrawErrorDialog(
        controller.withdrawError.value.isNotEmpty
            ? controller.withdrawError.value
            : 'Withdrawal request failed. Please try again.',
      );
      return;
    }

    _withdrawUpiController.clear();
    _withdrawAccountController.clear();
    _withdrawIfscController.clear();
    Get.back();
    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF1E1E2D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 58,
              ),
              Spacing.v16,
              const SemiBoldText(
                text: 'Request Submitted',
                fontSize: TextStyles.k18FontSize,
                color: kColorWhite,
              ),
              Spacing.v8,
              AppText(
                text:
                    'Withdrawal request ${result.transactionId} is ${result.status.toLowerCase()}.',
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite.withValues(alpha: 0.72),
                align: TextAlign.center,
              ),
              Spacing.v20,
              SizedBox(
                width: double.infinity,
                height: 42,
                child: TextButton(
                  onPressed: Get.back,
                  style: TextButton.styleFrom(
                    backgroundColor: kColorPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const SemiBoldText(
                    text: 'Done',
                    fontSize: TextStyles.k14FontSize,
                    color: kColorWhite,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWithdrawErrorDialog(String message) {
    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF1E1E2D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 34,
                ),
              ),
              Spacing.v16,
              const SemiBoldText(
                text: 'Withdrawal Failed',
                fontSize: TextStyles.k18FontSize,
                color: kColorWhite,
              ),
              Spacing.v8,
              AppText(
                text: message,
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite.withValues(alpha: 0.72),
                align: TextAlign.center,
              ),
              Spacing.v20,
              SizedBox(
                width: double.infinity,
                height: 42,
                child: TextButton(
                  onPressed: Get.back,
                  style: TextButton.styleFrom(
                    backgroundColor: kColorPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const SemiBoldText(
                    text: 'Okay',
                    fontSize: TextStyles.k14FontSize,
                    color: kColorWhite,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _balanceCard({
    required String title,
    required String amount,
    String? icon,
    IconData? iconData,
    String? subtitle,
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
              if (icon != null)
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
          if (subtitle != null && subtitle.trim().isNotEmpty) ...[
            Spacing.v4,
            AppText(
              text: subtitle,
              fontSize: TextStyles.k10FontSize,
              color: kColorWhite.withValues(alpha: 0.7),
            ),
          ],
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
        color: isSelected
            ? kColorPrimary.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: kColorPrimary, width: 1.5)
            : Border.all(color: Colors.transparent),
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
