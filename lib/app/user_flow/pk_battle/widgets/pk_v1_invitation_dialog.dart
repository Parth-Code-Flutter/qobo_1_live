import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/models/v1/pk_v1_models.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Premium PK invitation popup with a live countdown. Returns `true` on accept,
/// `false` on reject / auto-expire.
class PkV1InvitationDialog extends StatefulWidget {
  const PkV1InvitationDialog({super.key, required this.invitation});

  final PkInvitation invitation;

  @override
  State<PkV1InvitationDialog> createState() => _PkV1InvitationDialogState();
}

class _PkV1InvitationDialogState extends State<PkV1InvitationDialog> {
  static const _pkGold = Color(0xFFFFC857);
  static const _pkRed = Color(0xFFFF3B5C);

  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final fromInvite = widget.invitation.remainingSeconds;
    _remaining = fromInvite > 0 ? fromInvite : 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining = _remaining - 1);
      if (_remaining <= 0) {
        _timer?.cancel();
        if (Get.isDialogOpen ?? false) Get.back(result: false);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invitation;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A0737), Color(0xFF3B0D2E)],
          ),
          border: Border.all(color: _pkGold.withValues(alpha: 0.55), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: _pkRed.withValues(alpha: 0.28),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _badge(),
            const SizedBox(height: 14),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [_pkGold, _pkRed],
                    ),
                  ),
                  child: AppUserAvatar(
                    name: inv.fromUserName,
                    imageUrl: inv.fromUserAvatar,
                    size: 76,
                  ),
                ),
                _countdownPill(),
              ],
            ),
            const SizedBox(height: 12),
            SemiBoldText(
              text: inv.fromUserName,
              fontSize: TextStyles.k18FontSize,
              color: kColorWhite,
            ),
            const SizedBox(height: 4),
            AppText(
              text: 'challenges you to a PK Battle!',
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite.withValues(alpha: 0.75),
              align: TextAlign.center,
            ),
            const SizedBox(height: 10),
            _durationChip(inv.durationSec),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: appButton(
                    onPressed: () => Get.back(result: false),
                    buttonText: 'Reject',
                    buttonHeight: 48,
                    isGradient: false,
                    buttonColor: Colors.white.withValues(alpha: 0.10),
                    buttonBorderColor: Colors.white.withValues(alpha: 0.18),
                    borderRadius: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: appButton(
                    onPressed: () => Get.back(result: true),
                    buttonText: 'Accept',
                    buttonHeight: 48,
                    isGradient: true,
                    gradientColors: const [_pkGold, _pkRed],
                    borderRadius: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(colors: [_pkGold, _pkRed]),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flash_on_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          BoldText(
            text: 'PK BATTLE CHALLENGE',
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite,
          ),
        ],
      ),
    );
  }

  Widget _countdownPill() {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _pkRed,
        border: Border.all(color: kColorWhite, width: 2),
      ),
      child: BoldText(
        text: '${_remaining < 0 ? 0 : _remaining}',
        fontSize: TextStyles.k12FontSize,
        color: kColorWhite,
      ),
    );
  }

  Widget _durationChip(int durationSec) {
    final minutes = (durationSec / 60).toStringAsFixed(
      durationSec % 60 == 0 ? 0 : 1,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, color: _pkGold, size: 15),
          const SizedBox(width: 6),
          AppText(
            text: '$minutes min battle',
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite,
          ),
        ],
      ),
    );
  }
}
