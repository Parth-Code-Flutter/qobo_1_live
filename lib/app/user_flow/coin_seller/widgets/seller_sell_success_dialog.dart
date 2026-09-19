import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/widgets/coin_seller_ui_kit.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_coin_icon.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';

/// Premium success dialog after a coin transfer.
class SellerSellSuccessDialog extends StatefulWidget {
  const SellerSellSuccessDialog({
    super.key,
    required this.amount,
    required this.recipient,
    required this.price,
    this.currency = 'INR',
  });

  final int amount;
  final String recipient;
  final num price;
  final String currency;

  static Future<void> show({
    required int amount,
    required String recipient,
    required num price,
    String currency = 'INR',
  }) {
    return Get.dialog<void>(
      SellerSellSuccessDialog(
        amount: amount,
        recipient: recipient,
        price: price,
        currency: currency,
      ),
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
    );
  }

  @override
  State<SellerSellSuccessDialog> createState() =>
      _SellerSellSuccessDialogState();
}

class _SellerSellSuccessDialogState extends State<SellerSellSuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.9, end: 1),
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: kColorWhite,
            border: Border.all(color: CoinSellerUi.borderStrong),
            boxShadow: [
              ...AppLightUi.cardShadow,
              BoxShadow(
                color: CoinSellerUi.mint.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF25D98F),
                      CoinSellerUi.gold,
                      CoinSellerUi.pink,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _successBadge(),
                    Spacing.v16,
                    const SemiBoldText(
                      text: 'Transfer successful',
                      fontSize: 18,
                      color: CoinSellerUi.title,
                    ),
                    Spacing.v4,
                    AppText(
                      text: 'Coins delivered to ${widget.recipient}',
                      fontSize: 12,
                      color: CoinSellerUi.body,
                      align: TextAlign.center,
                    ),
                    Spacing.v16,
                    _amountHero(),
                    Spacing.v12,
                    _detailChips(),
                    Spacing.v12,
                    _ledgerNote(),
                    Spacing.v16,
                    _doneButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _successBadge() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final glow = 0.18 + (_pulse.value * 0.22);
        return Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF86EFAC), Color(0xFF25D98F)],
            ),
            boxShadow: [
              BoxShadow(
                color: CoinSellerUi.mint.withValues(alpha: glow),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          padding: const EdgeInsets.all(3),
          child: const DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kColorWhite,
            ),
            child: Icon(
              Icons.check_rounded,
              color: CoinSellerUi.mint,
              size: 34,
            ),
          ),
        );
      },
    );
  }

  Widget _amountHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            CoinSellerUi.gold.withValues(alpha: 0.14),
            CoinSellerUi.pink.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: CoinSellerUi.gold.withValues(alpha: 0.32)),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppCoinIcon(size: 14, color: CoinSellerUi.gold),
              SizedBox(width: 6),
              AppText(
                text: 'COINS SENT',
                fontSize: 11,
                color: CoinSellerUi.body,
              ),
            ],
          ),
          Spacing.v6,
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFFFFE082),
                CoinSellerUi.gold,
                CoinSellerUi.goldDeep,
              ],
            ).createShader(bounds),
            child: SemiBoldText(
              text: CoinSellerUi.formatCoins(widget.amount),
              fontSize: 32,
              color: kColorWhite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailChips() {
    return Row(
      children: [
        Expanded(
          child: _infoChip(
            icon: Icons.person_rounded,
            label: 'Buyer',
            value: widget.recipient,
            accent: CoinSellerUi.pink,
          ),
        ),
        Spacing.h10,
        Expanded(
          child: _infoChip(
            icon: Icons.payments_rounded,
            label: 'Received',
            value:
                '${widget.currency} ${CoinSellerUi.formatMoney(widget.price)}',
            accent: CoinSellerUi.mint,
          ),
        ),
      ],
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppLightUi.cardSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 5),
              AppText(text: label, fontSize: 11, color: CoinSellerUi.body),
            ],
          ),
          Spacing.v6,
          SemiBoldText(
            text: value,
            fontSize: 13,
            color: CoinSellerUi.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _ledgerNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: CoinSellerUi.violet.withValues(alpha: 0.08),
        border: Border.all(color: CoinSellerUi.violet.withValues(alpha: 0.22)),
      ),
      child: const Row(
        children: [
          Icon(Icons.receipt_long_rounded, size: 16, color: CoinSellerUi.violet),
          SizedBox(width: 8),
          Expanded(
            child: AppText(
              text: 'Sale saved to your Transactions ledger.',
              fontSize: 12,
              color: CoinSellerUi.body,
            ),
          ),
        ],
      ),
    );
  }

  Widget _doneButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: CoinSellerUi.sellButtonGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: CoinSellerUi.pink.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Get.back<void>(),
            borderRadius: BorderRadius.circular(14),
            child: const Center(
              child: SemiBoldText(
                text: 'Done',
                fontSize: 14,
                color: kColorWhite,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
