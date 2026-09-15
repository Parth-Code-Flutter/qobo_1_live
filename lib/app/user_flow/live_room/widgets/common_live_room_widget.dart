import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
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

  static const _radius = 14.0;

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
        color: AppLightUi.card,
        border: Border.all(color: AppLightUi.border),
        boxShadow: AppLightUi.cardShadow,
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
                          color: AppLightUi.cardSoft,
                        ),
                      )
                    : Image.asset(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: AppLightUi.cardSoft,
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
                        Colors.black.withValues(alpha: 0.04),
                        Colors.black.withValues(alpha: 0.08),
                        Colors.black.withValues(alpha: 0.78),
                      ],
                      stops: const [0, 0.48, 1],
                    ),
                  ),
                ),
              ),
              // Subtle top gloss for dating-app polish.
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 48,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          kColorWhite.withValues(alpha: 0.14),
                          kColorWhite.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Positioned(left: 8, top: 8, child: _LiveBadge()),
              if (badgeText.trim().isNotEmpty)
                Positioned(right: 8, top: 8, child: _topBadge()),
              if (isFavorite)
                Positioned(
                  right: 8,
                  top: 40,
                  child: Container(
                    width: 26,
                    height: 26,
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
                      size: 14,
                    ),
                  ),
                ),
              Positioned(left: 6, right: 6, bottom: 6, child: _bottomInfo()),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(_radius),
                      border: Border.all(
                        color: AppLightUi.borderStrong.withValues(alpha: 0.55),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppLightUi.violet.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(kIconMedal, width: 13, height: 13),
          Spacing.h2,
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
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.10)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              BoldText(
                text: userNameAge,
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Spacing.v4,
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF00E676),
                    size: 12,
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
                  Spacing.h4,
                  _HeatPill(pointsText: pointsText),
                ],
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: -16,
            child: SvgPicture.asset(kIconBadge, width: 16, height: 16),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: liveGreen.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppLightUi.title.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, color: kColorWhite, size: 6),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: Color(0xFFFFC04D),
            size: 12,
          ),
          const SizedBox(width: 2),
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
