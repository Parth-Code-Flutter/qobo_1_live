import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/constants/leader_board_colors.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/leader_board_controller.dart';
import '../models/leader_board_models.dart';

/// Full-screen leaderboard: podium top 3 + “Running up” list (light theme).
class LeaderBoardView extends GetView<LeaderBoardController> {
  const LeaderBoardView({super.key});

  static const double _centerAvatar = 104;
  static const double _sideAvatar = 76;
  static const double _rankBadgeSize = 28;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LeaderBoardColors.gradientTop,
      appBar: CommonAppBarWidget(
        title: 'Leaderboard',
        actions: [
          IconButton(
            onPressed: () {},
            icon: SvgPicture.asset(
              kIconFilter,
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                kColorWhite,
                BlendMode.srcIn,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              LeaderBoardColors.gradientTop,
              LeaderBoardColors.gradientBottom,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (LeaderBoardController.podium.isEmpty &&
                  LeaderBoardController.runningUp.isEmpty)
                const _LeaderBoardEmptyState()
              else ...[
                if (LeaderBoardController.podium.length >= 3)
                  _podiumSection(context),
                Spacing.v24,
                _runningUpHeader(),
                Spacing.v12,
                if (LeaderBoardController.runningUp.isEmpty)
                  const _LeaderBoardEmptyState()
                else
                  ...LeaderBoardController.runningUp.map(_runningRow),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _podiumSection(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _podiumColumn(
              user: LeaderBoardController.podium[0],
              avatarDiameter: _sideAvatar,
              lift: 28,
            ),
          ),
          Expanded(
            flex: 2,
            child: _podiumCenterColumn(user: LeaderBoardController.podium[1]),
          ),
          Expanded(
            child: _podiumColumn(
              user: LeaderBoardController.podium[2],
              avatarDiameter: _sideAvatar,
              lift: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _podiumCenterColumn({required LeaderBoardPodiumUser user}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _starRow(),
        const SizedBox(height: 6),
        _rankBadge(user.rank),
        const SizedBox(height: 8),
        _avatarRing(
          diameter: _centerAvatar,
          imageAsset: user.imageAsset,
          ringWidth: 3,
        ),
        Spacing.v10,
        SemiBoldText(
          text: user.name,
          fontSize: TextStyles.k16FontSize,
          color: AppLightUi.title,
          align: TextAlign.center,
        ),
      ],
    );
  }

  Widget _podiumColumn({
    required LeaderBoardPodiumUser user,
    required double avatarDiameter,
    required double lift,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: lift),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _rankBadge(user.rank),
          const SizedBox(height: 8),
          _avatarRing(
            diameter: avatarDiameter,
            imageAsset: user.imageAsset,
            ringWidth: 2,
          ),
          Spacing.v10,
          SemiBoldText(
            text: user.name,
            fontSize: TextStyles.k14FontSize,
            color: AppLightUi.title,
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _starRow() {
    return SizedBox(
      height: 26,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < 5; i++)
            Positioned(
              left: -36 + i * 18.0,
              top: 4 + 6 * math.sin((i - 2) * 0.55),
              child: Icon(
                Icons.star_rounded,
                size: 20,
                color: LeaderBoardColors.rankBadgeGold.withValues(alpha: 0.95),
              ),
            ),
        ],
      ),
    );
  }

  Widget _rankBadge(int rank) {
    final label = rank.toString().padLeft(2, '0');
    return Container(
      width: _rankBadgeSize,
      height: _rankBadgeSize,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppLightUi.gold, Color(0xFFFF8A48)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppLightUi.gold.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyles.kSemiBoldPoppins(
          fontSize: TextStyles.k12FontSize,
          colors: LeaderBoardColors.rankBadgeText,
        ),
      ),
    );
  }

  Widget _avatarRing({
    required double diameter,
    required String imageAsset,
    required double ringWidth,
  }) {
    return Container(
      width: diameter + ringWidth * 2,
      height: diameter + ringWidth * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppLightUi.pinkSoft.withValues(alpha: 0.85),
          width: ringWidth,
        ),
        boxShadow: AppLightUi.cardShadow,
      ),
      child: Center(
        child: ClipOval(
          child: Image.asset(
            imageAsset,
            width: diameter,
            height: diameter,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _runningUpHeader() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: SemiBoldText(
        text: 'Running Up',
        fontSize: TextStyles.k16FontSize,
        color: AppLightUi.title,
      ),
    );
  }

  Widget _runningRow(LeaderBoardListEntry e) {
    final bg = e.highlighted
        ? LeaderBoardColors.listRowHighlightBg
        : LeaderBoardColors.listCardBg;
    final rankColor = e.highlighted
        ? LeaderBoardColors.listRowHighlightText
        : AppLightUi.title;
    final nameColor = e.highlighted
        ? LeaderBoardColors.listRowHighlightText
        : AppLightUi.title;
    final subColor = e.highlighted
        ? LeaderBoardColors.listRowHighlightSub
        : AppLightUi.subtitle;
    final pointsColor = e.highlighted
        ? LeaderBoardColors.listRowHighlightText
        : AppLightUi.pink;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: bg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: e.highlighted
                ? AppLightUi.pinkSoft.withValues(alpha: 0.55)
                : AppLightUi.border,
          ),
        ),
        shadowColor: AppLightUi.title.withValues(alpha: 0.08),
        child: InkWell(
          onTap: () {},
          customBorder: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: SemiBoldText(
                    text: e.displayRank.toString().padLeft(2, '0'),
                    fontSize: TextStyles.k14FontSize,
                    color: rankColor,
                  ),
                ),
                ClipOval(
                  child: Image.asset(
                    e.imageAsset,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                ),
                Spacing.h10,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SemiBoldText(
                        text: e.name,
                        fontSize: TextStyles.k14FontSize,
                        color: nameColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Spacing.v2,
                      AppText(
                        text: e.subtitle,
                        fontSize: TextStyles.k12FontSize,
                        color: subColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SemiBoldText(
                    text: e.points,
                    fontSize: TextStyles.k14FontSize,
                    color: pointsColor,
                    align: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaderBoardEmptyState extends StatelessWidget {
  const _LeaderBoardEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 80),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: AppLightUi.cardDecoration(radius: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            color: AppLightUi.gold.withValues(alpha: 0.9),
            size: 56,
          ),
          Spacing.v12,
          const SemiBoldText(
            text: 'No data found',
            fontSize: TextStyles.k16FontSize,
            color: AppLightUi.title,
            align: TextAlign.center,
          ),
          Spacing.v6,
          const AppText(
            text: 'Leaderboard rankings will appear here when available.',
            fontSize: TextStyles.k12FontSize,
            color: AppLightUi.subtitle,
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
