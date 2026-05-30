import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// One video room row: same model for collapsed (compact) and expanded (hero).
typedef _VideoRoomTileData = ({
  String collapsedTitle,
  String hostName,
  String streamSubtitle,
  String watchingLabel,
  String viewerCountShort,
  String image,
  String avatar,
  List<String> tags,
});

/// Video Room discover feed: every tile expands to the hero layout on tap.
class DiscoverVideoRoomView extends StatefulWidget {
  const DiscoverVideoRoomView({
    super.key,
    this.rooms = const <Map<String, dynamic>>[],
    this.isLoading = false,
  });

  final List<Map<String, dynamic>> rooms;
  final bool isLoading;

  static const String roomLabel = 'Video Room';

  static const ColorFilter _whiteIcon = ColorFilter.mode(
    kColorWhite,
    BlendMode.srcIn,
  );

  @override
  State<DiscoverVideoRoomView> createState() => _DiscoverVideoRoomViewState();
}

class _DiscoverVideoRoomViewState extends State<DiscoverVideoRoomView> {
  /// Index of expanded tile, or `null` when all are collapsed.
  /// First tile starts expanded (Video Room default).
  int? _expandedIndex = 0;

  void _onTileTap(int index) {
    setState(() {
      if (_expandedIndex == index) {
        _expandedIndex = null;
      } else {
        _expandedIndex = index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tiles = List<_VideoRoomTileData>.generate(
      widget.rooms.length,
      (index) => _tileFromRoom(widget.rooms[index], index),
    );

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
      child: widget.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: kColorWhite,
                strokeWidth: 2,
              ),
            )
          : tiles.isEmpty
          ? const _VideoRoomsEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
              physics: const BouncingScrollPhysics(),
              itemCount: tiles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final data = tiles[index];
                final expanded = _expandedIndex == index;
                return _ExpandableVideoRoomTile(
                  data: data,
                  expanded: expanded,
                  onToggle: () => _onTileTap(index),
                );
              },
            ),
    );
  }

  _VideoRoomTileData _tileFromRoom(Map<String, dynamic> room, int index) {
    const fallbackImages = [kImgTemp2, kImgTemp3, kImgTemp4, kImgTemp5];
    final host = room['host'];
    final hostMap = host is Map ? host : const <String, dynamic>{};
    final title =
        _text(room['name']) ??
        _text(room['title']) ??
        _text(room['hostName']) ??
        'Live Video Room';
    final hostName =
        _text(room['hostName']) ??
        _text(hostMap['name']) ??
        _text(room['userName']) ??
        title;
    final viewers =
        _text(room['viewerCount']) ??
        _text(room['onlineCount']) ??
        _text(room['heatScore']) ??
        _text(room['audienceCount']) ??
        _text(room['watching']) ??
        _text(room['_count']) ??
        '0';
    final image =
        ApiImageUtils.normalize(
          _text(room['coverImage']) ??
              _text(room['image']) ??
              _text(room['thumbnail']) ??
              _text(room['poster']),
        ) ??
        fallbackImages[index % fallbackImages.length];
    final avatar =
        ApiImageUtils.normalize(
          _text(room['hostDisplayPicture']) ??
              _text(room['hostAvatar']) ??
              _text(hostMap['displayPicture']),
        ) ??
        fallbackImages[(index + 1) % fallbackImages.length];
    return (
      collapsedTitle: title,
      hostName: hostName,
      streamSubtitle:
          _text(room['bio']) ?? _text(room['category']) ?? 'Live video stream',
      watchingLabel: '$viewers watching',
      viewerCountShort: viewers,
      image: image,
      avatar: avatar,
      tags: [
        '#${(room['type']?.toString() ?? 'video').toUpperCase()}',
        if (_text(room['countryName']) != null) '#${room['countryName']}',
        if (_text(room['countryName']) == null &&
            _text(room['countryCode']) != null)
          '#${room['countryCode']}',
        if (_text(room['countryName']) == null &&
            _text(room['countryCode']) == null &&
            _text(room['country']) != null)
          '#${room['country']}',
      ],
    );
  }

  String? _text(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return null;
    return text;
  }
}

class _VideoRoomsEmptyState extends StatelessWidget {
  const _VideoRoomsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: kColorWhite.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.videocam_off_outlined,
                color: kColorWhite,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            const SemiBoldText(
              text: 'No data found',
              fontSize: TextStyles.k16FontSize,
              color: kColorWhite,
              align: TextAlign.center,
            ),
            Spacing.v6,
            AppText(
              text: 'Video rooms will appear here when available.',
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite.withValues(alpha: 0.72),
              align: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandableVideoRoomTile extends StatelessWidget {
  const _ExpandableVideoRoomTile({
    required this.data,
    required this.expanded,
    required this.onToggle,
  });

  final _VideoRoomTileData data;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: expanded
          ? _ExpandedHeroCard(data: data, onCollapse: onToggle)
          : _CollapsedTile(data: data, onExpand: onToggle),
    );
  }
}

/// Compact row — tap anywhere to expand.
class _CollapsedTile extends StatelessWidget {
  const _CollapsedTile({required this.data, required this.onExpand});

  final _VideoRoomTileData data;
  final VoidCallback onExpand;

  static const ColorFilter _whiteIcon = ColorFilter.mode(
    kColorWhite,
    BlendMode.srcIn,
  );

  @override
  Widget build(BuildContext context) {
    const thumbSize = 92.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onExpand,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
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
                      child: _RoomImage(
                        path: data.image,
                        width: thumbSize,
                        height: thumbSize,
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
                            text: data.collapsedTitle,
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
                          child: _RoomImage(
                            path: data.avatar,
                            width: 26,
                            height: 26,
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
                  ],
                ),
              ),
            ],
          ),
        ),
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

/// Hero card — tap image/overlay to collapse; Join Live does not collapse.
class _ExpandedHeroCard extends StatelessWidget {
  const _ExpandedHeroCard({required this.data, required this.onCollapse});

  final _VideoRoomTileData data;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: onCollapse,
              behavior: HitTestBehavior.opaque,
              child: _RoomImage(path: data.image, fit: BoxFit.cover),
            ),
            Positioned.fill(
              child: IgnorePointer(
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
            ),
            Positioned(
              left: 12,
              top: 12,
              child: GestureDetector(
                onTap: onCollapse,
                child: _liveBadgeFeatured(compact: false),
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: GestureDetector(
                onTap: onCollapse,
                child: _viewerCountPill(data.viewerCountShort),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: onCollapse,
                    behavior: HitTestBehavior.translucent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BoldText(
                          text: data.hostName,
                          fontSize: TextStyles.k18FontSize,
                          color: kColorWhite,
                        ),
                        Spacing.v4,
                        AppText(
                          text: data.streamSubtitle,
                          fontSize: TextStyles.k14FontSize,
                          color: kColorWhite.withValues(alpha: 0.92),
                        ),
                        if (data.tags.isNotEmpty) ...[
                          Spacing.v10,
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final tag in data.tags) _TagChip(label: tag),
                            ],
                          ),
                        ],
                      ],
                    ),
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

  Widget _liveBadgeFeatured({required bool compact}) {
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

  Widget _viewerCountPill(String label) {
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

class _RoomImage extends StatelessWidget {
  const _RoomImage({
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      width: width,
      height: height,
      color: kColorVideoListTileBg,
    );
  }
}
