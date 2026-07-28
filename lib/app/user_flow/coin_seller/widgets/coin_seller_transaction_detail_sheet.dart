import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/controllers/coin_seller_controller.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/models/seller_sale.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/widgets/coin_seller_ui_kit.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF241535), Color(0xFF120A1E)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Spacing.v16,
          Row(
            children: [
              AppUserAvatar(
                name: sale.displayName,
                imageUrl: sale.avatarUrl,
                size: 52,
              ),
              Spacing.h12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemiBoldText(
                      text: sale.displayName,
                      fontSize: 16,
                      color: kColorWhite,
                    ),
                    Spacing.v4,
                    AppText(
                      text: sale.displayUserId,
                      fontSize: 11,
                      color: Colors.white54,
                    ),
                  ],
                ),
              ),
              _StatusChip(sale: sale),
            ],
          ),
          Spacing.v16,
          _detailRow('Transaction ID', sale.id.isEmpty ? '—' : sale.id),
          _detailRow('Coins sent', CoinSellerUi.formatCoins(sale.amount)),
          _detailRow(
            'Price',
            '${sale.currency} ${CoinSellerUi.formatMoney(sale.price)}',
          ),
          _detailRow('Date', sale.formattedDate),
          if ((sale.note ?? '').trim().isNotEmpty)
            _detailRow('Note', sale.note!.trim()),
          Spacing.v16,
          Row(
            children: [
              if (sale.canEdit)
                Expanded(
                  child: _actionButton(
                    label: 'Edit price',
                    icon: Icons.edit_rounded,
                    color: CoinSellerUi.sky,
                    onTap: () {
                      Get.back<void>();
                      controller.openEditTransaction(sale);
                    },
                  ),
                ),
              if (sale.canEdit && sale.canReverse) Spacing.h10,
              if (sale.canReverse)
                Expanded(
                  child: Obx(
                    () {
                      final busy = controller.isReversing.value &&
                          controller.reversingSaleId.value == sale.id;
                      return _actionButton(
                        label: busy ? 'Reversing…' : 'Reverse',
                        icon: Icons.undo_rounded,
                        color: Colors.redAccent,
                        onTap: busy
                            ? null
                            : () {
                                Get.back<void>();
                                controller.reverseSale(sale);
                              },
                      );
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: AppText(
              text: label,
              fontSize: 11,
              color: Colors.white54,
            ),
          ),
          Expanded(
            child: SemiBoldText(
              text: value,
              fontSize: 12,
              color: kColorWhite,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 46,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              SemiBoldText(text: label, fontSize: 12, color: color),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: sale.statusColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: sale.statusColor.withValues(alpha: 0.45)),
      ),
      child: SemiBoldText(
        text: sale.statusLabel,
        fontSize: 10,
        color: sale.statusColor,
      ),
    );
  }
}
