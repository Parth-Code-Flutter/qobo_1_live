import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/widgets/coin_seller_ui_kit.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/social_user_card.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_coin_icon.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';

/// Premium confirm dialog before coins leave the merchant wallet.
class CoinSellerConfirmTransferDialog extends StatefulWidget {
  const CoinSellerConfirmTransferDialog({
    super.key,
    required this.buyer,
    required this.amount,
    required this.price,
    this.currency = 'INR',
  });

  final SocialUserCard buyer;
  final int amount;
  final num price;
  final String currency;

  static Future<bool?> show({
    required SocialUserCard buyer,
    required int amount,
    required num price,
    String currency = 'INR',
  }) {
    return Get.dialog<bool>(
      CoinSellerConfirmTransferDialog(
        buyer: buyer,
        amount: amount,
        price: price,
        currency: currency,
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.45),
    );
  }

  @override
  State<CoinSellerConfirmTransferDialog> createState() =>
      _CoinSellerConfirmTransferDialogState();
}

class _CoinSellerConfirmTransferDialogState
    extends State<CoinSellerConfirmTransferDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
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
                color: CoinSellerUi.pink.withValues(alpha: 0.16),
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
                  gradient: CoinSellerUi.sellButtonGradient,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _headerBadge(),
                    Spacing.v12,
                    const SemiBoldText(
                      text: 'Ready to send coins?',
                      fontSize: 18,
                      color: CoinSellerUi.title,
                    ),
                    Spacing.v4,
                    const AppText(
                      text: 'Double-check the buyer before confirming',
                      fontSize: 12,
                      color: CoinSellerUi.body,
                      align: TextAlign.center,
                    ),
                    Spacing.v16,
                    _transferVisual(),
                    Spacing.v12,
                    _amountHero(),
                    Spacing.v10,
                    _priceChip(),
                    Spacing.v12,
                    _warningBanner(),
                    Spacing.v16,
                    _actions(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerBadge() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final glow = 0.18 + (_pulse.value * 0.22);
        return Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppLightUi.glossRingGradient,
            boxShadow: [
              BoxShadow(
                color: CoinSellerUi.gold.withValues(alpha: glow),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          padding: const EdgeInsets.all(3),
          child: const DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFFBF5),
            ),
            child: Center(
              child: AppCoinIcon(size: 30, color: CoinSellerUi.gold),
            ),
          ),
        );
      },
    );
  }

  Widget _transferVisual() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppLightUi.cardSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CoinSellerUi.borderStrong),
      ),
      child: Row(
        children: [
          _partyChip(
            label: 'You',
            icon: Icons.storefront_rounded,
            accent: CoinSellerUi.gold,
          ),
          Expanded(child: _coinTrail()),
          _partyChip(
            label: widget.buyer.name,
            avatarName: widget.buyer.name,
            avatarUrl: widget.buyer.displayPicture,
            accent: CoinSellerUi.pink,
          ),
        ],
      ),
    );
  }

  Widget _partyChip({
    required String label,
    required Color accent,
    IconData? icon,
    String? avatarName,
    String? avatarUrl,
  }) {
    return Column(
      children: [
        if (avatarName != null)
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
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
                name: avatarName,
                imageUrl: avatarUrl,
                size: 42,
              ),
            ),
          )
        else
          Container(
            width: 46,
            height: 46,
            decoration: AppLightUi.iconTileDecoration(accent, radius: 23),
            child: Icon(icon, color: accent, size: 22),
          ),
        Spacing.v6,
        SizedBox(
          width: 72,
          child: SemiBoldText(
            text: label,
            fontSize: 11,
            color: CoinSellerUi.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            align: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _coinTrail() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        return SizedBox(
          height: 42,
          child: CustomPaint(
            painter: _CoinTrailPainter(progress: _pulse.value),
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
        border: Border.all(color: CoinSellerUi.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          const AppText(
            text: 'COINS TO SEND',
            fontSize: 11,
            color: CoinSellerUi.body,
          ),
          Spacing.v4,
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFFFFE082),
                CoinSellerUi.gold,
                CoinSellerUi.goldDeep,
              ],
            ).createShader(bounds),
            child: BoldText(
              text: CoinSellerUi.formatCoins(widget.amount),
              fontSize: 34,
              color: kColorWhite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: CoinSellerUi.mint.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: CoinSellerUi.mint.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.payments_rounded, size: 16, color: CoinSellerUi.mint),
          const SizedBox(width: 8),
          const AppText(
            text: 'Received payment',
            fontSize: 12,
            color: CoinSellerUi.body,
          ),
          const SizedBox(width: 8),
          SemiBoldText(
            text: '${widget.currency} ${CoinSellerUi.formatMoney(widget.price)}',
            fontSize: 13,
            color: CoinSellerUi.title,
          ),
        ],
      ),
    );
  }

  Widget _warningBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CoinSellerUi.violet.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CoinSellerUi.violet.withValues(alpha: 0.22)),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_moon_rounded, size: 18, color: CoinSellerUi.violet),
          SizedBox(width: 8),
          Expanded(
            child: AppText(
              text:
                  'Confirm only after payment is received. Coins credit the buyer instantly.',
              fontSize: 12,
              color: CoinSellerUi.body,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: () => Get.back(result: false),
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
        ),
        Spacing.h10,
        Expanded(
          child: SizedBox(
            height: 48,
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
                  onTap: () => Get.back(result: true),
                  borderRadius: BorderRadius.circular(14),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bolt_rounded, color: kColorWhite, size: 18),
                      SizedBox(width: 6),
                      SemiBoldText(
                        text: 'Send coins',
                        fontSize: 13,
                        color: kColorWhite,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CoinTrailPainter extends CustomPainter {
  _CoinTrailPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(8, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.05,
        size.width - 8,
        size.height * 0.55,
      );

    final line = Paint()
      ..color = CoinSellerUi.gold.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, line);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    for (var i = 0; i < 3; i++) {
      final t = (progress + i * 0.28) % 1.0;
      final tangent = metric.getTangentForOffset(metric.length * t);
      if (tangent == null) continue;
      final r = 3.5 + (i == 1 ? 1.5 : 0);
      canvas.drawCircle(
        tangent.position,
        r,
        Paint()
          ..color = Color.lerp(
            const Color(0xFFFFE082),
            CoinSellerUi.goldDeep,
            i / 2,
          )!,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CoinTrailPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
