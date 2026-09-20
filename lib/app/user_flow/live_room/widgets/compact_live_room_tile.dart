import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/app_widgets/glossy_dating_card.dart';
import 'package:qobo_one_live/utils/app_widgets/live_session_badge.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Premium 3-col hub cell: framed host avatar, LIVE pill, name + optional heat.
class CompactLiveRoomTile extends StatelessWidget {
  const CompactLiveRoomTile({
    super.key,
    required this.displayName,
    this.imageUrl,
    this.frameUrl,
    this.frameSeed,
    this.viewerLabel,
    this.onTap,
  });

  final String displayName;
  final String? imageUrl;
  final String? frameUrl;
  final String? frameSeed;
  final String? viewerLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final heat = _compactHeat(viewerLabel);
    final seed = (frameSeed?.trim().isNotEmpty ?? false)
        ? frameSeed!.trim()
        : displayName;

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
          const DecoratedBox(
            decoration: BoxDecoration(
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
          ),
          // Soft vignette so the LIVE pill stays readable.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x44000000),
                  Color(0x00000000),
                  Color(0x66080612),
                ],
                stops: [0, 0.35, 1],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 26, 6, 8),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // FramedUserAvatar lays out at size * 1.34; keep crowns
                        // inside the cell without clipping.
                        final maxFrame = constraints.biggest.shortestSide;
                        final avatarSize =
                            (maxFrame / 1.34).clamp(42.0, 64.0);
                        return FramedUserAvatar(
                          name: displayName,
                          imageUrl: imageUrl,
                          frameUrl: frameUrl,
                          frameSeed: seed,
                          size: avatarSize,
                          fontSize: avatarSize >= 56
                              ? TextStyles.k14FontSize
                              : TextStyles.k10FontSize,
                        );
                      },
                    ),
                  ),
                ),
                Spacing.v4,
                SemiBoldText(
                  text: displayName,
                  fontSize: TextStyles.k10FontSize,
                  color: kColorWhite,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  align: TextAlign.center,
                ),
              ],
            ),
          ),
          Positioned(
            left: 4,
            top: 4,
            child: LiveSessionBadge.live(compact: true),
          ),
          if (heat != null)
            Positioned(
              right: 6,
              top: 6,
              child: _HeatChip(label: heat),
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
