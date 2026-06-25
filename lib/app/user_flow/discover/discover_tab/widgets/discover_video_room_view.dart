import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// One video room row for collapsed header + expanded body.
typedef _VideoRoomTileData = ({
  String title,
  String hostName,
  String category,
  String viewerCountShort,
  String image,
  String avatar,
  List<String> tags,
  Map<String, dynamic> room,
});

/// Video Room discover feed — accordion tiles (tap to expand / collapse).
class DiscoverVideoRoomView extends StatefulWidget {
  const DiscoverVideoRoomView({
    super.key,
    this.rooms = const <Map<String, dynamic>>[],
    this.isLoading = false,
    this.onJoinLive,
    this.onCreateVideoRoom,
  });

  final List<Map<String, dynamic>> rooms;
  final bool isLoading;
  final ValueChanged<Map<String, dynamic>>? onJoinLive;
  final VoidCallback? onCreateVideoRoom;

  static const String roomLabel = 'Video Room';

  static const ColorFilter _whiteIcon = ColorFilter.mode(
    kColorWhite,
    BlendMode.srcIn,
  );

  static const _previewGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kColorVideoPreviewGradientStart, kColorVideoPreviewGradientEnd],
  );

  @override
  State<DiscoverVideoRoomView> createState() => _DiscoverVideoRoomViewState();
}

class _DiscoverVideoRoomViewState extends State<DiscoverVideoRoomView> {
  int? _expandedIndex;

  void _onTileTap(int index) {
    setState(() {
      _expandedIndex = _expandedIndex == index ? null : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tiles = List<_VideoRoomTileData>.generate(
      widget.rooms.length,
      (index) => _tileFromRoom(widget.rooms[index], index),
    );

    return widget.isLoading
        ? const Center(
            child: CircularProgressIndicator(
              color: kColorWhite,
              strokeWidth: 2,
            ),
          )
        : tiles.isEmpty
        ? const _VideoRoomsEmptyState()
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
            physics: const BouncingScrollPhysics(),
            itemCount: tiles.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _CreateVideoRoomPanel(
                  liveCount: tiles.length,
                  onTap: widget.onCreateVideoRoom,
                );
              }
              final tileIndex = index - 1;
              final data = tiles[tileIndex];
              return _VideoRoomAccordionTile(
                data: data,
                expanded: _expandedIndex == tileIndex,
                onToggle: () => _onTileTap(tileIndex),
                onJoinLive: widget.onJoinLive == null
                    ? null
                    : () => widget.onJoinLive!(data.room),
              );
            },
          );
  }

  _VideoRoomTileData _tileFromRoom(Map<String, dynamic> room, int index) {
    const fallbackImages = [kImgTemp2, kImgTemp3, kImgTemp4, kImgTemp5];
    final host = room['host'];
    final hostMap = host is Map ? host : const <String, dynamic>{};
    final rawTags = room['tags'];
    final roomTags = rawTags is List
        ? rawTags
              .map((tag) => _text(tag))
              .whereType<String>()
              .map((tag) => tag.startsWith('#') ? tag : '#$tag')
              .toList()
        : const <String>[];
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
      title: title,
      hostName: hostName,
      category:
          _text(room['bio']) ?? _text(room['category']) ?? 'Live video stream',
      viewerCountShort: viewers,
      image: image,
      avatar: avatar,
      tags: [
        '#${(room['type']?.toString() ?? 'video').toUpperCase()}',
        ...roomTags,
        if (_text(room['countryName']) != null) '#${room['countryName']}',
        if (_text(room['countryName']) == null &&
            _text(room['countryCode']) != null)
          '#${room['countryCode']}',
        if (_text(room['countryName']) == null &&
            _text(room['countryCode']) == null &&
            _text(room['country']) != null)
          '#${room['country']}',
        if (_text(room['countryName']) == null &&
            _text(room['countryCode']) == null &&
            _text(room['country']) == null)
          '#Global',
      ],
      room: room,
    );
  }

  String? _text(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return null;
    return text;
  }
}

class _CreateVideoRoomPanel extends StatelessWidget {
  const _CreateVideoRoomPanel({required this.liveCount, this.onTap});

  final int liveCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kColorVideoJoinLivePurple.withValues(alpha: 0.92),
            kColorVideoPreviewGradientEnd.withValues(alpha: 0.95),
          ],
        ),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: kColorVideoJoinLivePurple.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kColorWhite.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kColorWhite.withValues(alpha: 0.12)),
            ),
            child: const Icon(Icons.add_rounded, color: kColorWhite, size: 28),
          ),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SemiBoldText(
                  text: 'Start a Video Room',
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Spacing.v4,
                AppText(
                  text: '$liveCount rooms live now',
                  fontSize: TextStyles.k12FontSize,
                  color: kColorWhite.withValues(alpha: 0.72),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Spacing.h10,
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: kColorWhite,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: const SemiBoldText(
                  text: 'Create',
                  fontSize: TextStyles.k12FontSize,
                  color: kColorPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
                gradient: const LinearGradient(
                  colors: [
                    kColorVideoPreviewGradientStart,
                    kColorVideoPreviewGradientEnd,
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: kColorVideoPreviewAccent.withValues(alpha: 0.4),
                ),
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

/// Single accordion card: header always visible; body animates open below.
class _VideoRoomAccordionTile extends StatelessWidget {
  const _VideoRoomAccordionTile({
    required this.data,
    required this.expanded,
    required this.onToggle,
    this.onJoinLive,
  });

  final _VideoRoomTileData data;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback? onJoinLive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: kColorWhite.withValues(alpha: 0.10),
        border: Border.all(
          color: expanded
              ? kColorVideoPreviewAccent.withValues(alpha: 0.42)
              : kColorWhite.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CollapsedHeader(
            data: data,
            expanded: expanded,
            onTap: onToggle,
            onJoinLive: onJoinLive,
          ),
          AnimatedCrossFade(
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeOutCubic,
            sizeCurve: Curves.easeOutCubic,
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 280),
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _ExpandedBody(data: data, onJoinLive: onJoinLive),
          ),
        ],
      ),
    );
  }
}

class _CollapsedHeader extends StatelessWidget {
  const _CollapsedHeader({
    required this.data,
    required this.expanded,
    required this.onTap,
    this.onJoinLive,
  });

  final _VideoRoomTileData data;
  final bool expanded;
  final VoidCallback onTap;
  final VoidCallback? onJoinLive;

  static const double _thumbSize = 64;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: kColorVideoPreviewAccent.withValues(alpha: 0.2),
        highlightColor: kColorWhite.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _ThumbWithFrame(data: data, size: _thumbSize),
                  Spacing.h10,
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 72),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SemiBoldText(
                            text: data.title,
                            fontSize: TextStyles.k14FontSize,
                            color: kColorWhite,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Spacing.v4,
                          AppText(
                            text: data.category,
                            fontSize: TextStyles.k12FontSize,
                            color: kColorVideoSecondaryText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Spacing.v6,
                          AppText(
                            text: data.hostName,
                            fontSize: TextStyles.k12FontSize,
                            color: kColorWhite.withValues(alpha: 0.84),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 0,
                top: 0,
                child: _ViewerMiniPill(count: data.viewerCountShort),
              ),
              Positioned(
                right: 0,
                bottom: 3,
                child: _SimpleJoinButton(onTap: onJoinLive ?? onTap),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimpleJoinButton extends StatelessWidget {
  const _SimpleJoinButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 34,
        width: 68,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kColorVideoJoinLivePurple, kColorVideoJoinLiveGradientEnd],
          ),
          borderRadius: BorderRadius.circular(17),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_arrow_rounded, color: kColorWhite, size: 18),
            Spacing.h2,
            const SemiBoldText(
              text: 'Join',
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThumbWithFrame extends StatelessWidget {
  const _ThumbWithFrame({required this.data, required this.size});

  final _VideoRoomTileData data;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: kColorWhite.withValues(alpha: 0.14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _RoomImage(path: data.image, width: size, height: size),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.30),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 6,
              bottom: 6,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: kColorWhite.withValues(alpha: 0.92),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 5,
                    ),
                  ],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.videocam_rounded,
                  color: kColorVideoJoinLivePurple,
                  size: 12,
                ),
              ),
            ),
            Positioned(
              left: 6,
              bottom: 7,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: kColorVideoLiveBadgeRed,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kColorVideoLiveBadgeRed.withValues(alpha: 0.45),
                      blurRadius: 5,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewerMiniPill extends StatelessWidget {
  const _ViewerMiniPill({required this.count});

  final String count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            kIconEye,
            width: 12,
            height: 12,
            colorFilter: DiscoverVideoRoomView._whiteIcon,
          ),
          const SizedBox(width: 4),
          SemiBoldText(
            text: count,
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite,
          ),
        ],
      ),
    );
  }
}

class _ExpandedBody extends StatelessWidget {
  const _ExpandedBody({required this.data, this.onJoinLive});

  final _VideoRoomTileData data;
  final VoidCallback? onJoinLive;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  kColorVideoPreviewAccent.withValues(alpha: 0.45),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PreviewFrame(
                imagePath: data.image,
                viewerCount: data.viewerCountShort,
              ),
              const SizedBox(height: 14),
              if (data.tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final tag in data.tags) _TagChip(label: tag)],
                ),
              if (data.tags.isNotEmpty) Spacing.v12,
              _JoinLiveButton(onTap: onJoinLive),
            ],
          ),
        ),
      ],
    );
  }
}

/// Preview area with purple gradient base so empty/failed images match the app.
class _PreviewFrame extends StatelessWidget {
  const _PreviewFrame({required this.imagePath, required this.viewerCount});

  final String imagePath;
  final String viewerCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            kColorVideoPreviewAccent.withValues(alpha: 0.55),
            kColorVideoJoinLivePurple.withValues(alpha: 0.35),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: kColorVideoJoinLivePurple.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: DiscoverVideoRoomView._previewGradient,
                ),
              ),
              const _PreviewDecorations(),
              _RoomImage(path: imagePath, fit: BoxFit.cover),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      kColorVideoPreviewGradientStart.withValues(alpha: 0.35),
                      Colors.transparent,
                      kColorVideoRoomBgGradientBottom.withValues(alpha: 0.55),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
              const Positioned(
                left: 10,
                top: 10,
                child: _LiveBadge(compact: false),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: _ViewerMiniPill(count: viewerCount),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Soft glow orbs behind preview when stream thumb is missing.
class _PreviewDecorations extends StatelessWidget {
  const _PreviewDecorations();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: -20,
          top: -10,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kColorVideoPreviewAccent.withValues(alpha: 0.22),
            ),
          ),
        ),
        Positioned(
          left: -16,
          bottom: -24,
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kColorVideoJoinLiveGradientEnd.withValues(alpha: 0.2),
            ),
          ),
        ),
        Center(
          child: Icon(
            Icons.live_tv_rounded,
            size: 48,
            color: kColorWhite.withValues(alpha: 0.18),
          ),
        ),
      ],
    );
  }
}

class _JoinLiveButton extends StatelessWidget {
  const _JoinLiveButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [kColorVideoJoinLivePurple, kColorVideoJoinLiveGradientEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: kColorVideoJoinLivePurple.withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.play_circle_fill_rounded,
                  color: kColorWhite,
                  size: 22,
                ),
                SizedBox(width: 8),
                SemiBoldText(
                  text: 'Join Live',
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: kColorVideoLiveBadgeRed,
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: kColorVideoLiveBadgeRed.withValues(alpha: 0.45),
            blurRadius: compact ? 4 : 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            kIconVideoCamera,
            width: compact ? 10 : 12,
            height: compact ? 10 : 12,
            colorFilter: DiscoverVideoRoomView._whiteIcon,
          ),
          SizedBox(width: compact ? 4 : 5),
          SemiBoldText(
            text: 'Live',
            fontSize: compact ? TextStyles.k10FontSize : TextStyles.k12FontSize,
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
        gradient: LinearGradient(
          colors: [
            kColorVideoTagBg,
            kColorVideoJoinLivePurple.withValues(alpha: 0.65),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: kColorVideoPreviewAccent.withValues(alpha: 0.35),
        ),
      ),
      child: AppText(
        text: label,
        fontSize: TextStyles.k12FontSize,
        color: kColorWhite.withValues(alpha: 0.92),
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
    return SizedBox(
      width: width,
      height: height,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: DiscoverVideoRoomView._previewGradient,
        ),
        child: Center(
          child: Icon(Icons.videocam_rounded, color: kColorWhite, size: 32),
        ),
      ),
    );
  }
}
