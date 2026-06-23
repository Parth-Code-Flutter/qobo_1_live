import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Shown when `GET /api/live-streaming/verify-access` denies Go Live.
class LiveStreamAccessDeniedDialog extends StatelessWidget {
  const LiveStreamAccessDeniedDialog({
    super.key,
    required this.message,
    required this.onBecomeAgency,
    required this.onAddCoins,
    this.coins,
  });

  final String message;
  final double? coins;
  final VoidCallback onBecomeAgency;
  final VoidCallback onAddCoins;

  static Future<void> show(
    BuildContext context, {
    required String message,
    double? coins,
    required VoidCallback onBecomeAgency,
    required VoidCallback onAddCoins,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => LiveStreamAccessDeniedDialog(
        message: message,
        coins: coins,
        onBecomeAgency: () {
          Navigator.of(dialogContext).pop();
          onBecomeAgency();
        },
        onAddCoins: () {
          Navigator.of(dialogContext).pop();
          onAddCoins();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = message.trim().isNotEmpty
        ? message.trim()
        : 'You need to join an agency or add coins before you can go live.';

    return Dialog(
      backgroundColor: kColorWhite,
      shadowColor: Colors.black26,
      surfaceTintColor: kColorWhite,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: kColorRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.live_tv_rounded,
                color: kColorRed,
                size: 32,
              ),
            ),
            Spacing.v16,
            const SemiBoldText(
              text: 'Live Access Required',
              fontSize: TextStyles.k18FontSize,
              color: kColorText,
              align: TextAlign.center,
            ),
            Spacing.v10,
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kColorHint.withValues(alpha: 0.25)),
              ),
              child: AppText(
                text: body,
                fontSize: TextStyles.k14FontSize,
                color: kColorTextGrey,
                align: TextAlign.center,
              ),
            ),
            if (coins != null) ...[
              Spacing.v12,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.monetization_on_outlined,
                    size: 18,
                    color: kColorWalletAmount.withValues(alpha: 0.9),
                  ),
                  Spacing.h6,
                  AppText(
                    text: 'Your balance: ${coins!.toStringAsFixed(0)} coins',
                    fontSize: TextStyles.k12FontSize,
                    color: kColorTextGrey,
                  ),
                ],
              ),
            ],
            Spacing.v20,
            appButton(
              onPressed: onBecomeAgency,
              buttonText: 'Become Agency',
              buttonHeight: 48,
              isGradient: true,
            ),
            Spacing.v10,
            appButton(
              onPressed: onAddCoins,
              buttonText: 'Add Coins',
              buttonHeight: 48,
              buttonColor: kColorWhite,
              buttonBorderColor: kColorPrimary.withValues(alpha: 0.55),
              isGradient: false,
              textStyle: TextStyles.kSemiBoldPoppins(
                fontSize: TextStyles.k14FontSize,
                colors: kColorPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
