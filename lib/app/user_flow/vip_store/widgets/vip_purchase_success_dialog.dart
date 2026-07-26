import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/network_svga_widget.dart';
import 'package:qobo_one_live/utils/app_widgets/profile_background_media.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Success dialog after buying a VIP frame — shows the purchased media.
class VipPurchaseSuccessDialog extends StatelessWidget {
  const VipPurchaseSuccessDialog({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.svgaUrl,
    this.durationLabel,
  });

  final String name;
  final String imageUrl;
  final String svgaUrl;
  final String? durationLabel;

  static Future<void> show({
    required String name,
    required String imageUrl,
    required String svgaUrl,
    String? durationLabel,
  }) {
    return Get.dialog<void>(
      VipPurchaseSuccessDialog(
        name: name,
        imageUrl: imageUrl,
        svgaUrl: svgaUrl,
        durationLabel: durationLabel,
      ),
      barrierDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    const previewSize = 148.0;
    final duration = durationLabel?.trim() ?? '';

    return Dialog(
      backgroundColor: kColorWhite,
      shadowColor: kColorPrimary.withValues(alpha: 0.22),
      surfaceTintColor: kColorWhite,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: kColorPrimary.withValues(alpha: 0.10)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4D6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const SemiBoldText(
                text: 'VIP Equipped',
                fontSize: TextStyles.k12FontSize,
                color: Color(0xFF9A6B00),
              ),
            ),
            Spacing.v16,
            _framePreview(size: previewSize),
            Spacing.v16,
            SemiBoldText(
              text: name,
              fontSize: TextStyles.k18FontSize,
              color: kColorText,
              align: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Spacing.v8,
            AppText(
              text: duration.isNotEmpty
                  ? 'Purchased and equipped automatically.\nValid for $duration.'
                  : 'Purchased and equipped automatically.\nIt will play as your room entrance.',
              fontSize: TextStyles.k14FontSize,
              color: kColorTextGrey,
              align: TextAlign.center,
            ),
            Spacing.v20,
            SizedBox(
              width: double.infinity,
              height: 46,
              child: appButton(
                onPressed: () => Get.back(),
                buttonText: 'Awesome!',
                buttonColor: kColorPrimary,
                textColor: kColorWhite,
                borderRadius: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _framePreview({required double size}) {
    final source = svgaUrl.isNotEmpty ? svgaUrl : imageUrl;

    return Container(
      width: size + 28,
      height: size + 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            kColorPrimary.withValues(alpha: 0.14),
            const Color(0xFFFFD76A).withValues(alpha: 0.28),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: kColorPrimary.withValues(alpha: 0.18)),
      ),
      alignment: Alignment.center,
      child: source.isEmpty
          ? Icon(
              Icons.workspace_premium_rounded,
              color: kColorPrimary.withValues(alpha: 0.75),
              size: 56,
            )
          : _media(source: source, size: size),
    );
  }

  Widget _media({required String source, required double size}) {
    final fallback = imageUrl.isNotEmpty
        ? Image.network(
            imageUrl,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.workspace_premium_rounded,
              color: kColorPrimary.withValues(alpha: 0.75),
              size: 56,
            ),
          )
        : Icon(
            Icons.workspace_premium_rounded,
            color: kColorPrimary.withValues(alpha: 0.75),
            size: 56,
          );

    if (ProfileBackgroundMedia.isSvgaUrl(source) || svgaUrl.isNotEmpty) {
      return NetworkSvgaWidget(
        url: source,
        width: size,
        height: size,
        fit: BoxFit.contain,
        showLoadingIndicator: true,
        fallback: fallback,
      );
    }

    return Image.network(
      source,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}
