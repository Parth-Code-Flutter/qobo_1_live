import 'package:aligned_rewards/constants/color_constants.dart';
import 'package:aligned_rewards/constants/image_constants.dart';
import 'package:aligned_rewards/routes/app_pages.dart';
import 'package:aligned_rewards/utils/app_widgets/icon_with_background_widget.dart';
import 'package:aligned_rewards/utils/ui_utils/app_ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

/// Common Filter Icon Widget
/// Reusable filter icon (kIconFilter) with consistent size across Projects, Todo, etc.
class CommonFilterIconWidget extends StatelessWidget {
  /// Icon size (default: 24 to match Projects/Todo search row)
  final double iconSize;

  const CommonFilterIconWidget({super.key, this.iconSize = 24});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      kIconFilter,
      height: iconSize,
      width: iconSize,
    );
  }
}

/// Common Search Icon Widget
/// A reusable search icon with optional onTap callback
///
/// Features:
/// - Circular white background
/// - Customizable size
/// - Optional onTap callback
class CommonSearchIconWidget extends StatelessWidget {
  /// Size of the icon (default: 22)
  final double iconSize;

  /// Size of the circular background (default: calculated from iconSize)
  final double? backgroundSize;

  /// Callback when icon is tapped (optional)
  final VoidCallback? onTap;

  const CommonSearchIconWidget({
    super.key,
    this.iconSize = 22,
    this.backgroundSize,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final widget = IconWithBackgroundWidget(
      iconPath: kIconSearch,
      iconSize: iconSize,
      backgroundSize: backgroundSize,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: widget,
      );
    }

    return widget;
  }
}

/// Common Notification Icon Widget
/// A reusable notification icon with navigation to notification screen
///
/// Features:
/// - Circular white background
/// - Customizable size
/// - Navigates to notification screen on tap
/// - Optional custom onTap callback
class CommonNotificationIconWidget extends StatelessWidget {
  /// Size of the icon (default: 24)
  final double iconSize;

  /// Size of the circular background (default: calculated from iconSize)
  final double? backgroundSize;

  /// Custom onTap callback (if null, navigates to notification screen)
  final VoidCallback? onTap;

  const CommonNotificationIconWidget({
    super.key,
    this.iconSize = 24,
    this.backgroundSize,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Get.toNamed(Routes.ADMIN_NOTIFICATION),
      child: IconWithBackgroundWidget(
        iconPath: kIconNotification,
        iconSize: iconSize,
        backgroundSize: backgroundSize,
      ),
    );
  }
}

/// Common Action Icons Row Widget
/// A reusable row containing search and notification icons
///
/// Features:
/// - Search icon on the left
/// - Notification icon on the right
/// - Proper spacing between icons
/// - Customizable icon sizes
class CommonActionIconsRowWidget extends StatelessWidget {

  /// Size of notification icon (default: 24)
  final double notificationIconSize;

  /// Spacing between icons (default: 12)
  final double spacing;

  /// Custom onTap for search icon (optional)
  final VoidCallback? onSearchTap;

  /// Custom onTap for notification icon (optional)
  final VoidCallback? onNotificationTap;

  const CommonActionIconsRowWidget({
    super.key,
    this.notificationIconSize = 24,
    this.spacing = 12,
    this.onSearchTap,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: spacing),
        CommonNotificationIconWidget(
          iconSize: notificationIconSize,
          onTap: onNotificationTap,
        ),
      ],
    );
  }
}

/// Common Edit/Delete Actions Row Widget
/// A reusable row containing circular edit and delete icons with borders
///
/// Features:
/// - Circular icons with grey border
/// - Uses shared SVG assets (kIconEdit, kIconDelete)
/// - Customizable sizes and callbacks
class CommonEditDeleteActionsRow extends StatelessWidget {
  /// Callback when edit icon is tapped (optional)
  final VoidCallback? onEditTap;

  /// Callback when delete icon is tapped (optional)
  final VoidCallback? onDeleteTap;

  /// Diameter of the circular container (default: 28)
  final double circleSize;

  /// Icon size inside the circle (default: 16)
  final double iconSize;

  /// Spacing between edit and delete icons (default: 10)
  final double spacing;

  const CommonEditDeleteActionsRow({
    super.key,
    this.onEditTap,
    this.onDeleteTap,
    this.circleSize = 26,
    this.iconSize = 14,
    this.spacing = 6, // edit and delete icon spacing
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onEditTap != null)
          _buildActionIcon(
            iconPath: kIconEdit,
            onTap: onEditTap!,
          ),
        if (onEditTap != null && onDeleteTap != null) SizedBox(width: spacing),
        if (onDeleteTap != null)
          _buildActionIcon(
            iconPath: kIconDelete,
            onTap: onDeleteTap!,
          ),
      ],
    );
  }

  Widget _buildActionIcon({
    required String iconPath,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(circleSize / 2),
      child: Container(
        height: circleSize,
        width: circleSize,
        padding: EdgeInsets.all((circleSize - iconSize) / 2.3),
        decoration: BoxDecoration(
          borderRadius: AppUIUtils.primaryBorderRadius,
          border: Border.all(
            color: kColorBlack,
            width: .5,
          ),
        ),
        child: SvgPicture.asset(
          iconPath,
        ),
      ),
    );
  }
}

/// Common Create Action Button
/// A reusable "create" button that can be used across modules
///
/// Features:
/// - Supports either SVG asset or Material icon
/// - Can be circular (for header actions) or rounded-rectangle (for cards/headers)
/// - Customizable size, colors and border
class CommonCreateActionButton extends StatelessWidget {
  /// Callback when button is tapped
  final VoidCallback onTap;

  /// SVG icon path (optional). If null, [iconData] will be used.
  final String? svgIconPath;

  /// Material icon (optional). Used when [svgIconPath] is null.
  final IconData? iconData;

  /// Size of the button (width & height)
  final double size;

  /// Background color of the button
  final Color backgroundColor;

  /// Icon color (for Material icon or SVG tint)
  final Color iconColor;

  /// Whether the button should be circular. If false, rounded rectangle is used.
  final bool isCircular;

  /// Optional border color. If null, no border will be drawn.
  final Color? borderColor;

  /// Optional custom border radius when [isCircular] is false.
  final BorderRadius? borderRadius;

  /// Internal padding around the icon
  final EdgeInsetsGeometry padding;

  const CommonCreateActionButton({
    super.key,
    required this.onTap,
    this.svgIconPath,
    this.iconData,
    this.size = 40,
    this.backgroundColor = kColorPrimary,
    this.iconColor = kColorWhite,
    this.isCircular = true,
    this.borderColor,
    this.borderRadius,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius effectiveRadius = borderRadius ??
        BorderRadius.circular(
          isCircular ? size / 2 : AppUIUtils.primaryRadius,
        );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircular ? null : effectiveRadius,
          border: borderColor != null ? Border.all(color: borderColor!) : null,
        ),
        child: Center(
          child: _buildIcon(),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (svgIconPath != null) {
      return SvgPicture.asset(
        svgIconPath!,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      );
    }

    return Icon(
      iconData ?? Icons.add,
      color: iconColor,
      size: size / 2,
    );
  }
}
