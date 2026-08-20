import 'package:flutter/material.dart';
import 'package:qobo_one_live/utils/app_widgets/app_coin_icon.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/controllers/live_broadcast_controller.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/controllers/pk_v1_controller.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/models/v1/pk_v1_models.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/zego_live_id_utils.dart';
import 'package:zego_uikit/zego_uikit.dart';

/// One host's slot in the PK split view.
///
/// When [hostUserId] is set, renders a live Zego camera feed (same session) with
/// avatar fallback; otherwise shows the accent avatar tile.
class PkHostVideoTile extends StatelessWidget {
  const PkHostVideoTile({
    super.key,
    required this.name,
    required this.avatarUrl,
    required this.accent,
    required this.alignEnd,
    this.hostUserId,
  });

  final String name;
  final String? avatarUrl;
  final Color accent;
  final bool alignEnd;
  final String? hostUserId;

  @override
  Widget build(BuildContext context) {
    final userId = hostUserId?.trim() ?? '';
    if (userId.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.all(4),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.5)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PkHostLiveVideoFill(
              userId: userId,
              name: name,
              imageUrl: avatarUrl,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    accent.withValues(alpha: 0.22),
                    Colors.black.withValues(alpha: 0.45),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black.withValues(alpha: 0.4),
                ),
                child: Row(
                  mainAxisAlignment:
                      alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    SemiBoldText(
                      text: name.isEmpty ? 'Host' : name,
                      fontSize: TextStyles.k12FontSize,
                      color: kColorWhite,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: 0.28),
            Colors.black.withValues(alpha: 0.35),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Stack(
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accent, width: 2),
              ),
              child: AppUserAvatar(
                name: name.isEmpty ? 'Host' : name,
                imageUrl: avatarUrl,
                size: 84,
              ),
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withValues(alpha: 0.4),
              ),
              child: Row(
                mainAxisAlignment:
                    alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  SemiBoldText(
                    text: name.isEmpty ? 'Host' : name,
                    fontSize: TextStyles.k12FontSize,
                    color: kColorWhite,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Server-authoritative countdown pill with a "PK" flash badge.
class PkTimerPill extends StatelessWidget {
  const PkTimerPill({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC857), Color(0xFFFF3B5C)],
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flash_on_rounded, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          BoldText(text: text, fontSize: TextStyles.k14FontSize, color: kColorWhite),
        ],
      ),
    );
  }
}

/// Split score bar: Side A (left) vs Side B (right).
class PkScoreBar extends StatelessWidget {
  const PkScoreBar({
    super.key,
    required this.scoreA,
    required this.scoreB,
    required this.progressA,
    required this.leftColor,
    required this.rightColor,
  });

  final int scoreA;
  final int scoreB;
  final double progressA;
  final Color leftColor;
  final Color rightColor;

  @override
  Widget build(BuildContext context) {
    final clamped = progressA.clamp(0.05, 0.95);
    return Column(
      children: [
        Row(
          children: [
            BoldText(text: '$scoreA', fontSize: TextStyles.k14FontSize, color: leftColor),
            const Spacer(),
            BoldText(text: '$scoreB', fontSize: TextStyles.k14FontSize, color: rightColor),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 14,
            child: Stack(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: (clamped * 1000).round(),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              leftColor,
                              leftColor.withValues(alpha: 0.75),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: ((1 - clamped) * 1000).round(),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              rightColor.withValues(alpha: 0.75),
                              rightColor,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Center energy glow (reference PK bar flash).
                Align(
                  alignment: Alignment((clamped * 2) - 1, 0),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.85),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
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
}

/// Bottom sheet to pick a side and a gift, then send it to that PK side.
class PkGiftPickerSheet extends StatefulWidget {
  const PkGiftPickerSheet({
    super.key,
    required this.controller,
    required this.sideA,
    required this.sideB,
  });

  final PkV1Controller controller;
  final PkSideInfo sideA;
  final PkSideInfo sideB;

  @override
  State<PkGiftPickerSheet> createState() => _PkGiftPickerSheetState();
}

class _PkGiftPickerSheetState extends State<PkGiftPickerSheet> {
  static const _pkRed = Color(0xFFFF3B5C);
  static const _pkBlue = Color(0xFF3AA0FF);

  PkBattleSide _side = PkBattleSide.a;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF2A0737),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 14),
            SemiBoldText(
              text: 'Support a side',
              fontSize: TextStyles.k16FontSize,
              color: kColorWhite,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _sideChip(
                    label: widget.sideA.displayName.isEmpty
                        ? 'Side A'
                        : widget.sideA.displayName,
                    color: _pkRed,
                    selected: _side == PkBattleSide.a,
                    onTap: () => setState(() => _side = PkBattleSide.a),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _sideChip(
                    label: widget.sideB.displayName.isEmpty
                        ? 'Side B'
                        : widget.sideB.displayName,
                    color: _pkBlue,
                    selected: _side == PkBattleSide.b,
                    onTap: () => setState(() => _side = PkBattleSide.b),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              final gifts = widget.controller.giftCatalog;
              if (gifts.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: AppText(
                    text: 'No gifts available right now.',
                    color: kColorWhite.withValues(alpha: 0.6),
                  ),
                );
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: gifts.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.78,
                ),
                itemBuilder: (_, i) => _giftTile(gifts[i]),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _sideChip({
    required String label,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: color.withValues(alpha: selected ? 0.3 : 0.12),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.35),
            width: selected ? 2 : 1,
          ),
        ),
        child: SemiBoldText(
          text: label,
          fontSize: TextStyles.k12FontSize,
          color: kColorWhite,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _giftTile(PkGiftCatalogItem gift) {
    return GestureDetector(
      onTap: () {
        widget.controller.sendGiftToSide(gift: gift, side: _side);
        Get.back();
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: gift.iconUrl.isNotEmpty
                  ? Image.network(gift.iconUrl, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.card_giftcard_rounded,
                          color: Colors.white54))
                  : const Icon(Icons.card_giftcard_rounded,
                      color: Colors.white54),
            ),
            const SizedBox(height: 4),
            AppText(
              text: gift.name,
              fontSize: 10,
              color: kColorWhite,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppCoinIcon(color: Color(0xFFFFC857), size: 11),
                const SizedBox(width: 2),
                AppText(
                  text: '${gift.coinCost}',
                  fontSize: 10,
                  color: kColorWhite.withValues(alpha: 0.8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-bleed Zego camera for PK host panes (live room / co-located streams).
class PkHostLiveVideoFill extends StatefulWidget {
  const PkHostLiveVideoFill({
    super.key,
    required this.userId,
    required this.name,
    this.imageUrl,
    this.preferLocalUser = false,
  });

  final String userId;
  final String name;
  final String? imageUrl;

  /// When true, bind the local Zego user (reliable self camera during PK).
  final bool preferLocalUser;

  @override
  State<PkHostLiveVideoFill> createState() => _PkHostLiveVideoFillState();
}

class _PkHostLiveVideoFillState extends State<PkHostLiveVideoFill> {
  bool _screenUtilReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureScreenUtil();
  }

  void _ensureScreenUtil() {
    if (_screenUtilReady) return;
    if (MediaQuery.maybeOf(context) == null) return;
    try {
      final _ = ZegoScreenUtil().screenWidth;
      _screenUtilReady = true;
    } catch (_) {
      try {
        ZegoScreenUtil.init(context);
        _screenUtilReady = true;
      } catch (_) {
        _screenUtilReady = false;
      }
    }
    if (_screenUtilReady && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _ensureScreenUtil();

    if (!Get.isRegistered<LiveBroadcastController>()) {
      return _fallbackAvatar();
    }

    final controller = Get.find<LiveBroadcastController>();
    return Obx(() {
      // Rebuild when camera / zego connection changes so PK panes refresh.
      final _ = controller.isCameraOff.value;
      final connected = controller.isZegoConnected.value;
      if (!connected || !_screenUtilReady) {
        return _fallbackAvatar();
      }

      ZegoUIKitUser? zegoUser;
      try {
        if (widget.preferLocalUser) {
          final local = ZegoUIKit().getLocalUser();
          if (local.id.trim().isNotEmpty) {
            zegoUser = local;
          }
        }
        if (zegoUser == null) {
          final zegoId =
              ZegoLiveIdUtils.sanitizeUserId(widget.userId.trim());
          if (zegoId.isEmpty) {
            return _fallbackAvatar();
          }
          for (final user in ZegoUIKit().getAllUsers()) {
            final uid = ZegoLiveIdUtils.sanitizeUserId(user.id);
            if (user.id == zegoId || uid == zegoId) {
              zegoUser = user;
              break;
            }
          }
          zegoUser ??= ZegoUIKitUser(id: zegoId, name: widget.name);
        }
      } catch (_) {
        return _fallbackAvatar();
      }

      return ZegoAudioVideoView(
        user: zegoUser,
        borderRadius: 0,
        borderColor: Colors.transparent,
        backgroundBuilder: (context, size, user, extraInfo) {
          return _fallbackAvatar();
        },
        avatarConfig: ZegoAvatarConfig(
          showInAudioMode: true,
          showSoundWavesInAudioMode: false,
          builder: (context, size, user, extraInfo) {
            return AppUserAvatar(
              name: widget.name,
              imageUrl: widget.imageUrl,
              size: size.shortestSide * 0.42,
            );
          },
        ),
      );
    });
  }

  Widget _fallbackAvatar() {
    return ColoredBox(
      color: const Color(0xFF1A1228),
      child: Center(
        child: AppUserAvatar(
          name: widget.name,
          imageUrl: widget.imageUrl,
          size: 72,
        ),
      ),
    );
  }
}
