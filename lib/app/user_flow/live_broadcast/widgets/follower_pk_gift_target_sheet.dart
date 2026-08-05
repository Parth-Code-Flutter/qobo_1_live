import 'package:flutter/material.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/models/audio_room_models.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Side-aware target chooser shown instead of room-wide gifts during an active
/// follower PK. Backend remains authoritative and rejects non-followers.
class FollowerPkGiftTargetSheet extends StatelessWidget {
  const FollowerPkGiftTargetSheet({
    super.key,
    required this.players,
    required this.onSelected,
  });

  final List<AudioRoomSeatModel> players;
  final ValueChanged<AudioRoomSeatModel> onSelected;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(10, 0, 10, bottomInset + 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF32134A), Color(0xFF150A26)],
          ),
          border: Border.all(
            color: const Color(0xFFFF3EA5).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Spacing.v16,
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bolt_rounded, color: Color(0xFFFF8A2A), size: 20),
                SizedBox(width: 7),
                SemiBoldText(
                  text: 'Choose your PK player',
                  fontSize: TextStyles.k16FontSize,
                  color: kColorWhite,
                ),
              ],
            ),
            Spacing.v6,
            const AppText(
              text: 'You can gift only the contestant you follow.',
              fontSize: TextStyles.k12FontSize,
              color: Colors.white60,
              align: TextAlign.center,
            ),
            Spacing.v20,
            Row(
              children: List.generate(players.length, (index) {
                final player = players[index];
                final colors = index.isEven
                    ? const [Color(0xFF6C63FF), Color(0xFF2ED3FF)]
                    : const [Color(0xFFFF3EA5), Color(0xFFFF8A2A)];
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 0 : 6,
                      right: index == players.length - 1 ? 0 : 6,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onSelected(player),
                        borderRadius: BorderRadius.circular(20),
                        child: Ink(
                          padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colors.first.withValues(alpha: 0.25),
                                Colors.white.withValues(alpha: 0.05),
                              ],
                            ),
                            border: Border.all(
                              color: colors.first.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(colors: colors),
                                ),
                                child: AppUserAvatar(
                                  name: player.name,
                                  imageUrl: player.avatarUrl,
                                  size: 58,
                                ),
                              ),
                              Spacing.v10,
                              SemiBoldText(
                                text: player.name,
                                fontSize: TextStyles.k12FontSize,
                                color: kColorWhite,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Spacing.v8,
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: LinearGradient(colors: colors),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.redeem_rounded,
                                      color: kColorWhite,
                                      size: 15,
                                    ),
                                    SizedBox(width: 4),
                                    AppText(
                                      text: 'Gift',
                                      fontSize: TextStyles.k10FontSize,
                                      color: kColorWhite,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
