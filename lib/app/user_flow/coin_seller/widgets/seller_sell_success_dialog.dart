import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/widgets/coin_seller_ui_kit.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
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
      barrierColor: Colors.black.withValues(alpha: 0.72),
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
        tween: Tween(begin: 0.86, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: ((scale - 0.86) / 0.14).clamp(0.0, 1.0),
              child: child,
            ),
          );
        },
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
                  color: CoinSellerUi.mint.withValues(alpha: 0.32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: CoinSellerUi.mint.withValues(alpha: 0.18),
                    blurRadius: 36,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 28,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  _glowBlob(
                    top: -36,
                    right: -24,
                    color: CoinSellerUi.mint.withValues(alpha: 0.18),
                    size: 130,
                  ),
                  _glowBlob(
                    bottom: -48,
                    left: -20,
                    color: CoinSellerUi.gold.withValues(alpha: 0.14),
                    size: 140,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _successBadge(),
                        Spacing.v16,
                        const SemiBoldText(
                          text: 'Transfer successful',
                          fontSize: 18,
                          color: kColorWhite,
                        ),
                        Spacing.v4,
                        AppText(
                          text: 'Coins delivered to ${widget.recipient}',
                          fontSize: 12,
                          color: Colors.white54,
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
        ),
      ),
    );
  }

  Widget _successBadge() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final glow = 0.28 + (_pulse.value * 0.32);
        return Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [
                Color(0xFF86EFAC),
                Color(0xFF22C55E),
                Color(0xFF15803D),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: CoinSellerUi.mint.withValues(alpha: glow),
                blurRadius: 24,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF102018),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: CoinSellerUi.mint,
              size: 36,
            ),
          ),
        );
      },
    );
  }

  Widget _amountHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CoinSellerUi.gold.withValues(alpha: 0.22),
            const Color(0xFFFF4081).withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        border: Border.all(color: CoinSellerUi.gold.withValues(alpha: 0.28)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.monetization_on_rounded,
                color: CoinSellerUi.gold.withValues(alpha: 0.9),
                size: 14,
              ),
              const SizedBox(width: 6),
              const AppText(
                text: 'COINS SENT',
                fontSize: 10,
                color: Colors.white54,
              ),
            ],
          ),
          Spacing.v8,
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFFF8E1), Color(0xFFFFC107), Color(0xFFFF8F00)],
            ).createShader(bounds),
            child: SemiBoldText(
              text: CoinSellerUi.formatCoins(widget.amount),
              fontSize: 34,
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
            accent: const Color(0xFFFF4081),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _infoChip(
            icon: Icons.payments_rounded,
            label: 'Received',
            value: '${widget.currency} ${CoinSellerUi.formatMoney(widget.price)}',
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
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: accent),
              const SizedBox(width: 5),
              AppText(
                text: label,
                fontSize: 10,
                color: Colors.white54,
              ),
            ],
          ),
          Spacing.v6,
          SemiBoldText(
            text: value,
            fontSize: 13,
            color: kColorWhite,
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
        color: CoinSellerUi.mint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CoinSellerUi.mint.withValues(alpha: 0.22)),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_rounded, color: CoinSellerUi.mint, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: AppText(
              text: 'Stock and sales ledger updated instantly.',
              fontSize: 11,
              color: Colors.white60,
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
              color: CoinSellerUi.goldDeep.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Get.back(),
            borderRadius: BorderRadius.circular(14),
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.done_all_rounded, color: kColorWhite, size: 18),
                  SizedBox(width: 6),
                  SemiBoldText(
                    text: 'Done',
                    fontSize: 14,
                    color: kColorWhite,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _glowBlob({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required Color color,
    required double size,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }
}
