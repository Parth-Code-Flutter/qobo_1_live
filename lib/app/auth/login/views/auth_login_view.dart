import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/generated/locales.g.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import 'package:get/get.dart';

import '../controllers/auth_login_controller.dart';

class AuthLoginView extends GetView<AuthLoginController> {
  const AuthLoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorWhite,
      appBar: CommonAppBarWidget(title: '', showBackButton: false),
      body: Column(
        children: [
          welcomeTextHeader(),
          const Expanded(
            child: Center(
              child: AppText(text: 'AuthLoginView is working', fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget welcomeTextHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          Image.asset(kIconApp, width: 86, height: 86, fit: BoxFit.contain),
          Spacing.v12,
          BoldText(
            text: LocaleKeys.loginWelcomeTitle.tr,
            fontSize: TextStyles.k22FontSize,
            color: kColorText,
          ),
          Spacing.v2,
          MediumText(
            text: LocaleKeys.loginSubTitle.tr,
            fontSize: TextStyles.k16FontSize,
            color: kColorHint,
          ),
        ],
      ),
    );
  }
}
