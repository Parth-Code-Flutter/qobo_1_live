import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF302A5C), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
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
                      Colors.black.withAlpha(80),
                      Colors.black.withAlpha(130),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF541878).withAlpha(220),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium, color: Color(0xFFFFCC33), size: 14),
          const SizedBox(width: 4),
          SemiBoldText(
            text: badgeText,
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite,
          ),
        ],
      ),
    );
  }

  Widget _bottomInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BoldText(
          text: userNameAge,
          fontSize: TextStyles.k14FontSize,
          color: kColorWhite,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.location_on_outlined, color: Color(0xFF00E676), size: 14),
            const SizedBox(width: 2),
            AppText(
              text: locationText,
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite,
            ),
            const Spacer(),
            const Icon(Icons.wb_sunny_outlined, color: kColorWhite, size: 14),
            const SizedBox(width: 3),
            AppText(
              text: pointsText,
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite,
            ),
          ],
        ),
      ],
    );
  }
}
