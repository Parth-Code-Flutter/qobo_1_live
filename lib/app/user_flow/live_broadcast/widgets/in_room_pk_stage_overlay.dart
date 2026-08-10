import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/controllers/pk_v1_controller.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/models/v1/pk_v1_models.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/widgets/pk_v1_battle_widgets.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// In-room PK Battle stage matching the live PK reference:
/// split hosts · center PK timer badge · pink/blue score bar · top-3 slots.
///
/// Dropped into the live room where the seat grid normally sits so chat +
/// audience + gift dock stay below.
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

  static const _pink = Color(0xFFFF2D87);
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
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _HostPane(
                          side: sideA,
                          accent: _pink,
                          alignEnd: false,
                          score: controller.scoreA.value,
                          isSelf: controller.isSelfSideA,
                        ),
                      ),
                      Expanded(
                        child: _HostPane(
                          side: sideB,
                          accent: _blue,
                          alignEnd: true,
                          score: controller.scoreB.value,
                          isSelf: !controller.isSelfSideA,
                        ),
                      ),
                    ],
                  ),
                  // Center PK timer badge over the split seam.
                  Positioned(
                    top: compact ? 6 : 10,
                    left: 0,
                    right: 0,
                    child: Center(child: _PkBadge(time: controller.formattedTime)),
                  ),
                  if (finished)
                    Positioned.fill(
                      child: _ResultBanner(controller: controller),
                    ),
                ],
              ),
            ),
            SizedBox(height: compact ? 6 : 8),
            PkScoreBar(
              scoreA: controller.scoreA.value,
              scoreB: controller.scoreB.value,
              progressA: controller.sideAProgress,
              leftColor: _pink,
              rightColor: _blue,
            ),
            SizedBox(height: compact ? 6 : 8),
            _SideAudienceRow(
              leftMembers: controller.sideAAudience.toList(),
              rightMembers: controller.sideBAudience.toList(),
              leftAccent: _pink,
              rightAccent: _blue,
              compact: compact,
            ),
            // Viewers gift during PK; hosts cannot send gifts until battle ends.
            if (!finished && !controller.isSelfHost) ...[
              SizedBox(height: compact ? 6 : 8),
              _GiftCta(
                onTap: () {
                  Get.bottomSheet(
                    PkGiftPickerSheet(
                      controller: controller,
                      sideA: sideA,
                      sideB: sideB,
                    ),
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                  );
                },
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _PkBadge extends StatelessWidget {
  const _PkBadge({required this.time});

  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC857), Color(0xFFFF3B5C)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFC857).withValues(alpha: 0.45),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flash_on_rounded, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          BoldText(text: 'PK', fontSize: 11, color: kColorWhite),
          const SizedBox(width: 6),
          BoldText(text: time, fontSize: TextStyles.k12FontSize, color: kColorWhite),
        ],
      ),
    );
  }
}

class _HostPane extends StatelessWidget {
  const _HostPane({
    required this.side,
    required this.accent,
    required this.alignEnd,
    required this.score,
    required this.isSelf,
  });

  final PkSideInfo side;
  final Color accent;
  final bool alignEnd;
  final int score;
  final bool isSelf;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        left: alignEnd ? 2 : 0,
        right: alignEnd ? 0 : 2,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: 0.32),
            Colors.black.withValues(alpha: 0.55),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.55)),
      ),
      child: Stack(
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accent, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: AppUserAvatar(
                name: side.displayName.isEmpty ? 'Host' : side.displayName,
                imageUrl: side.avatarUrl,
                size: 72,
              ),
            ),
          ),
          // Corner score chip (star + points) like the reference.
          Positioned(
            left: alignEnd ? null : 6,
            right: alignEnd ? 6 : null,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: accent.withValues(alpha: 0.92),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: Colors.white, size: 13),
                  const SizedBox(width: 3),
                  BoldText(
                    text: '$score',
                    fontSize: TextStyles.k12FontSize,
                    color: kColorWhite,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 6,
            right: 6,
            top: 8,
            child: Align(
              alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.black.withValues(alpha: 0.45),
                ),
                child: SemiBoldText(
                  text: side.displayName.isEmpty
                      ? (isSelf ? 'You' : 'Host')
                      : side.displayName,
                  fontSize: 10,
                  color: kColorWhite,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideAudienceRow extends StatelessWidget {
  const _SideAudienceRow({
    required this.leftMembers,
    required this.rightMembers,
    required this.leftAccent,
    required this.rightAccent,
    required this.compact,
  });

  final List<PkAudienceMember> leftMembers;
  final List<PkAudienceMember> rightMembers;
  final Color leftAccent;
  final Color rightAccent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 28.0 : 32.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _AudienceCluster(
            members: leftMembers,
            accent: leftAccent,
            size: size,
            alignEnd: false,
          ),
        ),
        Expanded(
          child: _AudienceCluster(
            members: rightMembers,
            accent: rightAccent,
            size: size,
            alignEnd: true,
          ),
        ),
      ],
    );
  }
}

class _AudienceCluster extends StatelessWidget {
  const _AudienceCluster({
    required this.members,
    required this.accent,
    required this.size,
    required this.alignEnd,
  });

  final List<PkAudienceMember> members;
  final Color accent;
  final double size;
  final bool alignEnd;

  static const _maxVisible = 5;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: AppText(
          text: 'No audience yet',
          fontSize: 10,
          color: Colors.white38,
        ),
      );
    }

    final visible = members.take(_maxVisible).toList();
    final overflow = members.length - visible.length;

    return Align(
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      child: Wrap(
        alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
        spacing: 6,
        runSpacing: 4,
        children: [
          for (var i = 0; i < visible.length; i++)
            _AudienceAvatar(
              member: visible[i],
              rank: i + 1,
              accent: accent,
              size: size,
            ),
          if (overflow > 0)
            Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.4),
                border: Border.all(color: accent.withValues(alpha: 0.7)),
              ),
              child: BoldText(
                text: '+$overflow',
                fontSize: 9,
                color: kColorWhite,
              ),
            ),
        ],
      ),
    );
  }
}

class _AudienceAvatar extends StatelessWidget {
  const _AudienceAvatar({
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
            border: Border.all(color: accent.withValues(alpha: 0.85)),
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
            width: 14,
            height: 14,
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
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GiftCta extends StatelessWidget {
  const _GiftCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFC857), Color(0xFFFF2D87)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF2D87).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            BoldText(text: 'Send Gift', fontSize: 14, color: kColorWhite),
          ],
        ),
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.controller});

  final PkV1Controller controller;

  @override
  Widget build(BuildContext context) {
    final result = controller.result.value;
    final side = result?.winnerSide ?? PkBattleSide.none;
    final title = side == PkBattleSide.tie
        ? "IT'S A TIE!"
        : side == PkBattleSide.none
            ? 'PK ENDED'
            : 'WINNER · SIDE ${pkSideToApi(side)}';
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFC857), size: 42),
          const SizedBox(height: 8),
          BoldText(text: title, fontSize: 18, color: const Color(0xFFFFC857)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              if (Get.isRegistered<PkV1Controller>()) {
                controller.clearEmbeddedBattle();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withValues(alpha: 0.14),
                border: Border.all(color: Colors.white24),
              ),
              child: const AppText(
                text: 'Back to room',
                color: kColorWhite,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
