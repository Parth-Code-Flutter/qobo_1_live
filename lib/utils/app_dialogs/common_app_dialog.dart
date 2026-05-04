import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:flutter/material.dart';

/// One row in [CommonAppDialog]. [onPressed] runs after the dialog has been popped.
class CommonAppDialogAction {
  const CommonAppDialogAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}

/// Shared modal shell: white background, rounded card, title, and text-style actions.
///
/// Use [CommonAppDialog.show] from UI code; keep business logic in the caller’s callbacks.
class CommonAppDialog extends StatelessWidget {
  const CommonAppDialog({
    super.key,
    required this.title,
    required this.actions,
  });

  final String title;
  final List<CommonAppDialogAction> actions;

  /// Presents a centered [Dialog] with a white surface (see [kColorWhite]).
  static Future<void> show(
    BuildContext context, {
    required String title,
    required List<CommonAppDialogAction> actions,
    bool barrierDismissible = true,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) =>
          CommonAppDialog(title: title, actions: actions),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kColorWhite,
      shadowColor: Colors.transparent,
      surfaceTintColor: kColorWhite,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SemiBoldText(
              text: title,
              fontSize: TextStyles.k16FontSize,
              color: kColorText,
              align: TextAlign.center,
            ),
            Spacing.v16,
            ...actions.map(
              (action) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: appButton(
                    onPressed: () {
                      Navigator.of(context).pop<void>();
                      action.onPressed();
                    },
                    buttonText: action.label,
                    textColor: kColorPrimary,
                    buttonColor: kColorWhite,
                    buttonHeight: 42,
                    textStyle: TextStyles.kSemiBoldPoppins(
                      fontSize: TextStyles.k14FontSize,
                      colors: kColorPrimary
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
