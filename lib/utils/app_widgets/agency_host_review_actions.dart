import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Reject-reason dialog for agency host review flows.
Future<String?> showAgencyHostRejectReasonDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const _RejectReasonDialog(),
  );
}

class _RejectReasonDialog extends StatefulWidget {
  const _RejectReasonDialog();

  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  late final TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submitReject() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      Get.snackbar(
        'Required',
        'Please enter a rejection reason.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1230),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      title: const SemiBoldText(
        text: 'Reject host application',
        fontSize: TextStyles.k16FontSize,
        color: kColorWhite,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppText(
              text:
                  'Please provide a reason. The applicant will see this message.',
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite,
            ),
            Spacing.v12,
            AppTextField(
              controller: _reasonController,
              hintText: 'Rejection reason',
              maxLines: 3,
              minLines: 3,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const AppText(
            text: 'Cancel',
            fontSize: TextStyles.k14FontSize,
            color: kColorHint,
          ),
        ),
        TextButton(
          onPressed: _submitReject,
          child: const SemiBoldText(
            text: 'Reject',
            fontSize: TextStyles.k14FontSize,
            color: Colors.orangeAccent,
          ),
        ),
      ],
    );
  }
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
