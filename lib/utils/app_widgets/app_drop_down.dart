import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/ui_utils/app_ui_utils.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

class AppDropDown<T> extends StatelessWidget {
  const AppDropDown({
    required this.items,
    required this.string,
    required this.onChanged,
    super.key,
    this.selectedItem,
    this.prefix,
    this.labelText,
    this.labelStyle,
    this.floatingLabelStyle,
    this.hintText,
    this.error = false,
    this.fieldTitle,
    this.isRequired = false,
    this.padding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 14,
    ),
    this.validator,
    this.showSearchBox = true,
  });

  final List<T> items;
  final T? selectedItem;
  final String Function(T item) string;
  final void Function(T? value)? onChanged;
  final Widget? prefix;
  final String? labelText;
  final TextStyle? labelStyle;
  final TextStyle? floatingLabelStyle;
  final String? hintText;
  final bool error;
  final String? fieldTitle;
  final bool isRequired;
  final EdgeInsetsGeometry padding;
  final String? Function(T? value)? validator;
  final bool? showSearchBox;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (fieldTitle != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: AppText(
                    text: fieldTitle!,
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
          Spacing.v8,
        ],
        DropdownSearch<T>(
          enabled: onChanged != null,
          onChanged: onChanged,
          selectedItem: selectedItem,
          items: items,
          itemAsString: string,
          popupProps: PopupProps.menu(
            fit: FlexFit.loose,
            showSearchBox: showSearchBox ?? true,
            searchDelay: Duration.zero,
            itemBuilder: (context, item, isSelected) {
              final isSelected = selectedItem == item;
              print('isSelected ------ $isSelected');
              print('selectedItem ------ ${selectedItem}');
              return Container(
                color: kColorBackground,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      text: string(item),
                      style: AppUIUtils.globalTextStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Divider(color: kColorSecondPrimary, height: 1),
                  ],
                ),
              );
            },
            searchFieldProps: TextFieldProps(
              style: TextStyles.kSemiBoldPoppins(
                fontSize: TextStyles.k14FontSize,
                colors: kColorSecondPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search',
                constraints: BoxConstraints(minHeight: 40, maxHeight: 42),
                hintStyle: TextStyles.kBoldPoppins(
                  fontSize: TextStyles.k18FontSize,
                  colors: kColorSecondPrimary,
                ),
                alignLabelWithHint: true,
                contentPadding: const EdgeInsets.only(left: 18),
                fillColor: kColorBackground,
                filled: true,
                border: _enabledBorder,
                enabledBorder: _enabledBorder,
                focusedBorder: _focusedBorder,
              ),
            ),
          ),
          clearButtonProps: const ClearButtonProps(
            icon: Icon(
              Icons.clear,
              size: 16,
            ),
            isVisible: false,
            constraints: BoxConstraints(),
            padding: EdgeInsets.zero,
            iconSize: 16,
            alignment: Alignment.centerRight,
          ),

          /// Dropdown icon: matches AppMultiDropdown (Projects) for consistency.
          dropdownButtonProps: DropdownButtonProps(
            iconSize: 16,
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: kColorHint,
              size: 16,
            ),
            color: kColorWhite,
            disabledColor: kColorWhite,
          ),
          validator: validator,
          dropdownDecoratorProps: DropDownDecoratorProps(
            baseStyle: AppUIUtils.globalTextStyle,
            /*    baseStyle: TextStyles.kPrimaryBoldInter(
              fontSize: TextStyles.k18FontSize,
              // colors: kColorPrimary,
              colors: kColorBackground,
            ),*/
            dropdownSearchDecoration: InputDecoration(
              fillColor: kColorBackground,
              filled: true,
              isDense: true,
              contentPadding: padding,
              hintText: hintText,
              hintStyle: AppUIUtils.hintTextFieldTextStyle,
              // Only show label inside if fieldTitle is not used (for backward compatibility)
              // When fieldTitle is used, label is shown above the field, so no label inside
              label: fieldTitle == null && labelText != null
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
              floatingLabelBehavior: fieldTitle == null && labelText != null
                  ? FloatingLabelBehavior.always
                  : FloatingLabelBehavior.never,
              labelStyle: AppUIUtils.labelTextFieldTextStyle,
              enabledBorder: _enabledBorder,
              focusedBorder: _focusedBorder,
              errorBorder: _enabledErrorBorder,
              focusedErrorBorder: _focusedErrorBorder,
              prefixIcon: prefix,
              prefixIconConstraints: const BoxConstraints(),
              disabledBorder: _enabledBorder,
              // constraints: BoxConstraints(
              //   maxHeight: 30,
              //   minHeight: 30,
              //   maxWidth: 0.50.screenWidth,
              //   minWidth: 0.50.screenWidth,
              // ),
            ),
          ),
        ),
      ],
    );
  }

  final double gapPadding = 4;
  final double borderWidth = 0.5;

  InputBorder get _enabledBorder {
    return OutlineInputBorder(
      gapPadding: gapPadding,
      borderRadius: AppUIUtils.primaryBorderRadius,
      borderSide: BorderSide(
        color: error ? kColorRed : kColorTextFieldBorder,
        width: borderWidth,
        // width: error ? 0.7 : AppUIUtils.borderWidth,
      ),
    );
  }

  InputBorder get _focusedBorder {
    return OutlineInputBorder(
      gapPadding: gapPadding,
      borderRadius: AppUIUtils.primaryBorderRadius,
      borderSide: BorderSide(
        color: error ? kColorRed : kColorTextFieldBorder,
        width: borderWidth,
      ),
    );
  }

  InputBorder get _enabledErrorBorder {
    return OutlineInputBorder(
      gapPadding: gapPadding,
      borderRadius: AppUIUtils.primaryBorderRadius,
      borderSide: BorderSide(
        color: kColorRed,
        width: borderWidth,
      ),
    );
  }

  InputBorder get _focusedErrorBorder {
    return OutlineInputBorder(
      gapPadding: gapPadding,
      borderRadius: AppUIUtils.primaryBorderRadius,
      borderSide: BorderSide(
        color: kColorRed,
        width: borderWidth,
      ),
    );
  }
}
