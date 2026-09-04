import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _walletHeader(),
                Spacing.v16,
                _balanceOverviewCard(),
                const SizedBox(height: 14),
                _vipTopUpBanner(),
                const SizedBox(height: 18),
                _sectionTitle(
                  icon: Icons.layers_rounded,
                  title: 'Choose Top Up Package',
                ),
                Spacing.v12,
                _coinPackagesPanel(),
                Spacing.v16,
                _sectionTitle(
                  icon: Icons.payment_rounded,
                  title: 'Select Payment Method',
                ),
                Spacing.v10,
                _paymentMethodsStrip(),
                const SizedBox(height: 14),
                _walletUtilityPanel(),
                const SizedBox(height: 14),
                _trustFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _coinPackagesPanel() {
    return Obx(() {
      if (controller.isLoadingPackages.value) {
        return _walletGlassPanel(
          height: 180,
          child: const Center(
            child: CircularProgressIndicator(color: kColorWalletAmount),
          ),
        );
      }
      if (controller.packages.isEmpty) {
        return _walletGlassPanel(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: AppText(
              text: controller.packageError.value.isNotEmpty
                  ? controller.packageError.value
                  : 'No coin packages found.',
              fontSize: 13,
              color: kColorWhite.withValues(alpha: 0.72),
              align: TextAlign.center,
            ),
          ),
        );
      }
      final displayIndexes =
          List<int>.generate(controller.packages.length, (index) => index)
            ..sort(
              (a, b) => controller.packages[b].amount.compareTo(
                controller.packages[a].amount,
              ),
            );
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: displayIndexes.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.90,
        ),
        itemBuilder: (_, index) {
          final planIndex = displayIndexes[index];
          final plan = controller.packages[planIndex];
          return Obx(() {
            final isSelected = controller.selectedPlanIndex.value == planIndex;
            return _coinPlanCard(
              plan: plan,
              index: planIndex,
              isSelected: isSelected,
            );
          });
        },
      );
    });
  }

  Widget _balanceOverviewCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFF130C36).withValues(alpha: 0.72),
        border: Border.all(
          color: const Color(0xFF8F36FF).withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7F28FF).withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Obx(
        () => Row(
          children: [
            Expanded(
              child: _topBalanceItem(
                title: 'My Coins',
                value: controller.coinBalance.value,
                accent: kColorWalletAmount,
                icon: AppCoinIcon(size: 34, color: kColorWalletAmount),
              ),
            ),
            Container(
              width: 1,
              height: 64,
              color: kColorWhite.withValues(alpha: 0.14),
            ),
            Expanded(
              child: _topBalanceItem(
                title: 'My Diamonds',
                value: controller.diamondBalance.value,
                accent: const Color(0xFF31C8FF),
                icon: const Icon(
                  Icons.diamond_rounded,
                  color: Color(0xFF31C8FF),
                  size: 36,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBalanceItem({
    required String title,
    required String value,
    required Color accent,
    required Widget icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.12),
              border: Border.all(color: accent.withValues(alpha: 0.42)),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.28),
                  blurRadius: 18,
                ),
              ],
            ),
            child: Center(child: icon),
          ),
          Spacing.h10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: title,
                  fontSize: TextStyles.k12FontSize,
                  color: kColorWhite.withValues(alpha: 0.68),
                ),
                Spacing.v4,
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: SemiBoldText(
                    text: value,
                    fontSize: TextStyles.k20FontSize,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vipTopUpBanner() {
    return GestureDetector(
      onTap: () => Get.toNamed(Routes.VIP_STORE),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF331258), Color(0xFF5B1678), Color(0xFF31104C)],
          ),
          border: Border.all(
            color: const Color(0xFFFF5EA7).withValues(alpha: 0.55),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF43C6).withValues(alpha: 0.16),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            _vipBadge(size: 74),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SemiBoldText(
                    text: 'Become VIP & Get More!',
                    fontSize: TextStyles.k16FontSize,
                    color: kColorWalletAmount,
                  ),
                  Spacing.v6,
                  _vipBenefit('10% Extra on every top up'),
                  _vipBenefit('Exclusive gifts & badges'),
                  _vipBenefit('VIP support & priority'),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD84E), Color(0xFFFF9C2A)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SemiBoldText(
                    text: 'View',
                    fontSize: 11,
                    color: kColorBlack,
                  ),
                  Spacing.h4,
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: kColorBlack,
                    size: 10,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vipBenefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF9B5CFF),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: AppText(
              text: text,
              fontSize: 11,
              color: kColorWhite.withValues(alpha: 0.84),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFB175FF), size: 20),
        Spacing.h8,
        SemiBoldText(
          text: title,
          fontSize: TextStyles.k14FontSize,
          color: kColorWhite,
        ),
      ],
    );
  }

  Widget _coinPlanCard({
    required CoinPackage plan,
    required int index,
    required bool isSelected,
  }) {
    final bestValue = plan.amount >= 1000;
    return GestureDetector(
      onTap: () => controller.selectedPlanIndex.value = index,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF21115B), Color(0xFF17083E)],
          ),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF4DE3)
                : kColorWhite.withValues(alpha: 0.12),
            width: isSelected ? 1.4 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF4DE3).withValues(alpha: 0.32),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (bestValue)
              Positioned(
                left: -12,
                top: -12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF2D8A),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomRight: Radius.circular(14),
                    ),
                  ),
                  child: const SemiBoldText(
                    text: 'BEST VALUE',
                    fontSize: 9,
                    color: kColorWhite,
                  ),
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _coinStackGraphic(index),
                Column(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SemiBoldText(
                        text: _formatPlanAmount(plan.amount),
                        fontSize: TextStyles.k20FontSize,
                        color: kColorWalletAmount,
                      ),
                    ),
                    const AppText(
                      text: 'Coins',
                      fontSize: TextStyles.k12FontSize,
                      color: kColorWhite,
                    ),
                    Spacing.v6,
                    if (plan.amount >= 500)
                      _extraBadge(_extraLabel(plan.amount))
                    else
                      const SizedBox(height: 22),
                  ],
                ),
                SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: TextButton(
                    onPressed: controller.isBuying.value
                        ? null
                        : () {
                            controller.selectedPlanIndex.value = index;
                            _openCheckoutBottomSheet(plan);
                          },
                    style: TextButton.styleFrom(
                      backgroundColor: isSelected
                          ? kColorWalletAmount
                          : const Color(0xFF7424EA),
                      foregroundColor: isSelected ? kColorBlack : kColorWhite,
                      disabledBackgroundColor: kColorWhite.withValues(
                        alpha: 0.10,
                      ),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: SemiBoldText(
                      text: controller.isBuying.value ? '...' : plan.priceLabel,
                      fontSize: TextStyles.k14FontSize,
                      color: isSelected ? kColorBlack : kColorWhite,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _coinStackGraphic(int index) {
    final selected = index == controller.selectedPlanIndex.value;
    return Center(
      child: SizedBox(
        width: 126,
        height: 58,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 112,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF8A3EF1).withValues(alpha: 0.24),
                    const Color(0xFF2A115A).withValues(alpha: 0.18),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: kColorWalletAmount.withValues(alpha: 0.15),
                    blurRadius: 18,
                  ),
                ],
              ),
            ),
            Positioned(left: 12, bottom: 10, child: _coinDisc(30)),
            Positioned(left: 36, bottom: 12, child: _coinDisc(34)),
            Positioned(left: 63, bottom: 10, child: _coinDisc(30)),
            Positioned(left: 87, bottom: 12, child: _coinDisc(26)),
            Positioned(
              left: 48,
              top: 2,
              child: Transform.rotate(angle: -0.16, child: _coinDisc(28)),
            ),
            if (selected)
              Positioned(
                right: 16,
                top: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF2D8A),
                    shape: BoxShape.circle,
                    border: Border.all(color: kColorWhite, width: 1.4),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF2D8A).withValues(alpha: 0.35),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: kColorWhite,
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _coinDisc(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF07A), Color(0xFFFFB21F)],
        ),
        border: Border.all(color: const Color(0xFFFFD84E), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: kColorWalletAmount.withValues(alpha: 0.30),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.star_rounded,
          color: const Color(0xFFB96A00).withValues(alpha: 0.82),
          size: size * 0.52,
        ),
      ),
    );
  }

  Widget _extraBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF9F19D8),
        borderRadius: BorderRadius.circular(7),
      ),
      child: SemiBoldText(text: text, fontSize: 10, color: kColorWhite),
    );
  }

  String _extraLabel(int amount) {
    if (amount >= 10000) return '+1,500 Extra';
    if (amount >= 5000) return '+500 Extra';
    if (amount >= 2500) return '+200 Extra';
    if (amount >= 1000) return '+50 Extra';
    if (amount >= 500) return '+20 Extra';
    return '+0 Extra';
  }

  String _formatPlanAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
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
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
        child: Center(child: logo ?? Icon(logoIcon, color: color, size: 20)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _headerBackButton(onTap: Get.back),
            Spacing.h12,
            const Expanded(
              child: SemiBoldText(
                text: 'Top Up',
                fontSize: TextStyles.k24FontSize,
                color: kColorWhite,
              ),
            ),
            GestureDetector(
              onTap: () => Get.toNamed(Routes.TRANSACTION_HISTORY),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFF16103A).withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: kColorWhite.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      size: 17,
                      color: kColorWhite,
                    ),
                    const SizedBox(width: 5),
                    const SemiBoldText(
                      text: 'History',
                      fontSize: 11,
                      color: kColorWhite,
                    ),
                  ],
                ),
              ),
            ),
            Spacing.h8,
            _vipBadge(size: 44),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 50, top: 2, right: 8),
          child: AppText(
            text: 'Top up coins and enjoy premium features',
            fontSize: 12,
            color: kColorWhite.withValues(alpha: 0.72),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _headerBackButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF16103A).withValues(alpha: 0.8),
          shape: BoxShape.circle,
          border: Border.all(color: kColorWhite.withValues(alpha: 0.12)),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: kColorWhite,
        ),
      ),
    );
  }

  Widget _vipBadge({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFD84E), Color(0xFF7B2BDB)],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: kColorWalletAmount.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: kColorWalletAmount.withValues(alpha: 0.26),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: SemiBoldText(
        text: 'VIP',
        fontSize: size > 60 ? TextStyles.k22FontSize : TextStyles.k14FontSize,
        color: kColorWhite,
      ),
    );
  }

  Widget _paymentMethodsStrip() {
    return Row(
      children: [
        Expanded(
          child: _paymentChip(
            label: 'Razorpay',
            subtitle: 'UPI',
            icon: Icons.verified_rounded,
            selected: true,
            onTap: () {
              final plan = controller.selectedPackage;
              if (plan != null) _openCheckoutBottomSheet(plan);
            },
          ),
        ),
        Spacing.h8,
        Expanded(
          child: _paymentChip(
            label: 'G Pay',
            subtitle: 'Soon',
            icon: Icons.g_mobiledata_rounded,
          ),
        ),
        Spacing.h8,
        Expanded(
          child: _paymentChip(
            label: 'Paytm',
            subtitle: 'Soon',
            icon: Icons.account_balance_wallet_rounded,
          ),
        ),
      ],
    );
  }

  Widget _paymentChip({
    required String label,
    required String subtitle,
    required IconData icon,
    bool selected = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFF150C39).withValues(alpha: 0.78),
          border: Border.all(
            color: selected
                ? const Color(0xFFFF4DE3)
                : kColorWhite.withValues(alpha: 0.10),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF4DE3).withValues(alpha: 0.26),
                    blurRadius: 16,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? kColorWalletAmount : kColorWhite,
              size: 21,
            ),
            Spacing.h8,
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SemiBoldText(
                    text: label,
                    fontSize: 11,
                    color: kColorWhite,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Spacing.v2,
                  AppText(
                    text: subtitle,
                    fontSize: 9,
                    color: kColorWhite.withValues(alpha: 0.62),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Color(0xFF9B5CFF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 13,
                  color: kColorWhite,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _walletUtilityPanel() {
    return _walletGlassPanel(
      child: Column(
        children: [
          Obx(() => _earnedDollarsCard()),
          Spacing.v10,
          Obx(() => _withdrawalLimitCard()),
          Spacing.v10,
          Obx(() => _withdrawActionCard()),
        ],
      ),
    );
  }

  Widget _trustFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF150C39).withValues(alpha: 0.72),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _trustItem(
              icon: Icons.shield_outlined,
              title: '100% Secure',
              subtitle: 'Safe payment',
            ),
          ),
          _footerDivider(),
          Expanded(
            child: _trustItem(
              icon: Icons.flash_on_rounded,
              title: 'Instant Credit',
              subtitle: 'Fast coins',
            ),
          ),
          _footerDivider(),
          Expanded(
            child: _trustItem(
              icon: Icons.headset_mic_rounded,
              title: '24/7 Support',
              subtitle: 'We can help',
            ),
          ),
        ],
      ),
    );
  }

  Widget _trustItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: const Color(0xFFFF75FF), size: 20),
        const SizedBox(width: 7),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SemiBoldText(
                text: title,
                fontSize: TextStyles.k10FontSize,
                color: kColorWhite,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              AppText(
                text: subtitle,
                fontSize: 8,
                color: kColorWhite.withValues(alpha: 0.62),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _footerDivider() {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: kColorWhite.withValues(alpha: 0.10),
    );
  }

  Widget _walletGlassPanel({required Widget child, double? height}) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF130C36).withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.10)),
      ),
      child: child,
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
                  text: 'Coin value',
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite,
                ),
                Spacing.v2,
                AppText(
                  text: '10,000 coins = \$1.00 USD',
                  fontSize: TextStyles.k10FontSize,
                  color: kColorWhite.withValues(alpha: 0.65),
                ),
              ],
            ),
          ),
          SemiBoldText(
            text: controller.coinDollarBalance.value,
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
}
