import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/icon_constants.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_coin_icon.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/transaction_history_controller.dart';

class TransactionHistoryView extends GetView<TransactionHistoryController> {
  const TransactionHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorBackground,
      appBar: const CommonAppBarWidget(
        title: 'Transaction History',
        useMaterialAppBar: true,
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(kColorPrimary),
                  ),
                );
              }

              final isCoinSelected = controller.selectedTab.value == 0;
              final list = isCoinSelected
                  ? controller.coinTransactions
                  : controller.diamondTransactions;

              if (list.isEmpty) {
                return _buildEmptyState(
                  message: controller.loadError.value.isNotEmpty
                      ? controller.loadError.value
                      : null,
                  onRetry: controller.loadError.value.isNotEmpty
                      ? controller.fetchTransactionHistory
                      : null,
                );
              }

              return _buildTransactionList(list, isCoinSelected);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      height: 48,
      decoration: BoxDecoration(
        color: kColorWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: kColorBlack.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() {
        return Row(
          children: [
            Expanded(child: _tabButton('Coins Ledger', 0)),
            Expanded(child: _tabButton('Diamonds Ledger', 1)),
          ],
        );
      }),
    );
  }

  Widget _tabButton(String text, int index) {
    final bool isSelected = controller.selectedTab.value == index;
    return GestureDetector(
      onTap: () => controller.selectedTab.value = index,
      child: Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isSelected
              ? const LinearGradient(
                  colors: [kColorPrimary, Color(0xFF9F3B8F)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
        ),
        child: SemiBoldText(
          text: text,
          fontSize: TextStyles.k14FontSize,
          color: isSelected ? kColorWhite : kColorText.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildEmptyState({String? message, VoidCallback? onRetry}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kColorPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              onRetry != null
                  ? Icons.cloud_off_rounded
                  : Icons.receipt_long_rounded,
              color: kColorPrimary,
              size: 64,
            ),
          ),
          Spacing.v24,
          SemiBoldText(
            text: onRetry != null ? 'Unable to Load' : 'No Transactions',
            fontSize: TextStyles.k18FontSize,
            color: kColorText,
          ),
          Spacing.v8,
          AppText(
            text: message ?? 'Your balance records will appear here.',
            fontSize: TextStyles.k14FontSize,
            color: kColorHint,
            align: TextAlign.center,
          ),
          if (onRetry != null) ...[
            Spacing.v16,
            TextButton(
              onPressed: onRetry,
              child: const SemiBoldText(
                text: 'Try Again',
                fontSize: TextStyles.k14FontSize,
                color: kColorPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionList(
    List<Map<String, dynamic>> list,
    bool isCoinSelected,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => Spacing.v12,
      itemBuilder: (context, index) {
        final tx = list[index];
        final bool isAddition = tx['isAddition'] ?? false;
        final String sign = isAddition ? '+' : '';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kColorWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: kColorBlack.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon Badge
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isAddition
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: _buildTransactionLeading(
                  tx['type']?.toString() ?? '',
                  isAddition ? Colors.green : Colors.red,
                ),
              ),
              Spacing.h16,
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemiBoldText(
                      text: tx['title'] ?? 'Transaction',
                      fontSize: TextStyles.k14FontSize,
                      color: kColorText,
                    ),
                    Spacing.v2,
                    AppText(
                      text: tx['subtitle'] ?? '',
                      fontSize: TextStyles.k12FontSize,
                      color: kColorHint,
                    ),
                    Spacing.v6,
                    AppText(
                      text: tx['date'] ?? '',
                      fontSize: 10,
                      color: kColorHint,
                    ),
                  ],
                ),
              ),
              Spacing.h12,
              // Amount Tag
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  BoldText(
                    text: '$sign${tx['amount']}',
                    fontSize: TextStyles.k18FontSize,
                    color: isAddition ? Colors.green : Colors.red,
                  ),
                  if (isCoinSelected &&
                      (tx['amountUsd']?.toString().isNotEmpty ?? false)) ...[
                    Spacing.v2,
                    AppText(
                      text: '$sign${tx['amountUsd']}',
                      fontSize: TextStyles.k10FontSize,
                      color: isAddition ? Colors.green : Colors.red,
                    ),
                  ],
                  Spacing.v4,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: kColorBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: AppText(
                      text: isCoinSelected ? 'Coins' : 'Diamonds',
                      fontSize: 9,
                      color: kColorText.withValues(alpha: 0.6),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getTransactionIcon(String type) {
    switch (type.toUpperCase()) {
      case 'SUPER_ADMIN_AGENCY_BONUS':
        return Icons.apartment_rounded;
      case 'AGENCY_HOST_BONUS':
        return Icons.person_add_alt_1_rounded;
    }

    switch (type.toLowerCase()) {
      case 'google pay':
        return Icons.credit_card_rounded;
      case 'coin seller':
        return Icons.person_add_rounded;
      case 'gift':
        return kGiftIcon;
      case 'noble rank':
        return Icons.workspace_premium_rounded;
      case 'broadcasting':
        return Icons.video_camera_front_rounded;
      case 'exchange':
        return Icons.swap_horiz_rounded;
      case 'official bonus':
        return Icons.emoji_events_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  Widget _buildTransactionLeading(String type, Color color) {
    final icon = _getTransactionIcon(type);
    if (icon == Icons.circle_outlined) {
      return AppCoinIcon(size: 22, color: color);
    }
    return Icon(icon, color: color, size: 22);
  }
}
