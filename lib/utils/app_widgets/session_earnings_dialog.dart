import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/services/session/session_earnings_tracker.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/session_earnings_utils.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Premium host dialog for session earnings + withdraw entry.
class SessionEarningsDialog extends StatefulWidget {
  const SessionEarningsDialog({
    super.key,
    required this.tracker,
    required this.onWithdraw,
    this.unitLabel = 'coins',
  });

  final SessionEarningsTracker tracker;
  final VoidCallback onWithdraw;
  final String unitLabel;

  static Future<void> show({
    required SessionEarningsTracker tracker,
    required VoidCallback onWithdraw,
    String unitLabel = 'coins',
  }) {
    return Get.dialog<void>(
      SessionEarningsDialog(
        tracker: tracker,
        onWithdraw: onWithdraw,
        unitLabel: unitLabel,
      ),
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.72),
    );
  }

  @override
  State<SessionEarningsDialog> createState() => _SessionEarningsDialogState();
}

class _SessionEarningsDialogState extends State<SessionEarningsDialog>
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.88, end: 1),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: ((scale - 0.88) / 0.12).clamp(0.0, 1.0),
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
                  color: kColorWalletAmount.withValues(alpha: 0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: kColorWalletAmount.withValues(alpha: 0.2),
                    blurRadius: 32,
                    spreadRadius: 1,
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
                    right: -18,
                    color: kColorWalletAmount.withValues(alpha: 0.18),
                    size: 120,
                  ),
                  _glowBlob(
                    bottom: -40,
                    left: -16,
                    color: const Color(0xFFFF4081).withValues(alpha: 0.12),
                    size: 130,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _coinBadge(),
                        Spacing.v16,
                        const SemiBoldText(
                          text: 'Session earnings',
                          fontSize: TextStyles.k18FontSize,
                          color: kColorWhite,
                        ),
                        Spacing.v4,
                        AppText(
                          text: 'Coins earned in this room so far',
                          fontSize: TextStyles.k12FontSize,
                          color: Colors.white54,
                          align: TextAlign.center,
                        ),
                        Spacing.v16,
                        _amountHero(),
                        Spacing.v12,
                        _noteBanner(),
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

  Widget _coinBadge() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final glow = 0.28 + (_pulse.value * 0.3);
        return Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [
                Color(0xFFFFF8E1),
                Color(0xFFFFC107),
                Color(0xFFFF8F00),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: kColorWalletAmount.withValues(alpha: glow),
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
            child: const Icon(
              Icons.monetization_on_rounded,
              color: kColorWalletAmount,
              size: 34,
            ),
          ),
        );
      },
    );
  }

  Widget _amountHero() {
    return Obx(() {
      final amount = SessionEarningsUtils.formatAmountForBanner(
        widget.tracker.displayCoins,
      );
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kColorWalletAmount.withValues(alpha: 0.22),
              const Color(0xFFFF4081).withValues(alpha: 0.1),
              Colors.white.withValues(alpha: 0.03),
            ],
          ),
          border: Border.all(
            color: kColorWalletAmount.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            const AppText(
              text: 'EARNED THIS SESSION',
              fontSize: TextStyles.k10FontSize,
              color: Colors.white54,
            ),
            Spacing.v8,
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFFFFF8E1),
                  Color(0xFFFFC107),
                  Color(0xFFFF8F00),
                ],
              ).createShader(bounds),
              child: SemiBoldText(
                text: amount,
                fontSize: 34,
                color: kColorWhite,
              ),
            ),
            Spacing.v4,
            AppText(
              text: widget.unitLabel,
              fontSize: TextStyles.k12FontSize,
              color: Colors.white60,
            ),
          ],
        ),
      );
    });
  }

  Widget _noteBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.white54, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: AppText(
              text: 'Withdraw anytime from your wallet. Session total updates live.',
              fontSize: TextStyles.k10FontSize,
              color: Colors.white60,
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
            height: 50,
            child: OutlinedButton(
              onPressed: () => Get.back(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const SemiBoldText(
                text: 'Close',
                fontSize: TextStyles.k12FontSize,
                color: Colors.white70,
              ),
            ),
          ),
        ),
        Spacing.h12,
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 50,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFC107), Color(0xFFFF8F00)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: kColorWalletAmount.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Get.back();
                    widget.onWithdraw();
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_rounded,
                          color: kColorBlack,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        SemiBoldText(
                          text: 'Withdraw',
                          fontSize: TextStyles.k12FontSize,
                          color: kColorBlack,
                        ),
                      ],
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
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}
