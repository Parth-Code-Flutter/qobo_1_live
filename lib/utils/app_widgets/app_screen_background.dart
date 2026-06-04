import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/theme/theme_context.dart';

/// Full-screen background for tab/hero screens — image in dark, soft gradient in light.
class AppScreenBackground extends StatelessWidget {
  const AppScreenBackground({
    super.key,
    required this.child,
    this.useBrandImageInDark = true,
  });

  final Widget child;
  final bool useBrandImageInDark;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final BoxDecoration decoration;
    if (colors.isDark && useBrandImageInDark) {
      decoration = const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(kImgBG),
          fit: BoxFit.cover,
        ),
      );
    } else {
      decoration = BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.heroGradientTop, colors.heroGradientBottom],
        ),
      );
    }

    return Container(decoration: decoration, child: child);
  }
}
