import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

/// Common Floating Action Button Widget
/// Shows/hides based on scrolling state
/// 
/// Usage:
/// ```dart
/// CommonFloatingActionButton(
///   isScrolling: controller.isScrolling,
///   onPressed: () => _addItemBottomSheet(context),
/// )
/// ```
class CommonFloatingActionButton extends StatelessWidget {
  const CommonFloatingActionButton({
    super.key,
    required this.isScrolling,
    required this.onPressed,
    this.backgroundColor,
    this.icon,
    this.iconColor,
  });

  /// Observable boolean to track scrolling state
  /// FAB will be hidden when this is true
  final RxBool isScrolling;

  /// Callback when FAB is pressed
  final VoidCallback onPressed;

  /// Background color of FAB (defaults to kColorPrimary)
  final Color? backgroundColor;

  /// Icon to display (defaults to kIconPlus)
  final String? icon;

  /// Icon color (defaults to kColorWhite)
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Hide FAB when scrolling
      if (isScrolling.value) {
        return const SizedBox.shrink();
      }

      return FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: backgroundColor ?? kColorPrimary,
        child: SvgPicture.asset(
          icon ?? kIconPlus,
          color: iconColor ?? kColorWhite,
        ),
      );
    });
  }
}

