import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/container_box_shadow_util.dart';
import 'package:qobo_one_live/utils/ui_utils/app_ui_utils.dart';
import 'package:flutter/material.dart';

/// Custom expandable tile widget with enhanced customization options
/// 
/// This widget provides a card-based expandable tile with customizable:
/// - Collapsed and expanded states
/// - Icon visibility
/// - Padding and margins
/// - Background colors and borders
/// - Animation duration
/// 
/// Usage example:
/// ```dart
/// AppCustomExpandableTile(
///   title: Text('Title'),
///   children: [
///     Text('Expanded content'),
///   ],
///   onExpansionChanged: (expanded) {
///     print('Expanded: $expanded');
///   },
/// )
/// ```
class AppCustomExpandableTile extends StatefulWidget {
  /// Widget to display in the collapsed state (title area)
  final Widget title;

  /// List of widgets to display when expanded
  final List<Widget> children;

  /// Callback when expansion state changes
  final ValueChanged<bool>? onExpansionChanged;

  /// Whether the tile is initially expanded
  final bool initiallyExpanded;

  /// Padding for the tile content
  final EdgeInsetsGeometry? tilePadding;

  /// Padding for the children content
  final EdgeInsetsGeometry? childrenPadding;

  /// Background color of the tile
  final Color? backgroundColor;

  /// Background color when collapsed
  final Color? collapsedBackgroundColor;

  /// Background color when expanded
  final Color? expandedBackgroundColor;

  /// Border radius for the tile
  final BorderRadius? borderRadius;

  /// Box shadow for the tile
  final List<BoxShadow>? boxShadow;

  /// Margin around the tile
  final EdgeInsetsGeometry? margin;

  /// Whether to show the expansion icon
  final bool showExpansionIcon;

  /// Custom expansion icon
  final Widget? expansionIcon;

  /// Custom collapsed icon
  final Widget? collapsedIcon;

  /// Duration of the expansion animation
  final Duration animationDuration;

  /// Text color when expanded
  final Color? textColor;

  /// Text color when collapsed
  final Color? collapsedTextColor;

  /// Icon color when expanded
  final Color? iconColor;

  /// Icon color when collapsed
  final Color? collapsedIconColor;

  /// Shape when expanded
  final ShapeBorder? shape;

  /// Shape when collapsed
  final ShapeBorder? collapsedShape;

  /// Whether to maintain state when rebuilding
  final bool maintainState;

  const AppCustomExpandableTile({
    super.key,
    required this.title,
    required this.children,
    this.onExpansionChanged,
    this.initiallyExpanded = false,
    this.tilePadding,
    this.childrenPadding,
    this.backgroundColor,
    this.collapsedBackgroundColor,
    this.expandedBackgroundColor,
    this.borderRadius,
    this.boxShadow,
    this.margin,
    this.showExpansionIcon = true,
    this.expansionIcon,
    this.collapsedIcon,
    this.animationDuration = const Duration(milliseconds: 200),
    this.textColor,
    this.collapsedTextColor,
    this.iconColor,
    this.collapsedIconColor,
    this.shape,
    this.collapsedShape,
    this.maintainState = false,
  });

  @override
  State<AppCustomExpandableTile> createState() => _AppCustomExpandableTileState();
}

class _AppCustomExpandableTileState extends State<AppCustomExpandableTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
      widget.onExpansionChanged?.call(_isExpanded);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isExpanded = _isExpanded;
    final backgroundColor = isExpanded
        ? (widget.expandedBackgroundColor ?? widget.backgroundColor ?? kColorWhite)
        : (widget.collapsedBackgroundColor ?? widget.backgroundColor ?? kColorWhite);
    final borderRadius = widget.borderRadius ?? AppUIUtils.primaryBorderRadius;
    final boxShadow = widget.boxShadow ?? containerBoxShadowUtils();
    final tilePadding = widget.tilePadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    final childrenPadding = widget.childrenPadding ?? EdgeInsets.zero;

    return Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        boxShadow: boxShadow,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          expansionTileTheme: ExpansionTileThemeData(
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            textColor: widget.textColor ?? kColorBlack,
            collapsedTextColor: widget.collapsedTextColor ?? kColorBlack,
            iconColor: widget.showExpansionIcon
                ? (widget.iconColor ?? kColorHint)
                : Colors.transparent,
            collapsedIconColor: widget.showExpansionIcon
                ? (widget.collapsedIconColor ?? kColorHint)
                : Colors.transparent,
            shape: widget.shape ?? RoundedRectangleBorder(
              borderRadius: borderRadius,
            ),
            collapsedShape: widget.collapsedShape ?? RoundedRectangleBorder(
              borderRadius: borderRadius,
            ),
          ),
        ),
        child: Column(
          children: [
            // Title row with tap to expand
            InkWell(
              onTap: _toggleExpansion,
              borderRadius: borderRadius,
              child: Padding(
                padding: tilePadding,
                child: Row(
                  children: [
                    // Title widget
                    Expanded(
                      child: widget.title,
                    ),
                    // Expansion icon (if enabled)
                    if (widget.showExpansionIcon) ...[
                      const SizedBox(width: 8),
                      RotationTransition(
                        turns: Tween<double>(begin: 0.0, end: 0.5).animate(_expandAnimation),
                        child: widget.expansionIcon ??
                            widget.collapsedIcon ??
                            Icon(
                              Icons.expand_more,
                              color: isExpanded
                                  ? (widget.iconColor ?? kColorHint)
                                  : (widget.collapsedIconColor ?? kColorHint),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Expanded content with animation
            ClipRect(
              child: SizeTransition(
                sizeFactor: _expandAnimation,
                axisAlignment: -1.0,
                child: widget.maintainState
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: childrenPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: widget.children,
                            ),
                          ),
                        ],
                      )
                    : _isExpanded
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: childrenPadding,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: widget.children,
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

