import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/constants/live_action_colors.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/app_widgets/app_mock_ad_widget.dart';

import '../controllers/live_action_controller.dart';

/// In-room live experience (center tab) — matches Figma live room layout.
class LiveActionView extends GetView<LiveActionController> {
  const LiveActionView({super.key});

  static const _roomName = 'White Room';
  static const _roomId = '25363';
  static const _viewerCount = '125';
  static const _announcement =
      'Announcement Enjaye the Talk and be respect';

  /// Figma: 1 center + 3 inner ring + 4 outer ring (8 listeners).
  static const _orbitParticipants = <_OrbitSeat>[
    _OrbitSeat('Afrin Sabila', 'ID-1245', '12', kImgTemp2, _SeatMic.active),
    _OrbitSeat('Afrin Sabila', 'ID-1245', '12', kImgTemp3, _SeatMic.muted),
    _OrbitSeat('Afrin Sabila', 'ID-1245', '12', kImgTemp4, _SeatMic.idle),
    _OrbitSeat('Afrin Sabila', 'ID-1245', '12', kImgTemp5, _SeatMic.muted),
    _OrbitSeat('Afrin Sabila', 'ID-1245', '12', kImgTemp2, _SeatMic.idle),
    _OrbitSeat('Afrin Sabila', 'ID-1245', '12', kImgTemp3, _SeatMic.muted),
    _OrbitSeat('Afrin Sabila', 'ID-1245', '12', kImgTemp4, _SeatMic.idle),
    _OrbitSeat('Afrin Sabila', 'ID-1245', '12', kImgTemp5, _SeatMic.muted),
  ];

  /// Alignment positions on the orbit stack (Figma concentric layout).
  static const _orbitSeatAlignments = <Alignment>[
    Alignment(0, 0.08),
    Alignment(-0.40, 0.30),
    Alignment(0, 0.40),
    Alignment(0.40, 0.30),
    Alignment(-0.72, 0.56),
    Alignment(-0.24, 0.72),
    Alignment(0.24, 0.72),
    Alignment(0.72, 0.56),
  ];

  static const _activityLines = <_ActivityLine>[
    _ActivityLine('Jessscia sent a flower', kImgTemp3, '🌸'),
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
            Spacing.v10,
            _roomActionPills(),
            Spacing.v4,
            Expanded(child: _stageArea(context)),
            _activityFeed(),
            Spacing.v8,
            const AppMockAdBannerWidget(provider: AdProvider.adMob),
            Spacing.v4,
            _bottomChatBar(context),
            SizedBox(height: MediaQuery.paddingOf(context).bottom + 88),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 10, 0),
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
          ClipOval(
            child: Image.asset(
              kImgTemp2,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          Spacing.h8,
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
          _headerIconButton(Icons.ios_share_rounded),
          Spacing.h6,
          _viewerPill(),
          Spacing.h6,
          _headerIconButton(Icons.power_settings_new_rounded),
        ],
      ),
    );
  }

  Widget _headerIconButton(IconData icon) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: LiveActionColors.pillFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: LiveActionColors.pillBorder, width: 0.8),
      ),
      child: Icon(icon, color: kColorWhite, size: 18),
    );
  }

  Widget _viewerPill() {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: LiveActionColors.pillFill,
        borderRadius: BorderRadius.circular(10),
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

  Widget _announcementBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
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
                fontSize: TextStyles.k10FontSize,
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

  Widget _roomActionPills() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(child: _actionPill('Room Set', Icons.settings_rounded)),
          Spacing.h10,
          Expanded(child: _actionPill('Ranking', Icons.calendar_month_rounded)),
        ],
      ),
    );
  }

  Widget _actionPill(String label, IconData icon) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: LiveActionColors.pillFill,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: LiveActionColors.pillBorder, width: 0.9),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kColorWhite, size: 16),
          const SizedBox(width: 5),
          Flexible(
            child: SemiBoldText(
              text: label,
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              align: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stageArea(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _openSeat(),
                  SizedBox(width: w * 0.08),
                  _hostSeat(),
                  SizedBox(width: w * 0.08),
                  _openSeat(),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  const Positioned.fill(
                    child: CustomPaint(
                      painter: _OrbitRingsPainter(),
                    ),
                  ),
                  for (var i = 0; i < _orbitSeatAlignments.length; i++)
                    Align(
                      alignment: _orbitSeatAlignments[i],
                      child: _orbitSeatTile(_orbitParticipants[i]),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _hostSeat() {
    return SizedBox(
      width: 76,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              const Positioned(
                top: -12,
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: LiveActionColors.crownGold,
                  size: 28,
                ),
              ),
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: kColorWhite, width: 2),
                ),
                child: ClipOval(
                  child: Image.asset(kImgTemp2, fit: BoxFit.cover),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: _micBadge(_SeatMic.active, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: LiveActionColors.pillFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: LiveActionColors.pillBorder, width: 0.6),
            ),
            child: const SemiBoldText(
              text: 'Host',
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _openSeat() {
    return SizedBox(
      width: 64,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LiveActionColors.openSeatFill,
              border: Border.all(
                color: kColorWhite.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: Icon(
              Icons.add_rounded,
              color: kColorWhite.withValues(alpha: 0.9),
              size: 28,
            ),
          ),
          Spacing.v6,
          AppText(
            text: 'Open Set',
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite.withValues(alpha: 0.9),
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _orbitSeatTile(_OrbitSeat seat) {
    return SizedBox(
      width: 52,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: kColorWhite.withValues(alpha: 0.75),
                      width: 1.2,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(seat.imageAsset, fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  left: -2,
                  top: -2,
                  child: _micBadge(seat.mic, size: 15),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          SemiBoldText(
            text: seat.name,
            fontSize: 9,
            color: kColorWhite,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            align: TextAlign.center,
          ),
          AppText(
            text: seat.idLabel,
            fontSize: 8,
            color: kColorWhite.withValues(alpha: 0.75),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            align: TextAlign.center,
          ),
          const SizedBox(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                kIconDiamond,
                width: 9,
                height: 9,
                colorFilter: const ColorFilter.mode(
                  LiveActionColors.diamondGold,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 2),
              SemiBoldText(
                text: seat.diamonds,
                fontSize: 8,
                color: LiveActionColors.diamondGold,
              ),
            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _activityLines
            .map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    ClipOval(
                      child: Image.asset(
                        line.avatarAsset,
                        width: 22,
                        height: 22,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Spacing.h8,
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyles.kRegularPoppins(
                            fontSize: TextStyles.k10FontSize,
                            colors: kColorWhite,
                          ),
                          children: [
                            TextSpan(
                              text: line.message,
                              style: TextStyles.kSemiBoldPoppins(
                                fontSize: TextStyles.k10FontSize,
                                colors: kColorWhite,
                              ),
                            ),
                            TextSpan(text: ' ${line.emoji} x1'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _bottomChatBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
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
          Spacing.h6,
          _giftButton(
            gradient: const [Color(0xFFE53935), Color(0xFFFFCA28)],
            icon: Icons.redeem_rounded,
          ),
        ],
      ),
    );
  }

  Widget _giftButton({
    required List<Color> gradient,
    required IconData icon,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
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

class _OrbitSeat {
  const _OrbitSeat(
    this.name,
    this.idLabel,
    this.diamonds,
    this.imageAsset,
    this.mic,
  );

  final String name;
  final String idLabel;
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

/// Three dashed concentric rings (Figma orbit stage).
class _OrbitRingsPainter extends CustomPainter {
  const _OrbitRingsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.38);
    final radii = <double>[
      size.width * 0.11,
      size.width * 0.27,
      size.width * 0.43,
    ];

    final paint = Paint()
      ..color = LiveActionColors.orbitLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    for (final r in radii) {
      _paintDashedCircle(canvas, center, r, paint);
    }
  }

  void _paintDashedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    const dashLength = 6.0;
    const gapLength = 5.0;
    final step = (dashLength + gapLength) / radius;
    var angle = 0.0;
    while (angle < 2 * math.pi) {
      final sweep = dashLength / radius;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        angle,
        sweep,
        false,
        paint,
      );
      angle += step;
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitRingsPainter oldDelegate) => false;
}
