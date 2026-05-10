import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Video Room discover feed matching Figma (featured hero + live list).
class DiscoverVideoRoomView extends StatelessWidget {
  const DiscoverVideoRoomView({super.key});

  static const String roomLabel = 'Video Room';

  static final _featured = (
    image: kImgTemp2,
    hostName: 'Sarah Jenkins',
    title: 'Late Night Vibes',
    viewerCountLabel: '12.5K',
  );

  static const _listItems =
      <
        ({
          String title,
          String hostName,
          String watchingLabel,
          String image,
          String avatar,
          List<String> tags,
        })
      >[
        (
          title: 'Late Night Talks',
          hostName: 'Riya Sharma',
          watchingLabel: '215 watching',
          image: kImgTemp3,
          avatar: kImgTemp4,
          tags: ['#Secret', '#Fun', '#Talk'],
        ),
        (
          title: 'Dating Advice',
          hostName: 'Riya Sharma',
          watchingLabel: '215 watching',
          image: kImgTemp4,
          avatar: kImgTemp5,
          tags: ['#Secret', '#Fun', '#Talk'],
        ),
        (
          title: 'Late Night Talks',
          hostName: 'Riya Sharma',
          watchingLabel: '215 watching',
          image: kImgTemp5,
          avatar: kImgTemp2,
          tags: ['#Secret', '#Fun', '#Talk'],
        ),
      ];

  static const ColorFilter _whiteIcon = ColorFilter.mode(
    kColorWhite,
    BlendMode.srcIn,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            kColorVideoRoomBgGradientTop,
            kColorVideoRoomBgGradientBottom,
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FeaturedLiveCard(data: _featured),
            const SizedBox(height: 14),
            ..._listItems.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _LiveStreamListTile(data: row),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef _FeaturedData = ({
  String image,
  String hostName,
  String title,
  String viewerCountLabel,
});

class _FeaturedLiveCard extends StatelessWidget {
  const _FeaturedLiveCard({required this.data});

  final _FeaturedData data;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(data.image, fit: BoxFit.cover),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.72),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(left: 12, top: 12, child: _liveBadge(compact: false)),
            Positioned(
              right: 12,
              top: 12,
              child: _viewerCountPillFeatured(data.viewerCountLabel),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  BoldText(
                    text: data.hostName,
                    fontSize: TextStyles.k18FontSize,
                    color: kColorWhite,
                  ),
                  Spacing.v4,
                  AppText(
                    text: data.title,
                    fontSize: TextStyles.k14FontSize,
                    color: kColorWhite.withValues(alpha: 0.92),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: Material(
                      color: kColorVideoJoinLivePurple,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(14),
                        child: const Center(
                          child: SemiBoldText(
                            text: 'Join Live',
                            fontSize: TextStyles.k14FontSize,
                            color: kColorWhite,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _liveBadge({required bool compact}) {
    final pad = compact
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 5)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 7);
    return Container(
      padding: pad,
      decoration: BoxDecoration(
        color: kColorVideoLiveBadgeRed,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            kIconVideoCamera,
            width: compact ? 11 : 13,
            height: compact ? 11 : 13,
            colorFilter: DiscoverVideoRoomView._whiteIcon,
          ),
          SizedBox(width: compact ? 5 : 6),
          SemiBoldText(
            text: 'Live',
            fontSize: compact ? TextStyles.k10FontSize : TextStyles.k12FontSize,
            color: kColorWhite,
          ),
        ],
      ),
    );
  }

  Widget _viewerCountPillFeatured(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kColorVideoViewerPillBg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            kIconEye,
            width: 14,
            height: 14,
            colorFilter: DiscoverVideoRoomView._whiteIcon,
          ),
          Spacing.h6,
          SemiBoldText(
            text: label,
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite,
          ),
        ],
      ),
    );
  }
}

typedef _ListTileData = ({
  String title,
  String hostName,
  String watchingLabel,
  String image,
  String avatar,
  List<String> tags,
});

class _LiveStreamListTile extends StatelessWidget {
  const _LiveStreamListTile({required this.data});

  final _ListTileData data;

  static const ColorFilter _whiteIcon = ColorFilter.mode(
    kColorWhite,
    BlendMode.srcIn,
  );

  @override
  Widget build(BuildContext context) {
    final thumbSize = 92.0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kColorVideoListTileBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: thumbSize,
            height: thumbSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    data.image,
                    width: thumbSize,
                    height: thumbSize,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(left: 6, top: 6, child: _miniLiveBadge()),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: kColorVideoThumbActionPurple,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        kIconVideoCamera,
                        width: 14,
                        height: 14,
                        colorFilter: _whiteIcon,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SemiBoldText(
                        text: data.title,
                        fontSize: TextStyles.k16FontSize,
                        color: kColorWhite,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.more_vert_rounded,
                      color: kColorWhite.withValues(alpha: 0.55),
                      size: 22,
                    ),
                  ],
                ),
                Spacing.v8,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipOval(
                      child: Image.asset(
                        data.avatar,
                        width: 26,
                        height: 26,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Spacing.h8,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            text: data.hostName,
                            fontSize: TextStyles.k14FontSize,
                            color: kColorWhite,
                          ),
                          AppText(
                            text: 'Host',
                            fontSize: TextStyles.k12FontSize,
                            color: kColorVideoSecondaryText,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Spacing.v8,
                Row(
                  children: [
                    SvgPicture.asset(
                      kIconUserPlus,
                      width: 14,
                      height: 14,
                      colorFilter: _whiteIcon,
                    ),
                    Spacing.h6,
                    Expanded(
                      child: AppText(
                        text: data.watchingLabel,
                        fontSize: TextStyles.k14FontSize,
                        color: kColorWhite,
                      ),
                    ),
                  ],
                ),
                Spacing.v10,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final tag in data.tags) _TagChip(label: tag)],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: kColorVideoLiveBadgeRed,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            kIconVideoCamera,
            width: 11,
            height: 11,
            colorFilter: _whiteIcon,
          ),
          const SizedBox(width: 4),
          const SemiBoldText(
            text: 'Live',
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite,
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: kColorVideoTagBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: AppText(
        text: label,
        fontSize: TextStyles.k12FontSize,
        color: kColorWhite.withValues(alpha: 0.9),
      ),
    );
  }
}
