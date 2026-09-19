import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/models/seller_sale.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/widgets/coin_seller_ui_kit.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';

enum CoinSellerTransactionAction { view, edit, reverse }

/// Light actions sheet for a sale row (Manage).
class CoinSellerTransactionActionsSheet extends StatelessWidget {
  const CoinSellerTransactionActionsSheet({
    super.key,
    required this.sale,
  });

  final SellerSale sale;

  static Future<CoinSellerTransactionAction?> show({
    required SellerSale sale,
  }) {
    return Get.bottomSheet<CoinSellerTransactionAction>(
      CoinSellerTransactionActionsSheet(sale: sale),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppLightUi.bottomSheetDecoration(topRadius: 28),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: CoinSellerUi.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Spacing.v16,
              _header(),
              Spacing.v16,
              _actionTile(
                icon: Icons.visibility_rounded,
                title: 'View details',
                subtitle: 'Full sale receipt & notes',
                accent: CoinSellerUi.violet,
                onTap: () => Get.back(
                  result: CoinSellerTransactionAction.view,
                ),
              ),
              if (sale.canEdit) ...[
                Spacing.v10,
                _actionTile(
                  icon: Icons.edit_rounded,
                  title: 'Edit price',
                  subtitle: 'Update amount received',
                  accent: CoinSellerUi.gold,
                  onTap: () => Get.back(
                    result: CoinSellerTransactionAction.edit,
                  ),
                ),
              ],
              if (sale.canReverse) ...[
                Spacing.v10,
                _actionTile(
                  icon: Icons.undo_rounded,
                  title: 'Reverse sale',
                  subtitle: 'Return coins to your stock',
                  accent: const Color(0xFFE84B6A),
                  destructive: true,
                  onTap: () => Get.back(
                    result: CoinSellerTransactionAction.reverse,
                  ),
                ),
              ],
              Spacing.v12,
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CoinSellerUi.body,
                    side: const BorderSide(color: CoinSellerUi.borderStrong),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const SemiBoldText(
                    text: 'Cancel',
                    fontSize: 13,
                    color: CoinSellerUi.body,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kColorWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CoinSellerUi.borderStrong),
        boxShadow: AppLightUi.cardShadow,
      ),
      child: Row(
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
                size: 44,
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
                  fontSize: 14,
                  color: CoinSellerUi.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Spacing.v4,
                AppText(
                  text:
                      '${CoinSellerUi.formatCoins(sale.amount)} coins · '
                      '${sale.currency} ${CoinSellerUi.formatMoney(sale.price)}',
                  fontSize: 12,
                  color: CoinSellerUi.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: sale.statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: sale.statusColor.withValues(alpha: 0.4),
              ),
            ),
            child: SemiBoldText(
              text: sale.statusLabel,
              fontSize: 11,
              color: sale.statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: accent.withValues(alpha: destructive ? 0.08 : 0.06),
            border: Border.all(
              color: accent.withValues(alpha: destructive ? 0.35 : 0.28),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: AppLightUi.iconTileDecoration(accent, radius: 12),
                child: Icon(icon, color: accent, size: 20),
              ),
              Spacing.h12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemiBoldText(
                      text: title,
                      fontSize: 14,
                      color: CoinSellerUi.title,
                    ),
                    Spacing.v2,
                    AppText(
                      text: subtitle,
                      fontSize: 11,
                      color: CoinSellerUi.body,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: accent,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
