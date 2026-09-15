import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/live_room_ui_colors.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/app_widgets/glossy_dating_card.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Premium 3-col hub cell: full-bleed cover, LIVE pill, name scrim.
class CompactLiveRoomTile extends StatelessWidget {
  const CompactLiveRoomTile({
    super.key,
    required this.displayName,
    this.imageUrl,
    this.viewerLabel,
    this.onTap,
  });

  final String displayName;
  final String? imageUrl;
  final String? viewerLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final heat = _compactHeat(viewerLabel);

    return GlossyDatingCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      radius: 16,
      borderWidth: 1.35,
      borderGradient: AppLightUi.glossRingGradient,
      fill: const Color(0xFF1A1224),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _CoverLayer(imageUrl: imageUrl, displayName: displayName),
          // Soft top vignette so the LIVE pill stays readable.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66000000),
                  Color(0x00000000),
                  Color(0x00000000),
                ],
                stops: [0, 0.28, 1],
              ),
            ),
          ),
          // Bottom scrim for host name.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00000000),
                  Color(0x00000000),
                  Color(0x99000000),
                  Color(0xE6080612),
                ],
                stops: [0, 0.42, 0.72, 1],
              ),
            ),
          ),
          const Positioned(
            left: 6,
            top: 6,
            child: _PulsingLivePill(),
          ),
          if (heat != null)
            Positioned(
              right: 6,
              top: 6,
              child: _HeatChip(label: heat),
            ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: SemiBoldText(
              text: displayName,
              fontSize: TextStyles.k10FontSize,
              color: kColorWhite,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Hide clutter when heat/viewers are missing or zero.
  static String? _compactHeat(String? raw) {
    final text = raw?.trim();
    if (text == null || text.isEmpty || text == 'null') return null;
    final n = int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (n == null) return text;
    if (n <= 0) return null;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(n >= 10000 ? 0 : 1)}K';
    return '$n';
  }
}

class _CoverLayer extends StatelessWidget {
  const _CoverLayer({required this.imageUrl, required this.displayName});

  final String? imageUrl;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final path = imageUrl?.trim() ?? '';
    final hasPath = path.isNotEmpty && path != 'null';
    final isNetwork = hasPath && path.startsWith('http');
    final isAsset = hasPath && !isNetwork && !isPlaceholderProfileImage(path);

    if (isNetwork) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _FallbackCover(name: displayName),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const ColoredBox(color: Color(0xFF1A1224));
        },
      );
    }

    if (isAsset) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _FallbackCover(name: displayName),
      );
    }

    return _FallbackCover(name: displayName);
  }
}

class _FallbackCover extends StatelessWidget {
  const _FallbackCover({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3A2458),
            Color(0xFF1A1224),
            Color(0xFF2A1840),
          ],
        ),
      ),
      child: Center(
        child: AppUserAvatar(
          name: name,
          size: 52,
          showFrame: false,
          backgroundColor: AppLightUi.violet.withValues(alpha: 0.45),
          textColor: kColorWhite,
          border: Border.all(
            color: kColorWhite.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _PulsingLivePill extends StatefulWidget {
  const _PulsingLivePill();

  @override
  State<_PulsingLivePill> createState() => _PulsingLivePillState();
}

class _PulsingLivePillState extends State<_PulsingLivePill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_pulse.value);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: LiveRoomUiColors.liveDot.withValues(alpha: 0.92 + t * 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: kColorWhite.withValues(alpha: 0.28 + t * 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: AppLightUi.title.withValues(alpha: 0.18),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final t = Curves.easeInOut.transform(_pulse.value);
              return Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: kColorWhite.withValues(alpha: 0.75 + t * 0.25),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kColorWhite.withValues(alpha: 0.35 + t * 0.45),
                      blurRadius: 3 + t * 2,
                    ),
                  ],
                ),
              );
            },
          ),
          Spacing.h4,
          const SemiBoldText(
            text: 'LIVE',
            fontSize: TextStyles.k8FontSize,
            color: kColorWhite,
          ),
        ],
      ),
    );
  }
}

class _HeatChip extends StatelessWidget {
  const _HeatChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: 10,
            color: kColorWhite.withValues(alpha: 0.92),
          ),
          const SizedBox(width: 2),
          SemiBoldText(
            text: label,
            fontSize: TextStyles.k8FontSize,
            color: kColorWhite.withValues(alpha: 0.92),
          ),
        ],
      ),
    );
  }
}
