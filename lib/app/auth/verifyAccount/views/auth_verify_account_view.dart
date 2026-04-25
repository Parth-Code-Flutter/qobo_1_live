import 'package:flutter/material.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/generated/locales.g.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/auth_verify_account_controller.dart';

class AuthVerifyAccountView extends GetView<AuthVerifyAccountController> {
  const AuthVerifyAccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorWhite,
      appBar: CommonAppBarWidget(title: '', showBackButton: true),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Spacing.v24,
            verifyAccountHeader(),
            Spacing.v28,
            phoneNumberInputWidget(),
            Spacing.v28,
            appButton(
              onPressed: () {},
              buttonText: LocaleKeys.continueButton.tr,
            ),
          ],
        ),
      ),
    );
  }

  Widget verifyAccountHeader() {
    return Column(
      children: [
        BoldText(
          text: LocaleKeys.verifyAccountTitle.tr,
          fontSize: TextStyles.k22FontSize,
          color: kColorText,
        ),
        Spacing.v2,
        AppText(
          text: LocaleKeys.verifyAccountSubTitle.tr,
          fontSize: TextStyles.k14FontSize,
          color: kColorTextGrey,
          align: TextAlign.center,
        ),
      ],
    );
  }

  Widget phoneNumberInputWidget() {
    return Row(
      children: [
        Container(
          height: 50,
          width: 88,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: kColorWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kColorTextFieldBorder),
          ),
          child: SizedBox(
            height: 56,
            child: Center(
              child: CountryCodePicker(
                initialSelection: 'IN',
                favorite: const ['+91', 'IN'],
                showCountryOnly: false,
                showOnlyCountryWhenClosed: false,
                showFlag: false,
                showDropDownButton: true,
                alignLeft: false,
                padding: EdgeInsets.zero,
                textStyle: TextStyles.kRegularPoppins(
                  fontSize: TextStyles.k14FontSize,
                  colors: kColorText,
                ),
                onChanged: (countryCode) {
                  controller.onCountryCodeChanged(countryCode.dialCode ?? '+91');
                },
              ),
            ),
          ),
        ),
        Spacing.h8,
        Expanded(
          child: AppTextField(
            controller: controller.phoneNumberController,
            hintText: LocaleKeys.verifyPhoneHint.tr,
            borderColor: kColorTextFieldBorder,
            hintStyle: TextStyles.kRegularPoppins(
              fontSize: TextStyles.k14FontSize,
              colors: kColorHint,
            ),
            textInputType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.none,
          ),
        ),
      ],
    );
  }
}
