import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_coin_icon.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/app_widgets/glossy_dating_card.dart';
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

  /// 0 = buy coins, 1 = cash out diamonds.
  late int _walletTab;

  @override
  void initState() {
    super.initState();
    _walletTab = widget.openWithdrawOnLoad ? 1 : 0;
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
      backgroundColor: kColorLavenderBg,
      appBar: CommonAppBarWidget(
        title: 'Wallet',
        subtitle: _walletTab == 0
            ? 'Buy coins for gifts, calls & perks'
            : 'Cash out diamonds',
        actions: [
          GestureDetector(
            onTap: () => Get.toNamed(Routes.TRANSACTION_HISTORY),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: kColorWhite.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: kColorWhite.withValues(alpha: 0.32)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_rounded, size: 17, color: kColorWhite),
                  SizedBox(width: 5),
                  SemiBoldText(
                    text: 'History',
                    fontSize: 11,
                    color: kColorWhite,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _balanceOverviewCard(),
            const SizedBox(height: 14),
            _walletTabs(),
            const SizedBox(height: 16),
            if (_walletTab == 0) ..._purchaseTab(),
            if (_walletTab == 1) ..._withdrawTab(),
          ],
        ),
      ),
    );
  }

  Widget _walletTabs() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppLightUi.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppLightUi.border),
        boxShadow: AppLightUi.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: _walletTabButton(
              index: 0,
              icon: Icons.shopping_bag_outlined,
              label: 'Purchase',
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _walletTabButton(
              index: 1,
              icon: Icons.account_balance_wallet_outlined,
              label: 'Withdraw',
            ),
          ),
        ],
      ),
    );
  }

  Widget _walletTabButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final selected = _walletTab == index;
    return GestureDetector(
      onTap: () {
        if (_walletTab == index) return;
        setState(() => _walletTab = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          gradient: selected ? AppLightUi.ctaGradient : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? kColorWhite : AppLightUi.subtitle,
            ),
            const SizedBox(width: 6),
            SemiBoldText(
              text: label,
              fontSize: TextStyles.k12FontSize,
              color: selected ? kColorWhite : AppLightUi.subtitle,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _purchaseTab() {
    return [
      _vipTopUpBanner(),
      const SizedBox(height: 18),
      _sectionTitle(icon: Icons.layers_rounded, title: 'Choose Top Up Package'),
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
      Obx(() => _earnedDollarsCard()),
      const SizedBox(height: 14),
      _trustFooter(),
    ];
  }

  List<Widget> _withdrawTab() {
    return [
      Obx(() => _withdrawHeroCard()),
      const SizedBox(height: 14),
      _walletGlassPanel(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: Obx(() => _withdrawHistoryPreview()),
        ),
      ),
    ];
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            child: Column(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppLightUi.violet.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.layers_outlined,
                    color: AppLightUi.violet,
                    size: 22,
                  ),
                ),
                Spacing.v10,
                AppText(
                  text: controller.packageError.value.isNotEmpty
                      ? controller.packageError.value
                      : 'No coin packages found.',
                  fontSize: TextStyles.k12FontSize,
                  color: AppLightUi.subtitle,
                  align: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }
      final packages = controller.packages;
      final displayIndexes = List<int>.generate(
        packages.length,
        (index) => index,
      )..sort((a, b) => packages[b].amount.compareTo(packages[a].amount));

      // Coins per currency unit drives the real "Best value" / "Save %" labels.
      double rateOf(CoinPackage p) => p.price > 0 ? p.amount / p.price : 0;
      final rates = packages.map(rateOf).where((r) => r > 0).toList();
      final bestRate = rates.isEmpty ? 0.0 : rates.reduce(math.max);
      final baseRate = rates.isEmpty ? 0.0 : rates.reduce(math.min);
      final showBest = rates.length > 1 && bestRate > baseRate;

      final textScale = MediaQuery.textScalerOf(
        context,
      ).scale(1).clamp(1.0, 1.35);

      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = width >= 900
              ? 4
              : width >= 560
              ? 3
              : 2;
          final compact = width / columns < 160;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayIndexes.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: (compact ? 176 : 188) * textScale,
            ),
            itemBuilder: (_, index) {
              final planIndex = displayIndexes[index];
              final plan = packages[planIndex];
              final rate = rateOf(plan);
              final savePercent = baseRate > 0 && rate > baseRate
                  ? ((rate / baseRate - 1) * 100).round()
                  : 0;
              return Obx(() {
                final isSelected =
                    controller.selectedPlanIndex.value == planIndex;
                return _coinPlanCard(
                  plan: plan,
                  index: planIndex,
                  isSelected: isSelected,
                  isBestValue: showBest && rate == bestRate,
                  savePercent: savePercent,
                  tier: index < 2
                      ? 3
                      : index < 4
                      ? 2
                      : 1,
                  compact: compact,
                );
              });
            },
          );
        },
      );
    });
  }

  Widget _balanceOverviewCard() {
    return GlossyDatingCard(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final orb = constraints.maxWidth < 330 ? 42.0 : 52.0;
          return Obx(
            () => Row(
              children: [
                Expanded(
                  child: _topBalanceItem(
                    title: 'My Coins',
                    value: controller.coinBalance.value,
                    accent: kColorWalletAmount,
                    orbSize: orb,
                    icon: AppCoinIcon(
                      size: orb * 0.58,
                      color: kColorWalletAmount,
                    ),
                  ),
                ),
                Container(width: 1, height: 44, color: AppLightUi.border),
                Expanded(
                  child: _topBalanceItem(
                    title: 'My Diamonds',
                    value: controller.diamondBalance.value,
                    accent: AppLightUi.cyan,
                    orbSize: orb,
                    icon: Icon(
                      Icons.diamond_rounded,
                      size: orb * 0.52,
                      color: AppLightUi.cyan,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _topBalanceItem({
    required String title,
    required String value,
    required Color accent,
    required Widget icon,
    double orbSize = 52,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          Container(
            width: orbSize,
            height: orbSize,
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
                  color: AppLightUi.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: AppLightUi.familyCtaGradient,
          boxShadow: [
            BoxShadow(
              color: AppLightUi.pink.withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _vipBadge(size: 48),
                const SizedBox(width: 12),
                const Expanded(
                  child: SemiBoldText(
                    text: 'Become VIP & Get More',
                    fontSize: TextStyles.k16FontSize,
                    color: kColorWhite,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            Spacing.v10,
            _vipBenefit('10% extra on every top up'),
            _vipBenefit('Exclusive gifts and badges'),
            _vipBenefit('VIP support and priority'),
            Spacing.v8,
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: kColorWhite.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SemiBoldText(
                      text: 'View',
                      fontSize: TextStyles.k12FontSize,
                      color: AppLightUi.title,
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppLightUi.title,
                      size: 10,
                    ),
                  ],
                ),
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
          Icon(
            Icons.check_circle_rounded,
            size: 12,
            color: kColorWhite.withValues(alpha: 0.95),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: AppText(
              text: text,
              fontSize: 11,
              color: kColorWhite.withValues(alpha: 0.92),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
          color: AppLightUi.title,
        ),
      ],
    );
  }

  Widget _coinPlanCard({
    required CoinPackage plan,
    required int index,
    required bool isSelected,
    required bool isBestValue,
    required int savePercent,
    required int tier,
    required bool compact,
  }) {
    return GestureDetector(
      onTap: () => controller.selectedPlanIndex.value = index,
      child: AnimatedScale(
        scale: isSelected ? 1.0 : 0.97,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: isSelected
                ? AppLightUi.familyCtaGradient
                : GlossyDatingCard.defaultBorderGradient,
            boxShadow: [
              BoxShadow(
                color: (isSelected ? AppLightUi.pink : AppLightUi.violet)
                    .withValues(alpha: isSelected ? 0.28 : 0.08),
                blurRadius: isSelected ? 18 : 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: EdgeInsets.all(isSelected ? 2 : 1.2),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.4),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  isSelected ? const Color(0xFFFFF4FA) : AppLightUi.card,
                  AppLightUi.card,
                ],
              ),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    10,
                    isBestValue ? 22 : 14,
                    10,
                    10,
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: compact ? 36 : 42,
                        child: _coinStackGraphic(tier),
                      ),
                      const Spacer(),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: BoldText(
                          text: _formatPlanAmount(plan.amount),
                          fontSize: compact
                              ? TextStyles.k16FontSize
                              : TextStyles.k18FontSize,
                          color: kColorWalletAmount,
                        ),
                      ),
                      const AppText(
                        text: 'Coins',
                        fontSize: TextStyles.k10FontSize,
                        color: AppLightUi.subtitle,
                      ),
                      Spacing.v4,
                      SizedBox(
                        height: 18,
                        child: savePercent > 0
                            ? _extraBadge('Save $savePercent%')
                            : null,
                      ),
                      Spacing.v8,
                      _planPriceButton(plan, index, isSelected),
                    ],
                  ),
                ),
                if (isBestValue)
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF2E83), Color(0xFFFF8A48)],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            size: 10,
                            color: kColorWhite,
                          ),
                          SizedBox(width: 3),
                          SemiBoldText(
                            text: 'BEST VALUE',
                            fontSize: 8,
                            color: kColorWhite,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (isSelected)
                  const Positioned(
                    right: 6,
                    top: 6,
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: AppLightUi.pink,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _planPriceButton(CoinPackage plan, int index, bool isSelected) {
    return SizedBox(
      width: double.infinity,
      height: 34,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFFFD84E), Color(0xFFFF9C2A)],
                )
              : AppLightUi.familyCtaGradient,
        ),
        child: TextButton(
          onPressed: controller.isBuying.value
              ? null
              : () {
                  controller.selectedPlanIndex.value = index;
                  _openCheckoutBottomSheet(plan);
                },
          style: TextButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: isSelected ? AppLightUi.title : kColorWhite,
            disabledBackgroundColor: Colors.transparent,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SemiBoldText(
              text: controller.isBuying.value
                  ? '...'
                  : controller.purchasePrice(plan),
              fontSize: TextStyles.k12FontSize,
              color: isSelected ? AppLightUi.title : kColorWhite,
            ),
          ),
        ),
      ),
    );
  }

  /// Bigger packages get a taller coin pile (tier 1–3).
  Widget _coinStackGraphic(int tier) {
    final coins = tier.clamp(1, 3);
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 100,
        height: 44,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 96,
              height: 30,
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppLightUi.violet.withValues(alpha: 0.14),
                    AppLightUi.pink.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            if (coins >= 2)
              Positioned(left: 18, bottom: 6, child: _coinDisc(22)),
            Positioned(left: 37, bottom: 9, child: _coinDisc(26)),
            if (coins >= 2)
              Positioned(left: 58, bottom: 6, child: _coinDisc(22)),
            if (coins >= 3)
              Positioned(left: 40, bottom: 26, child: _coinDisc(18)),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1FB57A), Color(0xFF2BC48A)],
        ),
        borderRadius: BorderRadius.circular(7),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SemiBoldText(text: text, fontSize: 10, color: kColorWhite),
      ),
    );
  }

  String _formatPlanAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  void _openCheckoutBottomSheet(CoinPackage plan) {
    if (controller.usesGooglePlay) {
      Get.bottomSheet(
        Builder(
          builder: (context) {
            return Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.9,
              ),
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                color: AppLightUi.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                  child: Obx(() {
                    final billing = controller.billing;
                    final available =
                        billing != null &&
                        billing.enabled &&
                        billing.products.containsKey(plan.googlePlayProductId);
                    final busy = (billing?.busy.value ?? false);
                    final message =
                        billing?.message.value ??
                        'Coin purchases are temporarily unavailable.';
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppLightUi.borderStrong,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Top up your coins',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppLightUi.title,
                                ),
                              ),
                            ),
                            IconButton.filledTonal(
                              tooltip: 'Close',
                              onPressed: () => Navigator.of(context).pop(),
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFF5F0FA),
                                foregroundColor: AppLightUi.subtitle,
                              ),
                              icon: const Icon(Icons.close_rounded, size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFF2EBFF), Color(0xFFFFEFF6)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFECE0F5)),
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 76,
                                width: 136,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Positioned(
                                      left: 6,
                                      bottom: 5,
                                      child: Transform.rotate(
                                        angle: -0.18,
                                        child: _coinDisc(46),
                                      ),
                                    ),
                                    Positioned(
                                      right: 6,
                                      bottom: 5,
                                      child: Transform.rotate(
                                        angle: 0.18,
                                        child: _coinDisc(46),
                                      ),
                                    ),
                                    Positioned(top: 0, child: _coinDisc(62)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _formatPlanAmount(plan.amount),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 36,
                                  height: 1.1,
                                  fontWeight: FontWeight.w800,
                                  color: AppLightUi.title,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Qobo Coins',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppLightUi.body,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Send gifts. Share a little joy.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppLightUi.subtitle,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppLightUi.subtitle,
                                ),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                controller.purchasePrice(plan),
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppLightUi.title,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'One-time purchase · No subscription',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppLightUi.subtitle,
                          ),
                        ),
                        if (message.trim().isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F2FB),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  size: 18,
                                  color: AppLightUi.violet,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    message,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.4,
                                      color: AppLightUi.body,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: available && !busy
                                ? AppLightUi.familyCtaGradient
                                : null,
                            color: const Color(0xFFE5DCEA),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              disabledBackgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              disabledForegroundColor: AppLightUi.subtitle,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed: available && !busy
                                ? () => controller.buyWithGooglePlay(plan)
                                : null,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (busy)
                                  const SizedBox(
                                    width: 19,
                                    height: 19,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppLightUi.subtitle,
                                    ),
                                  )
                                else
                                  const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 20,
                                  ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    busy
                                        ? 'Opening checkout…'
                                        : 'Continue with Google Play',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Payment handled by Google Play',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppLightUi.subtitle,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextButton.icon(
                          onPressed: busy
                              ? null
                              : () => controller.refreshPurchases(),
                          icon: const Icon(Icons.refresh_rounded, size: 17),
                          label: const Text('Refresh purchases'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppLightUi.subtitle,
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            );
          },
        ),
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
      );
      return;
    }
    Get.bottomSheet(
      Builder(
        builder: (context) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.86,
            ),
            decoration: BoxDecoration(
              color: AppLightUi.card,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(color: AppLightUi.border),
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
                          color: AppLightUi.borderStrong,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Spacing.v16,
                    const Center(
                      child: SemiBoldText(
                        text: 'Select Payment Method',
                        fontSize: 16,
                        color: AppLightUi.title,
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
                    const Divider(color: AppLightUi.border, height: 16),
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
                    const Divider(color: AppLightUi.border, height: 16),
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
                    const Divider(color: AppLightUi.border, height: 16),
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
      title: SemiBoldText(text: title, fontSize: 13, color: AppLightUi.title),
      subtitle: subtitle == null
          ? null
          : AppText(text: subtitle, fontSize: 11, color: AppLightUi.subtitle),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        color: AppLightUi.muted,
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
          backgroundColor: AppLightUi.card,
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
                    color: AppLightUi.title,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Added ${plan.coinsLabel} to your account via $method.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppLightUi.body, fontSize: 13),
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
    if (controller.usesGooglePlay) {
      return _paymentMethodRow(
        mark: 'G',
        title: 'Google Play',
        subtitle: 'Choose a coin pack to view payment options',
        accent: AppLightUi.violet,
        onTap: () {
          final plan = controller.selectedPackage;
          if (plan != null) _openCheckoutBottomSheet(plan);
        },
      );
    }
    return Container(
      decoration: AppLightUi.cardDecoration(radius: 18),
      child: Column(
        children: [
          _paymentMethodRow(
            mark: 'R',
            title: 'Razorpay',
            subtitle: 'UPI, cards and wallets',
            accent: const Color(0xFFFF2E83),
            onTap: () {
              final plan = controller.selectedPackage;
              if (plan != null) {
                _openCheckoutBottomSheet(plan);
                return;
              }
              Get.snackbar(
                'Choose a package',
                'Select a coin package, then pay with Razorpay.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.black87,
                colorText: kColorWhite,
              );
            },
          ),
          const Divider(height: 1, color: AppLightUi.border),
          _paymentMethodRow(
            mark: 'G',
            title: 'Google Pay',
            subtitle: 'Coming soon',
            accent: const Color(0xFF5B8DEF),
          ),
          const Divider(height: 1, color: AppLightUi.border),
          _paymentMethodRow(
            mark: 'P',
            title: 'Paytm',
            subtitle: 'Coming soon',
            accent: const Color(0xFF7B5CFF),
          ),
        ],
      ),
    );
  }

  Widget _paymentMethodRow({
    required String mark,
    required String title,
    required String subtitle,
    required Color accent,
    VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: enabled ? 0.14 : 0.08),
                ),
                child: SemiBoldText(
                  text: mark,
                  fontSize: TextStyles.k16FontSize,
                  color: enabled ? accent : AppLightUi.muted,
                ),
              ),
              Spacing.h12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemiBoldText(
                      text: title,
                      fontSize: TextStyles.k14FontSize,
                      color: enabled ? AppLightUi.title : AppLightUi.muted,
                      maxLines: 1,
                    ),
                    Spacing.v2,
                    AppText(
                      text: subtitle,
                      fontSize: TextStyles.k12FontSize,
                      color: AppLightUi.subtitle,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              Spacing.h8,
              if (enabled)
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: AppLightUi.ctaGradient,
                  ),
                  child: const SemiBoldText(
                    text: 'Pay',
                    fontSize: TextStyles.k12FontSize,
                    color: kColorWhite,
                  ),
                )
              else
                Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppLightUi.cardSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const SemiBoldText(
                    text: 'Soon',
                    fontSize: TextStyles.k10FontSize,
                    color: AppLightUi.subtitle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trustFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppLightUi.card,
        border: Border.all(color: AppLightUi.border),
        boxShadow: AppLightUi.cardShadow,
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
          Expanded(
            child: _trustItem(
              icon: Icons.flash_on_rounded,
              title: 'Instant Credit',
              subtitle: 'Fast coins',
            ),
          ),
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
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFF75FF), size: 20),
        const SizedBox(height: 6),
        SemiBoldText(
          text: title,
          fontSize: TextStyles.k10FontSize,
          color: AppLightUi.title,
          align: TextAlign.center,
          maxLines: 2,
        ),
        const SizedBox(height: 2),
        AppText(
          text: subtitle,
          fontSize: TextStyles.k10FontSize,
          color: AppLightUi.subtitle,
          align: TextAlign.center,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _walletGlassPanel({required Widget child, double? height}) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: AppLightUi.cardDecoration(radius: 18),
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
                  color: AppLightUi.title,
                ),
                Spacing.v2,
                AppText(
                  text: '10,000 coins = \$1.00 USD',
                  fontSize: TextStyles.k10FontSize,
                  color: AppLightUi.subtitle,
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

  Widget _withdrawHeroCard() {
    final isLoading = controller.isLoadingWithdrawConfig.value;
    final isEligible = controller.isEligibleForWithdrawThisWeek.value;
    final hasTiers = controller.allowedWithdrawTiers.isNotEmpty;
    final canWithdraw = !isLoading && hasTiers;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7B5CFF), Color(0xFFFF2E83)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppLightUi.pink.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            text: 'Available to withdraw',
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite,
          ),
          Spacing.v4,
          SemiBoldText(
            text:
                '${controller.withdrawCurrencySymbol.value}${controller.withdrawableBalance.value}',
            fontSize: TextStyles.k22FontSize,
            color: kColorWhite,
            maxLines: 1,
          ),
          Spacing.v4,
          AppText(
            text: 'Diamonds in wallet: ${controller.diamondBalance.value}',
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite.withValues(alpha: 0.88),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Spacing.v12,
          Row(
            children: [
              Expanded(
                child: _withdrawFact(
                  label: 'Minimum diamonds',
                  value: controller.withdrawalLimit.value,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _withdrawFact(
                  label: 'This week',
                  value: isLoading
                      ? 'Loading'
                      : isEligible
                      ? 'Ready'
                      : 'Requested',
                ),
              ),
            ],
          ),
          Spacing.v12,
          SizedBox(
            width: double.infinity,
            height: 46,
            child: TextButton(
              onPressed: canWithdraw ? _openWithdrawBottomSheet : null,
              style: TextButton.styleFrom(
                backgroundColor: canWithdraw
                    ? kColorWhite
                    : kColorWhite.withValues(alpha: 0.35),
                disabledBackgroundColor: kColorWhite.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: SemiBoldText(
                text: isLoading ? 'Loading' : 'Withdraw',
                fontSize: TextStyles.k14FontSize,
                color: canWithdraw ? AppLightUi.title : AppLightUi.muted,
              ),
            ),
          ),
          Spacing.v10,
          AppText(
            text: isEligible
                ? 'Pick an amount, then add UPI or your bank account.'
                : 'You have already requested a weekly withdrawal.',
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite.withValues(alpha: 0.9),
          ),
        ],
      ),
    );
  }

  Widget _withdrawFact({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            text: label,
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite.withValues(alpha: 0.86),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Spacing.v4,
          SemiBoldText(
            text: value,
            fontSize: TextStyles.k14FontSize,
            color: kColorWhite,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
            height: MediaQuery.of(context).size.height * 0.86,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: AppLightUi.card,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  _withdrawSheetHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Obx(
                        () => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _withdrawSummaryRow(),
                            if (!controller
                                .isEligibleForWithdrawThisWeek
                                .value) ...[
                              Spacing.v12,
                              _withdrawInfoBanner(
                                icon: Icons.event_busy_rounded,
                                text:
                                    'You have already requested a weekly withdrawal.',
                                color: Colors.orangeAccent,
                              ),
                            ],
                            Spacing.v16,
                            const SemiBoldText(
                              text: 'Select amount',
                              fontSize: TextStyles.k14FontSize,
                              color: AppLightUi.title,
                            ),
                            Spacing.v10,
                            _withdrawTierGrid(),
                            Spacing.v16,
                            const SemiBoldText(
                              text: 'Payout details',
                              fontSize: TextStyles.k14FontSize,
                              color: AppLightUi.title,
                            ),
                            Spacing.v6,
                            const AppText(
                              text:
                                  'Add a UPI ID, or a bank account number with IFSC.',
                              fontSize: TextStyles.k12FontSize,
                              color: AppLightUi.subtitle,
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
                            Spacing.v16,
                            _withdrawHistoryPreview(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Obx(() => _withdrawSubmitButton()),
                ],
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _withdrawSheetHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(gradient: AppLightUi.familyCtaGradient),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: kColorWhite.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Spacing.v12,
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: kColorWhite,
                size: 22,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemiBoldText(
                      text: 'Withdraw',
                      fontSize: TextStyles.k18FontSize,
                      color: kColorWhite,
                    ),
                    SizedBox(height: 2),
                    AppText(
                      text: 'Send diamonds to UPI or your bank',
                      fontSize: TextStyles.k12FontSize,
                      color: kColorWhite,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _withdrawSubmitButton() {
    final busy = controller.isSubmittingWithdrawal.value;
    final enabled = !busy && controller.isEligibleForWithdrawThisWeek.value;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: AppLightUi.card,
        border: Border(top: BorderSide(color: AppLightUi.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: enabled ? AppLightUi.ctaGradient : null,
            color: enabled ? null : AppLightUi.border,
          ),
          child: TextButton(
            onPressed: enabled ? _submitWithdrawRequest : null,
            style: TextButton.styleFrom(
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: kColorWhite,
                      strokeWidth: 2,
                    ),
                  )
                : SemiBoldText(
                    text: 'Submit Request',
                    fontSize: TextStyles.k14FontSize,
                    color: enabled ? kColorWhite : AppLightUi.muted,
                  ),
          ),
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppLightUi.cardSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppLightUi.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            text: label,
            fontSize: TextStyles.k10FontSize,
            color: AppLightUi.subtitle,
            maxLines: 1,
          ),
          Spacing.v4,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: SemiBoldText(
              text: value,
              fontSize: TextStyles.k16FontSize,
              color: kColorWalletAmount,
              maxLines: 1,
            ),
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
              color: AppLightUi.body,
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
        color: AppLightUi.subtitle,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final width = (constraints.maxWidth - gap * 2) / 3;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: tiers.map((tier) {
            final selected = controller.selectedWithdrawTier.value == tier;
            return GestureDetector(
              onTap: () => controller.selectWithdrawTier(tier),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: width,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: selected ? AppLightUi.ctaGradient : null,
                  color: selected ? null : AppLightUi.cardSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? Colors.transparent : AppLightUi.border,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SemiBoldText(
                    text: controller.tierLabel(tier),
                    fontSize: TextStyles.k14FontSize,
                    color: selected ? kColorWhite : AppLightUi.title,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
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
        colors: AppLightUi.title,
      ),
      cursorColor: kColorWalletAmount,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppLightUi.subtitle),
        labelStyle: TextStyles.kRegularPoppins(
          fontSize: TextStyles.k12FontSize,
          colors: AppLightUi.subtitle,
        ),
        hintStyle: TextStyles.kRegularPoppins(
          fontSize: TextStyles.k12FontSize,
          colors: AppLightUi.hint,
        ),
        filled: true,
        fillColor: AppLightUi.cardSoft,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppLightUi.border),
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
                color: AppLightUi.title,
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
            color: AppLightUi.subtitle,
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
                      color: AppLightUi.cardSoft,
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
                                color: AppLightUi.title,
                              ),
                              Spacing.v2,
                              AppText(
                                text: _withdrawHistorySubtitle(item),
                                fontSize: TextStyles.k10FontSize,
                                color: AppLightUi.subtitle,
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
        backgroundColor: AppLightUi.card,
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
                color: AppLightUi.title,
              ),
              Spacing.v8,
              AppText(
                text:
                    'Withdrawal request ${result.transactionId} is ${result.status.toLowerCase()}.',
                fontSize: TextStyles.k12FontSize,
                color: AppLightUi.subtitle,
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
        backgroundColor: AppLightUi.card,
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
                color: AppLightUi.title,
              ),
              Spacing.v8,
              AppText(
                text: message,
                fontSize: TextStyles.k12FontSize,
                color: AppLightUi.subtitle,
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
