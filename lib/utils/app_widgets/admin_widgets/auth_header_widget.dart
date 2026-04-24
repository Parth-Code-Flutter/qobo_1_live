import 'package:aligned_rewards/constants/image_constants.dart';
import 'package:aligned_rewards/utils/app_widgets/app_spaces.dart';
import 'package:aligned_rewards/utils/text_utils/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class AuthHeaderWidget extends StatelessWidget {
  const AuthHeaderWidget(
      {super.key, required this.title, this.subTitle, required this.onTap});

  final String title;
  final String? subTitle;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Spacing.v20,
          Spacing.h16,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: onTap,
                    child: SvgPicture.asset(
                      kIconArrowBack,
                      height: 18,
                      width: 10,
                    ),
                  ),
                  Spacing.h12,
                  BoldText(
                    text: title,
                    fontSize: 24,
                  ),
                ],
              ),
              SizedBox(
                width: Get.width * 0.85,
                child: Padding(
                  padding: const EdgeInsets.only(left: 28),
                  child: AppText(
                    text: subTitle ??
                        'Lorem ipsum dolor sit amet, consectetur elit. ',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
