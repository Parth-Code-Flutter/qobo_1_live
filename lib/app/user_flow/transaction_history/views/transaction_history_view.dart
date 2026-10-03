import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/icon_constants.dart';
import 'package:qobo_one_live/repo/economy/economy_api_utils.dart';
import 'package:qobo_one_live/utils/app_widgets/app_coin_icon.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/transaction_history_controller.dart';

class TransactionHistoryView extends GetView<TransactionHistoryController> {
  const TransactionHistoryView({super.key});

  static const _credit = Color(0xFF1FA971);
  static const _debit = Color(0xFFFF4F6D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppLightUi.bg,
      appBar: const CommonAppBarWidget(
        title: 'Transaction History',
        useMaterialAppBar: true,
      ),
      body: Column(
        children: [
          _segmentedTabs(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppLightUi.pink),
                );
              }

              final isCoins = controller.selectedTab.value == 0;
              final list = isCoins
                  ? controller.coinTransactions
                  : controller.diamondTransactions;

              return RefreshIndicator(
                color: AppLightUi.pink,
                onRefresh: controller.fetchTransactionHistory,
                child: list.isEmpty
                    ? _emptyState()
                    : _transactionList(list.toList(), isCoins),
              );
            }),
          ),
        ],
      ),
    );
  }

  // —— Tabs ——

  Widget _segmentedTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      height: 50,
      padding: const EdgeInsets.all(5),
      decoration: AppLightUi.cardDecoration(radius: 25),
      child: Obx(() {
        final index = controller.selectedTab.value;
        return Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              alignment: index == 0
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppLightUi.familyCtaGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppLightUi.pink.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: _tabLabel('Coins', Icons.toll_rounded, 0, index),
                  ),
                  Expanded(
                    child: _tabLabel(
                      'Diamonds',
                      Icons.diamond_rounded,
                      1,
                      index,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _filterChips() {
    const labels = ['All', 'Received', 'Spent'];
    return Obx(() {
      final selected = controller.filter.value;
      return Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) Spacing.h8,
            GestureDetector(
              onTap: () => controller.filter.value = i,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected == i
                      ? AppLightUi.violet.withValues(alpha: 0.14)
                      : AppLightUi.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected == i
                        ? AppLightUi.violet
                        : AppLightUi.border,
                  ),
                ),
                child: SemiBoldText(
                  text: labels[i],
                  fontSize: TextStyles.k12FontSize,
                  color: selected == i
                      ? AppLightUi.violet
                      : AppLightUi.subtitle,
                ),
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _tabLabel(String text, IconData icon, int tab, int selected) {
    final isSelected = tab == selected;
    final color = isSelected ? kColorWhite : AppLightUi.subtitle;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => controller.selectedTab.value = tab,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          Spacing.h6,
          Flexible(
            child: SemiBoldText(
              text: text,
              fontSize: TextStyles.k14FontSize,
              color: color,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // —— Summary ——

  Widget _summaryCard(List<Map<String, dynamic>> list, bool isCoins) {
    num received = 0;
    num spent = 0;
    for (final tx in list) {
      final value = tx['amountValue'] as num? ?? 0;
      if (tx['isAddition'] == true) {
        received += value;
      } else {
        spent += value;
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: AppLightUi.familyCtaGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppLightUi.violet.withValues(alpha: 0.28),
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
              Icon(
                isCoins ? Icons.toll_rounded : Icons.diamond_rounded,
                size: 16,
                color: kColorWhite.withValues(alpha: 0.9),
              ),
              Spacing.h6,
              Expanded(
                child: AppText(
                  text: isCoins ? 'Coins activity' : 'Diamonds activity',
                  fontSize: TextStyles.k12FontSize,
                  color: kColorWhite.withValues(alpha: 0.9),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kColorWhite.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AppText(
                  text: '${list.length} records',
                  fontSize: TextStyles.k10FontSize,
                  color: kColorWhite,
                ),
              ),
            ],
          ),
          Spacing.v12,
          Row(
            children: [
              Expanded(
                child: _summaryStat(
                  label: 'Received',
                  value: '+${formatLedgerAmount(received)}',
                  icon: Icons.south_west_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 34,
                color: kColorWhite.withValues(alpha: 0.3),
              ),
              Spacing.h12,
              Expanded(
                child: _summaryStat(
                  label: 'Spent',
                  value: '−${formatLedgerAmount(spent)}',
                  icon: Icons.north_east_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryStat({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: kColorWhite.withValues(alpha: 0.22),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: kColorWhite),
        ),
        Spacing.h8,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                text: label,
                fontSize: TextStyles.k10FontSize,
                color: kColorWhite.withValues(alpha: 0.85),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: BoldText(
                  text: value,
                  fontSize: TextStyles.k16FontSize,
                  color: kColorWhite,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // —— List ——

  Widget _transactionList(List<Map<String, dynamic>> list, bool isCoins) {
    final filter = controller.filter.value;
    final visible = list.where((tx) {
      final credit = tx['isAddition'] == true;
      return filter == 0 || (filter == 1 ? credit : !credit);
    }).toList();

    // Group consecutive rows by day (API returns newest first).
    final groups = <MapEntry<String, List<Map<String, dynamic>>>>[];
    for (final tx in visible) {
      final label = _dayLabel(tx['dateTime'] as DateTime?);
      if (groups.isEmpty || groups.last.key != label) {
        groups.add(MapEntry(label, []));
      }
      groups.last.value.add(tx);
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: [
        _summaryCard(list, isCoins),
        Spacing.v16,
        _filterChips(),
        Spacing.v16,
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: AppText(
              text: filter == 1
                  ? 'Nothing received yet.'
                  : 'Nothing spent yet.',
              fontSize: TextStyles.k14FontSize,
              color: AppLightUi.subtitle,
              align: TextAlign.center,
            ),
          ),
        for (final group in groups) ...[
          _dayHeader(group.key, group.value),
          _dayCard(group.value, isCoins),
          Spacing.v16,
        ],
      ],
    );
  }

  Widget _dayHeader(String label, List<Map<String, dynamic>> items) {
    num net = 0;
    for (final tx in items) {
      final value = tx['amountValue'] as num? ?? 0;
      net += tx['isAddition'] == true ? value : -value;
    }
    final netText = net == 0
        ? '0'
        : '${net > 0 ? '+' : '−'}${formatLedgerAmount(net.abs())}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: SemiBoldText(
              text: label,
              fontSize: TextStyles.k14FontSize,
              color: AppLightUi.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          AppText(
            text: 'Net $netText',
            fontSize: TextStyles.k12FontSize,
            color: net >= 0 ? _credit : _debit,
          ),
        ],
      ),
    );
  }

  Widget _dayCard(List<Map<String, dynamic>> items, bool isCoins) {
    return Container(
      decoration: AppLightUi.cardDecoration(radius: 18),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                indent: 66,
                endIndent: 14,
                color: AppLightUi.border,
              ),
            _transactionRow(items[i], isCoins),
          ],
        ],
      ),
    );
  }

  Widget _transactionRow(Map<String, dynamic> tx, bool isCoins) {
    final isCredit = tx['isAddition'] == true;
    final amountColor = isCredit ? _credit : _debit;
    final type = tx['type']?.toString() ?? '';
    final accent = _accentFor(type, isCredit);
    final dateTime = tx['dateTime'] as DateTime?;
    final timeLabel = dateTime == null
        ? (tx['date']?.toString() ?? '')
        : DateFormat('h:mm a').format(dateTime);
    final apiSubtitle = tx['subtitle']?.toString().trim() ?? '';
    final description = apiSubtitle.isNotEmpty
        ? apiSubtitle
        : _describe(type, isCredit);
    final usd = tx['amountUsd']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: _leadingIcon(type, accent)),
          ),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: tx['title']?.toString() ?? 'Transaction',
                  fontSize: TextStyles.k14FontSize,
                  color: AppLightUi.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Spacing.v2,
                AppText(
                  text: timeLabel.isEmpty
                      ? description
                      : '$description · $timeLabel',
                  fontSize: TextStyles.k12FontSize,
                  color: AppLightUi.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Spacing.h8,
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: BoldText(
                    text: '${isCredit ? '+' : '−'}${tx['amount']}',
                    fontSize: TextStyles.k16FontSize,
                    color: amountColor,
                  ),
                ),
                if (isCoins && usd.isNotEmpty)
                  AppText(
                    text: '${isCredit ? '+' : '−'}$usd',
                    fontSize: TextStyles.k10FontSize,
                    color: amountColor,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Short human line when the API sends no subtitle.
  String _describe(String type, bool isCredit) {
    final t = type.toUpperCase();
    if (t.contains('VIP')) return 'SVIP membership';
    if (t.contains('GIFT')) {
      final where = t.contains('FAMILY')
          ? ' in family'
          : t.contains('LIVE')
          ? ' in live'
          : t.contains('ROOM')
          ? ' in room'
          : '';
      return isCredit ? 'Gift received$where' : 'Gift sent$where';
    }
    if (t.contains('RECHARGE') || t.contains('TOPUP')) return 'Coins top up';
    if (t.contains('SELLER')) return 'From coin seller';
    if (t.contains('WITHDRAW')) return 'Withdrawal';
    if (t.contains('CALL')) return isCredit ? 'Call earning' : 'Call charge';
    if (t.contains('FRAME') || t.contains('MALL')) return 'Mall purchase';
    if (t.contains('BONUS') || t.contains('REWARD')) return 'Bonus reward';
    return isCredit ? 'Received' : 'Spent';
  }

  Widget _emptyState() {
    final hasError = controller.loadError.value.isNotEmpty;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      children: [
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppLightUi.violet.withValues(alpha: 0.18),
                  AppLightUi.pink.withValues(alpha: 0.12),
                ],
              ),
              border: Border.all(
                color: AppLightUi.violet.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              hasError ? Icons.cloud_off_rounded : Icons.receipt_long_rounded,
              color: AppLightUi.violet,
              size: 44,
            ),
          ),
        ),
        Spacing.v20,
        SemiBoldText(
          text: hasError ? 'Unable to load' : 'No transactions yet',
          fontSize: TextStyles.k18FontSize,
          color: AppLightUi.title,
          align: TextAlign.center,
        ),
        Spacing.v8,
        AppText(
          text: hasError
              ? controller.loadError.value
              : 'Your coin and diamond activity will appear here.',
          fontSize: TextStyles.k14FontSize,
          color: AppLightUi.subtitle,
          align: TextAlign.center,
        ),
        if (hasError) ...[
          Spacing.v16,
          Center(
            child: GestureDetector(
              onTap: controller.fetchTransactionHistory,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: AppLightUi.familyCtaGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const SemiBoldText(
                  text: 'Try again',
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // —— Helpers ——

  String _dayLabel(DateTime? date) {
    if (date == null) return 'Earlier';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat(
      day.year == now.year ? 'EEE, d MMM' : 'd MMM yyyy',
    ).format(day);
  }

  Color _accentFor(String type, bool isCredit) {
    final t = type.toUpperCase();
    if (t.contains('VIP') || t.contains('NOBLE')) return AppLightUi.gold;
    if (t.contains('GIFT')) return AppLightUi.pink;
    if (t.contains('RECHARGE') || t.contains('TOPUP') || t.contains('PAY')) {
      return AppLightUi.cyan;
    }
    if (t.contains('BONUS') || t.contains('REWARD')) return _credit;
    if (t.contains('WITHDRAW')) return const Color(0xFFFF8A48);
    return isCredit ? _credit : AppLightUi.violet;
  }

  IconData? _iconFor(String type) {
    final t = type.toUpperCase();
    if (t.contains('VIP') || t.contains('NOBLE')) {
      return Icons.workspace_premium_rounded;
    }
    if (t.contains('GIFT')) return kGiftIcon;
    if (t.contains('TASK')) return Icons.emoji_events_rounded;
    if (t.contains('AGENCY')) return Icons.apartment_rounded;
    if (t.contains('HOST')) return Icons.person_add_alt_1_rounded;
    if (t.contains('BONUS') || t.contains('REWARD')) {
      return Icons.card_giftcard_rounded;
    }
    if (t.contains('RECHARGE') || t.contains('TOPUP') || t.contains('PAY')) {
      return Icons.account_balance_wallet_rounded;
    }
    if (t.contains('SELLER')) return Icons.storefront_rounded;
    if (t.contains('WITHDRAW')) return Icons.account_balance_rounded;
    if (t.contains('EXCHANGE')) return Icons.swap_horiz_rounded;
    if (t.contains('CALL')) return Icons.call_rounded;
    if (t.contains('FRAME') || t.contains('MALL') || t.contains('PURCHASE')) {
      return Icons.shopping_bag_rounded;
    }
    if (t.contains('LIVE') || t.contains('BROADCAST')) {
      return Icons.videocam_rounded;
    }
    return null;
  }

  Widget _leadingIcon(String type, Color color) {
    final icon = _iconFor(type);
    if (icon == null) return AppCoinIcon(size: 20, color: color);
    return Icon(icon, color: color, size: 20);
  }
}
