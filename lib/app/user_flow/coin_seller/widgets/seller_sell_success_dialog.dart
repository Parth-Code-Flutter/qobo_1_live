import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';

/// Animated success dialog after a coin transfer.
class SellerSellSuccessDialog extends StatelessWidget {
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFF1E1E2D),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.4, end: 1),
              duration: const Duration(milliseconds: 480),
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withValues(alpha: 0.18),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.45),
                  ),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.greenAccent,
                  size: 40,
                ),
              ),
            ),
            Spacing.v16,
            const SemiBoldText(
              text: 'Transfer successful',
              fontSize: 18,
              color: kColorWhite,
            ),
            Spacing.v10,
            AppText(
              text: 'Sent $amount coins to $recipient\n'
                  'for $currency $price.',
              fontSize: 13,
              color: Colors.white70,
              align: TextAlign.center,
            ),
            Spacing.v8,
            const AppText(
              text: 'Your stock and sales ledger have been updated.',
              fontSize: 11,
              color: Colors.white38,
              align: TextAlign.center,
            ),
            Spacing.v20,
            SizedBox(
              width: double.infinity,
              height: 46,
              child: appButton(
                onPressed: () => Get.back(),
                buttonText: 'Done',
                isGradient: true,
                borderRadius: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
