import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Icon with Background Widget
/// A reusable widget that displays an SVG icon inside a circular background
/// 
/// Features:
/// - Circular white background by default
/// - Customizable background color
/// - Customizable icon size and color
/// - Properly centered icon
class IconWithBackgroundWidget extends StatelessWidget {
  /// The SVG icon asset path
  final String iconPath;
  
  /// The size of the icon (default: 28)
  final double iconSize;
  
  /// The color of the icon (default: null, uses original icon color)
  final Color? iconColor;
  
  /// The background color of the circle (default: white)
  final Color backgroundColor;
  
  /// The size of the circular background (default: calculated from iconSize + padding)
  final double? backgroundSize;
  
  /// Padding around the icon inside the circle (default: 8)
  final double padding;

  const IconWithBackgroundWidget({
    super.key,
    required this.iconPath,
    this.iconSize = 28,
    this.iconColor,
    this.backgroundColor = kColorWhite,
    this.backgroundSize,
    this.padding = 8,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate background size if not provided
    final double circleSize = backgroundSize ?? (iconSize + (padding * 2));
    
    return Container(
      width: circleSize,
      height: circleSize,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SvgPicture.asset(
          iconPath,
          height: iconSize,
          width: iconSize,
          colorFilter: iconColor != null
              ? ColorFilter.mode(iconColor!, BlendMode.srcIn)
              : null,
        ),
      ),
    );
  }
}
