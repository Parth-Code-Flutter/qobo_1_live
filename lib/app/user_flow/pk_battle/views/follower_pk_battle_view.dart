import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/pk_battle_controller.dart';
import '../models/follower_pk_battle.dart';

/// Premium UI for the audio-room follower PK contract.
///
/// The existing room-vs-room PK screen remains untouched and is selected by
/// [PKBattleController.isFollowerMode].
class FollowerPkBattleView extends GetView<PKBattleController> {
  const FollowerPkBattleView({super.key});

  static const _pink = Color(0xFFFF3EA5);
  static const _purple = Color(0xFF7B45FF);
  static const _orange = Color(0xFFFF8A2A);
  static const _surface = Color(0xFF1A102C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090512),
      body: Stack(
        children: [
          const Positioned.fill(child: _ArenaBackground()),
          SafeArea(
            child: Column(
              children: [
                _header(),
                Expanded(
                  child: Obx(() {
                    switch (controller.pkState.value) {
                      case PKState.idle:
                        return _startState();
                      case PKState.incomingRequest:
                        return _incomingState();
                      case PKState.outgoingRequest:
                      case PKState.searching:
                        return _waitingState();
                      case PKState.durationPending:
                        return _durationState();
                      case PKState.inBattle:
                        return _activeState();
                      case PKState.completed:
                        return _completedState();
                    }
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Row(
        children: [
          _circleAction(Icons.arrow_back_ios_new_rounded, Get.back),
          Spacing.h10,
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: 'Follower PK',
                  fontSize: TextStyles.k18FontSize,
                  color: kColorWhite,
                ),
                AppText(
                  text: 'Audio room gift battle',
                  fontSize: TextStyles.k10FontSize,
                  color: Colors.white54,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(colors: [_pink, _purple]),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, color: kColorWhite, size: 15),
                SizedBox(width: 4),
                SemiBoldText(
                  text: 'PK',
                  fontSize: TextStyles.k12FontSize,
                  color: kColorWhite,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _startState() {
    return _centerCard(
      icon: Icons.groups_2_rounded,
      title: 'Challenge your followers',
      subtitle:
          'We’ll notify your followers. The first eligible person to accept—or '
          'join from your audio-room PK badge—becomes your opponent.',
      child: Obx(
        () => _primaryButton(
          label: controller.isBusy.value
              ? 'Starting challenge...'
              : 'Notify my followers',
          icon: Icons.notifications_active_rounded,
          onTap: controller.isBusy.value ? null : controller.startFollowerPk,
        ),
      ),
    );
  }

  Widget _waitingState() {
    return _centerCard(
      icon: Icons.radar_rounded,
      title: 'Finding your challenger',
      subtitle: controller.notifiedFollowerCount.value > 0
          ? '${controller.notifiedFollowerCount.value} followers were notified. '
                'Your room PK badge is also live.'
          : 'Followers were notified and your room PK badge is live.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(color: _pink, strokeWidth: 2.5),
          ),
          Spacing.v20,
          _outlineButton(
            label: 'Cancel challenge',
            icon: Icons.close_rounded,
            onTap: controller.cancelFollowerPk,
          ),
        ],
      ),
    );
  }

  Widget _incomingState() {
    return _centerCard(
      avatar: controller.currentOpponentAvatar.value,
      avatarName: controller.currentOpponentName.value,
      title: '${controller.currentOpponentName.value} challenged you',
      subtitle:
          'Accept to become the opponent. The challenger will choose a '
          '5, 10, or 15 minute gift battle.',
      child: Obx(
        () => _primaryButton(
          label: controller.isBusy.value ? 'Joining...' : 'Accept PK challenge',
          icon: Icons.sports_mma_rounded,
          onTap: controller.isBusy.value
              ? null
              : controller.acceptFollowerChallenge,
        ),
      ),
    );
  }

  Widget _durationState() {
    final battle = controller.followerBattle.value;
    if (!controller.isChallenger.value) {
      return _centerCard(
        avatar: battle?.challenger.avatarUrl,
        avatarName: battle?.challenger.name ?? 'Challenger',
        title: 'Opponent locked in',
        subtitle:
            '${battle?.challenger.name ?? 'The challenger'} is choosing the '
            'battle duration. Get ready!',
        child: const SizedBox(
          width: 34,
          height: 34,
          child: CircularProgressIndicator(color: _orange, strokeWidth: 2.5),
        ),
      );
    }

    return _centerCard(
      avatar: battle?.opponent?.avatarUrl,
      avatarName: battle?.opponent?.name ?? 'Opponent',
      title: '${battle?.opponent?.name ?? 'Opponent'} joined!',
      subtitle: 'Choose how long this follower-only gift battle will run.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [300, 600, 900].map((seconds) {
              final minutes = seconds ~/ 60;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Obx(() {
                    final selected =
                        controller.selectedDurationSeconds.value == seconds;
                    return InkWell(
                      onTap: () =>
                          controller.selectedDurationSeconds.value = seconds,
                      borderRadius: BorderRadius.circular(18),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: selected
                              ? const LinearGradient(colors: [_pink, _purple])
                              : null,
                          color: selected ? null : Colors.white10,
                          border: Border.all(
                            color: selected ? _pink : Colors.white12,
                          ),
                        ),
                        child: Column(
                          children: [
                            SemiBoldText(
                              text: '$minutes',
                              fontSize: TextStyles.k18FontSize,
                              color: kColorWhite,
                            ),
                            const AppText(
                              text: 'MIN',
                              fontSize: TextStyles.k10FontSize,
                              color: Colors.white60,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              );
            }).toList(),
          ),
          Spacing.v20,
          Obx(
            () => _primaryButton(
              label: controller.isBusy.value ? 'Starting...' : 'Start battle',
              icon: Icons.bolt_rounded,
              onTap: controller.isBusy.value
                  ? null
                  : () => controller.setFollowerDuration(
                      controller.selectedDurationSeconds.value,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeState() {
    return Obx(() {
      final battle = controller.followerBattle.value;
      if (battle == null) return const SizedBox.shrink();
      final total = controller.myPoints.value + controller.opponentPoints.value;
      final myShare = total <= 0 ? 0.5 : controller.myPoints.value / total;
      // Score events can arrive before the opponent block is populated.
      final rival =
          battle.opponent ??
          const FollowerPkPlayer(userId: '', name: 'Opponent');
      final mySide = controller.isChallenger.value ? battle.challenger : rival;
      final rivalSide = controller.isChallenger.value
          ? rival
          : battle.challenger;
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
        child: Column(
          children: [
            _timerPill(),
            Spacing.v16,
            Row(
              children: [
                Expanded(
                  child: _playerCard(
                    player: mySide,
                    score: controller.myPoints.value,
                    colors: const [Color(0xFF6C63FF), Color(0xFF2ED3FF)],
                    label: 'YOU',
                    leading:
                        controller.myPoints.value >=
                        controller.opponentPoints.value,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [_pink, _orange]),
                    ),
                    child: const BoldText(
                      text: 'VS',
                      fontSize: TextStyles.k14FontSize,
                      color: kColorWhite,
                    ),
                  ),
                ),
                Expanded(
                  child: _playerCard(
                    player: rivalSide,
                    score: controller.opponentPoints.value,
                    colors: const [_pink, _orange],
                    label: 'RIVAL',
                    leading:
                        controller.opponentPoints.value >
                        controller.myPoints.value,
                  ),
                ),
              ],
            ),
            Spacing.v20,
            _scoreBar(myShare),
            Spacing.v20,
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_rounded, color: _orange, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: AppText(
                      text:
                          'Follower-only gifts are active. Each supporter can '
                          'gift only the PK player they follow.',
                      fontSize: TextStyles.k12FontSize,
                      color: Colors.white70,
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

  Widget _completedState() {
    final battle = controller.followerBattle.value;
    final result = battle?.result ?? '';
    final won =
        battle?.winnerUserId == _myPlayer(battle)?.userId ||
        (battle?.winnerUserId == null &&
            controller.myPoints.value > controller.opponentPoints.value);
    final draw =
        result == 'draw' ||
        (controller.myPoints.value == controller.opponentPoints.value);
    return _centerCard(
      icon: draw
          ? Icons.handshake_rounded
          : won
          ? Icons.emoji_events_rounded
          : Icons.shield_moon_rounded,
      title: draw
          ? 'Battle draw'
          : won
          ? 'Victory!'
          : 'Great battle',
      subtitle:
          '${controller.myPoints.value} vs ${controller.opponentPoints.value} coins',
      child: _primaryButton(
        label: 'Back to audio room',
        icon: Icons.keyboard_return_rounded,
        onTap: controller.closeFollowerArena,
      ),
    );
  }

  FollowerPkPlayer? _myPlayer(FollowerPkBattle? battle) {
    if (battle == null) return null;
    return controller.isChallenger.value ? battle.challenger : battle.opponent;
  }

  Widget _timerPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(colors: [_orange, _pink]),
        boxShadow: [
          BoxShadow(color: _pink.withValues(alpha: 0.28), blurRadius: 18),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_rounded, color: kColorWhite, size: 18),
          Spacing.h6,
          BoldText(
            text: controller.formattedTime,
            fontSize: TextStyles.k16FontSize,
            color: kColorWhite,
          ),
        ],
      ),
    );
  }

  Widget _playerCard({
    required FollowerPkPlayer player,
    required int score,
    required List<Color> colors,
    required String label,
    required bool leading,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.first.withValues(alpha: 0.26), _surface],
        ),
        border: Border.all(
          color: leading ? colors.first.withValues(alpha: 0.8) : Colors.white12,
          width: leading ? 1.8 : 1,
        ),
      ),
      child: Column(
        children: [
          if (leading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(colors: colors),
              ),
              child: const AppText(
                text: 'LEADING',
                fontSize: TextStyles.k10FontSize,
                color: kColorWhite,
              ),
            )
          else
            AppText(
              text: label,
              fontSize: TextStyles.k10FontSize,
              color: Colors.white54,
            ),
          Spacing.v10,
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: colors),
            ),
            child: AppUserAvatar(
              name: player.name,
              imageUrl: player.avatarUrl,
              size: 66,
            ),
          ),
          Spacing.v8,
          SemiBoldText(
            text: player.name,
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Spacing.v6,
          BoldText(
            text: '$score',
            fontSize: TextStyles.k18FontSize,
            color: colors.first,
          ),
          const AppText(
            text: 'gift coins',
            fontSize: TextStyles.k10FontSize,
            color: Colors.white54,
          ),
        ],
      ),
    );
  }

  Widget _scoreBar(double myShare) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SemiBoldText(
              text: '${controller.myPoints.value}',
              fontSize: TextStyles.k12FontSize,
              color: const Color(0xFF2ED3FF),
            ),
            SemiBoldText(
              text: '${controller.opponentPoints.value}',
              fontSize: TextStyles.k12FontSize,
              color: _orange,
            ),
          ],
        ),
        Spacing.v6,
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 15,
            child: Row(
              children: [
                Expanded(
                  flex: (myShare * 100).round().clamp(1, 99),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF2ED3FF)],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: ((1 - myShare) * 100).round().clamp(1, 99),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [_pink, _orange]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _centerCard({
    IconData? icon,
    String? avatar,
    String avatarName = 'Player',
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 430),
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _purple.withValues(alpha: 0.30),
                _surface.withValues(alpha: 0.98),
                _pink.withValues(alpha: 0.12),
              ],
            ),
            border: Border.all(color: _pink.withValues(alpha: 0.28)),
            boxShadow: [
              BoxShadow(
                color: _pink.withValues(alpha: 0.18),
                blurRadius: 34,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 82,
                height: 82,
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [_pink, _orange]),
                ),
                child: avatar != null
                    ? AppUserAvatar(
                        name: avatarName,
                        imageUrl: avatar,
                        size: 76,
                      )
                    : Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF24143A),
                        ),
                        child: Icon(
                          icon ?? Icons.bolt_rounded,
                          color: kColorWhite,
                          size: 34,
                        ),
                      ),
              ),
              Spacing.v20,
              SemiBoldText(
                text: title,
                fontSize: TextStyles.k18FontSize,
                color: kColorWhite,
                align: TextAlign.center,
              ),
              Spacing.v8,
              AppText(
                text: subtitle,
                fontSize: TextStyles.k12FontSize,
                color: Colors.white60,
                align: TextAlign.center,
              ),
              Spacing.v24,
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(colors: [_pink, _orange]),
          boxShadow: [
            BoxShadow(
              color: _pink.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: kColorWhite, size: 19),
                Spacing.h8,
                SemiBoldText(
                  text: label,
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _outlineButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white70,
        side: const BorderSide(color: Colors.white24),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  Widget _circleAction(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: Colors.white10),
          ),
          child: Icon(icon, color: kColorWhite, size: 18),
        ),
      ),
    );
  }
}

class _ArenaBackground extends StatelessWidget {
  const _ArenaBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF260B37), Color(0xFF090512), Color(0xFF101540)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 70,
            right: -80,
            child: _blob(const Color(0xFFFF3EA5), 210),
          ),
          Positioned(
            bottom: 80,
            left: -90,
            child: _blob(const Color(0xFF6C63FF), 230),
          ),
        ],
      ),
    );
  }

  static Widget _blob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.13),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 90,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }
}
