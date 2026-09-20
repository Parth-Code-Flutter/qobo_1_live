import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/gift_transactions/controllers/gift_transactions_controller.dart';
import 'package:qobo_one_live/app/user_flow/gift_transactions/models/gift_history_models.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/icon_constants.dart';
import 'package:qobo_one_live/repo/economy/economy_api_utils.dart';
import 'package:qobo_one_live/utils/app_widgets/app_coin_icon.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/app_widgets/dating_empty_hero.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

class GiftTransactionsView extends GetView<GiftTransactionsController> {
  const GiftTransactionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorLavenderBg,
      appBar: const CommonAppBarWidget(
        title: 'Transactions',
        subtitle: 'Gifts you sent across rooms',
        trailingIcon: Icons.receipt_long_rounded,
      ),
      body: Column(
        children: [
          _summaryHeader(),
          Spacing.v12,
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
      final accent = _accentFor(type);
      final gifts = summary.countFor(type);
      final coins = formatLedgerAmount(summary.coinsFor(type));

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppLightUi.borderStrong),
          boxShadow: AppLightUi.cardShadow,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppLightUi.card,
              accent.withValues(alpha: 0.10),
              AppLightUi.pink.withValues(alpha: 0.06),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: AppLightUi.familyCtaGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppLightUi.pink.withValues(alpha: 0.30),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(kGiftIcon, color: kColorWhite, size: 26),
                  ),
                  Spacing.h12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SemiBoldText(
                          text: 'Gifts you sent',
                          fontSize: TextStyles.k18FontSize,
                          color: AppLightUi.title,
                        ),
                        Spacing.v6,
                        AppText(
                          text: _summaryCaption(type),
                          fontSize: TextStyles.k12FontSize,
                          color: AppLightUi.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Spacing.h8,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: AppLightUi.familyCtaGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppLightUi.pink.withValues(alpha: 0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: SemiBoldText(
                      text: type.label,
                      fontSize: TextStyles.k10FontSize,
                      color: kColorWhite,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppLightUi.card.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppLightUi.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _statCell(
                      label: 'Gifts',
                      value: '$gifts',
                      accent: accent,
                      leading: Icon(
                        Icons.card_giftcard_rounded,
                        size: 16,
                        color: accent,
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 42,
                    color: AppLightUi.borderStrong,
                  ),
                  Expanded(
                    child: _statCell(
                      label: 'Coins spent',
                      value: coins,
                      accent: AppLightUi.gold,
                      leading: const AppCoinIcon(size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  String _summaryCaption(GiftHistoryType type) {
    switch (type) {
      case GiftHistoryType.audioRoom:
        return 'Totals for audio rooms';
      case GiftHistoryType.liveStream:
        return 'Totals for live streams';
      case GiftHistoryType.pk:
        return 'Totals for PK battles';
      case GiftHistoryType.call:
        return 'Totals for voice & video calls';
    }
  }

  Widget _statCell({
    required String label,
    required String value,
    required Color accent,
    required Widget leading,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: leading,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppText(
                  text: label,
                  fontSize: TextStyles.k12FontSize,
                  color: AppLightUi.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Spacing.v8,
          SemiBoldText(
            text: value,
            fontSize: TextStyles.k20FontSize,
            color: AppLightUi.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppLightUi.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppLightUi.border),
        boxShadow: AppLightUi.cardShadow,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isSelected ? AppLightUi.familyCtaGradient : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppLightUi.pink.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: SemiBoldText(
          text: type.label,
          fontSize: TextStyles.k12FontSize,
          color: isSelected ? kColorWhite : AppLightUi.subtitle,
        ),
      ),
    );
  }

  Widget _historyList() {
    return Obx(() {
      if (controller.isLoading.value && controller.items.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: AppLightUi.pink),
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
          color: AppLightUi.pink,
          backgroundColor: AppLightUi.card,
          onRefresh: () async {
            await Future.wait([
              controller.loadSummary(),
              controller.loadHistory(refresh: true),
            ]);
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
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
                        color: AppLightUi.pink,
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
      final accent = _accentFor(type);
      final heroStyle = _heroStyleFor(type);

      return RefreshIndicator(
        color: AppLightUi.pink,
        backgroundColor: AppLightUi.card,
        onRefresh: () async {
          await Future.wait([
            controller.loadSummary(),
            controller.loadHistory(refresh: true),
          ]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 36, 20, 24),
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.94, end: 1),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                decoration: BoxDecoration(
                  color: AppLightUi.card,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppLightUi.border),
                  boxShadow: AppLightUi.cardShadow,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppLightUi.card,
                      accent.withValues(alpha: 0.08),
                      AppLightUi.card,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    DatingEmptyHero(
                      style: error.isNotEmpty
                          ? DatingEmptyHeroStyle.messages
                          : heroStyle,
                      size: 148,
                      accentColors: error.isNotEmpty
                          ? const [AppLightUi.rose, AppLightUi.violet]
                          : [accent, AppLightUi.violet],
                    ),
                    Spacing.v16,
                    SemiBoldText(
                      text: error.isNotEmpty
                          ? 'Unable to load'
                          : 'No ${type.label.toLowerCase()} gifts',
                      fontSize: TextStyles.k16FontSize,
                      color: AppLightUi.title,
                      align: TextAlign.center,
                    ),
                    Spacing.v8,
                    AppText(
                      text: error.isNotEmpty
                          ? error
                          : 'Gifts you send in ${type.label.toLowerCase()} will appear here.',
                      fontSize: TextStyles.k12FontSize,
                      color: AppLightUi.subtitle,
                      align: TextAlign.center,
                    ),
                    if (error.isNotEmpty) ...[
                      Spacing.v16,
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => controller.loadHistory(refresh: true),
                          borderRadius: BorderRadius.circular(16),
                          child: Ink(
                            height: 44,
                            width: 140,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: AppLightUi.familyCtaGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: AppLightUi.pink.withValues(alpha: 0.28),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: SemiBoldText(
                                text: 'Try again',
                                fontSize: TextStyles.k12FontSize,
                                color: kColorWhite,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      Spacing.v10,
                      const AppText(
                        text: 'Pull down to refresh',
                        fontSize: TextStyles.k10FontSize,
                        color: AppLightUi.muted,
                        align: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _giftCard(GiftHistoryItem item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppLightUi.cardDecoration(radius: 20),
      child: Row(
        children: [
          _giftThumb(item),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: item.giftName,
                  fontSize: TextStyles.k14FontSize,
                  color: AppLightUi.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.receiverName.isNotEmpty) ...[
                  Spacing.v6,
                  Row(
                    children: [
                      AppUserAvatar(
                        name: item.receiverName,
                        imageUrl: item.receiverAvatar,
                        size: 20,
                      ),
                      Spacing.h6,
                      Expanded(
                        child: AppText(
                          text: item.receiverName,
                          fontSize: TextStyles.k12FontSize,
                          color: AppLightUi.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (_showContextLine(item)) ...[
                  Spacing.v4,
                  AppText(
                    text: item.contextSubtitle,
                    fontSize: TextStyles.k12FontSize,
                    color: AppLightUi.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (item.createdAtLabel.isNotEmpty) ...[
                  Spacing.v6,
                  AppText(
                    text: item.createdAtLabel,
                    fontSize: TextStyles.k10FontSize,
                    color: AppLightUi.muted,
                  ),
                ],
              ],
            ),
          ),
          Spacing.h10,
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SemiBoldText(
                text: '-${formatLedgerAmount(item.coinsSpent)}',
                fontSize: TextStyles.k16FontSize,
                color: const Color(0xFFE53935),
              ),
              Spacing.v6,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6E8),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppLightUi.gold.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppCoinIcon(size: 11),
                    const SizedBox(width: 4),
                    AppText(
                      text: item.quantity > 1 ? '×${item.quantity}' : 'Coins',
                      fontSize: TextStyles.k10FontSize,
                      color: const Color(0xFFB86A00),
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

  bool _showContextLine(GiftHistoryItem item) {
    final context = item.contextSubtitle.trim();
    if (context.isEmpty) return false;
    final receiver = item.receiverName.trim().toLowerCase();
    if (receiver.isNotEmpty && context.toLowerCase() == receiver) return false;
    return true;
  }

  Widget _giftThumb(GiftHistoryItem item) {
    final url = item.giftImage;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppLightUi.pink.withValues(alpha: 0.14),
            AppLightUi.violet.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(color: AppLightUi.pink.withValues(alpha: 0.22)),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? const Icon(kGiftIcon, color: AppLightUi.pink, size: 24)
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(kGiftIcon, color: AppLightUi.pink, size: 24),
            ),
    );
  }

  Color _accentFor(GiftHistoryType type) {
    switch (type) {
      case GiftHistoryType.audioRoom:
        return AppLightUi.violet;
      case GiftHistoryType.liveStream:
        return AppLightUi.pink;
      case GiftHistoryType.pk:
        return AppLightUi.gold;
      case GiftHistoryType.call:
        return AppLightUi.cyan;
    }
  }

  DatingEmptyHeroStyle _heroStyleFor(GiftHistoryType type) {
    switch (type) {
      case GiftHistoryType.audioRoom:
        return DatingEmptyHeroStyle.audio;
      case GiftHistoryType.liveStream:
        return DatingEmptyHeroStyle.live;
      case GiftHistoryType.pk:
        return DatingEmptyHeroStyle.sparks;
      case GiftHistoryType.call:
        return DatingEmptyHeroStyle.messages;
    }
  }
}
