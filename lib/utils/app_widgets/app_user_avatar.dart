import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    final labelFontSize =
        fontSize ??
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

/// User avatar with a decorative profile frame overlay.
///
/// [frameUrl] can be a backend URL, a local asset path, or a known frame id
/// such as `frame_gold`. When it is missing, a stable frame is selected from
/// [frameSeed] so users get a consistent mock frame until the API is ready.
class FramedUserAvatar extends StatelessWidget {
  const FramedUserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    required this.size,
    this.frameUrl,
    this.frameSeed,
    this.fontSize,
    this.fit = BoxFit.cover,
  });

  static const _royalFrame = 'assets/images/audio_room_frame_royal.svg';
  static const _neonFrame = 'assets/images/audio_room_frame_neon.svg';
  static const _luxeFrame = 'assets/images/audio_room_frame_luxe.svg';

  final String name;
  final String? imageUrl;
  final double size;
  final String? frameUrl;
  final String? frameSeed;
  final double? fontSize;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final frameSize = size * 1.34;
    final avatarSize = size;
    final source = _resolveFrameSource();

    return SizedBox(
      width: frameSize,
      height: frameSize,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: kColorPrimary.withValues(alpha: 0.30),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: AppUserAvatar(
              name: name,
              imageUrl: imageUrl,
              size: avatarSize,
              fontSize: fontSize,
              border: Border.all(
                color: kColorWhite.withValues(alpha: 0.92),
                width: 2,
              ),
              fit: fit,
            ),
          ),
          IgnorePointer(
            child: _FrameImage(source: source, size: frameSize),
          ),
        ],
      ),
    );
  }

  String _resolveFrameSource() {
    final raw = frameUrl?.trim() ?? '';
    if (raw.isNotEmpty && raw != 'null') return _mapFrameId(raw);

    final choices = [_royalFrame, _neonFrame, _luxeFrame];
    final seed = (frameSeed?.trim().isNotEmpty ?? false) ? frameSeed! : name;
    return choices[_stableIndex(seed, choices.length)];
  }

  String _mapFrameId(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('gold') || normalized.contains('royal')) {
      return _royalFrame;
    }
    if (normalized.contains('neon') || normalized.contains('fire')) {
      return _neonFrame;
    }
    if (normalized.contains('vip') ||
        normalized.contains('luxe') ||
        normalized.contains('love')) {
      return _luxeFrame;
    }
    return value;
  }

  int _stableIndex(String value, int length) {
    var hash = 0;
    for (final codeUnit in value.codeUnits) {
      hash = (hash + codeUnit) & 0x7fffffff;
    }
    return hash % length;
  }
}

class _FrameImage extends StatelessWidget {
  const _FrameImage({required this.source, required this.size});

  final String source;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isRemote =
        source.startsWith('http://') ||
        source.startsWith('https://') ||
        source.startsWith('/');
    final normalizedUrl = isRemote ? ApiImageUtils.normalize(source) : null;
    final isSvg = source.toLowerCase().endsWith('.svg');

    if (isRemote && isSvg) {
      return SvgPicture.network(
        normalizedUrl!,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }

    if (isRemote) {
      return Image.network(
        normalizedUrl!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }

    if (isSvg) {
      return SvgPicture.asset(
        source,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }

    return Image.asset(
      source,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}
