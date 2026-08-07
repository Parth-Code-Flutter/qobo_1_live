import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/admin_agency_chrome.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

enum FamilyMemberAction { sendGift, directMessage }

/// Premium glass sheet: Send Gift / Direct Message for a family member.
///
/// Icons use [AdminAgencyUi.glowIcon] (same as Family Tree / Announcement).
/// Avatar uses [FramedUserAvatar] like Discover / live-room profiles.
class FamilyMemberActionsSheet extends StatelessWidget {
  const FamilyMemberActionsSheet({
    super.key,
    required this.member,
    this.isSelf = false,
  });

  final Map<String, dynamic> member;
  final bool isSelf;

  static Future<FamilyMemberAction?> show({
    required Map<String, dynamic> member,
    bool isSelf = false,
  }) {
    return Get.bottomSheet<FamilyMemberAction>(
      FamilyMemberActionsSheet(member: member, isSelf: isSelf),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = member['name']?.toString() ?? 'Member';
    final role = member['role']?.toString() ?? 'member';
    final level = member['level'] ?? 1;
    final imageUrl = member['displayPicture']?.toString();
    final frameUrl = member['avatarFrameUrl']?.toString();
    final userId = member['userId']?.toString() ?? name;
    final online = member['isOnline'] == true;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        14,
        0,
        14,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xF02A1638),
                  Color(0xF0140C22),
                  Color(0xF00C0814),
                ],
              ),
              border: Border.all(
                color: AdminAgencyUi.gold.withValues(alpha: 0.28),
              ),
              boxShadow: [
                BoxShadow(
                  color: AdminAgencyUi.goldDeep.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: kColorWhite.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Spacing.v16,
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      FramedUserAvatar(
                        name: name,
                        imageUrl: imageUrl,
                        frameUrl: frameUrl,
                        frameSeed: userId,
                        size: 72,
                      ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: online ? Colors.greenAccent : Colors.grey,
                            shape: BoxShape.circle,
                            border: Border.all(color: kColorWhite, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Spacing.v12,
                  SemiBoldText(
                    text: name,
                    fontSize: TextStyles.k18FontSize,
                    color: kColorWhite,
                    align: TextAlign.center,
                  ),
                  Spacing.v4,
                  AppText(
                    text: '$role · Lv.$level',
                    fontSize: TextStyles.k12FontSize,
                    color: kColorWhite.withValues(alpha: 0.72),
                    align: TextAlign.center,
                  ),
                  Spacing.v20,
                  if (isSelf)
                    AppText(
                      text: 'This is you — pick another member to gift or DM.',
                      fontSize: TextStyles.k12FontSize,
                      color: kColorWhite.withValues(alpha: 0.7),
                      align: TextAlign.center,
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _ActionTile(
                            icon: Icons.card_giftcard_rounded,
                            label: 'Send Gift',
                            accent: AdminAgencyUi.pink,
                            accentEnd: AdminAgencyUi.violet,
                            onTap: () =>
                                Get.back(result: FamilyMemberAction.sendGift),
                          ),
                        ),
                        Spacing.h12,
                        Expanded(
                          child: _ActionTile(
                            icon: Icons.chat_bubble_rounded,
                            label: 'Message',
                            accent: AdminAgencyUi.cyan,
                            accentEnd: AdminAgencyUi.sky,
                            onTap: () => Get.back(
                              result: FamilyMemberAction.directMessage,
                            ),
                          ),
                        ),
                      ],
                    ),
                  Spacing.v8,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.accent,
    required this.accentEnd,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final Color accentEnd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 96,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.42),
                accentEnd.withValues(alpha: 0.22),
                const Color(0xFF1A0B2E),
              ],
            ),
            border: Border.all(color: accent.withValues(alpha: 0.28)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Same solid gradient tile + white glyph as Family Tree / header.
              AdminAgencyUi.glowIcon(
                icon: icon,
                accent: accent,
                accentEnd: accentEnd,
                size: 44,
                iconSize: 22,
              ),
              Spacing.v10,
              SemiBoldText(
                text: label,
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
