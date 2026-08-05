import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/constants/live_room_ui_colors.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/app_widgets/rooms_empty_state.dart';
import 'package:qobo_one_live/utils/geo/country_flag_utils.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Parsed card model for the video-room browse grid.
typedef _VideoRoomTileData = ({
  String title,
  String hostName,
  String viewerCountShort,
  String image,
  String avatar,
  String? frameUrl,
  String? countryFlag,
  String? countryLabel,
  Map<String, dynamic> room,
});

/// Video rooms listing — clean Bigo / party-room style 2-column grid.
///
/// Cover-first cards, small framed host avatars at the bottom, and a simple
/// people-count pill (no overlapping chips or giant center crowns).
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

  static const _previewGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A1548), Color(0xFF12081F)],
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

    if (widget.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: kColorWhite, strokeWidth: 2),
      );
    }

    return RefreshIndicator(
      color: kColorPrimary,
      backgroundColor: LiveRoomUiColors.screenGradientBottom,
      onRefresh: widget.onRefresh ?? () async {},
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          if (widget.showCreatePanel)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
              sliver: SliverToBoxAdapter(
                child: _CreateVideoRoomPanel(
                  liveCount: tiles.length,
                  onTap: widget.onCreateVideoRoom,
                ),
              ),
            ),
          if (tiles.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _VideoRoomsEmptyState(
                onCreate: widget.onCreateVideoRoom,
              ),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    const Expanded(
                      child: SemiBoldText(
                        text: 'Live now',
                        fontSize: TextStyles.k16FontSize,
                        color: kColorWhite,
                      ),
                    ),
                    AppText(
                      text:
                          '${tiles.length} ${tiles.length == 1 ? 'room' : 'rooms'}',
                      fontSize: TextStyles.k12FontSize,
                      color: kColorWhite.withValues(alpha: 0.55),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 28),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final data = tiles[index];
                    return _VideoRoomCard(
                      data: data,
                      onJoin: widget.onJoinLive == null
                          ? null
                          : () => widget.onJoinLive!(data.room),
                    );
                  },
                  childCount: tiles.length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  _VideoRoomTileData _tileFromRoom(Map<String, dynamic> room, int index) {
    const fallbackImages = [kImgTemp2, kImgTemp3, kImgTemp4, kImgTemp5];
    final host = room['host'];
    final hostMap = host is Map ? host : const <String, dynamic>{};
    final nestedRoom = room['roomData'];
    final nestedMap = nestedRoom is Map
        ? Map<String, dynamic>.from(nestedRoom)
        : const <String, dynamic>{};

    final title =
        _text(room['name']) ??
        _text(room['title']) ??
        _text(nestedMap['name']) ??
        _text(room['hostName']) ??
        'Video Room';
    final hostName =
        _text(room['hostName']) ??
        _text(hostMap['name']) ??
        _text(nestedMap['hostName']) ??
        'Host';
    final viewers =
        _formatViewers(
          _text(room['viewerCount']) ??
              _text(room['onlineCount']) ??
              _text(room['heatScore']) ??
              _text(room['audienceCount']) ??
              _text(nestedMap['viewerCount']) ??
              '0',
        );

    final image =
        ApiImageUtils.normalize(
          _firstNonEmpty([
            room['backgroundImage'],
            room['background_image'],
            room['backgroundUrl'],
            room['background_url'],
            room['background'],
            nestedMap['backgroundImage'],
            nestedMap['backgroundUrl'],
            nestedMap['background_url'],
            room['coverImage'],
            room['image'],
            room['thumbnail'],
            room['poster'],
            nestedMap['coverImage'],
          ]),
        ) ??
        fallbackImages[index % fallbackImages.length];

    final avatar =
        ApiImageUtils.normalize(
          _firstNonEmpty([
            room['hostDisplayPicture'],
            room['hostAvatar'],
            hostMap['displayPicture'],
            hostMap['avatar'],
            nestedMap['hostDisplayPicture'],
            nestedMap['hostAvatar'],
          ]),
        ) ??
        fallbackImages[(index + 1) % fallbackImages.length];

    final frameUrl = ApiImageUtils.normalize(
      _readFrameUrl(room['avatarFrame']) ??
          _readFrameUrl(room['avatarFrameUrl']) ??
          _readFrameUrl(hostMap['avatarFrame']) ??
          _readFrameUrl(hostMap['avatarFrameUrl']) ??
          _readFrameUrl(nestedMap['avatarFrame']) ??
          _readFrameUrl(nestedMap['hostAvatarFrame']) ??
          _readFrameUrl(nestedMap['hostAvatarFrameUrl']),
    );

    final countryRaw = _firstNonEmpty([
      room['countryCode'],
      room['country'],
      room['countryName'],
      hostMap['countryCode'],
      hostMap['country'],
      nestedMap['countryCode'],
      nestedMap['country'],
      nestedMap['countryName'],
    ]);
    final country = CountryFlagUtils.resolve(countryRaw);

    return (
      title: title,
      hostName: hostName,
      viewerCountShort: viewers,
      image: image,
      avatar: avatar,
      frameUrl: frameUrl,
      countryFlag: country?.emoji,
      countryLabel: country?.label,
      room: room,
    );
  }

  String _formatViewers(String raw) {
    final n = int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), ''));
    if (n == null) return raw;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(n >= 10000 ? 0 : 1)}K';
    return '$n';
  }

  String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = _text(value);
      if (text != null) return text;
    }
    return null;
  }

  String? _readFrameUrl(dynamic frame) {
    if (frame == null) return null;
    if (frame is String) return _text(frame);
    if (frame is Map) {
      return _firstNonEmpty([
        frame['image'],
        frame['imageUrl'],
        frame['url'],
        frame['frameUrl'],
        frame['svga'],
      ]);
    }
    return _text(frame);
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF7A1E63), Color(0xFFB8328A)],
            ),
            border: Border.all(color: kColorWhite.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              const Icon(Icons.videocam_rounded, color: kColorWhite, size: 22),
              Spacing.h10,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SemiBoldText(
                      text: 'Start video room',
                      fontSize: TextStyles.k14FontSize,
                      color: kColorWhite,
                    ),
                    AppText(
                      text: '$liveCount live now',
                      fontSize: TextStyles.k10FontSize,
                      color: kColorWhite.withValues(alpha: 0.72),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: kColorWhite,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const SemiBoldText(
                  text: 'Create',
                  fontSize: TextStyles.k12FontSize,
                  color: kColorPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoRoomsEmptyState extends StatelessWidget {
  const _VideoRoomsEmptyState({this.onCreate});

  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    return RoomsEmptyState(
      icon: Icons.videocam_rounded,
      title: 'No video rooms yet',
      subtitle:
          'Go live on camera and your room shows up here for everyone '
          'browsing right now.',
      accentColors: const [Color(0xFFFF4DC4), Color(0xFFFF6A3D)],
      ctaLabel: onCreate == null ? null : 'Start video room',
      onCta: onCreate,
    );
  }
}

/// Cover-first party-room card (Bigo-style hierarchy).
class _VideoRoomCard extends StatelessWidget {
  const _VideoRoomCard({required this.data, this.onJoin});

  final _VideoRoomTileData data;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onJoin,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _CoverImage(path: data.image),
                // Soft bottom scrim only — keeps the cover readable.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x14000000),
                        Color(0x00000000),
                        Color(0x99000000),
                        Color(0xE6080612),
                      ],
                      stops: [0, 0.35, 0.68, 1],
                    ),
                  ),
                ),
                // LIVE — top left, compact. Country flag sits beside it.
                Positioned(
                  left: 8,
                  top: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _LiveDot(),
                      if (data.countryFlag != null) ...[
                        const SizedBox(width: 6),
                        _CountryFlagChip(
                          flag: data.countryFlag!,
                          label: data.countryLabel ?? '',
                        ),
                      ],
                    ],
                  ),
                ),
                // Viewers — top right, glass pill (people icon, not eye).
                Positioned(
                  right: 8,
                  top: 8,
                  child: _ViewerCount(count: data.viewerCountShort),
                ),
                // Host + title — bottom only (no overlapping mid chips).
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _HostFrame(
                        name: data.hostName,
                        avatar: data.avatar,
                        frameUrl: data.frameUrl,
                      ),
                      Spacing.h8,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SemiBoldText(
                              text: data.title,
                              fontSize: TextStyles.k12FontSize,
                              color: kColorWhite,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Spacing.v2,
                            AppText(
                              text: data.hostName,
                              fontSize: TextStyles.k10FontSize,
                              color: kColorWhite.withValues(alpha: 0.72),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE13434),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const SemiBoldText(
        text: 'LIVE',
        fontSize: TextStyles.k10FontSize,
        color: kColorWhite,
      ),
    );
  }
}

class _CountryFlagChip extends StatelessWidget {
  const _CountryFlagChip({required this.flag, required this.label});

  final String flag;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(flag, style: const TextStyle(fontSize: 12, height: 1)),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 4),
            SemiBoldText(
              text: label,
              fontSize: TextStyles.k10FontSize,
              color: kColorWhite.withValues(alpha: 0.92),
            ),
          ],
        ],
      ),
    );
  }
}

/// Clean viewer count — soft glass + people icon (replaces messy eye pill).
class _ViewerCount extends StatelessWidget {
  const _ViewerCount({required this.count});

  final String count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_alt_rounded,
            size: 12,
            color: kColorWhite.withValues(alpha: 0.90),
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

/// Compact framed host avatar for the card footer.
class _HostFrame extends StatelessWidget {
  const _HostFrame({
    required this.name,
    required this.avatar,
    this.frameUrl,
  });

  final String name;
  final String avatar;
  final String? frameUrl;

  @override
  Widget build(BuildContext context) {
    // FramedUserAvatar adds its own frame padding (~1.34×); keep visual ~40dp.
    return FramedUserAvatar(
      name: name,
      imageUrl: avatar,
      frameUrl: frameUrl,
      frameSeed: name,
      size: 34,
      fontSize: TextStyles.k10FontSize,
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.path});

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
        child: Icon(Icons.videocam_rounded, color: kColorWhite, size: 28),
      ),
    );
  }
}
