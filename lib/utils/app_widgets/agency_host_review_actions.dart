import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_dialogs/common_app_dialog.dart';
import 'package:qobo_one_live/utils/app_widgets/admin_agency_chrome.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Reject-reason dialog for agency host review flows.
Future<String?> showAgencyHostRejectReasonDialog(BuildContext context) async {
  final reasonController = TextEditingController();
  final confirmed = await CommonAppDialog.show<bool>(
    context,
    title: 'Reject host application',
    message: 'Please provide a reason. The applicant will see this message.',
    icon: Icons.person_off_rounded,
    iconAccent: AdminAgencyUi.rose,
    barrierDismissible: false,
    content: AppTextField(
      controller: reasonController,
      hintText: 'Rejection reason',
      maxLines: 3,
      minLines: 3,
      textInputAction: TextInputAction.done,
    ),
    actions: const [
      CommonAppDialogAction(label: 'Cancel', result: false),
      CommonAppDialogAction(
        label: 'Reject',
        isPrimary: true,
        isDestructive: true,
        result: true,
      ),
    ],
  );

  final reason = reasonController.text.trim();
  reasonController.dispose();
  if (confirmed != true) return null;
  if (reason.isEmpty) {
    Get.snackbar(
      'Required',
      'Please enter a rejection reason.',
      snackPosition: SnackPosition.BOTTOM,
    );
    return null;
  }
  return reason;
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
                side: BorderSide(
                  color: Colors.orangeAccent.withValues(alpha: 0.7),
                ),
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
