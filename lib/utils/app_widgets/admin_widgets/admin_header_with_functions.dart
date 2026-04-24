import 'package:aligned_rewards/constants/color_constants.dart';
import 'package:aligned_rewards/utils/app_widgets/app_size_extension.dart';
import 'package:aligned_rewards/utils/app_widgets/app_spaces.dart';
import 'package:aligned_rewards/utils/text_utils/app_text.dart';
import 'package:flutter/material.dart';

class AdminHeaderWithFunctions extends StatelessWidget {
  const AdminHeaderWithFunctions({
    super.key,
    required this.title,
    required this.onTap,
    this.subTitle,
    this.subWidget,
    this.actionWidget,
    this.padding,
  });

  final String title;
  final String? subTitle;
  final Widget? subWidget;
  final Widget? actionWidget;
  final EdgeInsets? padding;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Spacing.h16,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BoldText(
                        text: title,
                        fontSize: 24,
                      ),
                      SizedBox(
                        width: 0.6.screenWidth,
                        child: AppText(
                          text: subTitle ??
                              'Oversee, manage, and achieve your tasks as planned.',
                          fontSize: 10,
                          color: kColorBlack22,
                        ),
                      ),
                    ],
                  ),
                  if (subWidget != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 24),
                      child: subWidget ?? SizedBox.shrink(),
                    ),
                ],
              ),
              if (actionWidget != null) actionWidget ?? SizedBox.shrink(),
            ],
          ),
        ],
      ),
    );
  }
}
