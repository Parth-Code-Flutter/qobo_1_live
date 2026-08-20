import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qobo_one_live/constants/image_constants.dart';

/// In-app coin glyph — uses project SVG assets (no $ / currency symbol).
class AppCoinIcon extends StatelessWidget {
  const AppCoinIcon({
    super.key,
    this.size = 16,
    this.color,
    this.asset = kIconCoin3,
  });

  final double size;
  final Color? color;

  /// Defaults to [kIconCoin3]; use [kIconCoin4] for slightly larger hero spots.
  final String asset;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}
