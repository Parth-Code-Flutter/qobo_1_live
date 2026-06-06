import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:qobo_one_live/utils/app_widgets/safe_network_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Two-letter initials from a display name (first letter of first two words).
String userDisplayInitials(String name) {
  final source = name.trim();
  if (source.isEmpty) return '?';
  final parts = source.split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
  final words = parts.toList();
  if (words.length >= 2) {
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
  return source.substring(0, source.length >= 2 ? 2 : 1).toUpperCase();
}

/// Backend placeholder paths — treat as no real photo.
bool isPlaceholderProfileImage(String? url) {
  final raw = url?.trim().toLowerCase() ?? '';
  if (raw.isEmpty || raw == 'null') return true;
  return raw.contains('default_dp') ||
      raw.contains('default_poster') ||
      raw.contains('default-avatar') ||
      raw.contains('placeholder');
}

/// Resolves a profile URL; returns null when empty or placeholder.
String? resolveUserAvatarUrl(String? url) {
  if (isPlaceholderProfileImage(url)) return null;
  return ApiImageUtils.normalize(url);
}

/// Circular user avatar: network photo when valid, else two-letter initials.
class AppUserAvatar extends StatelessWidget {
  const AppUserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    required this.size,
    this.fontSize,
    this.backgroundColor,
    this.textColor,
    this.border,
    this.fit = BoxFit.cover,
  });

  final String name;
  final String? imageUrl;
  final double size;
  final double? fontSize;
  final Color? backgroundColor;
  final Color? textColor;
  final BoxBorder? border;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = resolveUserAvatarUrl(imageUrl);
    final avatar = ClipOval(
      child: SafeNetworkAvatar(
        url: resolvedUrl,
        size: size,
        fit: fit,
        fallback: _initialsTile(),
      ),
    );

    if (border == null) {
      return SizedBox(width: size, height: size, child: avatar);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, border: border),
      child: avatar,
    );
  }

  Widget _initialsTile() {
    final labelFontSize = fontSize ??
        (size <= 32
            ? TextStyles.k10FontSize
            : size <= 48
            ? TextStyles.k12FontSize
            : TextStyles.k18FontSize);

    return ColoredBox(
      color: backgroundColor ?? kColorPrimary.withValues(alpha: 0.45),
      child: Center(
        child: SemiBoldText(
          text: userDisplayInitials(name),
          fontSize: labelFontSize,
          color: textColor ?? kColorWhite,
        ),
      ),
    );
  }
}
