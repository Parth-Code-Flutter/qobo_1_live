import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Premium "nothing here yet" card for the audio / video room listings.
///
/// Glass surface with a pulsing accent halo, the room-type icon, and a
/// gradient create CTA so the tab never looks like a dead screen.
class RoomsEmptyState extends StatefulWidget {
  const RoomsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColors,
    this.ctaLabel,
    this.onCta,
    this.hint = 'Pull down to refresh',
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> accentColors;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final String hint;

  @override
  State<RoomsEmptyState> createState() => _RoomsEmptyStateState();
}

class _RoomsEmptyStateState extends State<RoomsEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Color get _accent => widget.accentColors.first;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.92, end: 1),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: ((scale - 0.92) / 0.08).clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xE62A1638), Color(0xE6140C22)],
                  ),
                  border: Border.all(
                    color: _accent.withValues(alpha: 0.28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withValues(alpha: 0.18),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _haloIcon(),
                    Spacing.v20,
                    SemiBoldText(
                      text: widget.title,
                      fontSize: TextStyles.k18FontSize,
                      color: kColorWhite,
                      align: TextAlign.center,
                    ),
                    Spacing.v8,
                    AppText(
                      text: widget.subtitle,
                      fontSize: TextStyles.k12FontSize,
                      color: kColorWhite.withValues(alpha: 0.62),
                      align: TextAlign.center,
                    ),
                    if (widget.ctaLabel != null && widget.onCta != null) ...[
                      Spacing.v20,
                      _ctaButton(),
                    ],
                    Spacing.v16,
                    _hintRow(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _haloIcon() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_pulse.value);
        return SizedBox(
          width: 116,
          height: 116,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 84 + (t * 26),
                height: 84 + (t * 26),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _accent.withValues(alpha: 0.30 - (t * 0.22)),
                  ),
                ),
              ),
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.withValues(alpha: 0.12),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.accentColors,
          ),
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(widget.icon, color: kColorWhite, size: 26),
      ),
    );
  }

  Widget _ctaButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onCta,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.accentColors,
            ),
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, color: kColorWhite, size: 18),
              Spacing.h6,
              SemiBoldText(
                text: widget.ctaLabel!,
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hintRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.refresh_rounded,
          size: 14,
          color: kColorWhite.withValues(alpha: 0.4),
        ),
        Spacing.h6,
        AppText(
          text: widget.hint,
          fontSize: TextStyles.k10FontSize,
          color: kColorWhite.withValues(alpha: 0.4),
        ),
      ],
    );
  }
}
