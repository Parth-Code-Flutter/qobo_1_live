import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/theme/app_theme_colors.dart';
import 'package:qobo_one_live/theme/theme_context.dart';
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
  });

  final List<Map<String, dynamic>> rooms;
  final bool isLoading;
  final ValueChanged<Map<String, dynamic>>? onJoinLive;

  static const String roomLabel = 'Video Room';

  static const ColorFilter _whiteIcon = ColorFilter.mode(
    kColorWhite,
    BlendMode.srcIn,
  );

  static const _tileGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kColorVideoTileGradientStart, kColorVideoTileGradientEnd],
  );

  static const _previewGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kColorVideoPreviewGradientStart, kColorVideoPreviewGradientEnd],
  );

  static BoxDecoration accordionDecoration(
    AppThemeColors colors, {
    required bool expanded,
  }) {
    if (colors.isDark) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: _tileGradient,
        border: Border.all(
          color: expanded
              ? kColorVideoPreviewAccent.withValues(alpha: 0.65)
              : kColorWhite.withValues(alpha: 0.12),
          width: expanded ? 1.5 : 1,
        ),
        boxShadow: expanded
            ? [
                BoxShadow(
                  color: kColorVideoJoinLivePurple.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: kColorVideoPreviewAccent.withValues(alpha: 0.15),
                  blurRadius: 24,
                  spreadRadius: -4,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      );
    }
    return BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: expanded ? colors.chipSelected : colors.border,
        width: expanded ? 1.5 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

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

    final colors = context.appColors;
    final content = widget.isLoading
        ? Center(
            child: CircularProgressIndicator(
              color: kColorPrimary,
              strokeWidth: 2,
            ),
          )
        : tiles.isEmpty
        ? _VideoRoomsEmptyState(colors: colors)
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
            physics: const BouncingScrollPhysics(),
            itemCount: tiles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = tiles[index];
              return _VideoRoomAccordionTile(
                data: data,
                expanded: _expandedIndex == index,
                onToggle: () => _onTileTap(index),
                onJoinLive: widget.onJoinLive == null
                    ? null
                    : () => widget.onJoinLive!(data.room),
              );
            },
          );

    if (colors.isDark) {
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
        child: content,
      );
    }
    return content;
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
      title: title,
      hostName: hostName,
      category:
          _text(room['bio']) ?? _text(room['category']) ?? 'Live video stream',
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

class _VideoRoomsEmptyState extends StatelessWidget {
  const _VideoRoomsEmptyState({required this.colors});

  final AppThemeColors colors;

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
            SemiBoldText(
              text: 'No data found',
              fontSize: TextStyles.k16FontSize,
              color: colors.onHeroPrimary,
              align: TextAlign.center,
            ),
            Spacing.v6,
            AppText(
              text: 'Video rooms will appear here when available.',
              fontSize: TextStyles.k12FontSize,
              color: colors.onHeroMuted,
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
    final colors = context.appColors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: DiscoverVideoRoomView.accordionDecoration(
        colors,
        expanded: expanded,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CollapsedHeader(
            data: data,
            expanded: expanded,
            onTap: onToggle,
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
            secondChild: _ExpandedBody(
              data: data,
              onJoinLive: onJoinLive,
            ),
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
  });

  final _VideoRoomTileData data;
  final bool expanded;
  final VoidCallback onTap;

  static const double _thumbSize = 76;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final titleColor = colors.isDark ? kColorWhite : colors.onHeroPrimary;
    final mutedColor =
        colors.isDark ? kColorVideoSecondaryText : colors.onHeroSecondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: kColorVideoPreviewAccent.withValues(alpha: 0.2),
        highlightColor: colors.isDark
            ? kColorWhite.withValues(alpha: 0.06)
            : colors.surfaceMuted,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 10, expanded ? 10 : 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ThumbWithFrame(data: data, size: _thumbSize),
              Spacing.h12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SemiBoldText(
                            text: expanded
                                ? data.title
                                : '${data.title} LIVE 🔴',
                            fontSize: TextStyles.k16FontSize,
                            color: titleColor,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!expanded) ...[
                          Spacing.h4,
                          _ViewerMiniPill(count: data.viewerCountShort),
                        ],
                      ],
                    ),
                    Spacing.v4,
                    AppText(
                      text: data.category,
                      fontSize: TextStyles.k12FontSize,
                      color: mutedColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacing.v8,
                    Row(
                      children: [
                        _AvatarRing(path: data.avatar, size: 26),
                        Spacing.h8,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                text: data.hostName,
                                fontSize: TextStyles.k14FontSize,
                                color: titleColor,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              AppText(
                                text: 'Host',
                                fontSize: TextStyles.k12FontSize,
                                color: mutedColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Spacing.h6,
              _ExpandChevron(expanded: expanded),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandChevron extends StatelessWidget {
  const _ExpandChevron({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: colors.isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: expanded
                    ? [
                        kColorVideoJoinLivePurple,
                        kColorVideoJoinLiveGradientEnd,
                      ]
                    : [
                        kColorWhite.withValues(alpha: 0.14),
                        kColorWhite.withValues(alpha: 0.06),
                      ],
              )
            : null,
        color: colors.isDark ? null : colors.surfaceMuted,
        border: Border.all(
          color: expanded
              ? (colors.isDark
                  ? kColorVideoPreviewAccent.withValues(alpha: 0.5)
                  : colors.chipSelected)
              : (colors.isDark
                  ? kColorWhite.withValues(alpha: 0.15)
                  : colors.border),
        ),
      ),
      child: AnimatedRotation(
        turns: expanded ? 0.5 : 0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        child: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: colors.isDark
              ? kColorWhite.withValues(alpha: expanded ? 1 : 0.75)
              : colors.onHeroPrimary,
          size: 22,
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
        gradient: LinearGradient(
          colors: [
            kColorVideoPreviewAccent.withValues(alpha: 0.7),
            kColorVideoJoinLivePurple.withValues(alpha: 0.5),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _RoomImage(path: data.image, width: size, height: size),
            const Positioned(left: 6, top: 6, child: _LiveBadge(compact: true)),
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      kColorVideoJoinLivePurple,
                      kColorVideoJoinLiveGradientEnd,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: SvgPicture.asset(
                    kIconVideoCamera,
                    width: 13,
                    height: 13,
                    colorFilter: DiscoverVideoRoomView._whiteIcon,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarRing extends StatelessWidget {
  const _AvatarRing({required this.path, required this.size});

  final String path;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            kColorVideoPreviewAccent.withValues(alpha: 0.8),
            kColorVideoJoinLivePurple,
          ],
        ),
      ),
      child: ClipOval(
        child: _RoomImage(path: path, width: size, height: size),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kColorVideoViewerPillBg,
            kColorVideoJoinLivePurple.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: kColorVideoPreviewAccent.withValues(alpha: 0.35),
        ),
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
                  children: [
                    for (final tag in data.tags) _TagChip(label: tag),
                  ],
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
  const _PreviewFrame({
    required this.imagePath,
    required this.viewerCount,
  });

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
              const Positioned(left: 10, top: 10, child: _LiveBadge(compact: false)),
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
          colors: [
            kColorVideoJoinLivePurple,
            kColorVideoJoinLiveGradientEnd,
          ],
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
                Icon(Icons.play_circle_fill_rounded, color: kColorWhite, size: 22),
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
          child: Icon(
            Icons.videocam_rounded,
            color: kColorWhite,
            size: 32,
          ),
        ),
      ),
    );
  }
}
