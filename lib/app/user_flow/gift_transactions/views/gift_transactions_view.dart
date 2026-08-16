import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/gift_transactions/controllers/gift_transactions_controller.dart';
import 'package:qobo_one_live/app/user_flow/gift_transactions/models/gift_history_models.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/icon_constants.dart';
import 'package:qobo_one_live/repo/economy/economy_api_utils.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

class GiftTransactionsView extends GetView<GiftTransactionsController> {
  const GiftTransactionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorBackground,
      appBar: const CommonAppBarWidget(
        title: 'Transactions',
        useMaterialAppBar: true,
      ),
      body: Column(
        children: [
          _summaryHeader(),
          _tabBar(),
          Expanded(child: _historyList()),
        ],
      ),
    );
  }

  Widget _summaryHeader() {
    return Obx(() {
      final summary = controller.summary.value;
      final type = controller.selectedType.value;
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kColorPrimary, Color(0xFF9F3B8F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: kColorPrimary.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: kColorWhite.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(kGiftIcon, color: kColorWhite, size: 22),
                ),
                Spacing.h12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SemiBoldText(
                        text: 'Gifts you sent',
                        fontSize: TextStyles.k16FontSize,
                        color: kColorWhite,
                      ),
                      Spacing.v2,
                      AppText(
                        text: '${type.label} history',
                        fontSize: TextStyles.k12FontSize,
                        color: kColorWhite.withValues(alpha: 0.78),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Spacing.v16,
            Row(
              children: [
                Expanded(
                  child: _statChip(
                    label: '${type.label} gifts',
                    value: '${summary.countFor(type)}',
                  ),
                ),
                Spacing.h10,
                Expanded(
                  child: _statChip(
                    label: 'Coins spent',
                    value: formatLedgerAmount(summary.coinsFor(type)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _statChip({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: kColorWhite.withValues(alpha: 0.14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            text: label,
            fontSize: 10,
            color: kColorWhite.withValues(alpha: 0.75),
          ),
          Spacing.v4,
          SemiBoldText(
            text: value,
            fontSize: TextStyles.k18FontSize,
            color: kColorWhite,
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
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
            for (final type in GiftHistoryType.values)
              Expanded(child: _tabButton(type)),
          ],
        );
      }),
    );
  }

  Widget _tabButton(GiftHistoryType type) {
    final isSelected = controller.selectedType.value == type;
    return GestureDetector(
      onTap: () => controller.selectType(type),
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
          text: type.label,
          fontSize: TextStyles.k12FontSize,
          color: isSelected ? kColorWhite : kColorText.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _historyList() {
    return Obx(() {
      if (controller.isLoading.value && controller.items.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(kColorPrimary),
          ),
        );
      }

      if (controller.items.isEmpty) {
        return _emptyState();
      }

      return NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent - 80) {
            controller.loadHistory();
          }
          return false;
        },
        child: RefreshIndicator(
          color: kColorPrimary,
          onRefresh: () async {
            await Future.wait([
              controller.loadSummary(),
              controller.loadHistory(refresh: true),
            ]);
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount:
                controller.items.length +
                (controller.isLoadingMore.value ? 1 : 0),
            separatorBuilder: (_, __) => Spacing.v12,
            itemBuilder: (context, index) {
              if (index >= controller.items.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: kColorPrimary,
                      ),
                    ),
                  ),
                );
              }
              return _giftCard(controller.items[index]);
            },
          ),
        ),
      );
    });
  }

  Widget _emptyState() {
    return Obx(() {
      final error = controller.loadError.value;
      final type = controller.selectedType.value;
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
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
                  error.isNotEmpty ? Icons.cloud_off_rounded : kGiftIcon,
                  color: kColorPrimary,
                  size: 64,
                ),
              ),
              Spacing.v24,
              SemiBoldText(
                text: error.isNotEmpty ? 'Unable to Load' : 'No gifts yet',
                fontSize: TextStyles.k18FontSize,
                color: kColorText,
              ),
              Spacing.v8,
              AppText(
                text: error.isNotEmpty
                    ? error
                    : 'Gifts you send in ${type.label.toLowerCase()} will appear here.',
                fontSize: TextStyles.k14FontSize,
                color: kColorHint,
                align: TextAlign.center,
              ),
              if (error.isNotEmpty) ...[
                Spacing.v16,
                TextButton(
                  onPressed: () => controller.loadHistory(refresh: true),
                  child: const SemiBoldText(
                    text: 'Try Again',
                    fontSize: TextStyles.k14FontSize,
                    color: kColorPrimary,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _giftCard(GiftHistoryItem item) {
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
          _giftThumb(item),
          Spacing.h16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: item.giftName,
                  fontSize: TextStyles.k14FontSize,
                  color: kColorText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.receiverName.isNotEmpty) ...[
                  Spacing.v4,
                  Row(
                    children: [
                      AppUserAvatar(
                        name: item.receiverName,
                        imageUrl: item.receiverAvatar,
                        size: 18,
                      ),
                      Spacing.h6,
                      Expanded(
                        child: AppText(
                          text: item.receiverName,
                          fontSize: TextStyles.k12FontSize,
                          color: kColorHint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                Spacing.v4,
                AppText(
                  text: item.contextSubtitle,
                  fontSize: TextStyles.k12FontSize,
                  color: kColorHint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.createdAtLabel.isNotEmpty) ...[
                  Spacing.v6,
                  AppText(
                    text: item.createdAtLabel,
                    fontSize: 10,
                    color: kColorHint,
                  ),
                ],
              ],
            ),
          ),
          Spacing.h12,
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              BoldText(
                text: '-${formatLedgerAmount(item.coinsSpent)}',
                fontSize: TextStyles.k18FontSize,
                color: const Color(0xFFD32F2F),
              ),
              Spacing.v4,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: kColorBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AppText(
                  text: item.quantity > 1 ? '×${item.quantity} Coins' : 'Coins',
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
  }

  Widget _giftThumb(GiftHistoryItem item) {
    final url = item.giftImage;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: kColorPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? const Icon(kGiftIcon, color: kColorPrimary, size: 22)
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                kGiftIcon,
                color: kColorPrimary,
                size: 22,
              ),
            ),
    );
  }
}
