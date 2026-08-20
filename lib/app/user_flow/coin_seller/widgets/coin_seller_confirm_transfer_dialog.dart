import 'dart:ui';
import 'package:qobo_one_live/utils/app_widgets/app_coin_icon.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/widgets/coin_seller_ui_kit.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/social_user_card.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';

/// Premium confirm sheet before coins leave the merchant wallet.
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
      barrierColor: Colors.black.withValues(alpha: 0.72),
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
                  color: CoinSellerUi.gold.withValues(alpha: 0.28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: CoinSellerUi.goldDeep.withValues(alpha: 0.22),
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
                    top: -40,
                    left: -30,
                    color: CoinSellerUi.gold.withValues(alpha: 0.18),
                    size: 140,
                  ),
                  _glowBlob(
                    bottom: -50,
                    right: -20,
                    color: const Color(0xFFFF4081).withValues(alpha: 0.16),
                    size: 150,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _headerBadge(),
                        Spacing.v12,
                        const SemiBoldText(
                          text: 'Ready to send coins?',
                          fontSize: 18,
                          color: kColorWhite,
                        ),
                        Spacing.v4,
                        const AppText(
                          text: 'Double-check the buyer before confirming',
                          fontSize: 11,
                          color: Colors.white54,
                          align: TextAlign.center,
                        ),
                        Spacing.v16,
                        _transferVisual(),
                        Spacing.v16,
                        _amountHero(),
                        Spacing.v12,
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
        ),
      ),
    );
  }

  Widget _headerBadge() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final glow = 0.35 + (_pulse.value * 0.35);
        return Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [
                Color(0xFFFFE082),
                Color(0xFFFF8F00),
                Color(0xFFFF4081),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: CoinSellerUi.gold.withValues(alpha: glow),
                blurRadius: 22,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF1A1028),
            ),
            child: Center(
              child: AppCoinIcon(size: 32, color: CoinSellerUi.gold),
            ),
          ),
        );
      },
    );
  }

  Widget _transferVisual() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
            accent: const Color(0xFFFF4081),
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
              border: Border.all(color: accent.withValues(alpha: 0.7), width: 2),
            ),
            child: AppUserAvatar(
              name: avatarName,
              imageUrl: avatarUrl,
              size: 44,
            ),
          )
        else
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.16),
              border: Border.all(color: accent.withValues(alpha: 0.45)),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
        Spacing.v6,
        SizedBox(
          width: 72,
          child: SemiBoldText(
            text: label,
            fontSize: 11,
            color: kColorWhite,
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CoinSellerUi.gold.withValues(alpha: 0.22),
            const Color(0xFFFF4081).withValues(alpha: 0.12),
            Colors.black.withValues(alpha: 0.2),
          ],
        ),
        border: Border.all(color: CoinSellerUi.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          const AppText(
            text: 'COINS TO SEND',
            fontSize: 10,
            color: Colors.white54,
          ),
          Spacing.v4,
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFFFFF8E1),
                CoinSellerUi.gold,
                CoinSellerUi.goldDeep,
              ],
            ).createShader(bounds),
            child: BoldText(
              text: CoinSellerUi.formatCoins(widget.amount),
              fontSize: 36,
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
        color: CoinSellerUi.mint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: CoinSellerUi.mint.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.payments_rounded, size: 16, color: CoinSellerUi.mint),
          const SizedBox(width: 8),
          const AppText(
            text: 'Received payment',
            fontSize: 11,
            color: Colors.white70,
          ),
          const SizedBox(width: 8),
          SemiBoldText(
            text: '${widget.currency} ${CoinSellerUi.formatMoney(widget.price)}',
            fontSize: 13,
            color: CoinSellerUi.mint,
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
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.22)),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_moon_rounded, size: 18, color: Colors.orangeAccent),
          SizedBox(width: 8),
          Expanded(
            child: AppText(
              text:
                  'Confirm only after payment is received. Coins credit the buyer instantly.',
              fontSize: 11,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions() {
    const btnHeight = 50.0;
    const labelStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: kColorWhite,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: SizedBox(
            height: btnHeight,
            child: OutlinedButton(
              onPressed: () => Get.back(result: false),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Cancel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: btnHeight,
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
                  onTap: () => Get.back(result: true),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.bolt_rounded,
                            color: kColorWhite,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text('Send coins now', style: labelStyle),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _glowBlob({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required Color color,
    required double size,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
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
      ..color = CoinSellerUi.gold.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, line);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    for (var i = 0; i < 3; i++) {
      final t = ((progress + i * 0.28) % 1.0);
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
          )!
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CoinTrailPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
