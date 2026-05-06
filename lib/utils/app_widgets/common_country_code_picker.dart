import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Reusable dial-code picker container used in auth forms.
class CommonCountryCodePicker extends StatelessWidget {
  const CommonCountryCodePicker({
    super.key,
    required this.onChanged,
    this.initialSelection = 'IN',
    this.height = 56,
    this.width = 92,
    this.borderColor = kColorTextFieldBorder,
  });

  final ValueChanged<String> onChanged;
  final String initialSelection;
  final double height;
  final double width;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: kColorWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Center(
        child: CountryCodePicker(
          initialSelection: initialSelection,
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
          onChanged: (countryCode) => onChanged(countryCode.dialCode ?? '+91'),
        ),
      ),
    );
  }
}
