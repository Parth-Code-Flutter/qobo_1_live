import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_dialogs/common_app_dialog.dart';

export 'common_app_dialog.dart';
export 'common_giffy_dialog.dart';
export 'app_alert_sheet.dart';

class AppDialogs {
  static Future<void> selectDate({
    required BuildContext context,
    required void Function(DateTime? date) onSelected,
    required DateTime initialDate,
    required DateTime lastDate,
    required DateTime firstDate,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kColorPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null) return;
    onSelected(date);
  }

  static Future<void> selectTime({
    required BuildContext context,
    required void Function(TimeOfDay? time) onSelected,
    required TimeOfDay initialTime,
  }) async {
    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return child!;
      },
    );

    if (time == null) return;
    onSelected(time);
  }

  static Future<void> alertSheet({
    required BuildContext context,
    required String title,
    required String alertText,
    required String actionButtonText,
    required void Function() positiveClick,
    required void Function() negativeClick,
  }) async {
    final confirmed = await CommonAppDialog.confirm(
      context: context,
      title: title,
      message: alertText,
      confirmLabel: actionButtonText,
      cancelLabel: 'Cancel',
      destructive: true,
    );
    if (confirmed == true) {
      positiveClick();
    } else {
      negativeClick();
    }
  }
}
