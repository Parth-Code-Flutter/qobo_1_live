import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/glossy_auth_field_border.dart';
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
    this.onSubmitted,
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
    this.hintStyle,
    this.floatingLabelStyle,
    this.readOnly = false,
    this.onTap,
    this.fieldTitle,
    this.isRequired = false,
    this.exText,
    this.fillColor,
    this.padding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 12, // 8
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
    this.borderColor,
    this.glossyBorder = false,
    this.glossyRadius = 18,
    this.glossyBorderWidth = 1.6,
  });

  final TextEditingController? controller;
  final void Function(String value)? onChanged;
  /// Called when the keyboard action button (e.g. send/done) is pressed.
  final void Function(String value)? onSubmitted;
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
  final TextStyle? hintStyle;
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
  /// Optional border color override.
  final Color? borderColor;

  /// Wraps the input in [GlossyAuthFieldBorder] and shows validator errors
  /// below the ring (never inside it).
  final bool glossyBorder;
  final double glossyRadius;
  final double glossyBorderWidth;

  @override
  Widget build(BuildContext context) {
    if (forProfile) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (fieldTitle != null) ...[
            _title(context),
            Spacing.v8,
          ],
          AppText(
            text: value ?? '',
            style: TextStyles.kRegularPoppins(),
          ),
          Divider(color: Theme.of(context).primaryColor),
        ],
      );
    }

    // Glossy auth fields: keep the gradient ring around the input only;
    // FormField error text renders as a sibling below the ring.
    if (glossyBorder) {
      return _buildGlossyField(context);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._labelWidgets(context),
        TextFormField(
          autofocus: autoFocus ?? false,
          controller: controller,
          cursorColor: kColorPrimary,
          style: textStyle ?? AppUIUtils.globalTextStyle,
          keyboardType: textInputType,
          textCapitalization:
              textCapitalization ?? TextCapitalization.sentences,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          textInputAction: textInputAction ?? TextInputAction.next,
          maxLength: maxLength,
          initialValue: controller == null ? value : null,
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
          decoration: _decoration(context, showInlineError: true),
        ),
        if (exText != null) ...[
          Spacing.v8,
          _ex(context),
        ],
      ],
    );
  }

  Widget _buildGlossyField(BuildContext context) {
    return FormField<String>(
      validator: validator,
      initialValue: controller?.text ?? value,
      builder: (FormFieldState<String> field) {
        final input = TextField(
          autofocus: autoFocus ?? false,
          controller: controller,
          cursorColor: kColorPrimary,
          style: textStyle ?? AppUIUtils.globalTextStyle,
          keyboardType: textInputType,
          textCapitalization:
              textCapitalization ?? TextCapitalization.sentences,
          onChanged: (v) {
            field.didChange(v);
            onChanged?.call(v);
          },
          onSubmitted: onSubmitted,
          textInputAction: textInputAction ?? TextInputAction.next,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          maxLines: maxLines ?? 1,
          minLines: minLines ?? 1,
          readOnly: readOnly,
          onTap: onTap,
          focusNode: focusNode,
          obscureText: obscureText,
          obscuringCharacter: '*',
          autofillHints: autofillHints,
          decoration: _decoration(context, showInlineError: false).copyWith(
            // Ring owns the chrome — hide Material outline entirely.
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
          ),
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._labelWidgets(context),
            GlossyAuthFieldBorder(
              radius: glossyRadius,
              borderWidth: glossyBorderWidth,
              child: input,
            ),
            if (field.hasError && (field.errorText ?? '').isNotEmpty) ...[
              Spacing.v6,
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 4),
                child: Text(
                  field.errorText!,
                  style: TextStyles.kMediumPoppins(
                    colors: kColorRed,
                    fontSize: TextStyles.k10FontSize,
                  ),
                ),
              ),
            ],
            if (exText != null) ...[
              Spacing.v8,
              _ex(context),
            ],
          ],
        );
      },
    );
  }

  List<Widget> _labelWidgets(BuildContext context) {
    if (fieldTitle != null) {
      return [_title(context), Spacing.v8];
    }
    if (labelText != null) {
      return [
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
      ];
    }
    return const [];
  }

  InputDecoration _decoration(
    BuildContext context, {
    required bool showInlineError,
  }) {
    return InputDecoration(
      fillColor: fillColor ?? kColorWhite,
      filled: true,
      isDense: true,
      counterText: !showCounter ? '' : null,
      contentPadding: padding,
      hintText: hintText,
      hintStyle: hintStyle ?? AppUIUtils.hintTextFieldTextStyle,
      errorStyle: showInlineError
          ? TextStyles.kMediumPoppins(
              colors: kColorRed,
              fontSize: TextStyles.k10FontSize,
            )
          : const TextStyle(height: 0, fontSize: 0),
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
      enabledBorder: _enabledBorder(context),
      focusedBorder: _focusedBorder(context),
      floatingLabelBehavior: floatingLabelBehavior ??
          (labelText != null && fieldTitle == null
              ? FloatingLabelBehavior.never
              : FloatingLabelBehavior.always),
      errorBorder: _enabledErrorBorder(context),
      focusedErrorBorder: _focusedErrorBorder(context),
      prefixIcon: prefix,
      prefixIconConstraints: const BoxConstraints(
        minWidth: 0,
        maxWidth: 120,
        minHeight: 48,
        maxHeight: 48,
      ),
      suffixIcon: suffix,
      suffixIconConstraints: const BoxConstraints(
        minWidth: 0,
        maxWidth: 120,
        minHeight: 48,
        maxHeight: 48,
      ),
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
        color: error ?? false
            ? kColorRed
            : (borderColor ?? kColorTextFieldBorder),
        width: borderWidth,
      ),
    );
  }

  InputBorder _focusedBorder(BuildContext context) {
    return OutlineInputBorder(
      gapPadding: gapPadding,
      borderRadius: inputBorderRadius ?? AppUIUtils.primaryBorderRadius,
      borderSide: BorderSide(
        color: error ?? false
            ? kColorRed
            : (borderColor ?? kColorTextFieldBorder),
        width: borderWidth,
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
      ),
    );
  }
}
