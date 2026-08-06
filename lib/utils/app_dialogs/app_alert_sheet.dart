import 'package:flutter/material.dart';
import 'package:qobo_one_live/utils/app_dialogs/common_app_dialog.dart';
import 'package:qobo_one_live/utils/app_widgets/admin_agency_chrome.dart';

/// Legacy alert entry — now uses the shared premium [CommonAppDialog] shell.
class AppAlertDialog extends StatelessWidget {
  const AppAlertDialog({
    required this.title,
    required this.alertText,
    required this.actionButtonText,
    required this.positiveClick,
    required this.negativeClick,
    this.negativeButtonText,
    super.key,
  });

  final String title;
  final String alertText;
  final String actionButtonText;
  final String? negativeButtonText;
  final void Function() positiveClick;
  final void Function() negativeClick;

  @override
  Widget build(BuildContext context) {
    return CommonAppDialog(
      title: title,
      message: alertText,
      icon: Icons.warning_amber_rounded,
      iconAccent: AdminAgencyUi.rose,
      actions: [
        CommonAppDialogAction(
          label: negativeButtonText ?? 'No, cancel',
          onPressed: negativeClick,
        ),
        CommonAppDialogAction(
          label: actionButtonText,
          isPrimary: true,
          isDestructive: true,
          onPressed: positiveClick,
        ),
      ],
    );
  }
}
