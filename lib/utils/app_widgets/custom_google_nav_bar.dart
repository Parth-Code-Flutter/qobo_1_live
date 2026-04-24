import 'dart:math' show pow;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

/// Custom Google Navigation Bar with SVG icon support
/// Based on google_nav_bar package but modified to support SVG icons

enum GnavStyle {
  google,
  oldSchool,
}

class CustomGNav extends StatefulWidget {
  const CustomGNav({
    Key? key,
    required this.tabs,
    this.selectedIndex = 0,
    this.onTabChange,
    this.gap = 0,
    this.padding = const EdgeInsets.all(25),
    this.activeColor,
    this.color,
    this.rippleColor = Colors.transparent,
    this.hoverColor = Colors.transparent,
    this.backgroundColor = Colors.transparent,
    this.tabBackgroundColor = Colors.transparent,
    this.tabBorderRadius = 100.0,
    this.iconSize,
    this.textStyle,
    this.curve = Curves.easeInCubic,
    this.tabMargin = EdgeInsets.zero,
    this.debug = false,
    this.duration = const Duration(milliseconds: 500),
    this.tabBorder,
    this.tabActiveBorder,
    this.tabShadow,
    this.haptic = true,
    this.tabBackgroundGradient,
    this.mainAxisAlignment = MainAxisAlignment.spaceBetween,
    this.style = GnavStyle.google,
    this.textSize,
  }) : super(key: key);

  final List<CustomGButton> tabs;
  final int selectedIndex;
  final ValueChanged<int>? onTabChange;
  final double gap;
  final double tabBorderRadius;
  final double? iconSize;
  final Color? activeColor;
  final Color backgroundColor;
  final Color tabBackgroundColor;
  final Color? color;
  final Color rippleColor;
  final Color hoverColor;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry tabMargin;
  final TextStyle? textStyle;
  final Duration duration;
  final Curve curve;
  final bool debug;
  final bool haptic;
  final Border? tabBorder;
  final Border? tabActiveBorder;
  final List<BoxShadow>? tabShadow;
  final Gradient? tabBackgroundGradient;
  final MainAxisAlignment mainAxisAlignment;
  final GnavStyle? style;
  final double? textSize;

  @override
  _CustomGNavState createState() => _CustomGNavState();
}

class _CustomGNavState extends State<CustomGNav> {
  late int selectedIndex;
  bool clickable = true;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(CustomGNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      selectedIndex = widget.selectedIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: widget.backgroundColor,
        child: Row(
            mainAxisAlignment: widget.mainAxisAlignment,
            children: widget.tabs
                .map((t) => CustomGButton(
                      textSize: widget.textSize,
                      style: widget.style,
                      key: t.key,
                      border: t.border ?? widget.tabBorder,
                      activeBorder: t.activeBorder ?? widget.tabActiveBorder,
                      shadow: t.shadow ?? widget.tabShadow,
                      borderRadius: t.borderRadius ??
                          BorderRadius.all(
                            Radius.circular(widget.tabBorderRadius),
                          ),
                      debug: widget.debug,
                      margin: t.margin ?? widget.tabMargin,
                      active: selectedIndex == widget.tabs.indexOf(t),
                      gap: t.gap ?? widget.gap,
                      iconActiveColor: t.iconActiveColor ?? widget.activeColor,
                      iconColor: t.iconColor ?? widget.color,
                      iconSize: t.iconSize ?? widget.iconSize,
                      textColor: t.textColor ?? widget.activeColor,
                      rippleColor: t.rippleColor ?? widget.rippleColor,
                      hoverColor: t.hoverColor ?? widget.hoverColor,
                      padding: t.padding ?? widget.padding,
                      textStyle: t.textStyle ?? widget.textStyle,
                      text: t.text,
                      iconWidget: t.iconWidget,
                      haptic: widget.haptic,
                      leading: t.leading,
                      curve: widget.curve,
                      backgroundGradient:
                          t.backgroundGradient ?? widget.tabBackgroundGradient,
                      backgroundColor:
                          t.backgroundColor ?? widget.tabBackgroundColor,
                      duration: widget.duration,
                      onPressed: () {
                        if (!clickable) return;
                        setState(() {
                          selectedIndex = widget.tabs.indexOf(t);
                          clickable = false;
                        });

                        t.onPressed?.call();

                        widget.onTabChange?.call(selectedIndex);

                        Future.delayed(widget.duration, () {
                          if (context.mounted) {
                            setState(() {
                              clickable = true;
                            });
                          }
                        });
                      },
                    ))
                .toList()));
  }
}

class CustomGButton extends StatefulWidget {
  final bool? active;
  final bool? debug;
  final bool? haptic;
  final double? gap;
  final Color? iconColor;
  final Color? rippleColor;
  final Color? hoverColor;
  final Color? iconActiveColor;
  final Color? textColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final TextStyle? textStyle;
  final double? iconSize;
  final Function? onPressed;
  final String text;
  final Widget? iconWidget; // Changed from IconData to Widget for SVG support
  final Color? backgroundColor;
  final Duration? duration;
  final Curve? curve;
  final Gradient? backgroundGradient;
  final Widget? leading;
  final BorderRadius? borderRadius;
  final Border? border;
  final Border? activeBorder;
  final List<BoxShadow>? shadow;
  final String? semanticLabel;
  final GnavStyle? style;
  final double? textSize;

  const CustomGButton({
    Key? key,
    this.active,
    this.haptic,
    this.backgroundColor,
    this.iconWidget, // Changed from required icon to optional iconWidget
    this.iconColor,
    this.rippleColor,
    this.hoverColor,
    this.iconActiveColor,
    this.text = '',
    this.textColor,
    this.padding,
    this.margin,
    this.duration,
    this.debug,
    this.gap,
    this.curve,
    this.textStyle,
    this.iconSize,
    this.leading,
    this.onPressed,
    this.backgroundGradient,
    this.borderRadius,
    this.border,
    this.activeBorder,
    this.shadow,
    this.semanticLabel,
    this.style = GnavStyle.google,
    this.textSize,
  }) : super(key: key);

  @override
  _CustomGButtonState createState() => _CustomGButtonState();
}

class _CustomGButtonState extends State<CustomGButton> {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel ?? widget.text,
      child: CustomButton(
        textSize: widget.textSize,
        style: widget.style,
        borderRadius: widget.borderRadius,
        border: widget.border,
        activeBorder: widget.activeBorder,
        shadow: widget.shadow,
        debug: widget.debug,
        duration: widget.duration,
        iconSize: widget.iconSize,
        active: widget.active,
        onPressed: () {
          if (widget.haptic!) HapticFeedback.selectionClick();
          widget.onPressed?.call();
        },
        padding: widget.padding,
        margin: widget.margin,
        gap: widget.gap,
        color: widget.backgroundColor,
        rippleColor: widget.rippleColor,
        hoverColor: widget.hoverColor,
        gradient: widget.backgroundGradient,
        curve: widget.curve,
        leading: widget.leading,
        iconActiveColor: widget.iconActiveColor,
        iconColor: widget.iconColor,
        iconWidget: widget.iconWidget,
        textColor: widget.textColor,
        text: Text(
          widget.text,
          style: widget.textStyle ??
              TextStyle(
                fontWeight: FontWeight.w600,
                color: widget.textColor,
              ),
        ),
      ),
    );
  }
}

class CustomButton extends StatefulWidget {
  const CustomButton({
    Key? key,
    this.iconWidget, // Changed from IconData to Widget
    this.iconSize,
    this.leading,
    this.iconActiveColor,
    this.iconColor,
    this.textColor,
    this.text,
    this.gap,
    this.color,
    this.rippleColor,
    this.hoverColor,
    required this.onPressed,
    this.duration,
    this.curve,
    this.padding,
    this.margin,
    required this.active,
    this.debug,
    this.gradient,
    this.borderRadius,
    this.border,
    this.activeBorder,
    this.shadow,
    this.style = GnavStyle.google,
    this.textSize,
  }) : super(key: key);

  final Widget? iconWidget; // Changed from IconData? to Widget?
  final double? iconSize;
  final Text? text;
  final Widget? leading;
  final Color? iconActiveColor;
  final Color? iconColor;
  final Color? textColor;
  final Color? color;
  final Color? rippleColor;
  final Color? hoverColor;
  final double? gap;
  final bool? active;
  final bool? debug;
  final VoidCallback onPressed;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Duration? duration;
  final Curve? curve;
  final Gradient? gradient;
  final BorderRadius? borderRadius;
  final Border? border;
  final Border? activeBorder;
  final List<BoxShadow>? shadow;
  final GnavStyle? style;
  final double? textSize;

  @override
  _CustomButtonState createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with TickerProviderStateMixin {
  late bool _expanded;
  late final AnimationController expandController;

  @override
  void initState() {
    super.initState();
    _expanded = widget.active!;

    expandController =
        AnimationController(vsync: this, duration: widget.duration)
          ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    expandController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var curveValue = expandController
        .drive(CurveTween(
            curve: _expanded ? widget.curve! : widget.curve!.flipped))
        .value;
    var _colorTween =
        ColorTween(begin: widget.iconColor, end: widget.iconActiveColor);
    var _colorTweenAnimation = _colorTween.animate(CurvedAnimation(
        parent: expandController,
        curve: _expanded ? Curves.easeInExpo : Curves.easeOutCirc));
    
    // Text color animation for oldSchool style
    // The text color should match the icon color animation
    // If textColor is provided, use it; otherwise use icon colors
    var _textColorTween = widget.textColor != null
        ? ColorTween(begin: widget.iconColor, end: widget.textColor)
        : ColorTween(begin: widget.iconColor, end: widget.iconActiveColor);
    var _textColorTweenAnimation = _textColorTween.animate(CurvedAnimation(
        parent: expandController,
        curve: _expanded ? Curves.easeInExpo : Curves.easeOutCirc));

    _expanded = !widget.active!;
    if (_expanded)
      expandController.reverse();
    else
      expandController.forward();

    // Build icon widget - support both SVG and regular icons
    Widget icon = widget.leading ??
        (widget.iconWidget != null
            ? (_colorTweenAnimation.value != null
                ? ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      _colorTweenAnimation.value!,
                      BlendMode.srcIn,
                    ),
                    child: SizedBox(
                      width: widget.iconSize ?? 24,
                      height: widget.iconSize ?? 24,
                      child: widget.iconWidget,
                    ),
                  )
                : SizedBox(
                    width: widget.iconSize ?? 24,
                    height: widget.iconSize ?? 24,
                    child: widget.iconWidget,
                  ))
            : const SizedBox.shrink());

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        highlightColor: widget.hoverColor,
        splashColor: widget.rippleColor,
        borderRadius: widget.borderRadius,
        onTap: widget.onPressed,
        child: Container(
          padding: widget.margin,
          child: AnimatedContainer(
            curve: Curves.easeOut,
            padding: widget.padding,
            duration: widget.duration!,
            decoration: BoxDecoration(
              boxShadow: widget.shadow,
              border: widget.active!
                  ? (widget.activeBorder ?? widget.border)
                  : widget.border,
              gradient: widget.gradient,
              color: _expanded
                  ? widget.color!.withOpacity(0)
                  : widget.debug!
                      ? Colors.red
                      : widget.gradient != null
                          ? Colors.white
                          : widget.color,
              borderRadius: widget.borderRadius,
            ),
            child: FittedBox(
              fit: BoxFit.fitHeight,
              child: Builder(
                builder: (_) {
                  if (widget.style == GnavStyle.google) {
                    return Stack(
                      children: [
                        if (widget.text!.data != '')
                          Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Opacity(
                                  opacity: 0,
                                  child: icon,
                                ),
                                Container(
                                  child: Container(
                                    child: Align(
                                        alignment: Alignment.centerRight,
                                        widthFactor: curveValue,
                                        child: Container(
                                          child: Opacity(
                                              opacity: _expanded
                                                  ? pow(expandController.value,
                                                      13) as double
                                                  : expandController
                                                      .drive(CurveTween(
                                                          curve: Curves.easeIn))
                                                      .value,
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                    left: widget.gap! +
                                                        8 -
                                                        (8 *
                                                            expandController
                                                                .drive(CurveTween(
                                                                    curve: Curves
                                                                        .easeOutSine))
                                                                .value),
                                                    right: 8 *
                                                        expandController
                                                            .drive(CurveTween(
                                                                curve: Curves
                                                                    .easeOutSine))
                                                            .value),
                                                child: widget.text,
                                              )),
                                        )),
                                  ),
                                ),
                              ]),
                        Align(alignment: Alignment.centerLeft, child: icon),
                      ],
                    );
                  } else if (widget.style == GnavStyle.oldSchool) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        icon,
                        if (widget.text!.data != null && widget.text!.data!.isNotEmpty)
                          Container(
                            padding: EdgeInsets.only(top: widget.gap ?? 4),
                            child: DefaultTextStyle(
                              style: widget.text!.style ?? TextStyle(
                                color: _textColorTweenAnimation.value,
                                fontSize: widget.textSize ?? 12,
                              ),
                              child: widget.text!,
                            ),
                          ),
                      ],
                    );
                  } else {
                    return Container();
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

