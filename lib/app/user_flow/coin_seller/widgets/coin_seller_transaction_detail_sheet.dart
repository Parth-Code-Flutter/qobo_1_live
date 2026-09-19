import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/controllers/coin_seller_controller.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/models/seller_sale.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/widgets/coin_seller_ui_kit.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_coin_icon.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';

/// Full transaction detail + view / edit / reverse actions.
class CoinSellerTransactionDetailSheet extends StatelessWidget {
  const CoinSellerTransactionDetailSheet({
    super.key,
    required this.sale,
    required this.controller,
  });

  final SellerSale sale;
  final CoinSellerController controller;

  static Future<void> show({
    required SellerSale sale,
    required CoinSellerController controller,
  }) {
    return Get.bottomSheet<void>(
      CoinSellerTransactionDetailSheet(sale: sale, controller: controller),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
    );
  }

  @override
  Widget build(BuildContext context) {
    final note = (sale.note ?? '').trim();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
      ),
      decoration: AppLightUi.bottomSheetDecoration(topRadius: 28),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CoinSellerUi.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Spacing.v16,
              _header(),
              Spacing.v16,
              _summaryStrip(),
              Spacing.v16,
              _detailsCard(note),
              if (sale.canEdit || sale.canReverse) ...[
                Spacing.v16,
                _actionsRow(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppLightUi.glossRingGradient,
          ),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: kColorWhite,
            ),
            child: AppUserAvatar(
              name: sale.displayName,
              imageUrl: sale.avatarUrl,
              size: 52,
            ),
          ),
        ),
        Spacing.h12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SemiBoldText(
                text: sale.displayName,
                fontSize: 17,
                color: CoinSellerUi.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Spacing.v4,
              AppText(
                text: sale.displayUserId,
                fontSize: 12,
                color: CoinSellerUi.body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Spacing.h8,
        _StatusChip(sale: sale),
      ],
    );
  }

  Widget _summaryStrip() {
    return Row(
      children: [
        Expanded(
          child: _summaryTile(
            icon: const AppCoinIcon(size: 18, color: CoinSellerUi.gold),
            label: 'Coins sent',
            value: CoinSellerUi.formatCoins(sale.amount),
            accent: CoinSellerUi.gold,
          ),
        ),
        Spacing.h10,
        Expanded(
          child: _summaryTile(
            icon: Icon(
              Icons.payments_rounded,
              size: 18,
              color: sale.isReversed ? CoinSellerUi.body : CoinSellerUi.mint,
            ),
            label: 'Price',
            value: '${sale.currency} ${CoinSellerUi.formatMoney(sale.price)}',
            accent: sale.isReversed ? CoinSellerUi.body : CoinSellerUi.mint,
          ),
        ),
      ],
    );
  }

  Widget _summaryTile({
    required Widget icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: accent.withValues(alpha: 0.08),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              icon,
              Spacing.h6,
              AppText(text: label, fontSize: 11, color: CoinSellerUi.body),
            ],
          ),
          Spacing.v8,
          SemiBoldText(
            text: value,
            fontSize: 16,
            color: CoinSellerUi.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _detailsCard(String note) {
    final txId = sale.id.isEmpty ? '—' : sale.id;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: kColorWhite,
        border: Border.all(color: CoinSellerUi.borderStrong),
        boxShadow: AppLightUi.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: AppLightUi.iconTileDecoration(
                  CoinSellerUi.violet,
                  radius: 10,
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  size: 16,
                  color: CoinSellerUi.violet,
                ),
              ),
              Spacing.h10,
              const SemiBoldText(
                text: 'Sale details',
                fontSize: 14,
                color: CoinSellerUi.title,
              ),
            ],
          ),
          Spacing.v12,
          _idRow(txId),
          _detailRow(
            icon: Icons.schedule_rounded,
            label: 'Date',
            value: sale.formattedDate,
          ),
          if (note.isNotEmpty)
            _detailRow(
              icon: Icons.notes_rounded,
              label: 'Note',
              value: note,
            ),
        ],
      ),
    );
  }

  Widget _idRow(String txId) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppLightUi.cardSoft,
          border: Border.all(color: CoinSellerUi.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText(
                    text: 'Transaction ID',
                    fontSize: 11,
                    color: CoinSellerUi.body,
                  ),
                  Spacing.v4,
                  SemiBoldText(
                    text: txId,
                    fontSize: 12,
                    color: CoinSellerUi.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (txId != '—')
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Copy ID',
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: txId));
                  Get.snackbar(
                    'Copied',
                    'Transaction ID copied',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: CoinSellerUi.title.withValues(alpha: 0.9),
                    colorText: kColorWhite,
                    margin: const EdgeInsets.all(12),
                    duration: const Duration(seconds: 2),
                  );
                },
                icon: const Icon(
                  Icons.copy_rounded,
                  size: 18,
                  color: CoinSellerUi.violet,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: CoinSellerUi.violet),
          Spacing.h8,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(text: label, fontSize: 11, color: CoinSellerUi.body),
                Spacing.v2,
                SemiBoldText(
                  text: value,
                  fontSize: 13,
                  color: CoinSellerUi.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionsRow() {
    return Row(
      children: [
        if (sale.canEdit)
          Expanded(
            child: _actionButton(
              label: 'Edit price',
              icon: Icons.edit_rounded,
              foreground: CoinSellerUi.violet,
              background: CoinSellerUi.violet.withValues(alpha: 0.10),
              border: CoinSellerUi.violet.withValues(alpha: 0.32),
              onTap: () {
                Get.back<void>();
                controller.openEditTransaction(sale);
              },
            ),
          ),
        if (sale.canEdit && sale.canReverse) Spacing.h10,
        if (sale.canReverse)
          Expanded(
            child: Obx(() {
              final busy = controller.isReversing.value &&
                  controller.reversingSaleId.value == sale.id;
              return _actionButton(
                label: busy ? 'Reversing…' : 'Reverse',
                icon: Icons.undo_rounded,
                foreground: const Color(0xFFE84B6A),
                background: const Color(0xFFE84B6A).withValues(alpha: 0.10),
                border: const Color(0xFFE84B6A).withValues(alpha: 0.32),
                onTap: busy
                    ? null
                    : () {
                        Get.back<void>();
                        controller.reverseSale(sale);
                      },
              );
            }),
          ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color foreground,
    required Color background,
    required Color border,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: background,
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: foreground),
              Spacing.h6,
              SemiBoldText(text: label, fontSize: 13, color: foreground),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.sale});

  final SellerSale sale;

  @override
  Widget build(BuildContext context) {
    final color = sale.statusColor;
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: SemiBoldText(
        text: sale.statusLabel,
        fontSize: 11,
        color: color,
      ),
    );
  }
}
