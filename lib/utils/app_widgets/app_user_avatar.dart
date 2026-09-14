import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:qobo_one_live/utils/app_widgets/safe_network_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:flutter_svga/flutter_svga.dart';

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
    this.frameUrl,
    this.frameSeed,
    this.showFrame = true,
  });

  final String name;
  final String? imageUrl;
  final double size;
  final double? fontSize;
  final Color? backgroundColor;
  final Color? textColor;
  final BoxBorder? border;
  final BoxFit fit;
  final String? frameUrl;
  final String? frameSeed;

  /// Disable only when a parent already supplies the decorative frame.
  final bool showFrame;

  @override
  Widget build(BuildContext context) {
    if (showFrame) {
      return FramedUserAvatar(
        name: name,
        imageUrl: imageUrl,
        frameUrl: frameUrl,
        frameSeed: frameSeed,
        size: size / 1.34,
        fontSize: fontSize,
        fit: fit,
      );
    }
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
    final avatarSize = frameSize * 0.56;
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
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: AppUserAvatar(
              showFrame: false,
              name: name,
              imageUrl: imageUrl,
              size: avatarSize,
              fontSize: fontSize,
              border: Border.all(
                color: kColorWhite.withValues(alpha: 0.92),
                width: 1.6,
              ),
              fit: fit,
            ),
          ),
          IgnorePointer(
            child: _FrameImage(
              key: ValueKey(source),
              source: source,
              fallbackSource: _fallbackFrameSource(),
              size: frameSize,
            ),
          ),
        ],
      ),
    );
  }

  String _resolveFrameSource() {
    final raw = frameUrl?.trim() ?? '';
    if (raw.isNotEmpty && raw.toLowerCase() != 'null') return _mapFrameId(raw);
    return _fallbackFrameSource();
  }

  String _fallbackFrameSource() {
    final choices = [_royalFrame, _neonFrame, _luxeFrame];
    final seed = (frameSeed?.trim().isNotEmpty ?? false) ? frameSeed! : name;
    return choices[_stableIndex(seed, choices.length)];
  }

  String _mapFrameId(String value) {
    final normalized = value.toLowerCase();
    // Never replace an actual URL just because its filename contains "gold".
    if (value.contains('/') || value.contains('.')) return value;
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

class _FrameImage extends StatefulWidget {
  const _FrameImage({
    super.key,
    required this.source,
    required this.size,
    required this.fallbackSource,
  });

  final String source;
  final double size;
  final String fallbackSource;

  @override
  State<_FrameImage> createState() => _FrameImageState();
}

class _FrameImageState extends State<_FrameImage>
    with SingleTickerProviderStateMixin {
  SVGAAnimationController? _svgaController;
  bool _isSvgaReady = false;
  bool _svgaFailed = false;

  bool get _isRemote =>
      widget.source.startsWith('http://') ||
      widget.source.startsWith('https://') ||
      widget.source.startsWith('/');

  String get _sourcePath =>
      (Uri.tryParse(widget.source)?.path ?? widget.source).toLowerCase();

  bool get _isSvg => _sourcePath.endsWith('.svg');

  bool get _shouldTrySvga {
    final normalized = _sourcePath;
    return _isRemote &&
        !_isSvg &&
        !normalized.endsWith('.png') &&
        !normalized.endsWith('.jpg') &&
        !normalized.endsWith('.jpeg') &&
        !normalized.endsWith('.webp') &&
        !normalized.endsWith('.gif');
  }

  @override
  void initState() {
    super.initState();
    _loadSvgaIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _FrameImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      _svgaController?.dispose();
      _svgaController = null;
      _isSvgaReady = false;
      _svgaFailed = false;
      _loadSvgaIfNeeded();
    }
  }

  @override
  void dispose() {
    _svgaController?.dispose();
    super.dispose();
  }

  Future<void> _loadSvgaIfNeeded() async {
    if (!_shouldTrySvga) return;
    final controller = SVGAAnimationController(vsync: this);
    _svgaController = controller;
    try {
      final videoItem = await SVGAParser.shared.decodeFromURL(
        ApiImageUtils.normalize(widget.source) ?? widget.source,
      );
      if (!mounted || _svgaController != controller) return;
      controller.videoItem = videoItem;
      // Avatar-frame SVGAs must stay silent in profile / chat chrome.
      controller.muted = true;
      controller.repeat();
      setState(() {
        _isSvgaReady = true;
        _svgaFailed = false;
      });
    } catch (_) {
      if (!mounted || _svgaController != controller) return;
      setState(() {
        _isSvgaReady = false;
        _svgaFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = _isRemote
        ? ApiImageUtils.normalize(widget.source)
        : null;

    if (_svgaFailed) return _fallbackFrame();

    // Keep a frame visible while the equipped asset downloads.
    if (_shouldTrySvga && !_isSvgaReady && !_svgaFailed) {
      return _frameLoader();
    }

    if (_shouldTrySvga &&
        _isSvgaReady &&
        !_svgaFailed &&
        _svgaController != null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: SVGAImage(
          _svgaController!,
          fit: BoxFit.contain,
          preferredSize: Size.square(widget.size),
          clearsAfterStop: false,
        ),
      );
    }

    if (_isRemote && _isSvg) {
      return SvgPicture.network(
        normalizedUrl!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => _frameLoader(),
        errorBuilder: (_, __, ___) => _fallbackFrame(),
      );
    }

    if (_isRemote) {
      return Image.network(
        normalizedUrl!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _frameLoader();
        },
        errorBuilder: (_, __, ___) => _fallbackFrame(),
      );
    }

    if (_isSvg) {
      return SvgPicture.asset(
        widget.source,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
      );
    }

    return Image.asset(
      widget.source,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _fallbackFrame(),
    );
  }

  Widget _fallbackFrame() => SvgPicture.asset(
    widget.fallbackSource,
    width: widget.size,
    height: widget.size,
    fit: BoxFit.contain,
  );

  Widget _frameLoader() => _fallbackFrame();
}
