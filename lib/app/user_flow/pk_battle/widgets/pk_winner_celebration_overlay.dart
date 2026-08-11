import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/models/v1/pk_v1_models.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Full-screen PK winner celebration (SVGA-style blast via congratulation GIF).
///
/// Shown immediately when the server reports a result; auto-dismisses after
/// [displayDuration] and invokes [onFinished] so the live room can restore seats.
class PkWinnerCelebrationOverlay {
  PkWinnerCelebrationOverlay._();

  static const displayDuration = Duration(seconds: 5);

  static BuildContext? _dialogContext;
  static Timer? _dismissTimer;
  static bool _showing = false;

  static bool get isShowing => _showing;

  static void show({
    required PkResult result,
    PkSession? session,
    required VoidCallback onFinished,
  }) {
    dismiss();
    _showing = true;

    final winnerSide = result.winnerSide;
    final winnerInfo = _winnerInfo(result: result, session: session);
    final title = winnerSide == PkBattleSide.tie
        ? "IT'S A TIE!"
        : winnerSide == PkBattleSide.none
            ? 'PK ENDED'
            : 'WINNER';
    final subtitle = winnerSide == PkBattleSide.tie
        ? '${result.scoreA} — ${result.scoreB}'
        : '${winnerInfo.name} · ${winnerSide == PkBattleSide.a ? result.scoreA : result.scoreB} pts';

    void finish() {
      _dismissTimer?.cancel();
      _dismissTimer = null;
      if (_dialogContext != null &&
          _dialogContext!.mounted &&
          Navigator.of(_dialogContext!).canPop()) {
        Navigator.of(_dialogContext!).pop();
      }
      _dialogContext = null;
      _showing = false;
      onFinished();
    }

    _dismissTimer = Timer(displayDuration, finish);

    BuildContext? navigatorContext;
    try {
      navigatorContext = Get.context ?? Get.key.currentContext;
    } catch (_) {
      navigatorContext = null;
    }
    if (navigatorContext == null) {
      _showing = false;
      onFinished();
      return;
    }

    Get.dialog<void>(
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      useSafeArea: false,
      Builder(
        builder: (dialogContext) {
          _dialogContext = dialogContext;
          return _PkWinnerCelebrationView(
            title: title,
            subtitle: subtitle,
            winnerName: winnerInfo.name,
            winnerAvatar: winnerInfo.avatarUrl,
            scoreA: result.scoreA,
            scoreB: result.scoreB,
            winnerSide: winnerSide,
            onCompleted: finish,
          );
        },
      ),
    );
  }

  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (_dialogContext != null &&
        _dialogContext!.mounted &&
        Navigator.of(_dialogContext!).canPop()) {
      Navigator.of(_dialogContext!).pop();
    }
    _dialogContext = null;
    _showing = false;
  }

  static ({String name, String avatarUrl}) _winnerInfo({
    required PkResult result,
    PkSession? session,
  }) {
    if (session == null) {
      return (name: 'Champion', avatarUrl: '');
    }
    switch (result.winnerSide) {
      case PkBattleSide.a:
        return (
          name: session.sideA.displayName.isEmpty
              ? 'Side A'
              : session.sideA.displayName,
          avatarUrl: session.sideA.avatarUrl,
        );
      case PkBattleSide.b:
        return (
          name: session.sideB.displayName.isEmpty
              ? 'Side B'
              : session.sideB.displayName,
          avatarUrl: session.sideB.avatarUrl,
        );
      default:
        return (name: 'Great battle', avatarUrl: '');
    }
  }
}

class _PkWinnerCelebrationView extends StatefulWidget {
  const _PkWinnerCelebrationView({
    required this.title,
    required this.subtitle,
    required this.winnerName,
    required this.winnerAvatar,
    required this.scoreA,
    required this.scoreB,
    required this.winnerSide,
    required this.onCompleted,
  });

  final String title;
  final String subtitle;
  final String winnerName;
  final String winnerAvatar;
  final int scoreA;
  final int scoreB;
  final PkBattleSide winnerSide;
  final VoidCallback onCompleted;

  @override
  State<_PkWinnerCelebrationView> createState() =>
      _PkWinnerCelebrationViewState();
}

class _PkWinnerCelebrationViewState extends State<_PkWinnerCelebrationView>
    with SingleTickerProviderStateMixin {
  static const _pink = Color(0xFFFF2D87);
  static const _blue = Color(0xFF2F6BFF);
  static const _gold = Color(0xFFFFC857);

  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Material(
      color: Colors.transparent,
      child: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.62),
                ),
              ),
            ),
            Positioned.fill(
              child: Image.asset(
                kGifCongratulation,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.35),
                    ],
                  ),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1.06).animate(
                    CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [_gold, Color(0xFFFF3B5C)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _gold.withValues(alpha: 0.55),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.white,
                      size: 52,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                BoldText(
                  text: widget.title,
                  fontSize: 28,
                  color: _gold,
                ),
                const SizedBox(height: 8),
                if (widget.winnerSide != PkBattleSide.tie &&
                    widget.winnerSide != PkBattleSide.none) ...[
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _gold, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: _gold.withValues(alpha: 0.4),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: AppUserAvatar(
                      name: widget.winnerName,
                      imageUrl: widget.winnerAvatar,
                      size: 72,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                SemiBoldText(
                  text: widget.subtitle,
                  fontSize: TextStyles.k16FontSize,
                  color: kColorWhite,
                  maxLines: 2,
                  align: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withValues(alpha: 0.12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _scoreChip(
                        label: 'A',
                        score: widget.scoreA,
                        color: _pink,
                        highlight: widget.winnerSide == PkBattleSide.a,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: BoldText(
                          text: 'VS',
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      _scoreChip(
                        label: 'B',
                        score: widget.scoreB,
                        color: _blue,
                        highlight: widget.winnerSide == PkBattleSide.b,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: size.height * 0.08),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreChip({
    required String label,
    required int score,
    required Color color,
    required bool highlight,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: highlight ? color.withValues(alpha: 0.85) : color.withValues(alpha: 0.35),
        border: highlight
            ? Border.all(color: Colors.white.withValues(alpha: 0.7))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BoldText(text: label, fontSize: 11, color: kColorWhite),
          const SizedBox(width: 6),
          BoldText(text: '$score', fontSize: 13, color: kColorWhite),
        ],
      ),
    );
  }
}
