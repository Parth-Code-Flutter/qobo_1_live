import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../constants/color_constants.dart';

/// Reusable loading widget for consistent loading states across the app
class AppLoadingWidget extends StatelessWidget {
  final double? size;
  final Color? color;
  final String? message;
  final bool showMessage;
  final EdgeInsetsGeometry? padding;

  const AppLoadingWidget({
    super.key,
    this.size,
    this.color,
    this.message,
    this.showMessage = false,
    this.padding,
  });

  /// Small loading widget (24x24)
  const AppLoadingWidget.small({
    super.key,
    this.color,
    this.message,
    this.showMessage = false,
    this.padding,
  }) : size = 24.0;

  /// Medium loading widget (32x32)
  const AppLoadingWidget.medium({
    super.key,
    this.color,
    this.message,
    this.showMessage = false,
    this.padding,
  }) : size = 32.0;

  /// Large loading widget (48x48)
  const AppLoadingWidget.large({
    super.key,
    this.color,
    this.message,
    this.showMessage = false,
    this.padding,
  }) : size = 48.0;

  /// Extra large loading widget (64x64)
  const AppLoadingWidget.xlarge({
    super.key,
    this.color,
    this.message,
    this.showMessage = false,
    this.padding,
  }) : size = 64.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SpinKitFadingCircle(
            color: color ?? kColorPrimary,
            size: size ?? 32.0,
          ),
          if (showMessage && message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              style: TextStyle(
                color: color ?? kColorPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Loading overlay widget for full-screen loading
class AppLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? backgroundColor;
  final Color? loadingColor;

  const AppLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.backgroundColor,
    this.loadingColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: backgroundColor ?? kColorBlack.withValues(alpha: 0.5),
            child: Center(
              child: AppLoadingWidget.large(
                color: loadingColor ?? kColorWhite,
                message: message,
                showMessage: message != null,
              ),
            ),
          ),
      ],
    );
  }
}

/// Common circular progress bar used across the app
class CommonCircleProgressBarWidget extends StatelessWidget {
  final double size;
  final Color color;
  final EdgeInsetsGeometry? padding;

  const CommonCircleProgressBarWidget({
    super.key,
    this.size = 32,
    this.color = kColorPrimary,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: SizedBox(
          height: size,
          width: size,
          child: CircularProgressIndicator(
            color: color,
            // Colors are controlled by theme; wrapper gives us size
          ),
        ),
      ),
    );
  }
}
