import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:flutter/material.dart';

/// Common vertical divider widget with customizable properties
/// 
/// Usage examples:
/// ```dart
/// // Simple vertical divider with default styling
/// AppVerticalDivider()
/// 
/// // Vertical divider with custom color and thickness
/// AppVerticalDivider(
///   color: kColorGreyDA,
///   thickness: 0.5,
/// )
/// 
/// // Vertical divider with horizontal padding
/// AppVerticalDivider(
///   horizontalPadding: 16,
/// )
/// 
/// // Vertical divider with indent
/// AppVerticalDivider(
///   indent: 18,
///   endIndent: 18,
/// )
/// 
/// // Vertical divider with specific height
/// AppVerticalDivider(
///   height: 20,
/// )
/// ```
class AppVerticalDivider extends StatelessWidget {
  /// Color of the divider line
  final Color? color;

  /// Thickness of the divider line
  final double? thickness;

  /// Width of the divider (spacing around the line)
  final double? width;

  /// Height of the divider
  final double? height;

  /// Indent from the top edge
  final double? indent;

  /// Indent from the bottom edge
  final double? endIndent;

  /// Horizontal padding around the divider
  final double? horizontalPadding;

  /// Left margin
  final double? leftMargin;

  /// Right margin
  final double? rightMargin;

  const AppVerticalDivider({
    super.key,
    this.color,
    this.thickness,
    this.width,
    this.height,
    this.indent,
    this.endIndent,
    this.horizontalPadding,
    this.leftMargin,
    this.rightMargin,
  });

  @override
  Widget build(BuildContext context) {
    Widget divider = VerticalDivider(
      color: color ?? kColorHint,
      thickness: thickness ?? 1.0,
      width: width ?? 1.0,
      indent: indent ?? 0.0,
      endIndent: endIndent ?? 0.0,
    );

    // Apply height constraint if specified
    if (height != null) {
      divider = SizedBox(
        height: height,
        child: divider,
      );
    }

    // Apply padding/margin if specified
    if (horizontalPadding != null) {
      divider = Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding!),
        child: divider,
      );
    } else if (leftMargin != null || rightMargin != null) {
      divider = Padding(
        padding: EdgeInsets.only(
          left: leftMargin ?? 0.0,
          right: rightMargin ?? 0.0,
        ),
        child: divider,
      );
    }

    return divider;
  }
}

