import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Premium confirmation after a mall purchase.
class MallPurchaseSuccessDialog extends StatefulWidget {
  const MallPurchaseSuccessDialog({
    super.key,
    required this.name,
    required this.price,
  });

  final String name;
  final int price;

  static Future<void> show({required String name, required int price}) {
    return Get.dialog<void>(
      MallPurchaseSuccessDialog(name: name, price: price),
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.46),
    );
  }

  @override
  State<MallPurchaseSuccessDialog> createState() =>
      _MallPurchaseSuccessDialogState();
}

class _MallPurchaseSuccessDialogState extends State<MallPurchaseSuccessDialog>
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.86, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          decoration: BoxDecoration(
            color: kColorWhite,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppLightUi.pink.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: AppLightUi.pink.withValues(alpha: 0.22),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 5,
                width: double.infinity,
                decoration: const BoxDecoration(gradient: AppLightUi.familyCtaGradient),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _badge(),
                    Spacing.v16,
                    const SemiBoldText(
                      text: 'Purchase complete',
                      fontSize: TextStyles.k18FontSize,
                      color: AppLightUi.title,
                      align: TextAlign.center,
                    ),
                    Spacing.v6,
                    SemiBoldText(
                      text: widget.name,
                      fontSize: TextStyles.k16FontSize,
                      color: AppLightUi.pink,
                      align: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacing.v6,
                    const AppText(
                      text: 'Added to your Backpack',
                      fontSize: TextStyles.k12FontSize,
                      color: AppLightUi.subtitle,
                      align: TextAlign.center,
                    ),
                    Spacing.v16,
                    _priceChip(),
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

  Widget _badge() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final glow = 0.28 + (_pulse.value * 0.28);
        return Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppLightUi.familyCtaGradient,
            boxShadow: [
              BoxShadow(
                color: AppLightUi.pink.withValues(alpha: glow),
                blurRadius: 22,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        );
      },
      child: const Icon(
        Icons.check_rounded,
        color: kColorWhite,
        size: 42,
      ),
    );
  }

  Widget _priceChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFF6D8),
            AppLightUi.gold.withValues(alpha: 0.22),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppLightUi.gold.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.diamond_rounded, color: Color(0xFFD97706), size: 16),
          Spacing.h6,
          SemiBoldText(
            text: '${widget.price} Diamonds paid',
            fontSize: TextStyles.k12FontSize,
            color: const Color(0xFF9A5B00),
          ),
        ],
      ),
    );
  }

  Widget _doneButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppLightUi.familyCtaGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppLightUi.pink.withValues(alpha: 0.32),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: Get.back,
            child: const Center(
              child: SemiBoldText(
                text: 'Awesome',
                fontSize: TextStyles.k16FontSize,
                color: kColorWhite,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
