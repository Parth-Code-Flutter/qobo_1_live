import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/controllers/coin_seller_controller.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/models/seller_sale.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/widgets/coin_seller_transaction_actions_sheet.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/widgets/coin_seller_ui_kit.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_coin_icon.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

class CoinSellerView extends GetView<CoinSellerController> {
  const CoinSellerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: _dismissKeyboard,
        behavior: HitTestBehavior.deferToChild,
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(kImgBG),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Obx(() {
              if (controller.isBootstrapping.value ||
                  controller.screenState.value ==
                      CoinSellerScreenState.checking) {
                return const Center(
                  child: CircularProgressIndicator(color: CoinSellerUi.gold),
                );
              }
              return Column(
                children: [
                  _header(context),
                  Expanded(
                    child: _bodyForState(context, controller.screenState.value),
                  ),
                ],
              );
            }),
          ),
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

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          _iconButton(context, Icons.arrow_back_ios_new_rounded, Get.back),
          Expanded(
            child: Column(
              children: [
                const SemiBoldText(
                  text: 'Merchant Hub',
                  fontSize: 18,
                  color: kColorWhite,
                ),
                Obx(() {
                  final label = controller.sellerLabel.value.trim();
                  if (label.isEmpty) return const SizedBox.shrink();
                  return AppText(
                    text: label,
                    fontSize: 10,
                    color: Colors.white54,
                  );
                }),
              ],
            ),
          ),
          Obx(() {
            if (controller.screenState.value != CoinSellerScreenState.approved) {
              return const SizedBox(width: 40);
            }
            return _iconButton(
              context,
              Icons.refresh_rounded,
              () => controller.loadDashboard(),
            );
          }),
        ],
      ),
    );
  }

  Widget _iconButton(
    BuildContext context,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () => _runDismissKeyboard(context, onTap),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: kColorWhite, size: 18),
          ),
        ),
      ),
    );
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
              color: Colors.white60,
            ),
            Spacing.v20,
            AppTextField(
              controller: controller.detailsController,
              hintText: 'Payment methods & region (JazzCash, bank, etc.)',
              maxLines: 4,
              textInputType: TextInputType.multiline,
              fillColor: Colors.white.withValues(alpha: 0.06),
              borderColor: Colors.white12,
              textStyle: TextStyles.kRegularPoppins(
                colors: kColorWhite,
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
                color: kColorWhite,
              ),
              Spacing.v8,
              const AppText(
                text:
                    'Your request was submitted. An admin will review it soon. '
                    'Tap below once you are approved.',
                fontSize: 12,
                color: Colors.white60,
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
            child: Column(
              children: [
                _stockHero(),
                Spacing.v12,
                _metricsStrip(),
              ],
            ),
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
      padding: const EdgeInsets.all(20),
      decoration: CoinSellerUi.glassCard(
        borderColor: CoinSellerUi.gold.withValues(alpha: 0.35),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kColorWalletCardBgTop,
            kColorWalletCardBgBottom,
            Color(0xFF1A0E32),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Opacity(
              opacity: 0.08,
              child: AppCoinIcon(size: 120, color: CoinSellerUi.gold),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AppText(
                    text: 'Available stock',
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: CoinSellerUi.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: CoinSellerUi.gold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          color: CoinSellerUi.gold,
                          size: 13,
                        ),
                        SizedBox(width: 4),
                        SemiBoldText(
                          text: 'Verified',
                          fontSize: 10,
                          color: CoinSellerUi.gold,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Spacing.v10,
              Obx(
                () => ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFFF8E1), CoinSellerUi.gold, CoinSellerUi.goldDeep],
                  ).createShader(bounds),
                  child: BoldText(
                    text: CoinSellerUi.formatCoins(
                      controller.availableCoins.value,
                    ),
                    fontSize: 40,
                    color: kColorWhite,
                  ),
                ),
              ),
              const AppText(
                text: 'coins ready to sell',
                fontSize: 12,
                color: Colors.white54,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricsStrip() {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: _metricTile(
              Icons.payments_rounded,
              'Revenue',
              'INR ${CoinSellerUi.formatMoney(controller.totalRevenue.value)}',
              CoinSellerUi.mint,
            ),
          ),
          Spacing.h8,
          Expanded(
            child: _metricTile(
              Icons.toll_rounded,
              'Sold',
              CoinSellerUi.formatCoins(controller.totalCoinsSold.value),
              CoinSellerUi.gold,
            ),
          ),
          Spacing.h8,
          Expanded(
            child: _metricTile(
              Icons.receipt_long_rounded,
              'Sales',
              '${controller.totalTransactions.value}',
              CoinSellerUi.sky,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricTile(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: CoinSellerUi.glassCard(
        borderColor: color.withValues(alpha: 0.25),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          Spacing.v4,
          AppText(text: label, fontSize: 10, color: Colors.white54),
          Spacing.v2,
          SemiBoldText(
            text: value,
            fontSize: 12,
            color: color,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _tabBar(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TabBar(
        onTap: (_) => _dismissKeyboard(),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          gradient: CoinSellerUi.sellButtonGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: kColorWhite,
        unselectedLabelColor: Colors.white60,
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
            const SemiBoldText(
              text: 'Quick transfer',
              fontSize: 15,
              color: kColorWhite,
            ),
            Spacing.v6,
            const AppText(
              text: 'Pick a buyer from the list, then enter coins and price.',
              fontSize: 11,
              color: Colors.white54,
            ),
            Spacing.v16,
            _buyerSelector(context),
            Spacing.v12,
            _field(
              AppCoinIcon(size: 20, color: CoinSellerUi.gold),
              controller.coinsController,
              'Coins',
              number: true,
            ),
            Spacing.v12,
            _field(
              Icon(Icons.currency_rupee_rounded,
                  size: 20, color: CoinSellerUi.gold),
              controller.priceController,
              'Price (INR)',
              decimal: true,
            ),
            Spacing.v16,
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: AppText(
                      text:
                          'You will confirm the transfer before coins are sent.',
                      fontSize: 10,
                      color: Colors.white60,
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
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: CoinSellerUi.goldDeep.withValues(alpha: 0.35),
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
                      borderRadius: BorderRadius.circular(14),
                      child: Center(
                        child: SemiBoldText(
                          text: controller.isTransferring.value
                              ? 'Transferring…'
                              : 'Transfer now',
                          fontSize: 14,
                          color: kColorWhite,
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
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: buyer != null
                    ? CoinSellerUi.gold.withValues(alpha: 0.4)
                    : Colors.white12,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
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
                              color: kColorWhite,
                            ),
                            AppText(
                              text: 'Friends, followers, or search',
                              fontSize: 10,
                              color: Colors.white38,
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SemiBoldText(
                              text: buyer.name,
                              fontSize: 13,
                              color: kColorWhite,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            AppText(
                              text: buyer.id,
                              fontSize: 10,
                              color: Colors.white38,
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
                      color: Colors.white54,
                      size: 18,
                    ),
                    visualDensity: VisualDensity.compact,
                  )
                else
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white.withValues(alpha: 0.5),
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
      fillColor: Colors.white.withValues(alpha: 0.06),
      borderColor: Colors.white12,
      textStyle: TextStyles.kRegularPoppins(
        colors: kColorWhite,
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
          color: selected ? null : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: SemiBoldText(
          text: label,
          fontSize: 11,
          color: selected ? kColorWhite : Colors.white60,
        ),
      ),
    );
  }

  Widget _transactionTile(BuildContext context, SellerSale sale) {
    final accent = sale.isReversed
        ? const Color(0xFFFF6B6B)
        : CoinSellerUi.gold;
    final coinLabel = sale.isReversed
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
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.14),
                Colors.white.withValues(alpha: 0.05),
                Colors.black.withValues(alpha: 0.18),
              ],
            ),
            border: Border.all(color: accent.withValues(alpha: 0.28)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          accent.withValues(alpha: 0.85),
                          const Color(0xFFFF4081).withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF120A1E),
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
                          color: kColorWhite,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Spacing.v6,
                        Row(
                          children: [
                            _statusPill(sale),
                            Spacing.h8,
                            Flexible(
                              child: AppText(
                                text: sale.formattedDate,
                                fontSize: 10,
                                color: Colors.white38,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
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
                        size: 13,
                        color: sale.isReversed
                            ? Colors.white54
                            : CoinSellerUi.gold,
                      ),
                      label: 'Coins',
                      value: coinLabel,
                      accent: sale.isReversed ? Colors.white54 : CoinSellerUi.gold,
                    ),
                  ),
                  Spacing.h8,
                  Expanded(
                    child: _metricBlock(
                      icon: Icon(Icons.payments_rounded, size: 13, color: CoinSellerUi.mint),
                      label: 'Received',
                      value: priceLabel,
                      accent: CoinSellerUi.mint,
                    ),
                  ),
                ],
              ),
            ],
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
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
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
                fontSize: 10,
                color: Colors.white54,
              ),
            ],
          ),
          Spacing.v6,
          SemiBoldText(
            text: value,
            fontSize: 14,
            color: accent,
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
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                CoinSellerUi.gold.withValues(alpha: 0.22),
                const Color(0xFFFF4081).withValues(alpha: 0.16),
              ],
            ),
            border: Border.all(
              color: CoinSellerUi.gold.withValues(alpha: 0.45),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: CoinSellerUi.gold,
                size: 13,
              ),
              SizedBox(width: 4),
              SemiBoldText(
                text: 'Manage',
                fontSize: 11,
                color: kColorWhite,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: CoinSellerUi.glassCard(),
      child: child,
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CoinSellerUi.gold.withValues(alpha: 0.3),
                CoinSellerUi.goldDeep.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: CoinSellerUi.gold, size: 24),
        ),
        Spacing.h12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SemiBoldText(text: title, fontSize: 15, color: kColorWhite),
              Spacing.v2,
              AppText(text: subtitle, fontSize: 11, color: Colors.white54),
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
          Icon(icon, size: 52, color: Colors.white24),
          Spacing.v12,
          SemiBoldText(text: title, fontSize: 14, color: kColorWhite),
          Spacing.v4,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: AppText(
              text: subtitle,
              fontSize: 11,
              color: Colors.white38,
              align: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
