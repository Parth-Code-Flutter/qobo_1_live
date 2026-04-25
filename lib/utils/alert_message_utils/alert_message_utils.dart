import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class AlertMessageUtils {
  // Ensure only ONE dialog-based loader is shown at a time
  static bool _isLoaderVisible = false;

  /// show success popup snackBar message
  void showSuccessSnackBar(String message, {String? title}) {
    try {
      // Check if context is still valid
      if (Get.context == null || Get.overlayContext == null) {
        LoggerUtils.logger.w('Context is null, cannot show snackbar');
        return;
      }
      
      Get.snackbar(
        'Success',
        message,
        titleText: SemiBoldText(
          text: title ?? 'Success',
          color: kColorBlack,
        ),
        messageText: SemiBoldText(
          text: message,
          color: kColorBlack,
        ),
        snackPosition: SnackPosition.BOTTOM,
        colorText: kColorBlack,
        backgroundColor: kColorWhite,
        margin: const EdgeInsets.all(12),
      );
    } catch (e) {
      LoggerUtils.logger.w('Error showing success snackbar: $e');
    }
  }

  /// show error popup snackBar message
  void showErrorSnackBar(String message) {
    try {
      // Check if context is still valid
      if (Get.context == null || Get.overlayContext == null) {
        LoggerUtils.logger.w('Context is null, cannot show snackbar');
        return;
      }
      
      Get.snackbar(
        'Error',
        message,
        titleText: AppText(
          text: 'Error',
          style: TextStyles.kRegularPoppins(colors: kColorBlack),
        ),
        messageText: AppText(
          text: message,
          style: TextStyles.kRegularPoppins(colors: kColorBlack),
        ),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: kColorWhite,
        colorText: kColorBlack,
        margin: const EdgeInsets.only(bottom: 10, left: 8, right: 8),
      );
    } catch (e) {
      LoggerUtils.logger.w('Error showing error snackbar: $e');
    }
  }

  void showErrorSnackBar1(String text) {
    Flushbar<void>(
      message: text,
      messageText: AppText(
        text: text,
        style: TextStyles.kRegularPoppins(colors: kColorBlack),
      ),
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      // leftBarIndicatorColor: Colors.white,
      duration: const Duration(seconds: 3),
      backgroundColor: kColorWhite,
    ).show(Get.context!);
  }

  void showSuccessSnackBar1(String text,
      {Color? bgColor, Color? leftBarIndicatorColor, Color? textColor}) {
    Flushbar<void>(
      message: text,
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      leftBarIndicatorColor: leftBarIndicatorColor ?? kColorBlack,
      duration: const Duration(seconds: 3),
      backgroundColor: bgColor ?? kColorWhite,
      messageText: MediumText(
        text: text,
        color: textColor ?? kColorBlack,
      ),
    ).show(Get.context!);
  }

  /// show circular progress bar
  void showProgressDialog() {
    try {
      if (_isLoaderVisible) return;
      if (Get.overlayContext == null) return;

      _isLoaderVisible = true;

      showDialog(
        context: Get.overlayContext!,
        barrierDismissible: false,
        builder: (_) => PopScope(
          canPop: false,
          child: Container(
            decoration: BoxDecoration(color: kColorWhite.withValues(alpha: 0.5)),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 56,
              height: 56,
              child: SpinKitFadingCircle(
                color: kColorPrimary,
                size: 48.0,
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      LoggerUtils.logException('showProgressDialog', e);
    }
  }

  /// hider circular progress bar
  void hideProgressDialog() {
    try {
      if (!_isLoaderVisible) return;
      if (Get.overlayContext == null) return;

      Navigator.of(Get.overlayContext!).pop();
      _isLoaderVisible = false;
    } catch (ex) {
      LoggerUtils.logException('hideProgressDialog', ex);
    }
  }
}
