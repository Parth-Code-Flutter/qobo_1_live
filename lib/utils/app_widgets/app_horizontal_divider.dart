import 'package:aligned_rewards/constants/color_constants.dart';
import 'package:flutter/material.dart';

/// Common horizontal divider widget with customizable properties
/// 
/// Usage examples:
/// ```dart
/// // Simple divider with default styling
/// AppHorizontalDivider()
/// 
/// // Divider with custom color and thickness
/// AppHorizontalDivider(
///   color: kColorGreyDA,
///   thickness: 0.5,
/// )
/// 
/// // Divider with vertical padding
/// AppHorizontalDivider(
///   verticalPadding: 16,
/// )
/// 
/// // Divider with indent
/// AppHorizontalDivider(
///   indent: 18,
///   endIndent: 18,
/// )
/// ```
class AppHorizontalDivider extends StatelessWidget {
  /// Color of the divider line
  final Color? color;

  /// Thickness of the divider line
  final double? thickness;

  /// Height of the divider (spacing around the line)
  final double? height;

  /// Indent from the left edge
  final double? indent;

  /// Indent from the right edge
  final double? endIndent;

  /// Vertical padding around the divider
  final double? verticalPadding;

  /// Top margin
  final double? topMargin;

  /// Bottom margin
  final double? bottomMargin;

  const AppHorizontalDivider({
    super.key,
    this.color,
    this.thickness,
    this.height,
    this.indent,
    this.endIndent,
    this.verticalPadding,
    this.topMargin,
    this.bottomMargin,
  });

  @override
  Widget build(BuildContext context) {
    Widget divider = Divider(
      color: color ?? kColorGreyDA,
      thickness: thickness ?? 1.0,
      height: height ?? 1.0,
      indent: indent ?? 0.0,
      endIndent: endIndent ?? 0.0,
    );

    // Apply padding/margin if specified
    if (verticalPadding != null) {
      divider = Padding(
        padding: EdgeInsets.symmetric(vertical: verticalPadding!),
        child: divider,
      );
    } else if (topMargin != null || bottomMargin != null) {
      divider = Padding(
        padding: EdgeInsets.only(
          top: topMargin ?? 0.0,
          bottom: bottomMargin ?? 0.0,
        ),
        child: divider,
      );
    }

    return divider;
  }
}

