import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/constants/live_room_ui_colors.dart';
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
  String country,
  List<String> tags,
  Map<String, dynamic> room,
});

/// Video room feed with image-first cards for a dating-style browse feel.
class VideoRoomListView extends StatefulWidget {
  const VideoRoomListView({
    super.key,
    this.rooms = const <Map<String, dynamic>>[],
    this.isLoading = false,
    this.onJoinLive,
    this.onCreateVideoRoom,
    this.onRefresh,
    this.showCreatePanel = true,
  });

  final List<Map<String, dynamic>> rooms;
  final bool isLoading;
  final ValueChanged<Map<String, dynamic>>? onJoinLive;
  final VoidCallback? onCreateVideoRoom;
  final Future<void> Function()? onRefresh;
  final bool showCreatePanel;

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
  State<VideoRoomListView> createState() => _VideoRoomListViewState();
}

class _VideoRoomListViewState extends State<VideoRoomListView> {
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
        : RefreshIndicator(
            color: kColorPrimary,
            backgroundColor: LiveRoomUiColors.screenGradientBottom,
            onRefresh: widget.onRefresh ?? () async {},
            child: CustomScrollView(
              slivers: [
                if (widget.showCreatePanel)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                    sliver: SliverToBoxAdapter(
                      child: _CreateVideoRoomPanel(
                        liveCount: tiles.length,
                        onTap: widget.onCreateVideoRoom,
                      ),
                    ),
                  ),
                if (tiles.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _VideoRoomsEmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final data = tiles[index];
                        return _VideoRoomAccordionTile(
                          data: data,
                          onJoinLive: widget.onJoinLive == null
                              ? null
                              : () => widget.onJoinLive!(data.room),
                        );
                      }, childCount: tiles.length),
                    ),
                  ),
              ],
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
            ),
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
      country:
          _text(room['countryCode']) ??
          _text(room['country']) ??
          _text(room['countryName']) ??
          'GLOBAL',
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

/// Image-first card inspired by social/dating video room grids.
class _VideoRoomAccordionTile extends StatelessWidget {
  const _VideoRoomAccordionTile({required this.data, this.onJoinLive});

  final _VideoRoomTileData data;
  final VoidCallback? onJoinLive;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onJoinLive,
        splashColor: kColorWhite.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                kColorWhite.withValues(alpha: 0.18),
                kColorWhite.withValues(alpha: 0.06),
              ],
            ),
            border: Border.all(color: kColorWhite.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _RoomImage(path: data.image),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.10),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.82),
                    ],
                    stops: const [0, 0.45, 1],
                  ),
                ),
              ),
              Positioned(
                left: 10,
                top: 10,
                child: _CountryBadge(label: data.country),
              ),
              Positioned(
                right: 9,
                top: 9,
                child: _ViewerMiniPill(count: data.viewerCountShort),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RoomTypeChip(
                      label: data.tags.isNotEmpty
                          ? data.tags.first.replaceFirst('#', '')
                          : VideoRoomListView.roomLabel,
                    ),
                    Spacing.v8,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SemiBoldText(
                                text: data.title,
                                fontSize: TextStyles.k14FontSize,
                                color: kColorWhite,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Spacing.v2,
                              AppText(
                                text: data.hostName,
                                fontSize: TextStyles.k10FontSize,
                                color: kColorWhite.withValues(alpha: 0.82),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Spacing.h8,
                        _FloatingJoinButton(onTap: onJoinLive),
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
}

class _CountryBadge extends StatelessWidget {
  const _CountryBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final display = label.trim().toUpperCase();
    return Container(
      constraints: const BoxConstraints(maxWidth: 58),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.16)),
      ),
      child: AppText(
        text: display.length > 6 ? display.substring(0, 6) : display,
        fontSize: TextStyles.k10FontSize,
        color: kColorWhite,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        align: TextAlign.center,
      ),
    );
  }
}

class _RoomTypeChip extends StatelessWidget {
  const _RoomTypeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B4BFF), Color(0xFFFF4FA7)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: kColorVideoJoinLivePurple.withValues(alpha: 0.35),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_rounded, color: kColorWhite, size: 12),
          Spacing.h4,
          SemiBoldText(
            text: label.toLowerCase().contains('audio')
                ? 'Audio Room'
                : 'Video Room',
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite,
          ),
        ],
      ),
    );
  }
}

class _FloatingJoinButton extends StatelessWidget {
  const _FloatingJoinButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [kColorVideoJoinLivePurple, kColorVideoJoinLiveGradientEnd],
          ),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: kColorVideoJoinLivePurple.withValues(alpha: 0.45),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.play_arrow_rounded,
          color: kColorWhite,
          size: 25,
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
            colorFilter: VideoRoomListView._whiteIcon,
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

class _RoomImage extends StatelessWidget {
  const _RoomImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() {
    return const DecoratedBox(
      decoration: BoxDecoration(gradient: VideoRoomListView._previewGradient),
      child: Center(
        child: Icon(Icons.videocam_rounded, color: kColorWhite, size: 32),
      ),
    );
  }
}
