import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Reject-reason dialog for agency host review flows.
Future<String?> showAgencyHostRejectReasonDialog(BuildContext context) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1A1230),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const SemiBoldText(
          text: 'Reject host application',
          fontSize: TextStyles.k16FontSize,
          color: kColorWhite,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppText(
              text: 'Please provide a reason. The applicant will see this message.',
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite,
            ),
            Spacing.v12,
            AppTextField(
              controller: controller,
              hintText: 'Rejection reason',
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const AppText(
              text: 'Cancel',
              fontSize: TextStyles.k14FontSize,
              color: kColorHint,
            ),
          ),
          TextButton(
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.isEmpty) {
                Get.snackbar(
                  'Required',
                  'Please enter a rejection reason.',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }
              Navigator.of(ctx).pop(reason);
            },
            child: const SemiBoldText(
              text: 'Reject',
              fontSize: TextStyles.k14FontSize,
              color: Colors.orangeAccent,
            ),
          ),
        ],
      );
    },
  );
  controller.dispose();
  return result;
}

/// Accept / Reject row for pending host cards and bottom sheets.
class AgencyHostReviewActions extends StatelessWidget {
  const AgencyHostReviewActions({
    super.key,
    required this.onApprove,
    required this.onReject,
    this.isProcessing = false,
    this.compact = false,
  });

  final VoidCallback onApprove;
  final VoidCallback onReject;
  final bool isProcessing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (isProcessing) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: kColorPrimary,
            ),
          ),
        ),
      );
    }

    final height = compact ? 40.0 : 44.0;
    final fontSize =
        compact ? TextStyles.k12FontSize : TextStyles.k14FontSize;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: height,
            child: OutlinedButton(
              onPressed: onReject,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orangeAccent,
                side: BorderSide(color: Colors.orangeAccent.withValues(alpha: 0.7)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: SemiBoldText(
                text: 'Reject',
                fontSize: fontSize,
                color: Colors.orangeAccent,
              ),
            ),
          ),
        ),
        Spacing.h10,
        Expanded(
          child: SizedBox(
            height: height,
            child: appButton(
              onPressed: onApprove,
              buttonText: 'Accept',
              buttonHeight: height,
              isGradient: true,
              textStyle: TextStyles.kSemiBoldPoppins(
                fontSize: fontSize,
                colors: kColorWhite,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
