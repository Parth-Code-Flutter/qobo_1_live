import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Short full-screen emoji pop used for direct room emojis.
///
/// It is intentionally separate from gift SVGA playback so gift timing and
/// queueing remain untouched.
class EmojiCelebrationOverlay {
  EmojiCelebrationOverlay._();

  static BuildContext? _dialogContext;
  static Timer? _dismissTimer;

  static void show({
    required String image,
    String? name,
    Duration duration = const Duration(milliseconds: 2600),
  }) {
    dismiss();

    BuildContext? context;
    try {
      context = Get.context ?? Get.key.currentContext;
    } catch (_) {
      context = null;
    }
    if (context == null) return;

    void close(BuildContext dialogContext) {
      if (dialogContext.mounted && Navigator.of(dialogContext).canPop()) {
        Navigator.of(dialogContext).pop();
      }
      if (_dialogContext == dialogContext) _dialogContext = null;
    }

    Get.dialog<void>(
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      useSafeArea: false,
      Builder(
        builder: (dialogContext) {
          _dialogContext = dialogContext;
          _dismissTimer = Timer(duration, () => close(dialogContext));
          return _EmojiCelebrationView(image: image, name: name);
        },
      ),
    );
  }

  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;

    final dialogContext = _dialogContext;
    _dialogContext = null;
    try {
      if (dialogContext != null &&
          dialogContext.mounted &&
          Navigator.of(dialogContext).canPop()) {
        Navigator.of(dialogContext).pop();
      }
    } catch (_) {}
  }
}

class _EmojiCelebrationView extends StatefulWidget {
  const _EmojiCelebrationView({required this.image, this.name});

  final String image;
  final String? name;

  @override
  State<_EmojiCelebrationView> createState() => _EmojiCelebrationViewState();
}

class _EmojiCelebrationViewState extends State<_EmojiCelebrationView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final emojiSize = math.min(size.width * 0.58, 260.0);
    return SizedBox.expand(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final value = Curves.elasticOut.transform(
              _controller.value.clamp(0, 1),
            );
            final fade = _controller.value < 0.78
                ? 1.0
                : (1 - ((_controller.value - 0.78) / 0.22)).clamp(0.0, 1.0);

            return Opacity(
              opacity: fade,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.20),
                      ),
                    ),
                  ),
                  CustomPaint(
                    painter: _EmojiBurstPainter(progress: _controller.value),
                    size: Size.infinite,
                  ),
                  Transform.scale(
                    scale: 0.72 + (0.28 * value),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: emojiSize,
                          height: emojiSize,
                          child: EmojiMediaView(
                            image: widget.image,
                            fit: BoxFit.contain,
                          ),
                        ),
                        if (widget.name?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.54),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: kColorWhite.withValues(alpha: 0.14),
                              ),
                            ),
                            child: SemiBoldText(
                              text: widget.name!.trim(),
                              fontSize: TextStyles.k14FontSize,
                              color: kColorWhite,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class EmojiMediaView extends StatelessWidget {
  const EmojiMediaView({
    super.key,
    required this.image,
    this.fit = BoxFit.contain,
    this.emojiFontSize = 118,
  });

  final String image;
  final BoxFit fit;
  final double emojiFontSize;

  @override
  Widget build(BuildContext context) {
    final source = image.trim();
    if (source.isEmpty) return const Icon(Icons.emoji_emotions_rounded);

    if (source.startsWith('data:image/svg+xml')) {
      return SvgPicture.string(
        _decodeSvgDataUri(source),
        fit: fit,
        placeholderBuilder: (_) => const _EmojiFallback(),
      );
    }

    if (source.startsWith('http://') || source.startsWith('https://')) {
      final path = Uri.tryParse(source)?.path.toLowerCase() ?? '';
      if (path.endsWith('.svg') || source.contains('/svg')) {
        return SvgPicture.network(
          source,
          fit: fit,
          placeholderBuilder: (_) => const _EmojiFallback(),
        );
      }
      return Image.network(
        source,
        fit: fit,
        errorBuilder: (_, __, ___) => const _EmojiFallback(),
      );
    }

    if (source.length <= 8) {
      return Center(
        child: Text(source, style: TextStyle(fontSize: emojiFontSize)),
      );
    }

    return Image.asset(
      source,
      fit: fit,
      errorBuilder: (_, __, ___) => const _EmojiFallback(),
    );
  }

  String _decodeSvgDataUri(String value) {
    final comma = value.indexOf(',');
    if (comma < 0) return value;
    final metadata = value.substring(0, comma).toLowerCase();
    final payload = value.substring(comma + 1);
    if (metadata.contains(';base64')) {
      return utf8.decode(base64Decode(payload));
    }
    return Uri.decodeFull(payload);
  }
}

class _EmojiFallback extends StatelessWidget {
  const _EmojiFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.emoji_emotions_rounded,
        size: 112,
        color: Color(0xFFFFD84D),
      ),
    );
  }
}

class _EmojiBurstPainter extends CustomPainter {
  _EmojiBurstPainter({required this.progress});

  final double progress;

  static const _colors = [
    Color(0xFFFFD84D),
    Color(0xFFFF3F8B),
    Color(0xFF8F5BFF),
    Color(0xFF21D8FF),
    Color(0xFFFFFFFF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;
    final eased = Curves.easeOutCubic.transform(progress.clamp(0, 1));

    for (var i = 0; i < 32; i++) {
      final angle = (math.pi * 2 / 32) * i;
      final distance = (54 + (i % 5) * 16) * eased;
      final point =
          center +
          Offset(math.cos(angle) * distance, math.sin(angle) * distance);
      paint.color = _colors[i % _colors.length].withValues(
        alpha: (1 - progress * 0.55).clamp(0.0, 1.0),
      );
      canvas.drawCircle(point, (3.2 + (i % 3)).clamp(2, 6), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EmojiBurstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
