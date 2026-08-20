import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/repo/economy/economy_api_utils.dart';
import 'package:qobo_one_live/services/session/session_earnings_tracker.dart';
import 'package:qobo_one_live/utils/app_widgets/admin_agency_chrome.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/session_earnings_utils.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Premium host dialog for session earnings + withdraw entry.
///
/// Matches shared glass dialogs / AdminAgencyUi: dark gradient shell,
/// glow icon, gold hero amount, equal-height CTAs.
class SessionEarningsDialog extends StatefulWidget {
  const SessionEarningsDialog({
    super.key,
    required this.tracker,
    required this.onWithdraw,
    this.unitLabel = 'coins',
    this.title = 'Session earnings',
    this.subtitle = 'Coins earned in this room so far',
    this.noteWithBalance =
        'Withdraw anytime from your wallet. Session total updates live as gifts arrive.',
    this.noteEmpty = 'Receive a gift in this room to start earning coins.',
    this.showWithdraw = true,
    this.primaryLabel = 'Withdraw',
  });

  final SessionEarningsTracker tracker;
  final VoidCallback onWithdraw;
  final String unitLabel;
  final String title;
  final String subtitle;
  final String noteWithBalance;
  final String noteEmpty;
  final bool showWithdraw;
  final String primaryLabel;

  static Future<void> show({
    required SessionEarningsTracker tracker,
    required VoidCallback onWithdraw,
    String unitLabel = 'coins',
    String title = 'Session earnings',
    String subtitle = 'Coins earned in this room so far',
    String noteWithBalance =
        'Withdraw anytime from your wallet. Session total updates live as gifts arrive.',
    String noteEmpty = 'Receive a gift in this room to start earning coins.',
    bool showWithdraw = true,
    String primaryLabel = 'Withdraw',
  }) {
    return Get.dialog<void>(
      SessionEarningsDialog(
        tracker: tracker,
        onWithdraw: onWithdraw,
        unitLabel: unitLabel,
        title: title,
        subtitle: subtitle,
        noteWithBalance: noteWithBalance,
        noteEmpty: noteEmpty,
        showWithdraw: showWithdraw,
        primaryLabel: primaryLabel,
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.9, end: 1),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
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
                  color: AdminAgencyUi.gold.withValues(alpha: 0.38),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AdminAgencyUi.goldDeep.withValues(alpha: 0.22),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -48,
                    right: -28,
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, _) {
                          return Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AdminAgencyUi.gold.withValues(
                                    alpha: 0.14 + _pulse.value * 0.08,
                                  ),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -36,
                    left: -24,
                    child: IgnorePointer(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AdminAgencyUi.pink.withValues(alpha: 0.12),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AdminAgencyUi.glowCoinIcon(
                          accent: AdminAgencyUi.goldDeep,
                          accentEnd: AdminAgencyUi.gold,
                          size: 56,
                          iconSize: 28,
                        ),
                        Spacing.v16,
                        SemiBoldText(
                          text: widget.title,
                          fontSize: TextStyles.k18FontSize,
                          color: kColorWhite,
                          align: TextAlign.center,
                        ),
                        Spacing.v6,
                        AppText(
                          text: widget.subtitle,
                          fontSize: TextStyles.k12FontSize,
                          color: AdminAgencyUi.textSecondary,
                          align: TextAlign.center,
                        ),
                        Spacing.v16,
                        _amountHero(),
                        Spacing.v12,
                        _noteBanner(),
                        Spacing.v20,
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

  Widget _amountHero() {
    return Obx(() {
      final amount = SessionEarningsUtils.formatAmountForBanner(
        widget.tracker.displayCoins,
      );
      final hasEarnings = widget.tracker.displayCoins > 0;
      final usdLabel = formatWholeUsdFromCoins(widget.tracker.displayCoins);

      return AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final glow = hasEarnings ? 0.18 + _pulse.value * 0.16 : 0.08;
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AdminAgencyUi.gold.withValues(alpha: 0.28),
                  AdminAgencyUi.goldDeep.withValues(alpha: 0.12),
                  AdminAgencyUi.pink.withValues(alpha: 0.08),
                  const Color(0xFF1A0B2E),
                ],
              ),
              border: Border.all(
                color: AdminAgencyUi.gold.withValues(alpha: 0.45),
              ),
              boxShadow: [
                BoxShadow(
                  color: AdminAgencyUi.gold.withValues(alpha: glow),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.black.withValues(alpha: 0.28),
                    border: Border.all(
                      color: AdminAgencyUi.gold.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasEarnings
                              ? AdminAgencyUi.mint
                              : AdminAgencyUi.textFaint,
                        ),
                      ),
                      Spacing.h6,
                      SemiBoldText(
                        text: hasEarnings ? 'LIVE SESSION' : 'WAITING FOR GIFTS',
                        fontSize: 10,
                        color: AdminAgencyUi.gold,
                      ),
                    ],
                  ),
                ),
                Spacing.v12,
                AppText(
                  text: 'EARNED THIS SESSION',
                  fontSize: TextStyles.k10FontSize,
                  color: AdminAgencyUi.textMuted,
                ),
                Spacing.v6,
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFFFFF8E1),
                      Color(0xFFFFD166),
                      Color(0xFFFFB020),
                    ],
                  ).createShader(bounds),
                  child: SemiBoldText(
                    text: amount,
                    fontSize: 40,
                    color: kColorWhite,
                  ),
                ),
                Spacing.v2,
                AppText(
                  text: widget.unitLabel,
                  fontSize: TextStyles.k12FontSize,
                  color: AdminAgencyUi.textSecondary,
                ),
                Spacing.v6,
                AppText(
                  text: usdLabel,
                  fontSize: TextStyles.k14FontSize,
                  color: AdminAgencyUi.gold,
                ),
                Spacing.v2,
                AppText(
                  text: '≈ USD (1,000 coins = \$1)',
                  fontSize: TextStyles.k10FontSize,
                  color: AdminAgencyUi.textMuted,
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _noteBanner() {
    return Obx(() {
      final hasEarnings = widget.tracker.displayCoins > 0;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              AdminAgencyUi.violet.withValues(alpha: 0.22),
              AdminAgencyUi.pink.withValues(alpha: 0.1),
            ],
          ),
          border: Border.all(
            color: AdminAgencyUi.violet.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminAgencyUi.glowIcon(
              icon: hasEarnings
                  ? Icons.account_balance_wallet_rounded
                  : Icons.card_giftcard_rounded,
              accent: hasEarnings ? AdminAgencyUi.goldDeep : AdminAgencyUi.pink,
              accentEnd: hasEarnings ? AdminAgencyUi.gold : AdminAgencyUi.violet,
              size: 34,
              iconSize: 16,
            ),
            Spacing.h10,
            Expanded(
              child: AppText(
                text: hasEarnings
                    ? widget.noteWithBalance
                    : widget.noteEmpty,
                fontSize: TextStyles.k12FontSize,
                color: AdminAgencyUi.textSecondary,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _actions() {
    return Obx(() {
      final hasEarnings = widget.tracker.displayCoins > 0;
      return Row(
        children: [
          Expanded(
            child: _secondaryButton(
              label: 'Close',
              onTap: () => Get.back(),
            ),
          ),
          if (hasEarnings && widget.showWithdraw) ...[
            Spacing.h10,
            Expanded(
              child: _primaryButton(
                label: widget.primaryLabel,
                icon: Icons.account_balance_wallet_rounded,
                onTap: () {
                  Get.back();
                  widget.onWithdraw();
                },
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _secondaryButton({
    required String label,
    required VoidCallback onTap,
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
            color: kColorWhite.withValues(alpha: 0.1),
            border: Border.all(color: kColorWhite.withValues(alpha: 0.22)),
          ),
          child: Center(
            child: SemiBoldText(
              text: label,
              fontSize: TextStyles.k14FontSize,
              color: kColorWhite.withValues(alpha: 0.9),
            ),
          ),
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
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
            gradient: AdminAgencyUi.goldButtonGradient,
            boxShadow: [
              BoxShadow(
                color: AdminAgencyUi.goldDeep.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AdminAgencyUi.ctaInk, size: 18),
              Spacing.h6,
              SemiBoldText(
                text: label,
                fontSize: TextStyles.k14FontSize,
                color: AdminAgencyUi.ctaInk,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
