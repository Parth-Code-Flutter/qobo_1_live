import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:flutter/material.dart';

class AppText extends StatelessWidget {
  const AppText({
    required this.text,
    super.key,
    this.style,
    this.align,
    this.overflow,
    this.maxLines,
    this.fontSize,
    this.color,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? align;
  final TextOverflow? overflow;
  final int? maxLines;
  final Color? color;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style ??
          TextStyles.kRegularPoppins(
              fontSize: fontSize ?? 14, colors: color ?? kColorText),
      textAlign: align,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}

class MediumText extends StatelessWidget {
  const MediumText({
    required this.text,
    super.key,
    this.style,
    this.align,
    this.fontSize,
    this.color,
    this.overflow,
    this.maxLines,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? align;
  final Color? color;
  final double? fontSize;
  final TextOverflow? overflow;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      // style: style ?? Theme.of(context).textTheme.labelMedium,
      style: style ??
          TextStyles.kMediumPoppins(
              fontSize: fontSize ?? 20, colors: color ?? kColorText),
      textAlign: align,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}

class SemiBoldText extends StatelessWidget {
  const SemiBoldText({
    required this.text,
    super.key,
    this.style,
    this.align,
    this.fontSize,
    this.color,
    this.overflow,
    this.maxLines,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? align;
  final double? fontSize;
  final Color? color;
  final TextOverflow? overflow;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      // style: style ?? Theme.of(context).textTheme.labelMedium,
      style: style ??
          TextStyles.kSemiBoldPoppins(
            fontSize: fontSize ?? 16,
            colors: color ?? kColorText,
          ),
      textAlign: align,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}

class BoldText extends StatelessWidget {
  const BoldText({
    required this.text,
    super.key,
    this.style,
    this.align,
    this.fontSize,
    this.color,
    this.overflow,
    this.maxLines,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? align;
  final double? fontSize;
  final Color? color;
  final TextOverflow? overflow;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      // style: style ?? Theme.of(context).textTheme.labelMedium,
      style: style ??
          TextStyles.kBoldPoppins(
            fontSize: fontSize ?? 28,
            colors: color ?? kColorText,
          ),
      textAlign: align,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}
