import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/services/session/session_earnings_tracker.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/session_earnings_utils.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Compact session-earnings pill for room app bars (audio / live / video).
class SessionEarningsBadge extends StatelessWidget {
  const SessionEarningsBadge({
    super.key,
    required this.tracker,
    this.compact = false,
    this.icon = Icons.monetization_on_rounded,
    this.iconColor,
    this.textColor,
    this.backgroundColor,
    this.borderColor,
  });

  final SessionEarningsTracker tracker;
  final bool compact;
  final IconData icon;
  final Color? iconColor;
  final Color? textColor;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final amount = SessionEarningsUtils.formatAmount(tracker.displayCoins);
      return Container(
        height: compact ? 36 : 42,
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.black.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(compact ? 10 : 12),
          border: Border.all(
            color: borderColor ?? kColorWhite.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: compact ? 14 : 16,
              color: iconColor ?? const Color(0xFFFFA10A),
            ),
            Spacing.h4,
            AppText(
              text: amount,
              fontSize: compact
                  ? TextStyles.k10FontSize
                  : TextStyles.k12FontSize,
              color: textColor ?? kColorWhite,
            ),
          ],
        ),
      );
    });
  }
}

/// Host banner for live / video rooms — session earnings, not wallet balance.
class SessionEarningsHostBanner extends StatelessWidget {
  const SessionEarningsHostBanner({
    super.key,
    required this.tracker,
    this.compact = false,
    this.onWithdraw,
    this.unitLabel = 'coins',
  });

  final SessionEarningsTracker tracker;
  final bool compact;
  final VoidCallback? onWithdraw;
  final String unitLabel;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 14,
          vertical: compact ? 10 : 12,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2C1744).withValues(alpha: 0.92),
              const Color(0xFF181B45).withValues(alpha: 0.88),
            ],
          ),
          border: Border.all(color: kColorWalletAmount.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: compact ? 38 : 42,
              height: compact ? 38 : 42,
              decoration: BoxDecoration(
                color: kColorWalletAmount.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: kColorWalletAmount.withValues(alpha: 0.22),
                ),
              ),
              child: const Icon(
                Icons.monetization_on_rounded,
                color: kColorWalletAmount,
                size: 22,
              ),
            ),
            Spacing.h10,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    text: 'Session earnings',
                    fontSize: TextStyles.k10FontSize,
                    color: kColorWhite.withValues(alpha: 0.66),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Spacing.v2,
                  Row(
                    children: [
                      Flexible(
                        child: SemiBoldText(
                          text: SessionEarningsUtils.formatAmount(
                            tracker.displayCoins,
                          ),
                          fontSize: compact
                              ? TextStyles.k16FontSize
                              : TextStyles.k18FontSize,
                          color: kColorWalletAmount,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Spacing.h4,
                      AppText(
                        text: unitLabel,
                        fontSize: TextStyles.k10FontSize,
                        color: kColorWhite.withValues(alpha: 0.70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onWithdraw != null) ...[
              Spacing.h8,
              TextButton(
                onPressed: onWithdraw,
                style: TextButton.styleFrom(
                  minimumSize: Size(compact ? 86 : 96, compact ? 36 : 38),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  backgroundColor: kColorWalletAmount,
                  foregroundColor: kColorBlack,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const SemiBoldText(
                  text: 'Withdraw',
                  fontSize: TextStyles.k12FontSize,
                  color: kColorBlack,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
