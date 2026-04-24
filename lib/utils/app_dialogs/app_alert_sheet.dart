import 'package:aligned_rewards/constants/color_constants.dart';
import 'package:aligned_rewards/constants/image_constants.dart';
import 'package:aligned_rewards/generated/locales.g.dart';
import 'package:aligned_rewards/utils/app_widgets/app_button.dart';
import 'package:aligned_rewards/utils/app_widgets/app_size_extension.dart';
import 'package:aligned_rewards/utils/app_widgets/app_spaces.dart';
import 'package:aligned_rewards/utils/text_utils/app_text.dart';
import 'package:aligned_rewards/utils/text_utils/text_styles.dart';
import 'package:aligned_rewards/utils/ui_utils/app_ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

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
    return Dialog(
      backgroundColor: kColorWhite,
      shadowColor: Colors.transparent,
      surfaceTintColor: kColorWhite,
      insetPadding: EdgeInsets.symmetric(horizontal: 26),
      shape:
          RoundedRectangleBorder(borderRadius: AppUIUtils.primaryBorderRadius),
      child: ClipRRect(
        borderRadius: AppUIUtils.primaryBorderRadius,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: kColorWhite,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _warningIcon,
              Spacing.v12,
              _title,
              Spacing.v2,
              if (alertText.isNotEmpty) _alertText,
              Spacing.v16,
              _actions(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Warning icon displayed at the top of the dialog.
  ///
  /// Uses an existing SVG icon inside a circular background to
  /// visually indicate that this is a destructive / important action.
  /// If you later add a dedicated warning SVG, simply update the
  /// [kIconDelete] reference below to point to that asset instead.
  Widget get _warningIcon {
    return Center(
      child: Image.asset(
        kIconWarning,
        height: 45,
        width: 45,
      ),
    );
  }

  Widget get _title {
    return SizedBox(
      width: 0.7.screenWidth,
      child: AppText(
        text: title,
        fontSize: 14,
        color: kColorTextGrey,
        align: TextAlign.center,
      ),
    );
  }

  Widget get _alertText {
    return SemiBoldText(
      text: alertText,
      fontSize: 18,
      color: kColorBlack,
    );
  }

  Widget _actions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: appButton(
              buttonHeight: 38,
              onPressed: positiveClick,
              buttonText: actionButtonText,
              buttonBorderColor: kColorRed,
              buttonColor: kColorWhite,
              // Use a simple solid-color button (no gradient) for the primary action.
              isGradient: false,
              textStyle: TextStyles.kSemiBoldLato( colors: kColorRed,),
            ),
          ),
          Spacing.h16,
          Expanded(
            child: appButton(
              buttonHeight: 38,
              onPressed: negativeClick,
              buttonText: negativeButtonText ?? 'No, cancel',
              buttonBorderColor: kColorGrey187,
              buttonColor: kColorGrey187,
              // Use a simple solid-color button (no gradient) for the cancel action.
              isGradient: false,
              textStyle: TextStyles.kSemiBoldLato(

              ),
            ),
          ),
        ],
      ),
    );
  }
}
