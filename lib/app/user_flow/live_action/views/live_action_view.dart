import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/constants/live_action_colors.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/live_action_controller.dart';

/// In-room live experience (center tab) — matches Figma live room layout.
class LiveActionView extends GetView<LiveActionController> {
  const LiveActionView({super.key});

  static const _roomName = 'White Room';
  static const _roomId = '25363';
  static const _viewerCount = '125';
  static const _announcement = 'Announcement Enjaye the Talk and be respect';

  /// Figma: 1 center + 3 inner ring + 4 outer ring (8 listeners).
  static const _orbitParticipants = <_OrbitSeat>[
    _OrbitSeat('Afrin Sabila', '12', kImgTemp2, _SeatMic.active),
    _OrbitSeat('Afrin Sabila', '12', kImgTemp3, _SeatMic.muted),
    _OrbitSeat('Afrin Sabila', '12', kImgTemp4, _SeatMic.idle),
    _OrbitSeat('Afrin Sabila', '12', kImgTemp5, _SeatMic.muted),
    _OrbitSeat('Afrin Sabila', '12', kImgTemp2, _SeatMic.idle),
    _OrbitSeat('Afrin Sabila', '12', kImgTemp3, _SeatMic.muted),
    _OrbitSeat('Afrin Sabila', '12', kImgTemp4, _SeatMic.idle),
    _OrbitSeat('Afrin Sabila', '12', kImgTemp5, _SeatMic.muted),
  ];

  static const _activityLines = <_ActivityLine>[
    _ActivityLine('Jessica sent a flower', kImgTemp3, '🌸'),
    _ActivityLine('Jenifer Sent a flower', kImgTemp4, '🌸'),
  ];

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<LiveActionController>()) {
      Get.put(LiveActionController());
    }

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage(kImgBG), fit: BoxFit.cover),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context),
            Spacing.v8,
            _announcementBar(),
            Spacing.v6,
            Expanded(child: _stageArea(context)),
            _activityFeed(),
            Spacing.v8,
            _compactAdBanner(),
            Spacing.v8,
            _bottomChatBar(context),
            SizedBox(height: MediaQuery.paddingOf(context).bottom + 76),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 12, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: controller.onBackPressed,
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: kColorWhite,
              size: 20,
            ),
          ),
          Spacing.h4,
          ClipOval(
            child: Image.asset(
              kImgTemp2,
              width: 42,
              height: 42,
              fit: BoxFit.cover,
            ),
          ),
          Spacing.h10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SemiBoldText(
                  text: _roomName,
                  fontSize: TextStyles.k16FontSize,
                  color: kColorWhite,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                AppText(
                  text: 'Room Id : $_roomId',
                  fontSize: TextStyles.k10FontSize,
                  color: kColorWhite.withValues(alpha: 0.85),
                ),
              ],
            ),
          ),
          _viewerPill(),
          Spacing.h6,
          _roomMenuButton(),
          Spacing.h6,
          _headerIconButton(Icons.power_settings_new_rounded),
        ],
      ),
    );
  }

  Widget _headerIconButton(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: LiveActionColors.pillFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LiveActionColors.pillBorder, width: 0.8),
      ),
      child: Icon(icon, color: kColorWhite, size: 18),
    );
  }

  Widget _viewerPill() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: LiveActionColors.pillFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LiveActionColors.pillBorder, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            kIconEye,
            width: 16,
            height: 16,
            colorFilter: const ColorFilter.mode(kColorWhite, BlendMode.srcIn),
          ),
          Spacing.h4,
          const SemiBoldText(
            text: _viewerCount,
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite,
          ),
        ],
      ),
    );
  }

  Widget _roomMenuButton() {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      offset: const Offset(0, 42),
      color: const Color(0xFF35184C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'share',
          child: _RoomMenuItem(icon: Icons.ios_share_rounded, label: 'Share'),
        ),
        PopupMenuItem(
          value: 'settings',
          child: _RoomMenuItem(icon: Icons.settings_rounded, label: 'Room Set'),
        ),
        PopupMenuItem(
          value: 'ranking',
          child: _RoomMenuItem(
            icon: Icons.calendar_month_rounded,
            label: 'Ranking',
          ),
        ),
      ],
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: LiveActionColors.pillFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: LiveActionColors.pillBorder, width: 0.8),
        ),
        child: const Icon(Icons.more_horiz_rounded, color: kColorWhite),
      ),
    );
  }

  Widget _announcementBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: LiveActionColors.announcementFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: LiveActionColors.pillBorder, width: 0.6),
        ),
        child: Row(
          children: [
            const Icon(Icons.campaign_outlined, color: kColorWhite, size: 18),
            Spacing.h8,
            Expanded(
              child: AppText(
                text: _announcement,
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: kColorWhite.withValues(alpha: 0.9),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _stageArea(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stageHeight = constraints.maxHeight.clamp(318.0, 360.0);
        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SizedBox(
              height: stageHeight,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      kColorWhite.withValues(alpha: 0.14),
                      kColorBlack.withValues(alpha: 0.18),
                    ],
                  ),
                  border: Border.all(
                    color: kColorWhite.withValues(alpha: 0.16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kColorBlack.withValues(alpha: 0.18),
                      blurRadius: 22,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, cardConstraints) {
                    final tileWidth = (cardConstraints.maxWidth - 30) / 4;
                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: _openSeatCompact()),
                            Expanded(flex: 2, child: _hostSpotlight()),
                            Expanded(child: _openSeatCompact()),
                          ],
                        ),
                        Spacing.v8,
                        Row(
                          children: [
                            const SemiBoldText(
                              text: 'Speakers',
                              fontSize: TextStyles.k12FontSize,
                              color: kColorWhite,
                            ),
                            Spacing.h8,
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: LiveActionColors.micActive,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: LiveActionColors.micActive.withValues(
                                  alpha: 0.14,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const SemiBoldText(
                                text: '8 online',
                                fontSize: 9,
                                color: LiveActionColors.micActive,
                              ),
                            ),
                          ],
                        ),
                        Spacing.v8,
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final seat in _orbitParticipants)
                              _stageSeatBubble(seat, tileWidth),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _hostSpotlight() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    LiveActionColors.micActive.withValues(alpha: 0.25),
                    kColorWhite.withValues(alpha: 0.04),
                  ],
                ),
              ),
            ),
            const Positioned(
              top: 0,
              child: Icon(
                Icons.workspace_premium_rounded,
                color: LiveActionColors.crownGold,
                size: 22,
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: kColorWhite, width: 2.4),
                boxShadow: [
                  BoxShadow(
                    color: kColorBlack.withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipOval(child: Image.asset(kImgTemp2, fit: BoxFit.cover)),
            ),
            Positioned(
              right: 27,
              bottom: 8,
              child: _micBadge(_SeatMic.active, size: 22),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            color: kColorWhite.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kColorWhite.withValues(alpha: 0.18)),
          ),
          child: const SemiBoldText(
            text: 'Host',
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite,
          ),
        ),
      ],
    );
  }

  Widget _openSeatCompact() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: kColorWhite.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: kColorWhite.withValues(alpha: 0.26)),
          ),
          child: const Icon(Icons.add_rounded, color: kColorWhite, size: 28),
        ),
        const SizedBox(height: 5),
        AppText(
          text: 'Open',
          fontSize: TextStyles.k10FontSize,
          color: kColorWhite.withValues(alpha: 0.74),
          align: TextAlign.center,
        ),
      ],
    );
  }

  Widget _stageSeatBubble(_OrbitSeat seat, double width) {
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: seat.mic == _SeatMic.active
                        ? LiveActionColors.micActive
                        : kColorWhite.withValues(alpha: 0.7),
                    width: 1.6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kColorBlack.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(seat.imageAsset, fit: BoxFit.cover),
                ),
              ),
              Positioned(
                left: -1,
                top: -2,
                child: _micBadge(seat.mic, size: 17),
              ),
              Positioned(
                right: -3,
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF20132E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: LiveActionColors.diamondGold.withValues(
                        alpha: 0.8,
                      ),
                    ),
                  ),
                  child: SemiBoldText(
                    text: seat.diamonds,
                    fontSize: 8,
                    color: LiveActionColors.diamondGold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          SemiBoldText(
            text: seat.name,
            fontSize: 8,
            color: kColorWhite,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _micBadge(_SeatMic mic, {required double size}) {
    final bg = mic == _SeatMic.active
        ? LiveActionColors.micActive
        : LiveActionColors.micIdle;
    final icon = mic == _SeatMic.muted ? kIconMuteMike : kIconMike;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: kColorWhite.withValues(alpha: 0.5), width: 1),
      ),
      child: Center(
        child: SvgPicture.asset(
          icon,
          width: size * 0.55,
          height: size * 0.55,
          colorFilter: const ColorFilter.mode(kColorWhite, BlendMode.srcIn),
        ),
      ),
    );
  }

  Widget _activityFeed() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: kColorBlack.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 62,
              height: 34,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  for (var i = 0; i < _activityLines.length; i++)
                    Positioned(
                      left: i * 22,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF180B2A),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            _activityLines[i].avatarAsset,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Spacing.h6,
            Expanded(
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: TextStyles.kRegularPoppins(
                    fontSize: TextStyles.k10FontSize,
                    colors: kColorWhite,
                  ),
                  children: [
                    TextSpan(
                      text: _activityLines.first.message,
                      style: TextStyles.kSemiBoldPoppins(
                        fontSize: TextStyles.k10FontSize,
                        colors: kColorWhite,
                      ),
                    ),
                    TextSpan(text: ' ${_activityLines.first.emoji} x1'),
                  ],
                ),
              ),
            ),
            Spacing.h8,
            Container(
              width: 34,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: kColorWhite.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const SemiBoldText(
                text: '+1',
                fontSize: 9,
                color: kColorWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactAdBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: LiveActionColors.inputFill,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: kColorPrimary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const SemiBoldText(
                text: 'Ad',
                fontSize: 10,
                color: kColorWhite,
              ),
            ),
            Spacing.h10,
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SemiBoldText(
                    text: 'Learn Flutter 3.3',
                    fontSize: 11,
                    color: kColorWhite,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppText(
                    text: 'Master cross-platform development',
                    fontSize: 9,
                    color: kColorVideoSecondaryText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Spacing.h10,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: kColorPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const SemiBoldText(
                text: 'Enroll',
                fontSize: TextStyles.k10FontSize,
                color: kColorWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomChatBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: LiveActionColors.inputFill,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: kColorWhite.withValues(alpha: 0.15),
                  width: 0.8,
                ),
              ),
              alignment: Alignment.centerLeft,
              child: TextField(
                controller: controller.messageController,
                style: TextStyles.kRegularPoppins(
                  fontSize: TextStyles.k12FontSize,
                  colors: kColorWhite,
                ),
                cursorColor: kColorWhite,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Say something',
                  hintStyle: TextStyles.kRegularPoppins(
                    fontSize: TextStyles.k12FontSize,
                    colors: kColorWhite.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
          ),
          Spacing.h8,
          _giftButton(
            gradient: const [Color(0xFF9B5CFF), Color(0xFFFFB347)],
            icon: Icons.card_giftcard_rounded,
          ),
          Spacing.h8,
          _giftButton(
            gradient: const [Color(0xFFE53935), Color(0xFFFFCA28)],
            icon: Icons.redeem_rounded,
          ),
        ],
      ),
    );
  }

  Widget _giftButton({required List<Color> gradient, required IconData icon}) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: kColorWhite, size: 22),
    );
  }
}

enum _SeatMic { active, muted, idle }

class _RoomMenuItem extends StatelessWidget {
  const _RoomMenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: kColorWhite, size: 18),
        Spacing.h10,
        SemiBoldText(
          text: label,
          fontSize: TextStyles.k12FontSize,
          color: kColorWhite,
        ),
      ],
    );
  }
}

class _OrbitSeat {
  const _OrbitSeat(this.name, this.diamonds, this.imageAsset, this.mic);

  final String name;
  final String diamonds;
  final String imageAsset;
  final _SeatMic mic;
}

class _ActivityLine {
  const _ActivityLine(this.message, this.avatarAsset, this.emoji);

  final String message;
  final String avatarAsset;
  final String emoji;
}
