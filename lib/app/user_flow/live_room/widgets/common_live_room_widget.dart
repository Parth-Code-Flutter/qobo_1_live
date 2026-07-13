import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/constants/live_room_ui_colors.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Reusable card for one live room in the listing grid.
class CommonLiveRoomWidget extends StatelessWidget {
  const CommonLiveRoomWidget({
    super.key,
    required this.imageUrl,
    required this.userNameAge,
    required this.badgeText,
    required this.locationText,
    required this.pointsText,
    this.isFavorite = false,
  });

  static const _radius = 16.0;

  final String imageUrl;
  final String userNameAge;
  final String badgeText;
  final String locationText;
  final String pointsText;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        clipBehavior: Clip.antiAlias,
        child: ColoredBox(
          color: LiveRoomUiColors.cardSurface,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: imageUrl.startsWith('http')
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: LiveRoomUiColors.cardSurface,
                        ),
                      )
                    : Image.asset(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: LiveRoomUiColors.cardSurface,
                        ),
                      ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.02),
                        Colors.black.withValues(alpha: 0.20),
                        Colors.black.withValues(alpha: 0.78),
                      ],
                      stops: const [0, 0.42, 1],
                    ),
                  ),
                ),
              ),
              const Positioned(left: 10, top: 10, child: _LiveBadge()),
              Positioned(right: 10, top: 10, child: _topBadge()),
              if (isFavorite)
                Positioned(
                  right: 10,
                  top: 48,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.34),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: kColorWhite.withValues(alpha: 0.16),
                      ),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.pinkAccent,
                      size: 16,
                    ),
                  ),
                ),
              Positioned(left: 8, right: 8, bottom: 8, child: _bottomInfo()),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(_radius),
                      border: Border.all(
                        color: kColorWhite.withValues(alpha: 0.10),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF541878).withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(kIconMedal, width: 16, height: 16),
          Spacing.h4,
          SemiBoldText(
            text: badgeText,
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _bottomInfo() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.10)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BoldText(
                text: userNameAge,
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Spacing.v6,
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF00E676),
                    size: 14,
                  ),
                  Spacing.h2,
                  Expanded(
                    child: AppText(
                      text: locationText,
                      fontSize: TextStyles.k10FontSize,
                      color: kColorWhite.withValues(alpha: 0.84),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Spacing.h6,
                  _HeatPill(pointsText: pointsText),
                ],
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: -20,
            child: SvgPicture.asset(kIconBadge, width: 19, height: 19),
          ),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    const liveGreen = Color(0xFF22C55E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: liveGreen.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: liveGreen.withValues(alpha: 0.35), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, color: kColorWhite, size: 7),
          Spacing.h4,
          SemiBoldText(
            text: 'LIVE',
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite,
          ),
        ],
      ),
    );
  }
}

class _HeatPill extends StatelessWidget {
  const _HeatPill({required this.pointsText});

  final String pointsText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: Color(0xFFFFC04D),
            size: 13,
          ),
          const SizedBox(width: 3),
          AppText(
            text: pointsText,
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
