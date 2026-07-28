import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/controllers/coin_seller_controller.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/models/seller_sale.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/widgets/coin_seller_ui_kit.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
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
      backgroundColor: CoinSellerUi.ink,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: CoinSellerUi.heroGradient),
        child: SafeArea(
          child: Obx(() {
            if (controller.isBootstrapping.value ||
                controller.screenState.value == CoinSellerScreenState.checking) {
              return const Center(
                child: CircularProgressIndicator(color: CoinSellerUi.gold),
              );
            }
            return Column(
              children: [
                _header(),
                Expanded(child: _bodyForState(controller.screenState.value)),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _bodyForState(CoinSellerScreenState state) {
    switch (state) {
      case CoinSellerScreenState.checking:
        return const SizedBox.shrink();
      case CoinSellerScreenState.apply:
        return _buildApplyForm();
      case CoinSellerScreenState.pending:
        return _buildPendingState();
      case CoinSellerScreenState.approved:
        return _buildApprovedDashboard();
    }
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          _iconButton(Icons.arrow_back_ios_new_rounded, Get.back),
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
              Icons.refresh_rounded,
              () => controller.loadDashboard(),
            );
          }),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
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

  Widget _buildApplyForm() {
    return SingleChildScrollView(
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
                  onPressed: controller.applyToBecomeSeller,
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
                onPressed: () => controller.loadDashboard(isShowLoader: true),
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

  Widget _buildPendingState() {
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
                  onPressed: () => controller.loadDashboard(),
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

  Widget _buildApprovedDashboard() {
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
            child: _tabBar(),
          ),
          Spacing.v8,
          Expanded(
            child: TabBarView(
              children: [
                _transferPanel(),
                _transactionsPanel(),
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
        gradient: CoinSellerUi.heroGradient,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.monetization_on_rounded,
              size: 120,
              color: CoinSellerUi.gold.withValues(alpha: 0.08),
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

  Widget _tabBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          gradient: CoinSellerUi.sellButtonGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: kColorWhite,
        unselectedLabelColor: Colors.white60,
        labelStyle: TextStyles.kSemiBoldPoppins(fontSize: 12),
        tabs: const [
          Tab(text: 'Sell coins'),
          Tab(text: 'Transactions'),
        ],
      ),
    );
  }

  Widget _transferPanel() {
    return SingleChildScrollView(
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
              text:
                  'Buyer ID, email, or phone. Coins leave your stock instantly.',
              fontSize: 11,
              color: Colors.white54,
            ),
            Spacing.v16,
            _field(Icons.person_search_rounded, controller.userIdController,
                'User ID / email / phone'),
            Spacing.v12,
            _field(Icons.toll_rounded, controller.coinsController,
                'Coin amount', number: true),
            Spacing.v12,
            _field(Icons.currency_rupee_rounded, controller.priceController,
                'Price (INR)', decimal: true),
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
                          'Confirm payment received before transferring coins.',
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
                          : controller.transferCoins,
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

  Widget _field(
    IconData icon,
    TextEditingController ctrl,
    String hint, {
    bool number = false,
    bool decimal = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: CoinSellerUi.gold),
        ),
        Spacing.h10,
        Expanded(
          child: AppTextField(
            controller: ctrl,
            hintText: hint,
            textInputType: number
                ? TextInputType.number
                : decimal
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.text,
            fillColor: Colors.white.withValues(alpha: 0.06),
            borderColor: Colors.white12,
            textStyle: TextStyles.kRegularPoppins(
              colors: kColorWhite,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _transactionsPanel() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Obx(() => Row(
                children: [
                  _filterChip('All', CoinSellerTransactionFilter.all),
                  Spacing.h8,
                  _filterChip('Completed', CoinSellerTransactionFilter.completed),
                  Spacing.h8,
                  _filterChip('Reversed', CoinSellerTransactionFilter.reversed),
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: sales.length +
                    (controller.hasMoreTransactions.value ? 1 : 0),
                separatorBuilder: (_, __) => Spacing.v10,
                itemBuilder: (_, index) {
                  if (index >= sales.length) {
                    return Center(
                      child: TextButton(
                        onPressed: controller.loadMoreTransactions,
                        child: const Text('Load more'),
                      ),
                    );
                  }
                  return _transactionTile(sales[index]);
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _filterChip(String label, CoinSellerTransactionFilter filter) {
    final selected = controller.transactionFilter.value == filter;
    return GestureDetector(
      onTap: () => controller.setTransactionFilter(filter),
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

  Widget _transactionTile(SellerSale sale) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.openTransactionDetail(sale),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: CoinSellerUi.glassCard(),
          child: Row(
            children: [
              AppUserAvatar(
                name: sale.displayName,
                imageUrl: sale.avatarUrl,
                size: 46,
              ),
              Spacing.h12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SemiBoldText(
                            text: sale.displayName,
                            fontSize: 13,
                            color: kColorWhite,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _statusPill(sale),
                      ],
                    ),
                    Spacing.v4,
                    AppText(
                      text: sale.formattedDate,
                      fontSize: 10,
                      color: Colors.white38,
                    ),
                  ],
                ),
              ),
              Spacing.h8,
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SemiBoldText(
                    text: sale.isReversed
                        ? '${sale.amount}'
                        : '+${CoinSellerUi.formatCoins(sale.amount)}',
                    fontSize: 13,
                    color: sale.isReversed ? Colors.white54 : CoinSellerUi.gold,
                  ),
                  AppText(
                    text: '${sale.currency} ${CoinSellerUi.formatMoney(sale.price)}',
                    fontSize: 11,
                    color: CoinSellerUi.mint,
                  ),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: Colors.white54, size: 18),
                color: const Color(0xFF241535),
                onSelected: (action) {
                  switch (action) {
                    case 'view':
                      controller.openTransactionDetail(sale);
                    case 'edit':
                      controller.openEditTransaction(sale);
                    case 'reverse':
                      controller.reverseSale(sale);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'view', child: Text('View details')),
                  if (sale.canEdit)
                    const PopupMenuItem(value: 'edit', child: Text('Edit price')),
                  if (sale.canReverse)
                    const PopupMenuItem(
                      value: 'reverse',
                      child: Text('Reverse sale',
                          style: TextStyle(color: Colors.redAccent)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusPill(SellerSale sale) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: sale.statusColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: AppText(
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
