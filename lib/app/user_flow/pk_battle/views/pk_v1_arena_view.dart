import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/controllers/pk_v1_controller.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/models/v1/pk_v1_models.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/widgets/pk_v1_battle_widgets.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Single-screen state machine for the host-vs-host PK Battle v1 flow.
class PkV1ArenaView extends GetView<PkV1Controller> {
  const PkV1ArenaView({super.key});

  static const pkGold = Color(0xFFFFC857);
  static const pkRed = Color(0xFFFF3B5C);
  static const pkBlue = Color(0xFF3AA0FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF150421),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A0737), Color(0xFF150421)],
          ),
        ),
        child: SafeArea(
          child: Obx(() {
            switch (controller.stage.value) {
              case PkArenaStage.selecting:
                return _selectionView();
              case PkArenaStage.waiting:
                return _waitingView();
              case PkArenaStage.starting:
                return _startingView();
              case PkArenaStage.battling:
              case PkArenaStage.finished:
                // Battle UI renders inside the live room overlay.
                if (controller.embeddedInLiveRoom.value) {
                  return _returningToRoomView();
                }
                return controller.stage.value == PkArenaStage.finished
                    ? _resultView()
                    : _battleView();
            }
          }),
        ),
      ),
    );
  }

  // ======================================================================
  // Host selection
  // ======================================================================

  Widget _selectionView() {
    return Column(
      children: [
        _topBar('Invite Live Host'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: AppText(
            text: 'Hosts currently in audio or video rooms',
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite.withValues(alpha: 0.55),
            align: TextAlign.center,
          ),
        ),
        _searchField(),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value && controller.eligibleHosts.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: pkGold),
              );
            }
            final hosts = controller.eligibleHosts;
            if (hosts.isEmpty) {
              return _emptyState(
                icon: Icons.podcasts_rounded,
                title: 'No live hosts available',
                subtitle:
                    'Ask another host to go live, then pull to refresh.',
              );
            }
            return RefreshIndicator(
              color: pkGold,
              onRefresh: controller.loadEligibleHosts,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: hosts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _hostCard(hosts[i]),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _hostCard(PkEligibleHost host) {
    final enabled = host.canReceivePk;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.06),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [pkGold, pkRed]),
            ),
            child: AppUserAvatar(
              name: host.displayName,
              imageUrl: host.avatarUrl,
              size: 52,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: host.displayName,
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.remove_red_eye_rounded,
                        color: pkGold, size: 14),
                    const SizedBox(width: 4),
                    AppText(
                      text: '${host.viewerCount}',
                      fontSize: TextStyles.k12FontSize,
                      color: kColorWhite.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 10),
                    _livePill(),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: enabled ? () => controller.invite(host) : null,
            child: Opacity(
              opacity: enabled ? 1 : 0.5,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(colors: [pkGold, pkRed]),
                ),
                child: BoldText(
                  text: enabled ? 'Invite' : 'Busy',
                  fontSize: TextStyles.k12FontSize,
                  color: kColorWhite,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================================
  // Waiting (outgoing invite)
  // ======================================================================

  Widget _waitingView() {
    return Obx(() {
      final inv = controller.outgoingInvitation.value;
      return Column(
        children: [
          _topBar('Waiting for Opponent'),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: pkGold.withValues(alpha: 0.6), width: 2),
            ),
            child: AppUserAvatar(
              name: inv?.toUserName ?? 'Host',
              imageUrl: inv?.toUserAvatar,
              size: 96,
            ),
          ),
          const SizedBox(height: 16),
          SemiBoldText(
            text: inv?.toUserName ?? 'Host',
            fontSize: TextStyles.k18FontSize,
            color: kColorWhite,
          ),
          const SizedBox(height: 8),
          const _PulsingDots(),
          const SizedBox(height: 8),
          AppText(
            text: 'Waiting for them to accept…',
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite.withValues(alpha: 0.7),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: appButton(
              onPressed: controller.cancelOutgoing,
              buttonText: 'Cancel',
              isGradient: false,
              buttonColor: Colors.white.withValues(alpha: 0.10),
              buttonBorderColor: Colors.white.withValues(alpha: 0.18),
              borderRadius: 14,
            ),
          ),
        ],
      );
    });
  }

  Widget _startingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Center(child: CircularProgressIndicator(color: pkGold)),
        SizedBox(height: 16),
        Center(
          child: AppText(text: 'Starting battle…', color: Colors.white70),
        ),
      ],
    );
  }

  Widget _returningToRoomView() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(child: CircularProgressIndicator(color: pkGold)),
        SizedBox(height: 16),
        Center(
          child: AppText(
            text: 'Opening PK Battle in your room…',
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  // ======================================================================
  // Battle
  // ======================================================================

  Widget _battleView() {
    return Obx(() {
      final s = controller.session.value;
      final a = s?.sideA ?? PkSideInfo.empty;
      final b = s?.sideB ?? PkSideInfo.empty;
      return Column(
        children: [
          _battleHeader(),
          // Split video area (avatar tiles until streams are co-located).
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: PkHostVideoTile(
                    name: a.displayName,
                    avatarUrl: a.avatarUrl,
                    accent: pkRed,
                    alignEnd: false,
                  ),
                ),
                Expanded(
                  child: PkHostVideoTile(
                    name: b.displayName,
                    avatarUrl: b.avatarUrl,
                    accent: pkBlue,
                    alignEnd: true,
                  ),
                ),
              ],
            ),
          ),
          _battleFooter(a, b),
        ],
      );
    });
  }

  Widget _battleHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        children: [
          Row(
            children: [
              _iconButton(Icons.close_rounded, () => _confirmLeave()),
              const Spacer(),
              Obx(() => PkTimerPill(text: controller.formattedTime)),
              const Spacer(),
              _iconButton(Icons.flag_outlined, _openReport),
            ],
          ),
          const SizedBox(height: 8),
          Obx(
            () => PkScoreBar(
              scoreA: controller.scoreA.value,
              scoreB: controller.scoreB.value,
              progressA: controller.sideAProgress,
              leftColor: pkRed,
              rightColor: pkBlue,
            ),
          ),
          Obx(() {
            final note = controller.connectionNote.value;
            if (note.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: AppText(
                text: note,
                fontSize: TextStyles.k12FontSize,
                color: pkGold,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _battleFooter(PkSideInfo a, PkSideInfo b) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: appButton(
              onPressed: () => _openGiftPicker(a, b),
              buttonText: 'Send Gift',
              isGradient: true,
              gradientColors: const [pkGold, pkRed],
              borderRadius: 16,
              buttonHeight: 50,
              buttonIcon: const Icon(Icons.card_giftcard_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================================
  // Result
  // ======================================================================

  Widget _resultView() {
    return Obx(() {
      final r = controller.result.value;
      final side = r?.winnerSide ?? PkBattleSide.none;
      final title = side == PkBattleSide.tie
          ? "IT'S A TIE!"
          : side == PkBattleSide.none
              ? 'PK ENDED'
              : 'WINNER!';
      return Column(
        children: [
          _topBar('PK Result'),
          const Spacer(),
          Icon(
            side == PkBattleSide.tie
                ? Icons.handshake_rounded
                : Icons.emoji_events_rounded,
            color: pkGold,
            size: 80,
          ),
          const SizedBox(height: 12),
          BoldText(text: title, fontSize: 26, color: pkGold),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _resultScore('A', controller.scoreA.value, pkRed,
                  side == PkBattleSide.a),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: BoldText(text: 'VS', fontSize: 18, color: kColorWhite),
              ),
              _resultScore('B', controller.scoreB.value, pkBlue,
                  side == PkBattleSide.b),
            ],
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: appButton(
              onPressed: () => Get.back(),
              buttonText: 'Back to Live',
              isGradient: true,
              gradientColors: const [pkGold, pkRed],
              borderRadius: 16,
            ),
          ),
        ],
      );
    });
  }

  Widget _resultScore(String label, int score, Color color, bool isWinner) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: color.withValues(alpha: isWinner ? 0.28 : 0.12),
            border: Border.all(
              color: isWinner ? pkGold : color.withValues(alpha: 0.4),
              width: isWinner ? 2 : 1,
            ),
          ),
          child: BoldText(text: '$score', fontSize: 24, color: kColorWhite),
        ),
        const SizedBox(height: 6),
        AppText(
          text: 'Side $label',
          fontSize: TextStyles.k12FontSize,
          color: kColorWhite.withValues(alpha: 0.7),
        ),
      ],
    );
  }

  // ======================================================================
  // Shared chrome + actions
  // ======================================================================

  Widget _topBar(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          _iconButton(Icons.arrow_back_ios_new_rounded, () => Get.back()),
          Expanded(
            child: Center(
              child: SemiBoldText(
                text: title,
                fontSize: TextStyles.k16FontSize,
                color: kColorWhite,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        onSubmitted: (v) {
          controller.searchText.value = v;
          controller.loadEligibleHosts(search: v);
        },
        style: TextStyles.kRegularPoppins(
          fontSize: TextStyles.k14FontSize,
          colors: kColorWhite,
        ),
        decoration: InputDecoration(
          hintText: 'Search hosts…',
          hintStyle: TextStyles.kRegularPoppins(
            fontSize: TextStyles.k14FontSize,
            colors: kColorWhite.withValues(alpha: 0.5),
          ),
          prefixIcon:
              Icon(Icons.search_rounded, color: kColorWhite.withValues(alpha: 0.6)),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.06),
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: pkGold),
          ),
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.24),
        ),
        child: Icon(icon, color: kColorWhite, size: 20),
      ),
    );
  }

  Widget _livePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: pkRed,
      ),
      child: BoldText(text: 'LIVE', fontSize: 9, color: kColorWhite),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(icon, size: 64, color: Colors.white.withValues(alpha: 0.3)),
        const SizedBox(height: 16),
        Center(
          child: SemiBoldText(
            text: title,
            fontSize: TextStyles.k16FontSize,
            color: kColorWhite,
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: AppText(
            text: subtitle,
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  void _confirmLeave() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF2A0737),
        title: SemiBoldText(
          text: 'Leave PK Battle?',
          fontSize: TextStyles.k16FontSize,
          color: kColorWhite,
        ),
        content: AppText(
          text: 'Leaving now may forfeit the battle.',
          color: kColorWhite.withValues(alpha: 0.75),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.leaveBattle();
            },
            child: const Text('Leave', style: TextStyle(color: pkRed)),
          ),
        ],
      ),
    );
  }

  void _openReport() {
    final s = controller.session.value;
    if (s == null) return;
    final opponentId = controller.isSelfSideA ? s.sideB.hostId : s.sideA.hostId;
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF2A0737),
        title: SemiBoldText(
          text: 'Report this PK?',
          fontSize: TextStyles.k16FontSize,
          color: kColorWhite,
        ),
        content: AppText(
          text: 'Report inappropriate content or rule violations.',
          color: kColorWhite.withValues(alpha: 0.75),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.report(
                reportedUserId: opponentId,
                reason: 'Inappropriate content during PK',
              );
            },
            child: const Text('Report', style: TextStyle(color: pkRed)),
          ),
        ],
      ),
    );
  }

  void _openGiftPicker(PkSideInfo a, PkSideInfo b) {
    Get.bottomSheet(
      PkGiftPickerSheet(
        controller: controller,
        sideA: a,
        sideB: b,
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }
}

/// Simple three-dot pulsing indicator for the waiting screen.
class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = ((_c.value + i * 0.2) % 1.0);
            final scale = 0.6 + (0.4 * (1 - (t - 0.5).abs() * 2));
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: PkV1ArenaView.pkGold,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
