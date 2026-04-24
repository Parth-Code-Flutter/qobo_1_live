import 'package:aligned_rewards/utils/app_dialogs/app_alert_sheet.dart';
import 'package:aligned_rewards/utils/ui_utils/app_ui_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../constants/color_constants.dart';

class AppDialogs {
  // static void uploadImage({
  //   required BuildContext context,
  //   required void Function({required bool isCamera}) onSelected,
  // }) {
  //   _showBottomSheet(
  //     context: context,
  //     builder: (context) {
  //       return UploadImageSheet(
  //         onSelected: onSelected,
  //       );
  //     },
  //   );
  // }

  static Future<void> selectDate({
    required BuildContext context,
    required void Function(DateTime? date) onSelected,
    required DateTime initialDate,
    required DateTime lastDate,
    required DateTime firstDate,
  }) async {
    // showCupertinoModalPopup<void>(
    //   context: context,
    //   builder: (_) => Container(
    //     height: 220,
    //     decoration: BoxDecoration(color: AppColors.primaryBg),
    //     child: Column(
    //       mainAxisSize: MainAxisSize.min,
    //       children: [
    //         Align(
    //           alignment: Alignment.centerRight,
    //           child: AppTextButton(
    //             text: AppStrings.done,
    //             onPressed: () {
    //               NavHelper.pop(context);
    //             },
    //           ),
    //         ),
    //         SizedBox(
    //           height: 160,
    //           child: CupertinoDatePicker(
    //             backgroundColor: AppColors.primaryBg,
    //             mode: CupertinoDatePickerMode.date,
    //             minimumDate: minDate,
    //             maximumDate: maxDate,
    //             initialDateTime: initialDate,
    //             onDateTimeChanged: onSelected,
    //           ),
    //         ),
    //       ],
    //     ),
    //   ),
    // );

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
            child: child!);
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
    await _showBottomSheet(
      context: context,
      builder: (context) {
        return AppAlertDialog(
          title: title,
          alertText: alertText,
          actionButtonText: actionButtonText,
          negativeClick: negativeClick,
          positiveClick: positiveClick,
        );
      },
    );
  }

  // static Future<void> confirmSheet({
  //   required BuildContext context,
  //   required String title,
  //   required String confirmText,
  //   required String actionButtonText,
  //   required void Function() onConfirm,
  // }) async {
  //   await _showBottomSheet(
  //     context: context,
  //     builder: (context) {
  //       return AppConfirmSheet(
  //         title: title,
  //         confirmText: confirmText,
  //         actionButtonText: actionButtonText,
  //         onConfirm: onConfirm,
  //       );
  //     },
  //   );
  // }

  static Future<void> _showBottomSheet({
    required BuildContext context,
    required Widget Function(BuildContext context) builder,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppUIUtils.primaryRadius),
          topRight: Radius.circular(AppUIUtils.primaryRadius),
        ),
      ),
      builder: builder,
    );
  }
}
