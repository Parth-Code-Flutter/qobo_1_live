import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Visual tone for room-style feedback dialogs.
enum AudioRoomFeedbackTone {
  /// Host successfully removed a member.
  moderation,

  /// Viewer was removed from the room.
  removed,

  /// General success / info (e.g. Super Admin request status).
  info,
}

/// Styled room dialog for kick-off and removal feedback (dark glass + gradient CTA).
class AudioRoomFeedbackDialog extends StatelessWidget {
  const AudioRoomFeedbackDialog({
    super.key,
    required this.title,
    required this.message,
    required this.tone,
  });

  final String title;
  final String message;
  final AudioRoomFeedbackTone tone;

  static const Color _cardTop = Color(0xFF4A073F);
  static const Color _cardBottom = Color(0xFF1D222B);
  static const Color _accentPink = Color(0xFFE12BC5);
  static const Color _accentPurple = Color(0xFF8E1B85);

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    required AudioRoomFeedbackTone tone,
    bool barrierDismissible = true,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.62),
      builder: (dialogContext) => AudioRoomFeedbackDialog(
        title: title,
        message: message,
        tone: tone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _paletteForTone(tone);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_cardTop, _cardBottom],
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: palette.glow.withValues(alpha: 0.28),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IconBadge(palette: palette),
              Spacing.v16,
              SemiBoldText(
                text: title,
                fontSize: TextStyles.k18FontSize,
                color: kColorWhite,
                align: TextAlign.center,
              ),
              Spacing.v12,
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: kColorWhite.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kColorWhite.withValues(alpha: 0.08)),
                ),
                child: AppText(
                  text: message,
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite.withValues(alpha: 0.82),
                  align: TextAlign.center,
                ),
              ),
              Spacing.v20,
              appButton(
                onPressed: () => Navigator.of(context).pop<void>(),
                buttonText: 'OK',
                buttonHeight: 48,
                isGradient: true,
                gradientColors: palette.buttonGradient,
                textStyle: TextStyles.kSemiBoldPoppins(
                  fontSize: TextStyles.k14FontSize,
                  colors: kColorWhite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _DialogPalette _paletteForTone(AudioRoomFeedbackTone tone) {
    switch (tone) {
      case AudioRoomFeedbackTone.moderation:
        return const _DialogPalette(
          icon: Icons.person_remove_rounded,
          iconGradient: [Color(0xFFFF8A65), Color(0xFFE12BC5)],
          glow: _accentPink,
          buttonGradient: [_accentPurple, _accentPink],
        );
      case AudioRoomFeedbackTone.removed:
        return const _DialogPalette(
          icon: Icons.meeting_room_outlined,
          iconGradient: [Color(0xFFFF5A7A), Color(0xFF8E1B85)],
          glow: Color(0xFFFF5A7A),
          buttonGradient: [Color(0xFF8E1B85), Color(0xFFE12BC5)],
        );
      case AudioRoomFeedbackTone.info:
        return const _DialogPalette(
          icon: Icons.workspace_premium_rounded,
          iconGradient: [Color(0xFFE12BC5), Color(0xFF8E1B85)],
          glow: _accentPurple,
          buttonGradient: [_accentPurple, _accentPink],
        );
    }
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.palette});

  final _DialogPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.iconGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.glow.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(palette.icon, color: kColorWhite, size: 34),
    );
  }
}

class _DialogPalette {
  const _DialogPalette({
    required this.icon,
    required this.iconGradient,
    required this.glow,
    required this.buttonGradient,
  });

  final IconData icon;
  final List<Color> iconGradient;
  final Color glow;
  final List<Color> buttonGradient;
}
