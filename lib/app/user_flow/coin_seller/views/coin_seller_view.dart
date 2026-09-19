import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/controllers/coin_seller_controller.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/models/seller_sale.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/widgets/coin_seller_transaction_actions_sheet.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/widgets/coin_seller_ui_kit.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_coin_icon.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

class CoinSellerView extends GetView<CoinSellerController> {
  const CoinSellerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorLavenderBg,
      resizeToAvoidBottomInset: true,
      appBar: PreferredSize(
        preferredSize: const CommonAppBarWidget(title: 'Merchant Hub').preferredSize,
        child: Obx(() {
          final label = controller.sellerLabel.value.trim();
          final showRefresh =
              controller.screenState.value == CoinSellerScreenState.approved;
          return CommonAppBarWidget(
            title: 'Merchant Hub',
            subtitle: label.isEmpty ? null : label,
            actions: showRefresh
                ? [
                    IconButton(
                      onPressed: () => _runDismissKeyboard(
                        context,
                        controller.loadDashboard,
                      ),
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: kColorWhite,
                        size: 24,
                      ),
                    ),
                  ]
                : null,
          );
        }),
      ),
      body: GestureDetector(
        onTap: _dismissKeyboard,
        behavior: HitTestBehavior.deferToChild,
        child: CoinSellerUi.pageBackground(
          child: Obx(() {
            if (controller.isBootstrapping.value ||
                controller.screenState.value == CoinSellerScreenState.checking) {
              return const Center(
                child: CircularProgressIndicator(color: CoinSellerUi.gold),
              );
            }
            return _bodyForState(context, controller.screenState.value);
          }),
        ),
      ),
    );
  }

  void _dismissKeyboard([_]) {
    final focus = FocusManager.instance.primaryFocus;
    if (focus != null && focus.hasFocus) {
      focus.unfocus();
    }
  }

  void _runDismissKeyboard(BuildContext context, VoidCallback action) {
    _dismissKeyboard();
    action();
  }

  Widget _bodyForState(BuildContext context, CoinSellerScreenState state) {
    switch (state) {
      case CoinSellerScreenState.checking:
        return const SizedBox.shrink();
      case CoinSellerScreenState.apply:
        return _buildApplyForm(context);
      case CoinSellerScreenState.pending:
        return _buildPendingState(context);
      case CoinSellerScreenState.approved:
        return _buildApprovedDashboard(context);
    }
  }

  Widget _buildApplyForm(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(16),
      child: _glassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _heroBadge(
              icon: Icons.storefront_rounded,
              title: 'Become a verified merchant',
              subtitle: 'Sell coins P2P after admin approval',
            ),
            Spacing.v16,
            const AppText(
              text:
                  'Apply with your logged-in account. Once approved, transfer '
                  'coins to buyers and manage your sales ledger from here.',
              fontSize: 12,
              color: CoinSellerUi.body,
            ),
            Spacing.v20,
            AppTextField(
              controller: controller.detailsController,
              hintText: 'Payment methods & region (JazzCash, bank, etc.)',
              maxLines: 4,
              textInputType: TextInputType.multiline,
              fillColor: kColorWhite,
              borderColor: CoinSellerUi.borderStrong,
              textStyle: TextStyles.kRegularPoppins(
                colors: CoinSellerUi.title,
                fontSize: 13,
              ),
              hintStyle: TextStyles.kRegularPoppins(
                colors: CoinSellerUi.body,
                fontSize: 13,
              ),
            ),
            Spacing.v24,
            Obx(
              () => SizedBox(
                width: double.infinity,
                height: 50,
                child: appButton(
                  onPressed: () => _runDismissKeyboard(
                    context,
                    controller.applyToBecomeSeller,
                  ),
                  buttonText: controller.isApplying.value
                      ? 'Submitting…'
                      : 'Apply now',
                  isGradient: true,
                  borderRadius: 14,
                ),
              ),
            ),
            Spacing.v10,
            Center(
              child: TextButton(
                onPressed: () => _runDismissKeyboard(
                  context,
                  () => controller.loadDashboard(isShowLoader: true),
                ),
                child: const AppText(
                  text: 'Already approved? Refresh status',
                  fontSize: 12,
                  color: CoinSellerUi.gold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _glassPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      CoinSellerUi.gold.withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  color: CoinSellerUi.gold,
                  size: 36,
                ),
              ),
              Spacing.v16,
              const SemiBoldText(
                text: 'Application under review',
                fontSize: 17,
                color: CoinSellerUi.title,
              ),
              Spacing.v8,
              const AppText(
                text:
                    'Your request was submitted. An admin will review it soon. '
                    'Tap below once you are approved.',
                fontSize: 12,
                color: CoinSellerUi.body,
                align: TextAlign.center,
              ),
              Spacing.v20,
              SizedBox(
                width: double.infinity,
                height: 48,
                child: appButton(
                  onPressed: () => _runDismissKeyboard(
                    context,
                    () => controller.loadDashboard(),
                  ),
                  buttonText: 'Check approval status',
                  isGradient: true,
                  borderRadius: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApprovedDashboard(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _stockHero(),
          ),
          Spacing.v12,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _tabBar(context),
          ),
          Spacing.v8,
          Expanded(
            child: TabBarView(
              children: [
                _transferPanel(context),
                _transactionsPanel(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stockHero() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: kColorWhite,
        border: Border.all(color: CoinSellerUi.borderStrong),
        boxShadow: AppLightUi.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: CoinSellerUi.sellButtonGradient,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: AppLightUi.iconTileDecoration(
                              CoinSellerUi.violet,
                              radius: 11,
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 17,
                              color: CoinSellerUi.violet,
                            ),
                          ),
                          Spacing.h8,
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SemiBoldText(
                                  text: 'Merchant wallet',
                                  fontSize: 13,
                                  color: CoinSellerUi.title,
                                ),
                                AppText(
                                  text: 'Available stock',
                                  fontSize: 11,
                                  color: CoinSellerUi.body,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 28,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: AppLightUi.familyCtaGradient,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  color: kColorWhite,
                                  size: 13,
                                ),
                                SizedBox(width: 4),
                                SemiBoldText(
                                  text: 'Verified',
                                  fontSize: 10,
                                  color: kColorWhite,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Spacing.v12,
                      Obx(
                        () => Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Flexible(
                              child: ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                  colors: [
                                    Color(0xFFFFD54F),
                                    CoinSellerUi.gold,
                                    CoinSellerUi.goldDeep,
                                  ],
                                ).createShader(bounds),
                                child: BoldText(
                                  text: CoinSellerUi.formatCoins(
                                    controller.availableCoins.value,
                                  ),
                                  fontSize: 34,
                                  color: kColorWhite,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 6, bottom: 6),
                              child: AppText(
                                text: 'coins',
                                fontSize: 13,
                                color: CoinSellerUi.body,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Spacing.v6,
                      const AppText(
                        text: 'Ready to transfer to buyers instantly',
                        fontSize: 12,
                        color: CoinSellerUi.body,
                      ),
                    ],
                  ),
                ),
                Spacing.h10,
                _stockCoinBadge(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Obx(
              () => Row(
                children: [
                  _heroMiniStat(
                    icon: Icons.payments_rounded,
                    label: 'Revenue',
                    value:
                        '₹${CoinSellerUi.formatMoney(controller.totalRevenue.value)}',
                    color: CoinSellerUi.mint,
                  ),
                  Spacing.h8,
                  _heroMiniStat(
                    icon: Icons.toll_rounded,
                    label: 'Sold',
                    value: CoinSellerUi.formatCoins(
                      controller.totalCoinsSold.value,
                    ),
                    color: CoinSellerUi.gold,
                  ),
                  Spacing.h8,
                  _heroMiniStat(
                    icon: Icons.receipt_long_rounded,
                    label: 'Sales',
                    value: '${controller.totalTransactions.value}',
                    color: CoinSellerUi.sky,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stockCoinBadge() {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppLightUi.glossRingGradient,
        boxShadow: [
          BoxShadow(
            color: CoinSellerUi.pink.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2.5),
      child: const DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFFFFBF5),
        ),
        child: Center(
          child: AppCoinIcon(size: 36, color: CoinSellerUi.gold),
        ),
      ),
    );
  }

  Widget _heroMiniStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 15, color: color),
            Spacing.v4,
            SemiBoldText(
              text: value,
              fontSize: 12,
              color: CoinSellerUi.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Spacing.v2,
            AppText(
              text: label,
              fontSize: 10,
              color: CoinSellerUi.body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabBar(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CoinSellerUi.cardSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CoinSellerUi.borderStrong),
        boxShadow: AppLightUi.cardShadow,
      ),
      child: TabBar(
        onTap: (_) => _dismissKeyboard(),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          gradient: CoinSellerUi.sellButtonGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CoinSellerUi.pink.withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        labelColor: kColorWhite,
        unselectedLabelColor: CoinSellerUi.body,
        labelStyle: TextStyles.kSemiBoldPoppins(fontSize: 12),
        unselectedLabelStyle: TextStyles.kSemiBoldPoppins(fontSize: 12),
        tabs: const [
          Tab(text: 'Sell coins'),
          Tab(text: 'Transactions'),
        ],
      ),
    );
  }

  Widget _transferPanel(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: _glassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: AppLightUi.iconTileDecoration(
                    CoinSellerUi.pink,
                    radius: 12,
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    size: 20,
                    color: CoinSellerUi.pink,
                  ),
                ),
                Spacing.h10,
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SemiBoldText(
                        text: 'Quick transfer',
                        fontSize: 15,
                        color: CoinSellerUi.title,
                      ),
                      AppText(
                        text: 'Pick a buyer, then enter coins and price.',
                        fontSize: 11,
                        color: CoinSellerUi.body,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Spacing.v16,
            _buyerSelector(context),
            Spacing.v12,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _field(
                    AppCoinIcon(size: 18, color: CoinSellerUi.gold),
                    controller.coinsController,
                    'Coins',
                    number: true,
                  ),
                ),
                Spacing.h10,
                Expanded(
                  child: _field(
                    Icon(
                      Icons.currency_rupee_rounded,
                      size: 18,
                      color: CoinSellerUi.mint,
                    ),
                    controller.priceController,
                    'Price (INR)',
                    decimal: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [
                    CoinSellerUi.violet.withValues(alpha: 0.08),
                    CoinSellerUi.pink.withValues(alpha: 0.06),
                  ],
                ),
                border: Border.all(
                  color: CoinSellerUi.violet.withValues(alpha: 0.22),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.shield_moon_rounded,
                    size: 16,
                    color: CoinSellerUi.violet,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: AppText(
                      text:
                          'You will confirm the transfer before coins are sent.',
                      fontSize: 12,
                      color: CoinSellerUi.title,
                    ),
                  ),
                ],
              ),
            ),
            Spacing.v16,
            Obx(
              () => SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: CoinSellerUi.sellButtonGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: CoinSellerUi.pink.withValues(alpha: 0.32),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: controller.isTransferring.value
                          ? null
                          : () => _runDismissKeyboard(
                                context,
                                controller.transferCoins,
                              ),
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!controller.isTransferring.value) ...[
                              const Icon(
                                Icons.send_rounded,
                                size: 18,
                                color: kColorWhite,
                              ),
                              Spacing.h8,
                            ],
                            SemiBoldText(
                              text: controller.isTransferring.value
                                  ? 'Transferring…'
                                  : 'Transfer now',
                              fontSize: 14,
                              color: kColorWhite,
                            ),
                          ],
                        ),
                      ),
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

  Widget _buyerSelector(BuildContext context) {
    return Obx(() {
      final buyer = controller.selectedBuyer.value;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _runDismissKeyboard(context, controller.openBuyerPicker),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: kColorWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: buyer != null
                    ? CoinSellerUi.gold.withValues(alpha: 0.45)
                    : CoinSellerUi.borderStrong,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: CoinSellerUi.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: CoinSellerUi.border),
                  ),
                  alignment: Alignment.center,
                  child: buyer == null
                      ? const Icon(
                          Icons.person_search_rounded,
                          size: 18,
                          color: CoinSellerUi.gold,
                        )
                      : AppUserAvatar(
                          name: buyer.name,
                          imageUrl: buyer.displayPicture,
                          size: 36,
                        ),
                ),
                Spacing.h10,
                Expanded(
                  child: buyer == null
                      ? const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SemiBoldText(
                              text: 'Select buyer',
                              fontSize: 13,
                              color: CoinSellerUi.title,
                            ),
                            AppText(
                              text: 'Friends, followers, or search',
                              fontSize: 11,
                              color: CoinSellerUi.body,
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SemiBoldText(
                              text: buyer.name,
                              fontSize: 13,
                              color: CoinSellerUi.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            AppText(
                              text: buyer.id,
                              fontSize: 11,
                              color: CoinSellerUi.body,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                ),
                if (buyer != null)
                  IconButton(
                    onPressed: () => _runDismissKeyboard(
                      context,
                      controller.clearSelectedBuyer,
                    ),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: CoinSellerUi.muted,
                      size: 18,
                    ),
                    visualDensity: VisualDensity.compact,
                  )
                else
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: CoinSellerUi.muted,
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _field(
    Widget prefixIcon,
    TextEditingController ctrl,
    String hint, {
    bool number = false,
    bool decimal = false,
  }) {
    return AppTextField(
      controller: ctrl,
      hintText: hint,
      textInputType: number
          ? TextInputType.number
          : decimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _dismissKeyboard(),
      fillColor: kColorWhite,
      borderColor: CoinSellerUi.borderStrong,
      textStyle: TextStyles.kRegularPoppins(
        colors: CoinSellerUi.title,
        fontSize: 13,
      ),
      hintStyle: TextStyles.kRegularPoppins(
        colors: CoinSellerUi.body,
        fontSize: 13,
      ),
      prefix: Padding(
        padding: const EdgeInsets.only(left: 12, right: 8),
        child: prefixIcon,
      ),
    );
  }

  Widget _transactionsPanel(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Obx(() => Row(
                children: [
                  _filterChip(context, 'All', CoinSellerTransactionFilter.all),
                  Spacing.h8,
                  _filterChip(
                    context,
                    'Completed',
                    CoinSellerTransactionFilter.completed,
                  ),
                  Spacing.h8,
                  _filterChip(
                    context,
                    'Reversed',
                    CoinSellerTransactionFilter.reversed,
                  ),
                ],
              )),
        ),
        Spacing.v8,
        Expanded(
          child: Obx(() {
            final sales = controller.filteredSales;
            if (controller.isLoadingTransactions.value && sales.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: CoinSellerUi.gold),
              );
            }
            if (sales.isEmpty) {
              return _emptyState(
                Icons.receipt_long_rounded,
                'No transactions yet',
                'Your coin sales will appear here.',
              );
            }
            return RefreshIndicator(
              color: CoinSellerUi.gold,
              onRefresh: () => controller.loadTransactions(refresh: true),
              child: ListView.separated(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: sales.length +
                    (controller.hasMoreTransactions.value ? 1 : 0),
                separatorBuilder: (_, __) => Spacing.v10,
                itemBuilder: (_, index) {
                  if (index >= sales.length) {
                    return Center(
                      child: TextButton(
                        onPressed: () => _runDismissKeyboard(
                          context,
                          controller.loadMoreTransactions,
                        ),
                        child: const Text('Load more'),
                      ),
                    );
                  }
                  return _transactionTile(context, sales[index]);
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _filterChip(
    BuildContext context,
    String label,
    CoinSellerTransactionFilter filter,
  ) {
    final selected = controller.transactionFilter.value == filter;
    return GestureDetector(
      onTap: () => _runDismissKeyboard(
        context,
        () => controller.setTransactionFilter(filter),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: selected ? CoinSellerUi.sellButtonGradient : null,
          color: selected ? null : kColorWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : CoinSellerUi.borderStrong,
          ),
        ),
        child: SemiBoldText(
          text: label,
          fontSize: 11,
          color: selected ? kColorWhite : CoinSellerUi.body,
        ),
      ),
    );
  }

  Widget _transactionTile(BuildContext context, SellerSale sale) {
    final isReversed = sale.isReversed;
    final coinAccent = isReversed ? CoinSellerUi.body : CoinSellerUi.gold;
    final coinLabel = isReversed
        ? CoinSellerUi.formatCoins(sale.amount)
        : '+${CoinSellerUi.formatCoins(sale.amount)}';
    final priceLabel =
        '${sale.currency} ${CoinSellerUi.formatMoney(sale.price)}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _runDismissKeyboard(
          context,
          () => controller.openTransactionDetail(sale),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: kColorWhite,
            border: Border.all(color: CoinSellerUi.borderStrong),
            boxShadow: AppLightUi.cardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isReversed
                            ? const [
                                Color(0xFFE84B6A),
                                Color(0xFFFF8A9A),
                              ]
                            : const [
                                CoinSellerUi.violet,
                                CoinSellerUi.pink,
                              ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppLightUi.glossRingGradient,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(1.5),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: kColorWhite,
                                  ),
                                  child: AppUserAvatar(
                                    name: sale.displayName,
                                    imageUrl: sale.avatarUrl,
                                    size: 42,
                                  ),
                                ),
                              ),
                              Spacing.h10,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SemiBoldText(
                                      text: sale.displayName,
                                      fontSize: 14,
                                      color: CoinSellerUi.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Spacing.v6,
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        _statusPill(sale),
                                        AppText(
                                          text: sale.formattedDate,
                                          fontSize: 11,
                                          color: CoinSellerUi.body,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Spacing.h8,
                              _manageActionButton(context, sale),
                            ],
                          ),
                          Spacing.v12,
                          Row(
                            children: [
                              Expanded(
                                child: _metricBlock(
                                  icon: AppCoinIcon(
                                    size: 14,
                                    color: coinAccent,
                                  ),
                                  label: 'Coins',
                                  value: coinLabel,
                                  accent: coinAccent,
                                ),
                              ),
                              Spacing.h8,
                              Expanded(
                                child: _metricBlock(
                                  icon: Icon(
                                    Icons.payments_rounded,
                                    size: 14,
                                    color: isReversed
                                        ? CoinSellerUi.body
                                        : CoinSellerUi.mint,
                                  ),
                                  label: 'Received',
                                  value: priceLabel,
                                  accent: isReversed
                                      ? CoinSellerUi.body
                                      : CoinSellerUi.mint,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _metricBlock({
    required Widget icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppLightUi.cardSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              icon,
              const SizedBox(width: 5),
              AppText(
                text: label,
                fontSize: 11,
                color: CoinSellerUi.body,
              ),
            ],
          ),
          Spacing.v6,
          SemiBoldText(
            text: value,
            fontSize: 14,
            color: CoinSellerUi.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _manageActionButton(BuildContext context, SellerSale sale) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openTransactionActions(context, sale),
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: CoinSellerUi.violet.withValues(alpha: 0.10),
            border: Border.all(
              color: CoinSellerUi.violet.withValues(alpha: 0.32),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.more_horiz_rounded,
                color: CoinSellerUi.violet,
                size: 16,
              ),
              SizedBox(width: 4),
              SemiBoldText(
                text: 'Manage',
                fontSize: 11,
                color: CoinSellerUi.violet,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openTransactionActions(
    BuildContext context,
    SellerSale sale,
  ) async {
    _dismissKeyboard();
    final action = await CoinSellerTransactionActionsSheet.show(sale: sale);
    if (action == null) return;
    switch (action) {
      case CoinSellerTransactionAction.view:
        controller.openTransactionDetail(sale);
      case CoinSellerTransactionAction.edit:
        controller.openEditTransaction(sale);
      case CoinSellerTransactionAction.reverse:
        controller.reverseSale(sale);
    }
  }

  Widget _statusPill(SellerSale sale) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: sale.statusColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: sale.statusColor.withValues(alpha: 0.4)),
      ),
      child: SemiBoldText(
        text: sale.statusLabel,
        fontSize: 9,
        color: sale.statusColor,
      ),
    );
  }

  Widget _glassPanel({required Widget child}) {
    return CoinSellerUi.glossFrame(
      radius: 22,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.6),
          gradient: CoinSellerUi.cardGradient,
        ),
        child: child,
      ),
    );
  }

  Widget _heroBadge({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: AppLightUi.iconTileDecoration(CoinSellerUi.gold, radius: 14),
          child: Icon(icon, color: CoinSellerUi.goldDeep, size: 24),
        ),
        Spacing.h12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SemiBoldText(text: title, fontSize: 15, color: CoinSellerUi.title),
              Spacing.v2,
              AppText(text: subtitle, fontSize: 11, color: CoinSellerUi.muted),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: AppLightUi.iconTileDecoration(
              CoinSellerUi.violet,
              radius: 22,
            ),
            child: Icon(icon, size: 32, color: CoinSellerUi.violet),
          ),
          Spacing.v12,
          SemiBoldText(text: title, fontSize: 14, color: CoinSellerUi.title),
          Spacing.v4,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: AppText(
              text: subtitle,
              fontSize: 11,
              color: CoinSellerUi.muted,
              align: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
