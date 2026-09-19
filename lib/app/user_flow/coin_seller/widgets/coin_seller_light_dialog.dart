import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/widgets/coin_seller_ui_kit.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Shared light dialog chrome for Merchant Hub (lavender / white cards).
abstract final class CoinSellerLightDialog {
  CoinSellerLightDialog._();

  static Future<bool?> confirm({
    required String title,
    required String message,
    String? footnote,
    IconData icon = Icons.help_outline_rounded,
    Color accent = CoinSellerUi.violet,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool destructive = false,
    bool barrierDismissible = false,
  }) {
    final confirmColor =
        destructive ? const Color(0xFFE84B6A) : CoinSellerUi.violet;
    return Get.dialog<bool>(
      _CoinSellerLightShell(
        accent: destructive ? const Color(0xFFE84B6A) : accent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: AppLightUi.iconTileDecoration(
                destructive ? const Color(0xFFE84B6A) : accent,
                radius: 18,
              ),
              child: Icon(
                icon,
                size: 26,
                color: destructive ? const Color(0xFFE84B6A) : accent,
              ),
            ),
            Spacing.v16,
            SemiBoldText(
              text: title,
              fontSize: TextStyles.k18FontSize,
              color: CoinSellerUi.title,
              align: TextAlign.center,
            ),
            Spacing.v10,
            AppText(
              text: message,
              fontSize: 13,
              color: CoinSellerUi.body,
              align: TextAlign.center,
            ),
            if ((footnote ?? '').trim().isNotEmpty) ...[
              Spacing.v10,
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: (destructive
                          ? const Color(0xFFE84B6A)
                          : CoinSellerUi.violet)
                      .withValues(alpha: 0.08),
                  border: Border.all(
                    color: (destructive
                            ? const Color(0xFFE84B6A)
                            : CoinSellerUi.violet)
                        .withValues(alpha: 0.22),
                  ),
                ),
                child: AppText(
                  text: footnote!.trim(),
                  fontSize: 12,
                  color: CoinSellerUi.body,
                  align: TextAlign.center,
                ),
              ),
            ],
            Spacing.v20,
            Row(
              children: [
                Expanded(
                  child: _outlineAction(
                    label: cancelLabel,
                    onTap: () => Get.back(result: false),
                  ),
                ),
                Spacing.h10,
                Expanded(
                  child: _filledAction(
                    label: confirmLabel,
                    color: confirmColor,
                    onTap: () => Get.back(result: true),
                    gradient: destructive
                        ? null
                        : CoinSellerUi.sellButtonGradient,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.45),
    );
  }

  static Future<bool?> editTransaction({
    required TextEditingController priceController,
    required TextEditingController noteController,
  }) {
    return Get.dialog<bool>(
      _CoinSellerLightShell(
        accent: CoinSellerUi.violet,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: AppLightUi.iconTileDecoration(
                    CoinSellerUi.violet,
                    radius: 14,
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: CoinSellerUi.violet,
                    size: 22,
                  ),
                ),
                Spacing.h12,
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SemiBoldText(
                        text: 'Edit transaction',
                        fontSize: 17,
                        color: CoinSellerUi.title,
                      ),
                      AppText(
                        text: 'Update price or add a note',
                        fontSize: 12,
                        color: CoinSellerUi.body,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Spacing.v16,
            TextField(
              controller: priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: TextStyles.kRegularPoppins(
                colors: CoinSellerUi.title,
                fontSize: 14,
              ),
              decoration: _fieldDecoration(
                hint: 'Price (INR)',
                icon: Icons.currency_rupee_rounded,
                iconColor: CoinSellerUi.mint,
              ),
            ),
            Spacing.v12,
            TextField(
              controller: noteController,
              maxLines: 2,
              style: TextStyles.kRegularPoppins(
                colors: CoinSellerUi.title,
                fontSize: 14,
              ),
              decoration: _fieldDecoration(
                hint: 'Note (optional)',
                icon: Icons.notes_rounded,
                iconColor: CoinSellerUi.violet,
              ),
            ),
            Spacing.v20,
            Row(
              children: [
                Expanded(
                  child: _outlineAction(
                    label: 'Cancel',
                    onTap: () => Get.back(result: false),
                  ),
                ),
                Spacing.h10,
                Expanded(
                  child: _filledAction(
                    label: 'Save',
                    color: CoinSellerUi.violet,
                    onTap: () => Get.back(result: true),
                    gradient: CoinSellerUi.sellButtonGradient,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.45),
    );
  }

  static InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    required Color iconColor,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyles.kRegularPoppins(
        colors: CoinSellerUi.body,
        fontSize: 13,
      ),
      prefixIcon: Icon(icon, color: iconColor, size: 20),
      filled: true,
      fillColor: kColorWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: CoinSellerUi.borderStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: CoinSellerUi.borderStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: CoinSellerUi.violet, width: 1.4),
      ),
    );
  }

  static Widget _outlineAction({
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: CoinSellerUi.body,
          side: const BorderSide(color: CoinSellerUi.borderStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: SemiBoldText(
          text: label,
          fontSize: 13,
          color: CoinSellerUi.body,
        ),
      ),
    );
  }

  static Widget _filledAction({
    required String label,
    required Color color,
    required VoidCallback onTap,
    Gradient? gradient,
  }) {
    return SizedBox(
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: gradient,
          color: gradient == null ? color : null,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: SemiBoldText(
                text: label,
                fontSize: 13,
                color: kColorWhite,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CoinSellerLightShell extends StatelessWidget {
  const _CoinSellerLightShell({
    required this.child,
    required this.accent,
  });

  final Widget child;
  final Color accent;

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
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: kColorWhite,
            border: Border.all(color: CoinSellerUi.borderStrong),
            boxShadow: [
              ...AppLightUi.cardShadow,
              BoxShadow(
                color: accent.withValues(alpha: 0.16),
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
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent,
                      CoinSellerUi.pink,
                      CoinSellerUi.violet,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
