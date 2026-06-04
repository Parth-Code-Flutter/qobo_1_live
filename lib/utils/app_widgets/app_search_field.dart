import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/theme/theme_context.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Themed inline search field (tabs, headers). Use [AppTextField] for forms.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.height = 38,
    this.fontSize,
    this.borderRadius,
    this.leading,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final double height;
  final double? fontSize;
  final BorderRadius? borderRadius;
  final Widget? leading;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textSize = fontSize ?? TextStyles.k12FontSize;
    final radius = borderRadius ?? BorderRadius.circular(10);

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.searchFieldFill,
        borderRadius: radius,
        border: Border.all(color: colors.searchFieldBorder, width: 1),
      ),
      child: Row(
        children: [
          leading ??
              Icon(
                Icons.search_rounded,
                size: textSize + 4,
                color: colors.searchFieldHint,
              ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: autofocus,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              style: TextStyles.kRegularPoppins(
                fontSize: textSize,
                colors: colors.textPrimary,
              ),
              cursorColor: kColorPrimary,
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: hintText,
                hintStyle: TextStyles.kRegularPoppins(
                  fontSize: textSize,
                  colors: colors.searchFieldHint,
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: (height - textSize) / 2 - 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
