import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/ui_utils/app_ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.onChanged,
    this.validator,
    this.value,
    this.hintText,
    this.maxLength,
    this.textInputType,
    this.error,
    this.inputFormatters,
    this.maxLines,
    this.minLines,
    this.prefix,
    this.suffix,
    this.showCounter = false,
    this.labelText,
    this.labelStyle,
    this.textStyle,
    this.floatingLabelStyle,
    this.readOnly = false,
    this.onTap,
    this.fieldTitle,
    this.isRequired = false,
    this.exText,
    this.fillColor,
    this.padding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 14, // 8
    ),
    this.focusNode,
    this.obscureText = false,
    this.forProfile = false,
    this.inputBorderRadius,
    this.floatingLabelBehavior,
    this.autoFocus = false,
    this.autofillHints,
    this.textInputAction,
    this.textCapitalization,
  });

  final TextEditingController? controller;
  final void Function(String value)? onChanged;
  final String? Function(String? value)? validator;
  final String? value;
  final String? hintText;
  final int? maxLength;
  final TextInputType? textInputType;
  final List<TextInputFormatter>? inputFormatters;
  final bool? error;
  final int? maxLines;
  final int? minLines;
  final Widget? prefix;
  final Widget? suffix;
  final bool showCounter;
  final String? labelText;
  final TextStyle? labelStyle;
  final TextStyle? textStyle;
  final TextStyle? floatingLabelStyle;
  final bool readOnly;
  final void Function()? onTap;
  final String? fieldTitle;
  final bool isRequired;
  final String? exText;
  final Color? fillColor;
  final EdgeInsetsGeometry? padding;
  final FocusNode? focusNode;
  final bool obscureText;
  final bool forProfile;
  final BorderRadius? inputBorderRadius;
  final FloatingLabelBehavior? floatingLabelBehavior;
  final bool? autoFocus;
  /// Optional autofill hints to enable OS-level password / email managers.
  final Iterable<String>? autofillHints;
  /// Optional text input action override (e.g. TextInputAction.done).
  final TextInputAction? textInputAction;
  /// Optional text capitalization override (defaults to sentences when null).
  final TextCapitalization? textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show fieldTitle if provided, otherwise show labelText above the field
        if (fieldTitle != null) ...[
          _title(context),
          Spacing.v8,
        ] else if (labelText != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: AppText(
                    text: labelText ?? '',
                    style: labelStyle ?? AppUIUtils.labelTextFieldTextStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isRequired)
                  AppText(
                    text: ' *',
                    style: labelStyle ??
                        AppUIUtils.labelTextFieldTextStyle
                            .copyWith(color: kColorRed),
                  ),
              ],
            ),
          ),
          Spacing.v6,
        ],
        if (forProfile)
          AppText(
            text: value ?? '',
            style: TextStyles.kRegularPoppins(),
          )
        else
          TextFormField(
            autofocus: autoFocus ?? false,
            controller: controller,
            cursorColor: kColorPrimary,
            style: textStyle ?? AppUIUtils.globalTextStyle,
            // TextStyles.kPrimaryBoldInter(
            // fontSize: TextStyles.k24FontSize, colors: kColorD9D9D9),
            keyboardType: textInputType,
            textCapitalization: textCapitalization ?? TextCapitalization.sentences,
            onChanged: onChanged,
            textInputAction: textInputAction ?? TextInputAction.next,
            maxLength: maxLength,
            initialValue: value,
            inputFormatters: inputFormatters,
            maxLines: maxLines ?? 1,
            minLines: minLines ?? 1,
            readOnly: readOnly,
            onTap: onTap,
            focusNode: focusNode,
            obscureText: obscureText,
            obscuringCharacter: '*',
            validator: validator,
            autofillHints: autofillHints,
            decoration: InputDecoration(
              fillColor: fillColor ?? kColorWhite,
              filled: true,
              isDense: true,
              // alignLabelWithHint: true,
              counterText: !showCounter ? '' : null,
              contentPadding: padding,
              hintText: hintText,
              hintStyle: AppUIUtils.hintTextFieldTextStyle,
              errorStyle: TextStyles.kMediumPoppins(
                colors: kColorRed,
                fontSize: TextStyles.k12FontSize,
              ),
              // Only show label inside if fieldTitle is used (for backward compatibility)
              // Otherwise label is shown above the field
              label: fieldTitle != null && labelText != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: labelText ?? '',
                              style: labelStyle ?? AppUIUtils.labelTextFieldTextStyle,
                            ),
                            TextSpan(
                              text: (isRequired ? ' *' : ''),
                              style: labelStyle ??
                                  AppUIUtils.labelTextFieldTextStyle
                                      .copyWith(color: kColorRed),
                            ),
                          ],
                        ),
                      ),
                    )
                  : null,
              // labelText: labelText != null
              //     ? ((labelText ?? '') + (isRequired ? ' *' : ''))
              //     : null,
              // floatingLabelStyle:
              //     AppTextStyles.textFieldLabel(isFloating: true),
              // labelStyle:
              enabledBorder: _enabledBorder(context),
              focusedBorder: _focusedBorder(context),
              floatingLabelBehavior:
                  floatingLabelBehavior ?? 
                  (labelText != null && fieldTitle == null 
                      ? FloatingLabelBehavior.never 
                      : FloatingLabelBehavior.always),
              errorBorder: _enabledErrorBorder(context),
              focusedErrorBorder: _focusedErrorBorder(context),
              prefixIcon: prefix,
              prefixIconConstraints: const BoxConstraints(),
              suffixIcon: suffix,
              suffixIconConstraints: const BoxConstraints(),
            ),
          ),
        if (exText != null) ...[
          Spacing.v8,
          _ex(context),
        ],
        if (forProfile)
          Divider(
            color: Theme.of(context).primaryColor,
          ),
      ],
    );
  }

  Widget _title(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText(
          text: fieldTitle ?? '',
          style: TextStyles.kRegularPoppins(),
        ),
        if (isRequired)
          AppText(
            text: ' *',
            style: TextStyles.kRegularPoppins(),
          ),
      ],
    );
  }

  Widget _ex(BuildContext context) {
    return AppText(
      text: exText ?? '',
      style: TextStyles.kRegularPoppins(),
    );
  }

  final double gapPadding = 4;
  final double borderWidth = 0.5;

  InputBorder _enabledBorder(BuildContext context) {
    return OutlineInputBorder(
      gapPadding: gapPadding,
      borderRadius: inputBorderRadius ?? AppUIUtils.primaryBorderRadius,
      borderSide: BorderSide(
        color: error ?? false ? kColorRed : kColorTextFieldBorder,
        width: borderWidth,
        // width: error ?? false ? 0.7 : 0.7,
      ),
    );
  }

  InputBorder _focusedBorder(BuildContext context) {
    return OutlineInputBorder(
      gapPadding: gapPadding,
      borderRadius: inputBorderRadius ?? AppUIUtils.primaryBorderRadius,
      borderSide: BorderSide(
        color: error ?? false ? kColorRed : kColorTextFieldBorder,
        width: borderWidth,
        // width: error ?? false ? 0.7 : 0.7,
      ),
    );
  }

  InputBorder _enabledErrorBorder(BuildContext context) {
    return OutlineInputBorder(
      gapPadding: gapPadding,
      borderRadius: inputBorderRadius ?? AppUIUtils.primaryBorderRadius,
      borderSide: BorderSide(
        color: kColorRed,
        width: borderWidth,
        // width: error ?? false ? 0.7 : 0.7,
      ),
    );
  }

  InputBorder _focusedErrorBorder(BuildContext context) {
    return OutlineInputBorder(
      gapPadding: gapPadding,
      borderRadius: inputBorderRadius ?? AppUIUtils.primaryBorderRadius,
      borderSide: BorderSide(
        color: kColorPrimary,
        width: borderWidth,
        // width: error ?? false ? 0.7 : 0.7,
      ),
    );
  }
}
