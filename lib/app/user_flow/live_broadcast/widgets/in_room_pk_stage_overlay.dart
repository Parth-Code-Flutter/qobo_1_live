import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/controllers/pk_v1_controller.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/models/v1/pk_v1_models.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/widgets/pk_v1_battle_widgets.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';

/// In-room PK Battle stage for host + audience (live stream and party rooms).
///
/// Matches the product reference: PK logo · top gifters · tug-of-war score bar
/// with center timer/VS · 50/50 host video panes with team + host cards.
/// Chat / gift dock stay in the parent live room overlay below this stage.
class InRoomPkStageOverlay extends StatelessWidget {
  const InRoomPkStageOverlay({
    super.key,
    required this.controller,
    this.compact = false,
    this.maxHeight,
  });

  final PkV1Controller controller;
  final bool compact;
  final double? maxHeight;

  static const _red = Color(0xFFFF2D55);
  static const _blue = Color(0xFF2F6BFF);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final session = controller.session.value;
      final sideA = session?.sideA ?? PkSideInfo.empty;
      final sideB = session?.sideB ?? PkSideInfo.empty;
      final finished = controller.stage.value == PkArenaStage.finished;

      return SizedBox(
        height: maxHeight,
        width: double.infinity,
        child: Column(
          children: [
            _PkBattleTitleRow(
              compact: compact,
              leftGifters: controller.sideAAudience.toList(),
              rightGifters: controller.sideBAudience.toList(),
              leftAccent: _red,
              rightAccent: _blue,
            ),
            SizedBox(height: compact ? 6 : 8),
            _PkTugOfWarBar(
              scoreA: controller.scoreA.value,
              scoreB: controller.scoreB.value,
              progressA: controller.sideAProgress,
              leftName: sideA.displayName,
              rightName: sideB.displayName,
              timerText: finished ? 'END' : controller.formattedTime,
              compact: compact,
            ),
            SizedBox(height: compact ? 6 : 8),
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _HostVideoPane(
                          side: sideA,
                          accent: _red,
                          teamLabel: 'TEAM RED',
                          hostLabel: 'HOST A',
                          alignEnd: false,
                          isSelf: controller.isSelfSideA,
                          compact: compact,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: _HostVideoPane(
                          side: sideB,
                          accent: _blue,
                          teamLabel: 'TEAM BLUE',
                          hostLabel: 'HOST B',
                          alignEnd: true,
                          isSelf: !controller.isSelfSideA,
                          compact: compact,
                        ),
                      ),
                    ],
                  ),
                  if (!finished && controller.isSelfHost)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: _EndPkButton(
                        compact: compact,
                        onTap: controller.confirmEndEmbeddedBattle,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _PkBattleTitleRow extends StatelessWidget {
  const _PkBattleTitleRow({
    required this.compact,
    required this.leftGifters,
    required this.rightGifters,
    required this.leftAccent,
    required this.rightAccent,
  });

  final bool compact;
  final List<PkAudienceMember> leftGifters;
  final List<PkAudienceMember> rightGifters;
  final Color leftAccent;
  final Color rightAccent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _TopGiftersCluster(
            members: leftGifters,
            accent: leftAccent,
            alignEnd: false,
            compact: compact,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 8),
          child: const _PkBattleLogo(),
        ),
        Expanded(
          child: _TopGiftersCluster(
            members: rightGifters,
            accent: rightAccent,
            alignEnd: true,
            compact: compact,
          ),
        ),
      ],
    );
  }
}

class _PkBattleLogo extends StatelessWidget {
  const _PkBattleLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFF2D55), Color(0xFF2F6BFF)],
          ).createShader(bounds),
          child: const Text(
            'PK',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              height: 1,
            ),
          ),
        ),
        Text(
          'BATTLE',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.4,
            color: Colors.white.withValues(alpha: 0.92),
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

class _TopGiftersCluster extends StatelessWidget {
  const _TopGiftersCluster({
    required this.members,
    required this.accent,
    required this.alignEnd,
    required this.compact,
  });

  final List<PkAudienceMember> members;
  final Color accent;
  final bool alignEnd;
  final bool compact;

  static const _max = 3;

  @override
  Widget build(BuildContext context) {
    final visible = members.take(_max).toList();
    final avatarSize = compact ? 22.0 : 26.0;

    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        AppText(
          text: 'Top Gifters',
          fontSize: 9,
          color: Colors.white70,
        ),
        const SizedBox(height: 4),
        if (visible.isEmpty)
          AppText(
            text: '—',
            fontSize: 10,
            color: Colors.white38,
          )
        else
          SizedBox(
            height: avatarSize + 4,
            width: avatarSize + (visible.length - 1) * (avatarSize * 0.62),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < visible.length; i++)
                  Positioned(
                    left: alignEnd ? null : i * (avatarSize * 0.62),
                    right: alignEnd ? i * (avatarSize * 0.62) : null,
                    child: _RankedAvatar(
                      member: visible[i],
                      rank: i + 1,
                      accent: accent,
                      size: avatarSize,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RankedAvatar extends StatelessWidget {
  const _RankedAvatar({
    required this.member,
    required this.rank,
    required this.accent,
    required this.size,
  });

  final PkAudienceMember member;
  final int rank;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: accent, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.45),
                blurRadius: 8,
              ),
            ],
          ),
          child: AppUserAvatar(
            name: member.displayName,
            imageUrl: member.avatarUrl,
            size: size - 3,
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 12,
            height: 12,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent,
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 7,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PkTugOfWarBar extends StatelessWidget {
  const _PkTugOfWarBar({
    required this.scoreA,
    required this.scoreB,
    required this.progressA,
    required this.leftName,
    required this.rightName,
    required this.timerText,
    required this.compact,
  });

  final int scoreA;
  final int scoreB;
  final double progressA;
  final String leftName;
  final String rightName;
  final String timerText;
  final bool compact;

  static const _red = Color(0xFFFF2D55);
  static const _blue = Color(0xFF2F6BFF);

  @override
  Widget build(BuildContext context) {
    final clamped = progressA.clamp(0.08, 0.92);
    final barH = compact ? 22.0 : 26.0;

    return Column(
      children: [
        SizedBox(
          height: barH + 28,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(barH / 2),
                  child: SizedBox(
                    height: barH,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.5, end: clamped),
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return Row(
                          children: [
                            Expanded(
                              flex: (value * 1000).round().clamp(1, 999),
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFFF1744),
                                      Color(0xFFFF5C8A),
                                    ],
                                  ),
                                ),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 10),
                                child: BoldText(
                                  text: _compactScore(scoreA),
                                  fontSize: compact ? 11 : 12,
                                  color: kColorWhite,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: ((1 - value) * 1000).round().clamp(1, 999),
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF5B8CFF),
                                      Color(0xFF1E5BFF),
                                    ],
                                  ),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 10),
                                child: BoldText(
                                  text: _compactScore(scoreB),
                                  fontSize: compact ? 11 : 12,
                                  color: kColorWhite,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 10 : 12,
                      vertical: compact ? 4 : 5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: const Color(0xFF12121A),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _red.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(-3, 0),
                        ),
                        BoxShadow(
                          color: _blue.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(3, 0),
                        ),
                      ],
                    ),
                    child: BoldText(
                      text: timerText,
                      fontSize: compact ? 12 : 13,
                      color: kColorWhite,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: compact ? 22 : 26,
                    height: compact ? 22 : 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF2D55), Color(0xFF2F6BFF)],
                      ),
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.35),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: BoldText(
                      text: 'VS',
                      fontSize: compact ? 8 : 9,
                      color: kColorWhite,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: AppText(
                text: _handle(leftName),
                fontSize: 10,
                color: Colors.white70,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: AppText(
                text: _handle(rightName),
                fontSize: 10,
                color: Colors.white70,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                align: TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HostVideoPane extends StatelessWidget {
  const _HostVideoPane({
    required this.side,
    required this.accent,
    required this.teamLabel,
    required this.hostLabel,
    required this.alignEnd,
    required this.isSelf,
    required this.compact,
  });

  final PkSideInfo side;
  final Color accent;
  final String teamLabel;
  final String hostLabel;
  final bool alignEnd;
  final bool isSelf;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final name = side.displayName.isEmpty
        ? (isSelf ? 'You' : 'Host')
        : side.displayName;
    final fans = side.followerCount;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.65), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.22),
            blurRadius: 14,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PkHostLiveVideoFill(
            userId: side.hostId,
            name: name,
            imageUrl: side.avatarUrl,
            preferLocalUser: isSelf,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.72),
                ],
                stops: const [0.35, 0.62, 1],
              ),
            ),
          ),
          Positioned(
            left: alignEnd ? null : 8,
            right: alignEnd ? 8 : null,
            bottom: compact ? 44 : 52,
            child: SemiBoldText(
              text: teamLabel,
              fontSize: compact ? 9 : 10,
              color: accent,
            ),
          ),
          Positioned(
            left: 6,
            right: 6,
            bottom: 6,
            child: Align(
              alignment:
                  alignEnd ? Alignment.centerRight : Alignment.centerLeft,
              child: _HostInfoCard(
                name: name,
                hostLabel: hostLabel,
                avatarUrl: side.avatarUrl,
                accent: accent,
                fans: fans,
                compact: compact,
                alignEnd: alignEnd,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HostInfoCard extends StatelessWidget {
  const _HostInfoCard({
    required this.name,
    required this.hostLabel,
    required this.avatarUrl,
    required this.accent,
    required this.fans,
    required this.compact,
    required this.alignEnd,
  });

  final String name;
  final String hostLabel;
  final String avatarUrl;
  final Color accent;
  final int fans;
  final bool compact;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accent, width: 1.6),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: 0.55), blurRadius: 8),
        ],
      ),
      child: AppUserAvatar(
        name: name,
        imageUrl: avatarUrl,
        size: compact ? 26 : 30,
      ),
    );

    final textBlock = Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        BoldText(
          text: hostLabel,
          fontSize: 9,
          color: accent,
        ),
        SemiBoldText(
          text: _handle(name),
          fontSize: compact ? 10 : 11,
          color: kColorWhite,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        AppText(
          text: fans > 0 ? '${_compactScore(fans)} Fans' : 'Live now',
          fontSize: 9,
          color: Colors.white70,
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withValues(alpha: 0.42),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: alignEnd
            ? [Flexible(child: textBlock), const SizedBox(width: 6), avatar]
            : [avatar, const SizedBox(width: 6), Flexible(child: textBlock)],
      ),
    );
  }
}

class _EndPkButton extends StatelessWidget {
  const _EndPkButton({
    required this.onTap,
    required this.compact,
  });

  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 5 : 6,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFFFF5C7A), Color(0xFFE53935)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE53935).withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: compact ? 13 : 14,
              ),
              const SizedBox(width: 4),
              BoldText(
                text: 'End PK',
                fontSize: compact ? 10 : 11,
                color: kColorWhite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _handle(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '@Host';
  if (trimmed.startsWith('@')) return trimmed;
  return '@$trimmed';
}

String _compactScore(int value) {
  final n = value.abs();
  if (n >= 1000000) {
    final v = n / 1000000;
    final s = v >= 10 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    return '${s.replaceAll(RegExp(r'\.0$'), '')}M';
  }
  if (n >= 1000) {
    final v = n / 1000;
    final s = v >= 10 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    return '${s.replaceAll(RegExp(r'\.0$'), '')}K';
  }
  return '$n';
}
