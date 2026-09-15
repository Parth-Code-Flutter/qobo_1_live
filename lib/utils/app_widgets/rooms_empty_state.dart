import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/dating_empty_hero.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Soft dating-style empty card for audio / video room listings.
class RoomsEmptyState extends StatelessWidget {
  const RoomsEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accentColors,
    required this.heroStyle,
    this.ctaLabel,
    this.onCta,
    this.hint = 'Pull down to refresh',
  });

  final String title;
  final String subtitle;
  final List<Color> accentColors;
  final DatingEmptyHeroStyle heroStyle;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final String hint;

  Color get _accent => accentColors.first;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.94, end: 1),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFFFFF),
                      Color(0xFFFFF0F6),
                      Color(0xFFF5ECFF),
                    ],
                  ),
                  border: Border.all(
                    color: AppLightUi.pinkSoft.withValues(alpha: 0.55),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withValues(alpha: 0.14),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: AppLightUi.title.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DatingEmptyHero(
                      style: heroStyle,
                      accentColors: accentColors,
                      size: 156,
                    ),
                    Spacing.v12,
                    SemiBoldText(
                      text: title,
                      fontSize: TextStyles.k18FontSize,
                      color: AppLightUi.title,
                      align: TextAlign.center,
                    ),
                    Spacing.v8,
                    AppText(
                      text: subtitle,
                      fontSize: TextStyles.k12FontSize,
                      color: AppLightUi.subtitle,
                      align: TextAlign.center,
                    ),
                    if (ctaLabel != null && onCta != null) ...[
                      Spacing.v20,
                      _ctaButton(),
                    ],
                    Spacing.v12,
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

  Widget _ctaButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onCta,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: accentColors,
            ),
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: 0.32),
                blurRadius: 14,
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
                text: ctaLabel!,
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
        Icon(Icons.refresh_rounded, size: 14, color: AppLightUi.muted),
        Spacing.h6,
        AppText(
          text: hint,
          fontSize: TextStyles.k10FontSize,
          color: AppLightUi.muted,
        ),
      ],
    );
  }
}
