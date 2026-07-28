import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/models/seller_sale.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/widgets/coin_seller_ui_kit.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';

enum CoinSellerTransactionAction { view, edit, reverse }

/// Premium glass actions sheet for a sale row.
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
      barrierColor: Colors.black.withValues(alpha: 0.55),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        14,
        0,
        14,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xF02A1638),
                  Color(0xF0140C22),
                  Color(0xF00C0814),
                ],
              ),
              border: Border.all(
                color: CoinSellerUi.gold.withValues(alpha: 0.28),
              ),
              boxShadow: [
                BoxShadow(
                  color: CoinSellerUi.goldDeep.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -40,
                  right: -20,
                  child: IgnorePointer(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: CoinSellerUi.gold.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -36,
                  left: -16,
                  child: IgnorePointer(
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFF4081).withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
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
                      _header(),
                      Spacing.v16,
                      _actionTile(
                        icon: Icons.visibility_rounded,
                        title: 'View details',
                        subtitle: 'Full sale receipt & notes',
                        accent: CoinSellerUi.sky,
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
                          accent: const Color(0xFFFF6B6B),
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
                            foregroundColor: Colors.white70,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const SemiBoldText(
                            text: 'Cancel',
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: CoinSellerUi.gold.withValues(alpha: 0.55),
                width: 2,
              ),
            ),
            child: AppUserAvatar(
              name: sale.displayName,
              imageUrl: sale.avatarUrl,
              size: 44,
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
                  color: kColorWhite,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Spacing.v4,
                AppText(
                  text:
                      '${CoinSellerUi.formatCoins(sale.amount)} coins · '
                      '${sale.currency} ${CoinSellerUi.formatMoney(sale.price)}',
                  fontSize: 11,
                  color: Colors.white54,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: sale.statusColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: sale.statusColor.withValues(alpha: 0.4),
              ),
            ),
            child: SemiBoldText(
              text: sale.statusLabel,
              fontSize: 10,
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
            gradient: LinearGradient(
              colors: [
                accent.withValues(alpha: destructive ? 0.16 : 0.12),
                Colors.white.withValues(alpha: 0.03),
              ],
            ),
            border: Border.all(
              color: accent.withValues(alpha: destructive ? 0.4 : 0.28),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.18),
                  border: Border.all(color: accent.withValues(alpha: 0.45)),
                ),
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
                      color: kColorWhite,
                    ),
                    Spacing.v2,
                    AppText(
                      text: subtitle,
                      fontSize: 11,
                      color: Colors.white54,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: accent.withValues(alpha: 0.8),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
