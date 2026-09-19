import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/controllers/pk_v1_controller.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/models/v1/pk_v1_models.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/widgets/pk_v1_battle_widgets.dart';
import 'package:qobo_one_live/utils/app_widgets/app_coin_icon.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';

/// In-room PK Battle stage (host + audience).
///
/// Layout: Top Gifters · PK BATTLE · tug-of-war · 50/50 host panes ·
/// per-side Audience under hosts. Chat / bottom dock stay in the parent.
class InRoomPkStageOverlay extends StatelessWidget {
  const InRoomPkStageOverlay({
    super.key,
    required this.controller,
    this.compact = false,
    this.maxHeight,
    this.showEndButton = true,
  });

  final PkV1Controller controller;
  final bool compact;
  final double? maxHeight;
  final bool showEndButton;

  static const red = Color(0xFFFF2D55);
  static const blue = Color(0xFF2F6BFF);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final session = controller.session.value;
      final sideA = session?.sideA ?? PkSideInfo.empty;
      final sideB = session?.sideB ?? PkSideInfo.empty;
      final finished = controller.stage.value == PkArenaStage.finished;
      final isPreview =
          (session?.pkId ?? '').startsWith('ui_preview_');

      Widget body = Column(
        children: [
          _TopGiftersAndLogo(
            compact: compact,
            leftGifters: controller.sideATopContributors.toList(),
            rightGifters: controller.sideBTopContributors.toList(),
            label: 'Top Gifters',
          ),
          SizedBox(height: compact ? 4 : 6),
          _TugOfWarScoreBoard(
            scoreA: controller.scoreA.value,
            scoreB: controller.scoreB.value,
            progressA: controller.sideAProgress,
            leftName: sideA.displayName,
            rightName: sideB.displayName,
            timerText: finished ? 'END' : controller.formattedTime,
            compact: compact,
          ),
          SizedBox(height: compact ? 4 : 6),
          // Host panes flex so Top Gifters + score + Audience always fit
          // inside the parent maxHeight (avoids bottom overflow).
          Expanded(
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _HostVideoPane(
                        side: sideA,
                        accent: red,
                        teamLabel: 'TEAM RED',
                        hostLabel: 'HOST A',
                        alignEnd: false,
                        isSelf: controller.isSelfSideA,
                        compact: compact,
                        diamonds: controller.sideADiamonds.value,
                        coinFlyKey: controller.hostACoinFlyKey,
                        mockCoverAsset: isPreview
                            ? 'assets/images/temp4.png'
                            : null,
                      ),
                    ),
                    Container(
                      width: 1.5,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    Expanded(
                      child: _HostVideoPane(
                        side: sideB,
                        accent: blue,
                        teamLabel: 'TEAM BLUE',
                        hostLabel: 'HOST B',
                        alignEnd: true,
                        isSelf: !controller.isSelfSideA,
                        compact: compact,
                        diamonds: controller.sideBDiamonds.value,
                        coinFlyKey: controller.hostBCoinFlyKey,
                        mockCoverAsset: isPreview
                            ? 'assets/images/temp2.png'
                            : null,
                      ),
                    ),
                  ],
                ),
                if (showEndButton && !finished && controller.isSelfHost)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _EndPkButton(
                      compact: compact,
                      onTap: controller.confirmEndEmbeddedBattle,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: compact ? 6 : 8),
          _SideAudienceRow(
            compact: compact,
            leftAudience: controller.sideAAudience.toList(),
            rightAudience: controller.sideBAudience.toList(),
          ),
          Obx(() {
            final gift = controller.lastGift.value;
            if (gift == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
              child: _PkIncomingGiftBanner(gift: gift),
            );
          }),
        ],
      );

      // Always bound height so Expanded host panes can shrink to fit.
      final height = maxHeight ??
          (MediaQuery.sizeOf(context).height * (compact ? 0.56 : 0.64))
              .clamp(340.0, 600.0);
      body = SizedBox(height: height, width: double.infinity, child: body);

      return body;
    });
  }
}

// ---------------------------------------------------------------------------
// Top: gifters + PK BATTLE logo
// ---------------------------------------------------------------------------

class _TopGiftersAndLogo extends StatelessWidget {
  const _TopGiftersAndLogo({
    required this.compact,
    required this.leftGifters,
    required this.rightGifters,
    this.label = 'Top Gifters',
  });

  final bool compact;
  final List<PkAudienceMember> leftGifters;
  final List<PkAudienceMember> rightGifters;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _GifterCluster(
            members: leftGifters,
            accent: InRoomPkStageOverlay.red,
            alignEnd: false,
            compact: compact,
            label: label,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: compact ? 2 : 4, left: 6, right: 6),
          child: const _PkBattleLogo(),
        ),
        Expanded(
          child: _GifterCluster(
            members: rightGifters,
            accent: InRoomPkStageOverlay.blue,
            alignEnd: true,
            compact: compact,
            label: label,
          ),
        ),
      ],
    );
  }
}

/// Room audience under each host pane (sideA left / sideB right).
class _SideAudienceRow extends StatelessWidget {
  const _SideAudienceRow({
    required this.compact,
    required this.leftAudience,
    required this.rightAudience,
  });

  final bool compact;
  final List<PkAudienceMember> leftAudience;
  final List<PkAudienceMember> rightAudience;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _GifterCluster(
              members: leftAudience,
              accent: InRoomPkStageOverlay.red,
              alignEnd: false,
              compact: compact,
              label: 'Audience',
              avatarSize: compact ? 46 : 50,
            ),
          ),
          SizedBox(width: compact ? 12 : 20),
          Expanded(
            child: _GifterCluster(
              members: rightAudience,
              accent: InRoomPkStageOverlay.blue,
              alignEnd: true,
              compact: compact,
              label: 'Audience',
              avatarSize: compact ? 46 : 50,
            ),
          ),
        ],
      ),
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
              fontStyle: FontStyle.italic,
              letterSpacing: 0.5,
              height: 1,
            ),
          ),
        ),
        Text(
          'BATTLE',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.8,
            color: Colors.white.withValues(alpha: 0.95),
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

class _GifterCluster extends StatelessWidget {
  const _GifterCluster({
    required this.members,
    required this.accent,
    required this.alignEnd,
    required this.compact,
    this.label = 'Top Gifters',
    this.avatarSize,
  });

  final List<PkAudienceMember> members;
  final Color accent;
  final bool alignEnd;
  final bool compact;
  final String label;
  final double? avatarSize;

  @override
  Widget build(BuildContext context) {
    final visible = members.take(3).toList();
    final size = avatarSize ?? (compact ? 26.0 : 30.0);
    // Overlap without negative SizedBox widths (those crash layout).
    final overlap = size * 0.32;

    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText(
          text: label,
          fontSize: 9,
          color: Colors.white70,
        ),
        const SizedBox(height: 5),
        if (visible.isEmpty)
          const AppText(text: '—', fontSize: 10, color: Colors.white38)
        else
          SizedBox(
            height: size + 12,
            width: size + (visible.length - 1) * (size - overlap) + 6,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < visible.length; i++)
                  Positioned(
                    left: alignEnd
                        ? null
                        : i * (size - overlap),
                    right: alignEnd
                        ? i * (size - overlap)
                        : null,
                    child: _RankedAvatar(
                      member: visible[i],
                      rank: i + 1,
                      accent: accent,
                      size: size,
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
        AppUserAvatar(
          name: member.displayName,
          imageUrl: member.avatarUrl,
          frameUrl: member.frameUrl.isEmpty ? null : member.frameUrl,
          frameSeed: member.userId.isNotEmpty
              ? member.userId
              : member.displayName,
          size: size,
          showFrame: true,
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 13,
            height: 13,
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
                fontSize: 7.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tug-of-war score bar + timer / VS
// ---------------------------------------------------------------------------

class _TugOfWarScoreBoard extends StatelessWidget {
  const _TugOfWarScoreBoard({
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

  @override
  Widget build(BuildContext context) {
    final clamped = progressA.clamp(0.12, 0.88);
    final barH = compact ? 22.0 : 26.0;
    final stackH = compact ? 54.0 : 60.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: stackH,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  height: barH,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(barH / 2),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final total = constraints.maxWidth;
                        final leftW = (total * clamped).clamp(24.0, total - 24);
                        final rightW = total - leftW;
                        return Row(
                          children: [
                            Container(
                              width: leftW,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 12),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFFF1744),
                                    Color(0xFFFF5C8A),
                                  ],
                                ),
                              ),
                              child: Text(
                                _compactScore(scoreA),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: compact ? 11 : 13,
                                ),
                              ),
                            ),
                            Container(
                              width: rightW,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 12),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF5B8CFF),
                                    Color(0xFF1E5BFF),
                                  ],
                                ),
                              ),
                              child: Text(
                                _compactScore(scoreB),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: compact ? 11 : 13,
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
                      vertical: compact ? 3 : 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: const Color(0xFF0C0C14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              InRoomPkStageOverlay.red.withValues(alpha: 0.55),
                          blurRadius: 14,
                          offset: const Offset(-5, 0),
                        ),
                        BoxShadow(
                          color:
                              InRoomPkStageOverlay.blue.withValues(alpha: 0.55),
                          blurRadius: 14,
                          offset: const Offset(5, 0),
                        ),
                      ],
                    ),
                    child: Text(
                      timerText,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: compact ? 12 : 14,
                        letterSpacing: 0.8,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    width: compact ? 22 : 24,
                    height: compact ? 22 : 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF2D55), Color(0xFF2F6BFF)],
                      ),
                      border: Border.all(color: Colors.white, width: 1.6),
                    ),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: compact ? 8 : 9,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: AppText(
                text: _handle(leftName),
                fontSize: 11,
                color: Colors.white70,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: AppText(
                text: _handle(rightName),
                fontSize: 11,
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

// ---------------------------------------------------------------------------
// Host panes — full-bleed video / mock cover (matches reference)
// ---------------------------------------------------------------------------

class _HostVideoPane extends StatelessWidget {
  const _HostVideoPane({
    required this.side,
    required this.accent,
    required this.teamLabel,
    required this.hostLabel,
    required this.alignEnd,
    required this.isSelf,
    required this.compact,
    this.diamonds = 0,
    this.coinFlyKey,
    this.mockCoverAsset,
  });

  final PkSideInfo side;
  final Color accent;
  final String teamLabel;
  final String hostLabel;
  final bool alignEnd;
  final bool isSelf;
  final bool compact;
  /// PK session earnings for this host (`earnings` from side / score events).
  final int diamonds;
  final GlobalKey? coinFlyKey;
  final String? mockCoverAsset;

  @override
  Widget build(BuildContext context) {
    final name = side.displayName.isEmpty
        ? (isSelf ? 'You' : 'Host')
        : side.displayName;

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Edge-to-edge host visual (ref: live video fill, not framed avatar).
          if (mockCoverAsset != null)
            Image.asset(
              mockCoverAsset!,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            )
          else
            PkHostLiveVideoFill(
              userId: side.hostId,
              name: name,
              imageUrl: side.avatarUrl,
              preferLocalUser: isSelf,
            ),
          // Soft team tint at the outer edge.
          Align(
            alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    accent.withValues(alpha: 0.0),
                    accent.withValues(alpha: 0.85),
                    accent.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // Bottom readable gradient for team + host card.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.05),
                  Colors.black.withValues(alpha: 0.72),
                ],
                stops: const [0.45, 0.68, 1],
              ),
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Column(
              crossAxisAlignment: alignEnd
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  teamLabel,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    fontSize: compact ? 11 : 12,
                    letterSpacing: 1.1,
                    shadows: const [
                      Shadow(color: Colors.black87, blurRadius: 6),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                _HostInfoCard(
                  name: name,
                  hostLabel: hostLabel,
                  avatarUrl: side.avatarUrl,
                  frameUrl: side.frameUrl,
                  frameSeed: side.hostId,
                  accent: accent,
                  fans: side.followerCount,
                  earnings: diamonds > 0
                      ? diamonds
                      : (side.earnings > 0 ? side.earnings : side.diamonds),
                  compact: compact,
                  alignEnd: alignEnd,
                  coinFlyKey: coinFlyKey,
                ),
              ],
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
    this.earnings = 0,
    this.frameUrl = '',
    this.frameSeed = '',
    this.coinFlyKey,
  });

  final String name;
  final String hostLabel;
  final String avatarUrl;
  final String frameUrl;
  final String frameSeed;
  final Color accent;
  final int fans;
  final int earnings;
  final bool compact;
  final bool alignEnd;
  final GlobalKey? coinFlyKey;

  @override
  Widget build(BuildContext context) {
    final avatarSize = compact ? 34.0 : 40.0;
    final avatar = Container(
      key: coinFlyKey,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.55),
            blurRadius: 12,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: AppUserAvatar(
        name: name,
        imageUrl: avatarUrl,
        frameUrl: frameUrl.isEmpty ? null : frameUrl,
        frameSeed: frameSeed.isNotEmpty ? frameSeed : name,
        size: avatarSize,
        showFrame: true,
      ),
    );

    final text = Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          hostLabel,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 10,
            letterSpacing: 0.4,
          ),
        ),
        Text(
          _handle(name),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.95),
            fontWeight: FontWeight.w700,
            fontSize: compact ? 11 : 12,
          ),
        ),
        if (earnings > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppCoinIcon(size: 11),
              const SizedBox(width: 3),
              Text(
                _compactScore(earnings),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          )
        else
          Text(
            fans > 0 ? '${_compactScore(fans)} Fans' : 'Live now',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 9,
            ),
          ),
      ],
    );

    return Container(
      constraints: const BoxConstraints(maxWidth: 168),
      padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.black.withValues(alpha: 0.48),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: alignEnd
            ? [
                Flexible(child: text),
                const SizedBox(width: 8),
                avatar,
              ]
            : [
                avatar,
                const SizedBox(width: 8),
                Flexible(child: text),
              ],
      ),
    );
  }
}

class _EndPkButton extends StatelessWidget {
  const _EndPkButton({required this.onTap, required this.compact});

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
              Text(
                'End PK',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 10 : 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PkIncomingGiftBanner extends StatelessWidget {
  const _PkIncomingGiftBanner({required this.gift});

  final PkGiftEvent gift;

  @override
  Widget build(BuildContext context) {
    final sideColor = gift.targetSide == PkBattleSide.b
        ? InRoomPkStageOverlay.blue
        : InRoomPkStageOverlay.red;
    final sideLabel =
        gift.targetSide == PkBattleSide.b ? 'Team Blue' : 'Team Red';
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.black.withValues(alpha: 0.72),
          border: Border.all(color: sideColor.withValues(alpha: 0.75)),
          boxShadow: [
            BoxShadow(
              color: sideColor.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppUserAvatar(
              name: gift.senderName.isEmpty ? 'Viewer' : gift.senderName,
              imageUrl: gift.senderAvatar,
              frameSeed: gift.senderId.isNotEmpty
                  ? gift.senderId
                  : gift.senderName,
              size: 28,
              showFrame: true,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    gift.senderName.isEmpty ? 'Viewer' : gift.senderName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'sent ${gift.giftName.isEmpty ? 'a gift' : gift.giftName}'
                    '${gift.quantity > 1 ? ' x${gift.quantity}' : ''}'
                    ' → $sideLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (gift.iconUrl.isNotEmpty) ...[
              const SizedBox(width: 8),
              Image.network(
                gift.iconUrl,
                width: 28,
                height: 28,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.card_giftcard_rounded,
                  color: sideColor,
                  size: 22,
                ),
              ),
            ],
          ],
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
