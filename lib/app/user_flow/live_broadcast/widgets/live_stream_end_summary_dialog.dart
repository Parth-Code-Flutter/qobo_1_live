import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Host end-of-stream summary — duration, viewers, diamonds earned.
class LiveStreamEndSummaryDialog extends StatefulWidget {
  const LiveStreamEndSummaryDialog({
    super.key,
    required this.durationSeconds,
    required this.uniqueViewers,
    required this.peakViewers,
    required this.diamondsEarned,
    this.title = 'Live ended',
  });

  final int durationSeconds;
  final int uniqueViewers;
  final int peakViewers;
  final int diamondsEarned;
  final String title;

  static Future<void> show({
    required int durationSeconds,
    required int uniqueViewers,
    required int peakViewers,
    required int diamondsEarned,
    String title = 'Live ended',
  }) {
    return Get.dialog<void>(
      LiveStreamEndSummaryDialog(
        durationSeconds: durationSeconds,
        uniqueViewers: uniqueViewers,
        peakViewers: peakViewers,
        diamondsEarned: diamondsEarned,
        title: title,
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.72),
    );
  }

  @override
  State<LiveStreamEndSummaryDialog> createState() =>
      _LiveStreamEndSummaryDialogState();
}

class _LiveStreamEndSummaryDialogState extends State<LiveStreamEndSummaryDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  String get _durationLabel {
    final total = widget.durationSeconds.clamp(0, 1 << 31);
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.88, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1A1228).withValues(alpha: 0.94),
                    const Color(0xFF120C1C).withValues(alpha: 0.96),
                  ],
                ),
                border: Border.all(
                  color: AppLightUi.pink.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppLightUi.pink.withValues(alpha: 0.22),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, _) {
                        final t = _pulse.value;
                        return Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppLightUi.familyCtaGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppLightUi.pink.withValues(
                                  alpha: 0.28 + t * 0.2,
                                ),
                                blurRadius: 16 + t * 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.videocam_off_rounded,
                            color: kColorWhite,
                            size: 34,
                          ),
                        );
                      },
                    ),
                    Spacing.v16,
                    BoldText(
                      text: widget.title,
                      fontSize: TextStyles.k20FontSize,
                      color: kColorWhite,
                      align: TextAlign.center,
                    ),
                    Spacing.v6,
                    AppText(
                      text: 'Nice session — here’s your stream summary.',
                      fontSize: TextStyles.k12FontSize,
                      color: kColorWhite.withValues(alpha: 0.72),
                      align: TextAlign.center,
                    ),
                    Spacing.v20,
                    Row(
                      children: [
                        Expanded(
                          child: _StatChip(
                            icon: Icons.timer_outlined,
                            label: 'Duration',
                            value: _durationLabel,
                          ),
                        ),
                        Spacing.h10,
                        Expanded(
                          child: _StatChip(
                            icon: Icons.diamond_outlined,
                            label: 'Diamonds',
                            value: '${widget.diamondsEarned}',
                          ),
                        ),
                      ],
                    ),
                    Spacing.v10,
                    Row(
                      children: [
                        Expanded(
                          child: _StatChip(
                            icon: Icons.people_alt_outlined,
                            label: 'Viewers',
                            value: '${widget.uniqueViewers}',
                          ),
                        ),
                        Spacing.h10,
                        Expanded(
                          child: _StatChip(
                            icon: Icons.trending_up_rounded,
                            label: 'Peak',
                            value: '${widget.peakViewers}',
                          ),
                        ),
                      ],
                    ),
                    Spacing.v20,
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: AppLightUi.familyCtaGradient,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Get.back<void>(),
                            child: Center(
                              child: SemiBoldText(
                                text: 'Done',
                                fontSize: TextStyles.k16FontSize,
                                color: kColorWhite,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: kColorWhite.withValues(alpha: 0.06),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppLightUi.pink),
              Spacing.h6,
              AppText(
                text: label,
                fontSize: 10,
                color: kColorWhite.withValues(alpha: 0.65),
              ),
            ],
          ),
          Spacing.v6,
          SemiBoldText(
            text: value,
            fontSize: TextStyles.k16FontSize,
            color: kColorWhite,
          ),
        ],
      ),
    );
  }
}
