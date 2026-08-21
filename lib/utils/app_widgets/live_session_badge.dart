import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/user_active_session.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Visual family for live audio / video / stream chrome.
enum LiveSessionKind { audio, video, liveStream }

LiveSessionKind liveSessionKindFrom(UserActiveSession? session) {
  switch (session?.normalizedRoomType) {
    case 'AUDIO':
      return LiveSessionKind.audio;
    case 'LIVE_STREAM':
      return LiveSessionKind.liveStream;
    default:
      return LiveSessionKind.video;
  }
}

class _LiveSessionPalette {
  const _LiveSessionPalette({
    required this.gradient,
    required this.glow,
    required this.icon,
    required this.typeLabel,
  });

  final List<Color> gradient;
  final Color glow;
  final IconData icon;
  final String typeLabel;

  static _LiveSessionPalette of(LiveSessionKind kind) {
    switch (kind) {
      case LiveSessionKind.audio:
        return const _LiveSessionPalette(
          gradient: [Color(0xFFB24BFF), Color(0xFFFF3EA5), Color(0xFFFF6AD5)],
          glow: Color(0xFFFF3EA5),
          icon: Icons.headphones_rounded,
          typeLabel: 'AUDIO',
        );
      case LiveSessionKind.video:
        return const _LiveSessionPalette(
          gradient: [Color(0xFF3B82F6), Color(0xFF06B6D4), Color(0xFF22D3EE)],
          glow: Color(0xFF06B6D4),
          icon: Icons.videocam_rounded,
          typeLabel: 'VIDEO',
        );
      case LiveSessionKind.liveStream:
        return const _LiveSessionPalette(
          gradient: [Color(0xFFFF355D), Color(0xFFFF3EA5), Color(0xFFFF9A3D)],
          glow: Color(0xFFFF355D),
          icon: Icons.sensors_rounded,
          typeLabel: 'LIVE',
        );
    }
  }
}

/// Compact pulsing LIVE pill for cards / chip rows.
class LiveSessionBadge extends StatefulWidget {
  const LiveSessionBadge({
    super.key,
    required this.kind,
    this.label,
    this.compact = true,
  });

  factory LiveSessionBadge.fromSession(
    UserActiveSession? session, {
    Key? key,
    bool compact = true,
  }) {
    return LiveSessionBadge(
      key: key,
      kind: liveSessionKindFrom(session),
      label: compact
          ? (session?.liveBadgeLabelCompact ?? 'LIVE')
          : session?.liveBadgeLabel,
      compact: compact,
    );
  }

  final LiveSessionKind kind;
  final String? label;
  final bool compact;

  @override
  State<LiveSessionBadge> createState() => _LiveSessionBadgeState();
}

class _LiveSessionBadgeState extends State<LiveSessionBadge>
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
    final palette = _LiveSessionPalette.of(widget.kind);
    final label = (widget.label?.trim().isNotEmpty == true)
        ? widget.label!.trim()
        : (widget.compact ? palette.typeLabel : 'LIVE · ${palette.typeLabel}');
    final hPad = widget.compact ? 7.0 : 11.0;
    final vPad = widget.compact ? 3.5 : 6.0;
    final fontSize =
        widget.compact ? TextStyles.k8FontSize : TextStyles.k10FontSize;
    final iconSize = widget.compact ? 11.0 : 13.0;
    final dotSize = widget.compact ? 5.0 : 6.5;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_pulse.value);
        return Container(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: palette.gradient,
            ),
            border: Border.all(
              color: kColorWhite.withValues(alpha: 0.28 + t * 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: palette.glow.withValues(alpha: 0.32 + t * 0.22),
                blurRadius: widget.compact ? 8 + t * 4 : 10 + t * 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulseDot(size: dotSize, color: kColorWhite),
          SizedBox(width: widget.compact ? 4 : 6),
          Icon(palette.icon, size: iconSize, color: kColorWhite),
          SizedBox(width: widget.compact ? 3 : 5),
          SemiBoldText(
            text: label,
            fontSize: fontSize,
            color: kColorWhite,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.55 + t * 0.35),
                blurRadius: 3 + t * 4,
                spreadRadius: t * 1.2,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Glass hero strip for the Discover preview sheet when the user is live.
class LiveSessionPreviewBanner extends StatelessWidget {
  const LiveSessionPreviewBanner({
    super.key,
    required this.session,
    this.hostName,
  });

  final UserActiveSession session;
  final String? hostName;

  @override
  Widget build(BuildContext context) {
    final kind = liveSessionKindFrom(session);
    final palette = _LiveSessionPalette.of(kind);
    final title = session.title?.trim();
    final roomTitle = (title != null && title.isNotEmpty)
        ? title
        : (hostName?.trim().isNotEmpty == true
            ? "${hostName!.trim()}'s Room"
            : 'Live now');
    final viewers = session.viewerCount;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                palette.gradient.first.withValues(alpha: 0.42),
                palette.gradient.last.withValues(alpha: 0.18),
                kColorWhite.withValues(alpha: 0.06),
              ],
            ),
            border: Border.all(
              color: kColorWhite.withValues(alpha: 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: palette.glow.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: palette.gradient),
                  boxShadow: [
                    BoxShadow(
                      color: palette.glow.withValues(alpha: 0.45),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(palette.icon, color: kColorWhite, size: 22),
              ),
              Spacing.h12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SemiBoldText(
                          text: 'ON AIR',
                          fontSize: TextStyles.k10FontSize,
                          color: kColorWhite.withValues(alpha: 0.78),
                        ),
                        Spacing.h6,
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: kColorWhite.withValues(alpha: 0.45),
                          ),
                        ),
                        Spacing.h6,
                        SemiBoldText(
                          text: palette.typeLabel,
                          fontSize: TextStyles.k10FontSize,
                          color: kColorWhite,
                        ),
                      ],
                    ),
                    Spacing.v6,
                    SemiBoldText(
                      text: roomTitle,
                      fontSize: TextStyles.k14FontSize,
                      color: kColorWhite,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacing.v2,
                    AppText(
                      text: viewers > 0
                          ? '$viewers ${viewers == 1 ? 'person' : 'people'} watching'
                          : 'Be the first to join',
                      fontSize: TextStyles.k10FontSize,
                      color: kColorWhite.withValues(alpha: 0.7),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
