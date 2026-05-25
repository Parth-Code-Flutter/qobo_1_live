import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
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

  final String imageUrl;
  final String userNameAge;
  final String badgeText;
  final String locationText;
  final String pointsText;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF302A5C), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: imageUrl.startsWith('http')
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFF241D4D)),
                    )
                  : Image.asset(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFF241D4D)),
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
                      Colors.black.withValues(alpha: 0.72),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: _topBadge(),
            ),
            if (isFavorite)
              const Positioned(
                right: 10,
                top: 56,
                child: Icon(Icons.favorite, color: Colors.pinkAccent, size: 14),
              ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: _bottomInfo(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF541878).withValues(alpha: 0.92),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            kIconMedal,
            width: 16,
            height: 16,
          ),
          Spacing.h4,
          SemiBoldText(
            text: badgeText,
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite,
          ),
        ],
      ),
    );
  }

  Widget _bottomInfo() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BoldText(
              text: userNameAge,
              fontSize: TextStyles.k14FontSize,
              color: kColorWhite,
            ),
        Spacing.v4,
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Color(0xFF00E676), size: 14),
                Spacing.h2,
                AppText(
                  text: locationText,
                  fontSize: TextStyles.k12FontSize,
                  color: kColorWhite,
                ),
                const Spacer(),
                const Icon(
                  Icons.wb_sunny_outlined,
                  color: kColorWhite,
                  size: 18,
                ),
                Spacing.h4,
                AppText(
                  text: pointsText,
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite,
                ),
              ],
            ),
          ],
        ),
        Positioned(
          right: 0,
          top: -6,
          child: SvgPicture.asset(
            kIconBadge,
            width: 18,
            height: 18,
          ),
        ),
      ],
    );
  }
}
